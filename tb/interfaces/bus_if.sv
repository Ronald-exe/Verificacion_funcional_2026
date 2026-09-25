
Bus if · SV
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
 
  logic [drvrs-1:0]   pndng;
  logic [pckg_sz-1:0] D_pop  [drvrs];
  logic [drvrs-1:0]   pop;
 
  logic [drvrs-1:0]   push;
  logic [pckg_sz-1:0] D_push [drvrs];
 
  // Clocking blocks
  
  clocking cb_drv @(posedge clk);
    default input #1step output #1;
    output pndng, D_pop;
    input  pop;
  endclocking
 
  clocking cb_mon @(posedge clk);
    default input #1step;
    input pop, D_pop, push, D_push;
  endclocking
 
  // Modports

  modport driver_mp (
    input  clk, reset, pop,
    output pndng, D_pop
  );
 
  modport monitor_mp (
    input clk, reset, pop, D_pop, push, D_push
  );
 
endinterface