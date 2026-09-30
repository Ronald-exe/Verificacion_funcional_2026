
// Bus if · SV
//==============================================================================
// <NOMBRE DEL CURSO>
// Integrantes: <Integrante 1> - <Integrante 2>
//==============================================================================
// Archivo   : bus_if.sv
// Componente: Interfaz física entre el ambiente de verificación y el DUT
//------------------------------------------------------------------------------
// Descripción:
//   Agrupa las señales del bus compartido bs_gnrtr_n_rbtr y expone dos
//   modports basados en clocking blocks (antes se accedía a las señales
//   directo, sin CB, y el driver "resolvía" la carrera contra el DUT
//   conduciendo en negedge):
//     - driver_mp  (vía cb_drv)  -> el Driver conduce pndng/D_pop y lee pop
//     - monitor_mp (vía cb_mon)  -> el Monitor solo lee pop/D_pop/push/D_push
//

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
  // debe declararse igual para que la conexión de puertos type-matchee.
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
 
  modport monitor_mp (
    input clk, reset, pop, D_pop, push, D_push
  );
 
endinterface