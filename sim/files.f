// Directorios de inclusión (headers/defines)
+incdir+../tb/pkg
+incdir+../tb/if

// 1. Paquete primero (tipos de datos, transacciones)
../tb/pkg/bus_pkg.sv

// 2. Interfaz
../tb/if/bus_if.sv

// 3. Componentes del Ambiente TB
../tb/gen/generator.sv
../tb/drv/driver.sv
../tb/mon/monitor.sv
../tb/sb/scoreboard.sv
../tb/cov/coverage.sv
../tb/env/environment.sv
../tb/test/test_top.sv

// 4. RTL / DUT
../rtl/Library.sv
../rtl/fifo.sv
../rtl/top_dut.sv
