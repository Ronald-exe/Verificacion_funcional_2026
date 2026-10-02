#!/usr/bin/env bash
#==============================================================================
# Verificación Funcional
# Integrantes: Ronald - Eric
#==============================================================================
# Archivo   : comando.sh
# Descripción:
#   Compila y corre el ambiente con Synopsys VCS en el servidor de la escuela.
#   Cada caso se compila con sus propios +define (igual que las Compile
#   Options de EDA Playground) y se ejecuta en su carpeta sim/<caso>/, donde
#   quedan compile.log, sim.log, reporte_paquetes.csv, dump.vcd y, si hay
#   Verdi, waves.fsdb.
#   No borra nada fuera de sim/.
#
# Uso:
#   ./comando.sh                      -> menú: elegir el número del caso y la semilla
#   ./comando.sh 3                    -> caso número 3 del menú, seed=1
#   ./comando.sh 3 25                 -> caso número 3 del menú, seed=25
#   ./comando.sh broadcast            -> un caso, seed=1
#   ./comando.sh broadcast 25         -> un caso con seed=25
#   ./comando.sh broadcast auto       -> un caso con semilla automática
#   ./comando.sh todos                -> todos los casos, seed=1
#   ./comando.sh todos auto           -> todos los casos, semilla automática
#   ./comando.sh custom 1 "SCENARIO=SC_BROADCAST+DRVRS=8+DELAY_MAX=0"
#                                     -> defines a mano (lo que va después de +define+)
#   ./comando.sh lista                -> muestra los casos disponibles
#
#   VERDI=0 ./comando.sh todos       -> sin grabar ondas FSDB (más rápido)
#
#   Cada caso se compila con vcs -kdb -debug_access+all, por lo que la base
#   de datos de Verdi queda en sim/<caso>/simv.daidir. Si Verdi está
#   disponible, además se graban las ondas de todo tb_top en waves.fsdb:
#     cd sim/<caso> && verdi -dbdir simv.daidir -ssf waves.fsdb &
#   Sin FSDB se puede abrir con el VCD (solo señales del DUT):
#     cd sim/<caso> && verdi -dbdir simv.daidir -ssf dump.vcd &
#
#   Al final imprime una tabla resumen y la guarda en sim/resumen.txt y
#   sim/resumen.csv (una fila por caso, lista para el informe).
#==============================================================================

# Herramientas de Synopsys del servidor (mismo archivo que usa el curso)
SYNOPSYS_CFG=/mnt/vol_NFS_rh003/estudiantes/archivos_config/synopsys_tools2.sh
if ! command -v vcs > /dev/null 2>&1; then
  if [ -f "$SYNOPSYS_CFG" ]; then
    source "$SYNOPSYS_CFG"
  fi
fi
if ! command -v vcs > /dev/null 2>&1; then
  echo "ERROR: no se encontro vcs. Revisar la ruta SYNOPSYS_CFG en comando.sh"
  exit 1
fi

# Carpeta donde están los .sv (la misma de este script)
SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Resultados de las simulaciones (fuera de los .sv para no mezclarlos)
SIM_DIR="$SRC_DIR/sim"

# Opciones base (las mismas de EDA Playground + las del servidor)
VCS_OPTS="-full64 -sverilog -timescale=1ns/1ns +vcs+flush+all +warn=all +lint=TFIPC-L"

# Base de datos de Verdi: siempre se compila con -kdb (KDB del diseño en
# simv.daidir) y -debug_access+all (acceso a todas las señales).
VCS_OPTS="$VCS_OPTS -kdb -lca -debug_access+all"

# Verdi: se busca en el PATH o en $VERDI_HOME/bin. Si está, la simulación
# graba las ondas de tb_top en sim/<caso>/waves.fsdb (VERDI=0 lo desactiva).
if ! command -v verdi > /dev/null 2>&1 && [ -n "$VERDI_HOME" ] && [ -x "$VERDI_HOME/bin/verdi" ]; then
  PATH="$PATH:$VERDI_HOME/bin"
fi
USAR_VERDI=0
if [ "${VERDI:-1}" != "0" ] && command -v verdi > /dev/null 2>&1; then
  USAR_VERDI=1
fi

# -- Casos: nombre -> defines (lo que va después de +define+) ----------------
# Ver README.md sección 4 para la relación con el plan de pruebas (TP).
CASOS=(
  "random|"
  "unicast|SCENARIO=SC_UNICAST"
  "broadcast|SCENARIO=SC_BROADCAST"
  "invalid|SCENARIO=SC_INVALID"
  "addr_edges|SCENARIO=SC_ADDR_EDGES"
  "one_if|SCENARIO=SC_ONE_IF"
  "two_if|SCENARIO=SC_TWO_IF+SRC_A=1+SRC_B=3"
  "patterns|SCENARIO=SC_PATTERNS"
  "idle|DELAY_MIN=50+DELAY_MAX=100"
  "back2back|DELAY_MAX=0"
  "reset|RESET_AT=300"
  "d2_p16|DRVRS=2+PCKG_SZ=16"
  "d2_p32|DRVRS=2+PCKG_SZ=32"
  "d2_p64|DRVRS=2+PCKG_SZ=64"
  "d4_p16|DRVRS=4+PCKG_SZ=16"
  "d4_p32|DRVRS=4+PCKG_SZ=32"
  "d4_p64|DRVRS=4+PCKG_SZ=64"
  "d8_p16|DRVRS=8+PCKG_SZ=16"
  "d8_p32|DRVRS=8+PCKG_SZ=32"
  "d8_p64|DRVRS=8+PCKG_SZ=64"
  "bcast_param|BROADCAST=240+SCENARIO=SC_BCAST_PARAM"
)

# Descripción de cada caso para el menú (mismo orden que CASOS)
DESCS=(
  "TP08/TP11 Trafico mixto aleatorio (default)"
  "TP03      Solo unicast"
  "TP04/06   Solo broadcast"
  "TP05      Direccion invalida"
  "TP03/05   Bordes de direccion"
  "TP02      Una sola interfaz transmite"
  "TP07      Contencion entre dos interfaces (1 y 3)"
  "TP12      Patrones de payload"
  "TP09      Idle (retardo 50..100)"
  "TP10      Back-to-back (retardo 0)"
  "TP01      Reset en actividad (ciclo 300)"
  "TP14/15   drvrs=2 pckg_sz=16"
  "TP14/15   drvrs=2 pckg_sz=32"
  "TP14/15   drvrs=2 pckg_sz=64"
  "TP14/15   drvrs=4 pckg_sz=16"
  "TP14/15   drvrs=4 pckg_sz=32"
  "TP14/15   drvrs=4 pckg_sz=64"
  "TP14/15   drvrs=8 pckg_sz=16"
  "TP14/15   drvrs=8 pckg_sz=32"
  "TP14/15   drvrs=8 pckg_sz=64"
  "TP16      broadcast=0xF0: FAIL esperado (RTL usa 0xFF fijo)"
)
N_CASOS=${#CASOS[@]}
OPC_TODOS=$(( N_CASOS + 1 ))

RESUMEN=()

# correr_caso <nombre> <defines> <seed>
correr_caso() {
  local nombre="$1"
  local defines="$2"
  local seed="$3"
  local dir="$SIM_DIR/$nombre"
  local def_opt=""
  local seed_opt=""

  [ -n "$defines" ] && def_opt="+define+$defines"
  if [ "$seed" = "auto" ]; then
    seed_opt="+ntb_random_seed_automatic"
  else
    seed_opt="+ntb_random_seed=$seed"
  fi

  echo "=================================================================="
  echo "  CASO: $nombre   defines: ${defines:-(default)}   seed: $seed"
  echo "=================================================================="

  rm -rf "$dir"
  mkdir -p "$dir"
  cd "$dir" || return

  # Compilación
  # (con "todos" la salida de VCS va solo a compile.log)
  if [ "$SILENCIO" = "1" ]; then
    echo ">> compilando $nombre ..."
    vcs $VCS_OPTS +incdir+"$SRC_DIR" $def_opt "$SRC_DIR/testbench.sv" \
        -o simv -l compile.log > /dev/null 2>&1
  else
    vcs $VCS_OPTS +incdir+"$SRC_DIR" $def_opt "$SRC_DIR/testbench.sv" \
        -o simv -l compile.log
  fi
  if [ $? -ne 0 ] || [ ! -x simv ]; then
    echo ">> $nombre: ERROR DE COMPILACION (ver $dir/compile.log)"
    echo "$nombre,${defines:-default},,,,,,,,,,COMPILACION" >> "$RESUMEN_CSV"
    RESUMEN+=("$(printf '%-11s %s' "$nombre" "ERROR DE COMPILACION (ver sim/$nombre/compile.log)")")
    cd "$SRC_DIR"
    return
  fi

  # Ejecución (con "todos" la salida va solo a sim.log para no llenar la terminal).
  # Con Verdi, UCLI graba las ondas de todo tb_top en waves.fsdb.
  local sim_opts="$seed_opt -l sim.log"
  if [ "$USAR_VERDI" = "1" ]; then
    printf 'dump -file waves.fsdb -type FSDB\ndump -add tb_top -depth 0\nrun\nquit\n' > dump_fsdb.tcl
    sim_opts="$sim_opts -ucli -i dump_fsdb.tcl"
  fi
  if [ "$SILENCIO" = "1" ]; then
    echo ">> simulando $nombre ..."
    ./simv $sim_opts < /dev/null > /dev/null
  else
    ./simv $sim_opts < /dev/null
  fi
  if [ "$SILENCIO" != "1" ]; then
    echo ">> base de datos Verdi (vcs -kdb): sim/$nombre/simv.daidir"
    if [ -f waves.fsdb ]; then
      echo ">> abrir: cd sim/$nombre && verdi -dbdir simv.daidir -ssf waves.fsdb &"
    else
      echo ">> abrir: cd sim/$nombre && verdi -dbdir simv.daidir -ssf dump.vcd &"
    fi
  fi

  # Datos del reporte final del Checker
  local semilla num_tx ok err pend lat rr resultado
  semilla=$(grep -m1 "  seed=" sim.log | sed 's/.*seed=//')
  num_tx=$(grep -m1 "num_transactions=" sim.log | sed 's/.*num_transactions=\([0-9]*\).*/\1/')
  ok=$(grep "Transacciones correctas" sim.log | sed 's/.*: *//')
  err=$(grep "Transacciones con error" sim.log | sed 's/.*: *//')
  pend=$(grep "Esperados no observados" sim.log | sed 's/.*: *//')
  lat=$(grep "Retardo pop->push" sim.log | sed -E 's/.*min=([0-9]+) +max=([0-9]+) +prom=([0-9.]+).*/\1,\2,\3/')
  [ -z "$lat" ] && lat=",,"
  rr=$(grep -m1 "Round Robin *: [0-9]" sim.log | sed -E 's/.*, ([0-9]+) violaciones.*/\1/')
  if grep -q "RESULTADO: \*\* PASS" sim.log; then
    resultado="PASS"
  elif grep -q "RESULTADO" sim.log; then
    resultado="FAIL"
  elif grep -q "WATCHDOG" sim.log; then
    resultado="WATCHDOG"
  else
    resultado="SIN_RESULTADO"
  fi

  # TP16: el FAIL es la evidencia de que el RTL ignora el parámetro broadcast
  [ "$nombre" = "bcast_param" ] && [ "$resultado" = "FAIL" ] && resultado="FAIL_ESPERADO_TP16"

  echo "$nombre,${defines:-default},$semilla,$num_tx,$ok,$err,$pend,$lat,$rr,$resultado" >> "$RESUMEN_CSV"
  RESUMEN+=("$(printf '%-11s %-11s %5s %6s %5s %5s %16s %3s  %s' \
            "$nombre" "$semilla" "$num_tx" "$ok" "$err" "$pend" \
            "$(echo "$lat" | tr ',' '/')" "$rr" "$resultado")")
  cd "$SRC_DIR"
}

buscar_defines() {
  local c
  for c in "${CASOS[@]}"; do
    if [ "${c%%|*}" = "$1" ]; then
      echo "${c#*|}"
      return 0
    fi
  done
  return 1
}

mostrar_menu() {
  local i
  echo "=================================================================="
  echo "  CASOS DISPONIBLES"
  echo "=================================================================="
  for (( i=0; i<N_CASOS; i++ )); do
    printf '  %2d) %-11s %s\n' $(( i + 1 )) "${CASOS[$i]%%|*}" "${DESCS[$i]}"
  done
  printf '  %2d) %-11s %s\n' "$OPC_TODOS" "todos" "Corre los $N_CASOS casos"
  printf '  %2d) %s\n' 0 "salir"
  echo "=================================================================="
}

# Número de opción -> nombre del caso (1..N_CASOS, N_CASOS+1 = todos)
numero_a_caso() {
  local n="$1"
  if [ "$n" -ge 1 ] && [ "$n" -le "$N_CASOS" ]; then
    echo "${CASOS[$(( n - 1 ))]%%|*}"
  elif [ "$n" -eq "$OPC_TODOS" ]; then
    echo "todos"
  else
    return 1
  fi
}

# -- Argumentos -------------------------------------------------------------
# Sin argumentos: menú interactivo (elegir número y semilla)
if [ $# -eq 0 ]; then
  mostrar_menu
  read -r -p "  Elegi un numero [0-$OPC_TODOS]: " OPC
  if [[ ! "$OPC" =~ ^[0-9]+$ ]] || [ "$OPC" -eq 0 ]; then
    echo "  Saliendo."
    exit 0
  fi
  if ! CASO=$(numero_a_caso "$OPC"); then
    echo "  Opcion invalida: $OPC"
    exit 1
  fi
  read -r -p "  Semilla [Enter = 1, un numero, o 'auto' = aleatoria]: " SEED
  SEED="${SEED:-1}"
  # Con un solo caso se puede abrir Verdi directamente al terminar
  if [ "$USAR_VERDI" = "1" ] && [ "$CASO" != "todos" ]; then
    read -r -p "  Abrir Verdi al terminar? [s/N]: " RESP
    [[ "$RESP" =~ ^[sS]$ ]] && ABRIR_VERDI=1
  fi
else
  CASO="$1"
  SEED="${2:-1}"
  # También se acepta el número del menú: ./comando.sh 3 25
  if [[ "$CASO" =~ ^[0-9]+$ ]]; then
    if ! CASO=$(numero_a_caso "$1"); then
      echo "Opcion invalida: $1  (./comando.sh lista para ver los casos)"
      exit 1
    fi
  fi
fi

if [[ ! "$SEED" =~ ^[0-9]+$ ]] && [ "$SEED" != "auto" ]; then
  echo "Semilla invalida: '$SEED' (usar un numero o 'auto')"
  exit 1
fi

SILENCIO=0
[ "$CASO" = "todos" ] && SILENCIO=1

# Resumen de esta ejecución: tabla en terminal + sim/resumen.txt + sim/resumen.csv
RESUMEN_CSV="$SIM_DIR/resumen.csv"
RESUMEN_TXT="$SIM_DIR/resumen.txt"
if [ "$CASO" != "lista" ]; then
  mkdir -p "$SIM_DIR"
  echo "caso,defines,seed,num_tx,correctas,errores,pendientes,lat_min_ns,lat_max_ns,lat_prom_ns,rr_violaciones,resultado" > "$RESUMEN_CSV"
fi

case "$CASO" in
  lista)
    mostrar_menu
    echo "  custom: ./comando.sh custom <seed> \"DEFINE1=X+DEFINE2=Y\""
    exit 0
    ;;
  todos)
    for c in "${CASOS[@]}"; do
      correr_caso "${c%%|*}" "${c#*|}" "$SEED"
    done
    ;;
  custom)
    correr_caso "custom" "${3:-}" "$SEED"
    ;;
  *)
    if DEFS=$(buscar_defines "$CASO"); then
      correr_caso "$CASO" "$DEFS" "$SEED"
    else
      echo "Caso desconocido: $CASO  (./comando.sh lista para ver los casos)"
      exit 1
    fi
    ;;
esac

# -- Resumen ----------------------------------------------------------------
N_PASS=$(grep -c ",PASS$" "$RESUMEN_CSV")
N_TOTAL=$(( $(wc -l < "$RESUMEN_CSV") - 1 ))
{
  echo ""
  echo "=================================================================================="
  echo "  RESUMEN  $(date '+%Y-%m-%d %H:%M')   PASS: $N_PASS de $N_TOTAL"
  echo "=================================================================================="
  printf '  %-11s %-11s %5s %6s %5s %5s %16s %3s  %s\n' \
         "caso" "seed" "n_tx" "ok" "err" "pend" "lat min/max/prom" "rr" "resultado"
  echo "  --------------------------------------------------------------------------------"
  for r in "${RESUMEN[@]}"; do
    echo "  $r"
  done
  echo "=================================================================================="
  echo "  Detalle de cada caso: sim/<caso>/sim.log, compile.log, reporte_paquetes.csv"
  echo "  Tabla para el informe: sim/resumen.csv"
  echo "  Base de datos Verdi (vcs -kdb): sim/<caso>/simv.daidir"
  if [ "$USAR_VERDI" = "1" ]; then
    echo "  Abrir en Verdi: cd sim/<caso> && verdi -dbdir simv.daidir -ssf waves.fsdb &"
  else
    echo "  Abrir en Verdi: cd sim/<caso> && verdi -dbdir simv.daidir -ssf dump.vcd &"
    echo "  (sin waves.fsdb: verdi no se encontro al correr; dump.vcd tiene solo el DUT)"
  fi
} | tee "$RESUMEN_TXT"

# Abrir Verdi con el caso recién simulado (si se pidió en el menú)
if [ "${ABRIR_VERDI:-0}" = "1" ] && [ -d "$SIM_DIR/$CASO/simv.daidir" ]; then
  ONDAS=waves.fsdb
  [ -f "$SIM_DIR/$CASO/$ONDAS" ] || ONDAS=dump.vcd
  (cd "$SIM_DIR/$CASO" && verdi -dbdir simv.daidir -ssf "$ONDAS" > verdi.log 2>&1 &)
  echo "  Abriendo Verdi con sim/$CASO/$ONDAS ..."
fi

