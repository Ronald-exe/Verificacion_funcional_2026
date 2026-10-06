.DEFAULT_GOAL := help

DRVRS ?= 4
PCKG_SZ ?= 16
BITS ?= 1
BROADCAST ?= 255
SCENARIO ?= SC_MIXED
NUM ?= 50
SEED ?= 1
SCENARIOS ?= SC_RANDOM SC_BURST SC_CONCURRENT SC_BOUNDARY SC_MIXED
SEEDS ?= 1 2 3
BUILD_DIR = sim/eda_vcs/d$(DRVRS)_p$(PCKG_SZ)_b$(BROADCAST)/build
RUN_DIR = sim/eda_vcs/d$(DRVRS)_p$(PCKG_SZ)_b$(BROADCAST)/$(SCENARIO)_n$(NUM)_s$(SEED)
CSV ?= $(RUN_DIR)/reporte_paquetes.csv
PLOT ?= $(RUN_DIR)/histograma_retardos.png
ANCHO ?= 50
VCS_SETUP ?= /mnt/vol_NFS_rh003/estudiantes/archivos_config/synopsys_tools2.sh

.PHONY: help compile run regression plot verdi

help:
	@printf '%s\n' \
	  'make compile [DRVRS=4 PCKG_SZ=16 BITS=1 BROADCAST=255]' \
	  'make run [DRVRS=4 PCKG_SZ=16 BROADCAST=255 SCENARIO=SC_MIXED NUM=50 SEED=1]' \
	  'make verdi [DRVRS=4 PCKG_SZ=16 BROADCAST=255 SCENARIO=SC_MIXED NUM=50 SEED=1]' \
	  'NUM is the number of transactions generated per source/interface' \
	  'Compile once per structural configuration; run before verdi' \
	  'make regression [SCENARIOS="SC_RANDOM SC_MIXED" SEEDS="1 2 3"]' \
	  'make plot [ANCHO=50 CSV=sim/eda_vcs/.../reporte_paquetes.csv]'

compile:
	@DRVRS='$(DRVRS)' PCKG_SZ='$(PCKG_SZ)' BITS='$(BITS)' BROADCAST='$(BROADCAST)' \
	 VCS_SETUP='$(VCS_SETUP)' bash ./scripts/run_eda_vcs.sh compile

run:
	@DRVRS='$(DRVRS)' PCKG_SZ='$(PCKG_SZ)' BITS='$(BITS)' BROADCAST='$(BROADCAST)' \
	 SCENARIO='$(SCENARIO)' NUM='$(NUM)' SEED='$(SEED)' VCS_SETUP='$(VCS_SETUP)' \
	 bash ./scripts/run_eda_vcs.sh run

verdi:
	@DRVRS='$(DRVRS)' PCKG_SZ='$(PCKG_SZ)' BITS='$(BITS)' BROADCAST='$(BROADCAST)' \
	 SCENARIO='$(SCENARIO)' NUM='$(NUM)' SEED='$(SEED)' VCS_SETUP='$(VCS_SETUP)' \
	 bash ./scripts/run_eda_vcs.sh verdi

regression:
	@set -eu; \
	for scenario in $(SCENARIOS); do \
	  for seed in $(SEEDS); do \
	    DRVRS='$(DRVRS)' PCKG_SZ='$(PCKG_SZ)' BITS='$(BITS)' BROADCAST='$(BROADCAST)' \
	    SCENARIO="$$scenario" NUM='$(NUM)' SEED="$$seed" VCS_SETUP='$(VCS_SETUP)' \
	    bash ./scripts/run_eda_vcs.sh run; \
	  done; \
	done

plot:
	@test -f "$(CSV)" || { echo "CSV no encontrado: $(CSV)" >&2; exit 1; }
	@command -v gnuplot >/dev/null 2>&1 || { echo "gnuplot no esta disponible" >&2; exit 127; }
	@test "$(ANCHO)" -gt 0 || { echo "ANCHO debe ser un entero mayor que cero" >&2; exit 2; }
	@mkdir -p "$(dir $(PLOT))"
	@gnuplot -e "archivo='$(CSV)'; salida='$(PLOT)'; ancho=$(ANCHO)" EDA_VCS/histograma.gp
