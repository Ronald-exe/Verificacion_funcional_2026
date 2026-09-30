#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd -- "$script_dir/.." && pwd)
cd "$repo_root"

usage() {
  cat <<'EOF'
Usage: bash scripts/run_vcs.sh MODE [SEED]

Modes:
  random          Mixed traffic (default)
  unicast         Valid unicast destinations
  broadcast       Broadcast traffic
  invalid         Invalid destinations
  addr_edges      Destination boundary values
  one_if          Traffic from one interface
  two_if          Contention between two interfaces
  patterns        Payload patterns
  back_to_back    No delay between offered packets
  idle            Long idle intervals
  reset           Reset during traffic

Optional environment settings: DRVRS (2, 4, 8), PCKG_SZ (16, 32, 64),
SRC_A, SRC_B. Example:
  DRVRS=8 PCKG_SZ=32 bash scripts/run_vcs.sh broadcast 17
EOF
}

mode=${1:-random}
seed=${2:-1}
drvrs=${DRVRS:-4}
pckg_sz=${PCKG_SZ:-16}
src_a=${SRC_A:-0}
src_b=${SRC_B:-1}
delay_min=0
delay_max=10
reset_at=0
reset_cycles=5

case "$drvrs" in
  2|4|8) ;;
  *) echo "Unsupported DRVRS=$drvrs (choose 2, 4, or 8)." >&2; exit 2 ;;
esac
case "$pckg_sz" in
  16|32|64) ;;
  *) echo "Unsupported PCKG_SZ=$pckg_sz (choose 16, 32, or 64)." >&2; exit 2 ;;
esac

case "$mode" in
  random) scenario=SC_RANDOM ;;
  unicast) scenario=SC_UNICAST ;;
  broadcast) scenario=SC_BROADCAST ;;
  invalid) scenario=SC_INVALID ;;
  addr_edges) scenario=SC_ADDR_EDGES ;;
  one_if) scenario=SC_ONE_IF ;;
  two_if)
    scenario=SC_TWO_IF
    src_a=${SRC_A:-1}
    src_b=${SRC_B:-3}
    ;;
  patterns) scenario=SC_PATTERNS ;;
  back_to_back)
    scenario=SC_RANDOM
    delay_max=0
    ;;
  idle)
    scenario=SC_RANDOM
    delay_min=50
    delay_max=100
    ;;
  reset)
    scenario=SC_RANDOM
    reset_at=300
    ;;
  -h|--help|help) usage; exit 0 ;;
  *) echo "Unknown mode: $mode" >&2; usage >&2; exit 2 ;;
esac

if [[ "$mode" == two_if ]] && (( src_a >= drvrs || src_b >= drvrs || src_a == src_b )); then
  echo "two_if needs distinct SRC_A and SRC_B values smaller than DRVRS." >&2
  exit 2
fi

if ! command -v vcs >/dev/null 2>&1; then
  echo "VCS was not found. Load the Synopsys VCS environment and license first." >&2
  exit 127
fi

build_dir="$repo_root/sim/${mode}_drvrs${drvrs}_pckg${pckg_sz}_src${src_a}_${src_b}"
mkdir -p "$build_dir"
defines="+define+SCENARIO=${scenario}+DRVRS=${drvrs}+PCKG_SZ=${pckg_sz}+SRC_A=${src_a}+SRC_B=${src_b}+DELAY_MIN=${delay_min}+DELAY_MAX=${delay_max}+RESET_AT=${reset_at}+RESET_CYCLES=${reset_cycles}"

printf 'Mode: %s | drvrs=%s | pckg_sz=%s | seed=%s\n' "$mode" "$drvrs" "$pckg_sz" "$seed"
vcs -full64 -sverilog -timescale=1ns/1ns \
  -f tb/filelist.f \
  -top tb_top \
  -Mdir="$build_dir/csrc" \
  -o "$build_dir/simv" \
  "$defines" 2>&1 | tee "$build_dir/compile.log"

(cd "$build_dir" && ./simv "+ntb_random_seed=$seed" 2>&1 | tee run.log)