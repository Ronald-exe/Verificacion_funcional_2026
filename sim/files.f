// Ejecutado desde sim/: resolver los includes desde la raiz del proyecto
// y el include interno de Library.sv desde rtl/.
+incdir+..
+incdir+../rtl

// Punto de entrada unico: incluye RTL y componentes del ambiente.
../tb/tests/testbench.sv
