#!/usr/bin/env bash
#==============================================================================
# Verificación Funcional
# Integrantes: Ronald - Eric
#==============================================================================
# Archivo   : comando.sh
# Descripción:
#   Compila y corre el ambiente con Synopsys VCS en el servidor de la escuela.
#   Cada caso se compila con sus propios +define (igual que las Compile
#   Options de EDA Playground) y se ejecuta en su carpeta runs/<caso>/, donde
#   quedan compile.log, sim.log, reporte_paquetes.csv y dump.vcd.
#   No borra nada fuera de runs/.
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
#   Al final imprime una tabla resumen y la guarda en runs/resumen.txt y
#   runs/resumen.csv (una fila por caso, lista para el informe).
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
RUNS_DIR="$SRC_DIR/runs"

# Opciones base (las mismas de EDA Playground + las del servidor)
VCS_OPTS="-full64 -sverilog -timescale=1ns/1ns +vcs+flush+all +warn=all +lint=TFIPC-L"

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
)
N_CASOS=${#CASOS[@]}
OPC_TODOS=$(( N_CASOS + 1 ))

RESUMEN=()

# correr_caso <nombre> <defines> <seed>
correr_caso() {
  local nombre="$1"
  local defines="$2"
  local seed="$3"
  local dir="$RUNS_DIR/$nombre"
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
    RESUMEN+=("$(printf '%-11s %s' "$nombre" "ERROR DE COMPILACION (ver runs/$nombre/compile.log)")")
    cd "$SRC_DIR"
    return
  fi

  # Ejecución (con "todos" la salida va solo a sim.log para no llenar la terminal)
  if [ "$SILENCIO" = "1" ]; then
    echo ">> simulando $nombre ..."
    ./simv $seed_opt -l sim.log > /dev/null
  else
    ./simv $seed_opt -l sim.log
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

# Resumen de esta ejecución: tabla en terminal + runs/resumen.txt + runs/resumen.csv
RESUMEN_CSV="$RUNS_DIR/resumen.csv"
RESUMEN_TXT="$RUNS_DIR/resumen.txt"
if [ "$CASO" != "lista" ]; then
  mkdir -p "$RUNS_DIR"
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
  echo "  Detalle de cada caso: runs/<caso>/sim.log, compile.log, reporte_paquetes.csv"
  echo "  Tabla para el informe: runs/resumen.csv"
} | tee "$RESUMEN_TXT"

