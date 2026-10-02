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

.PHONY: help run regression

help:
	@printf '%s\n' \
	  'make run [DRVRS=4 PCKG_SZ=16 BITS=1 BROADCAST=255 SCENARIO=SC_MIXED NUM=50 SEED=1]' \
	  'make regression [SCENARIOS="SC_RANDOM SC_MIXED" SEEDS="1 2 3"]'

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
