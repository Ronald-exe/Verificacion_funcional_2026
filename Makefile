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
RUN_DIR = sim/eda_vcs/d$(DRVRS)_p$(PCKG_SZ)_b$(BROADCAST)/$(SCENARIO)_n$(NUM)_s$(SEED)
CSV ?= $(RUN_DIR)/reporte_paquetes.csv
PLOT ?= $(RUN_DIR)/histograma_retardos.png

.PHONY: help run regression plot

help:
	@printf '%s\n' \
	  'make run [DRVRS=4 PCKG_SZ=16 BITS=1 BROADCAST=255 SCENARIO=SC_MIXED NUM=50 SEED=1]' \
	  'NUM is the number of transactions generated per source/interface' \
	  'make regression [SCENARIOS="SC_RANDOM SC_MIXED" SEEDS="1 2 3"]' \
	  'make plot [CSV=sim/eda_vcs/.../reporte_paquetes.csv]'

run:
	@DRVRS='$(DRVRS)' PCKG_SZ='$(PCKG_SZ)' BITS='$(BITS)' BROADCAST='$(BROADCAST)' \
	 SCENARIO='$(SCENARIO)' NUM='$(NUM)' SEED='$(SEED)' bash ./scripts/run_eda_vcs.sh

regression:
	@set -eu; \
	for scenario in $(SCENARIOS); do \
	  for seed in $(SEEDS); do \
	    DRVRS='$(DRVRS)' PCKG_SZ='$(PCKG_SZ)' BITS='$(BITS)' BROADCAST='$(BROADCAST)' \
	    SCENARIO="$$scenario" NUM='$(NUM)' SEED="$$seed" bash ./scripts/run_eda_vcs.sh; \
	  done; \
	done

plot:
	@test -f "$(CSV)" || { echo "CSV no encontrado: $(CSV)" >&2; exit 1; }
	@command -v gnuplot >/dev/null 2>&1 || { echo "gnuplot no esta disponible" >&2; exit 127; }
	@mkdir -p "$(dir $(PLOT))"
	@gnuplot -e "archivo='$(CSV)'; salida='$(PLOT)'" EDA_VCS/histograma.gp
