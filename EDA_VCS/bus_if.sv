//==============================================================================
// Verificación Funcional
// Integrantes: Ronald - Eric
//==============================================================================
// Archivo   : bus_if.sv
// Componente: Interfaz física entre el ambiente de verificación y el DUT
//------------------------------------------------------------------------------
// Descripción:
//   Agrupa las señales del bus compartido bs_gnrtr_n_rbtr y expone dos
//   modports que acceden a las señales directamente:
//     - driver_mp  -> el Driver conduce pndng/D_pop (en negedge, para no
//                     competir con el DUT que muestrea en posedge) y lee pop
//     - monitor_mp -> solo lectura de pndng/pop/D_pop/push/D_push; lo usan
//                     el Monitor y el chequeo de Round Robin del Checker
//
//   Los clocking blocks cb_drv/cb_mon quedan declarados pero los componentes
//   no los usan.
//==============================================================================


interface bus_if #(
  parameter int bits    = tb_pkg::BITS_DEFAULT,
  parameter int drvrs   = tb_pkg::DRVRS_DEFAULT,
  parameter int pckg_sz = tb_pkg::PCKG_SZ_DEFAULT
);
 
  logic clk;
  logic reset;
 
  // Forma 2D [bits-1:0][drvrs-1:0], igual que los puertos reales del DUT
  // (bs_gnrtr_n_rbtr en Library.sv). bits=1 es fijo, pero la dimensión
  // debe declararse igual para que la conexión de puertos type matchee.

  logic               pndng  [bits-1:0][drvrs-1:0];
  logic [pckg_sz-1:0] D_pop  [bits-1:0][drvrs-1:0];
  logic               pop    [bits-1:0][drvrs-1:0];

  logic               push   [bits-1:0][drvrs-1:0];
  logic [pckg_sz-1:0] D_push [bits-1:0][drvrs-1:0];

  // Modports

  modport driver_mp (
    input  clk, reset, pop,
    output pndng, D_pop
  );
 
  // pndng se incluye (solo lectura) para el chequeo de Round Robin del Checker
  modport monitor_mp (
    input clk, reset, pndng, pop, D_pop, push, D_push
  );
 
endinterface