# Invoke VCS from the repository root. testbench.sv includes the RTL and TB
# components in dependency order; rtl is also the include path for fifo.sv.
+incdir+rtl
tb/tests/testbench.sv
