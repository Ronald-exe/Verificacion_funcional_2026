#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
TB_DIR="$ROOT_DIR/EDA_VCS"
SIM_DIR="$ROOT_DIR/sim/eda_vcs"

VCS_SETUP="${VCS_SETUP:-/mnt/vol_NFS_rh003/estudiantes/archivos_config/synopsys_tools2.sh}"
ACTION="${1:-}"
DRVRS="${DRVRS:-4}"
PCKG_SZ="${PCKG_SZ:-16}"
BITS="${BITS:-1}"
BROADCAST="${BROADCAST:-255}"
SCENARIO="${SCENARIO:-SC_MIXED}"
NUM="${NUM:-50}"
SEED="${SEED:-1}"

if [[ "$ACTION" != compile && "$ACTION" != run && "$ACTION" != verdi ]]; then
  echo "Uso: $0 compile|run|verdi" >&2
  exit 2
fi

case "$DRVRS" in
  2|4|8) ;;
  *) echo "ERROR: DRVRS debe ser 2, 4 u 8 (recibido: $DRVRS)" >&2; exit 2 ;;
esac
case "$PCKG_SZ" in
  16|32|64) ;;
  *) echo "ERROR: PCKG_SZ debe ser 16, 32 o 64 (recibido: $PCKG_SZ)" >&2; exit 2 ;;
esac
if [[ "$BITS" != 1 ]]; then
  echo "ERROR: EDA_VCS solo soporta BITS=1 (recibido: $BITS)" >&2
  exit 2
fi
if [[ ! "$BROADCAST" =~ ^[0-9]+$ ]] || (( 10#$BROADCAST > 255 )); then
  echo "ERROR: BROADCAST debe ser un entero entre 0 y 255 (recibido: $BROADCAST)" >&2
  exit 2
fi
if [[ "$ACTION" == run || "$ACTION" == verdi ]]; then
  case "$SCENARIO" in
    SC_RANDOM|SC_BURST|SC_CONCURRENT|SC_BOUNDARY|SC_MIXED) ;;
    *) echo "ERROR: perfil SCENARIO desconocido: $SCENARIO" >&2; exit 2 ;;
  esac
  if [[ ! "$NUM" =~ ^[0-9]+$ ]]; then
    echo "ERROR: NUM debe ser un entero no negativo (recibido: $NUM)" >&2
    exit 2
  fi
  if [[ ! "$SEED" =~ ^[0-9]+$ ]]; then
    echo "ERROR: SEED debe ser un entero no negativo (recibido: $SEED)" >&2
    exit 2
  fi
fi

CONFIG_DIR="$SIM_DIR/d${DRVRS}_p${PCKG_SZ}_b${BROADCAST}"
BUILD_DIR="$CONFIG_DIR/build"

if [[ "$ACTION" == run && ! -x "$BUILD_DIR/simv" ]]; then
  echo "ERROR: no existe el ejecutable para DRVRS=$DRVRS PCKG_SZ=$PCKG_SZ BROADCAST=$BROADCAST." >&2
  echo "Ejecute primero: make compile DRVRS=$DRVRS PCKG_SZ=$PCKG_SZ BROADCAST=$BROADCAST" >&2
  exit 2
fi

RUN_DIR="$CONFIG_DIR/${SCENARIO}_n${NUM}_s${SEED}"
if [[ "$ACTION" == verdi ]]; then
  if [[ ! -f "$BUILD_DIR/simv.daidir/simv.kdb" ]]; then
    echo "ERROR: no se encontro la base KDB de Verdi en $BUILD_DIR/simv.daidir." >&2
    echo "Ejecute primero make compile con la misma configuracion estructural." >&2
    exit 2
  fi
  if [[ ! -f "$RUN_DIR/dump.vcd" ]]; then
    echo "ERROR: no se encontro el waveform $RUN_DIR/dump.vcd." >&2
    echo "Ejecute primero make run con los mismos DRVRS/PCKG_SZ/BROADCAST/SCENARIO/NUM/SEED." >&2
    exit 2
  fi
fi

if [[ -f "$VCS_SETUP" ]]; then
  # shellcheck source=/dev/null
  source "$VCS_SETUP"
fi
if [[ "$ACTION" == verdi ]]; then
  if ! command -v verdi >/dev/null 2>&1; then
    echo "ERROR: no se encontro Verdi. Configure VCS_SETUP o ejecute en el servidor Synopsys." >&2
    exit 127
  fi
else
  if ! command -v vcs >/dev/null 2>&1; then
    echo "ERROR: no se encontro VCS. Configure VCS_SETUP o ejecute en el servidor Synopsys." >&2
    exit 127
  fi
fi

if [[ "$ACTION" == compile ]]; then
  mkdir -p "$BUILD_DIR"
  cd "$BUILD_DIR"
  echo "Compilando RTL/TB: BITS=$BITS DRVRS=$DRVRS PCKG_SZ=$PCKG_SZ BROADCAST=$BROADCAST"
  echo "Ejecutable: $BUILD_DIR/simv"

  if ! vcs -Mupdate \
    -full64 \
    -sverilog \
    -kdb \
    -lca \
    -debug_access+all \
    -debug_region+design+cell+encrypt \
    +lint=TFIPC-L \
    -top tb_top \
    "+incdir+$TB_DIR" \
    "+define+DRVRS=$DRVRS+PCKG_SZ=$PCKG_SZ+BROADCAST=$BROADCAST" \
    -Mdir=csrc \
    -o simv \
    -l compile.log \
    "$TB_DIR/testbench.sv"; then
    echo "ERROR: compilacion VCS fallida; revisar $BUILD_DIR/compile.log" >&2
    exit 1
  fi
  exit 0
fi

if [[ "$ACTION" == verdi ]]; then
  echo "Abriendo Verdi: SCENARIO=$SCENARIO NUM=$NUM SEED=$SEED"
  echo "KDB: $BUILD_DIR/simv.daidir/simv.kdb"
  echo "VCD: $RUN_DIR/dump.vcd"
  exec verdi -dbdir "$BUILD_DIR/simv.daidir" -ssf "$RUN_DIR/dump.vcd"
fi

mkdir -p "$RUN_DIR"
cd "$RUN_DIR"
echo "Ejecutando: SCENARIO=$SCENARIO NUM=$NUM/source SEED=$SEED"
echo "Resultados: $RUN_DIR"

if ! "$BUILD_DIR/simv" "+SCENARIO=$SCENARIO" "+NUM=$NUM" "+SEED=$SEED" -l simulation.log; then
  echo "ERROR: simulacion fallida; revisar $RUN_DIR/simulation.log" >&2
  exit 1
fi
