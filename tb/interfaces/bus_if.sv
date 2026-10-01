//==============================================================================
// <NOMBRE DEL CURSO>
// Integrantes: <Integrante 1> - <Integrante 2>
//==============================================================================
// Archivo   : bus_if.sv
// Componente: Interfaz física entre el ambiente de verificación y el DUT
//------------------------------------------------------------------------------
// Descripción:
//   Agrupa las señales del único bus del DUT y expone modports de señales:
//     - driver_mp  -> el Driver conduce pndng/D_pop y lee pop
//     - monitor_mp -> el Monitor solo lee pop/D_pop/push/D_push
//

//==============================================================================
`include "tb_pkg.sv"

interface bus_if #(
  parameter int bits    = tb_pkg::BITS_DEFAULT,
  parameter int drvrs   = tb_pkg::DRVRS_DEFAULT,
  parameter int pckg_sz = tb_pkg::PCKG_SZ_DEFAULT
)(input logic clk);
 
  logic reset;
 
  logic                  pndng [bits-1:0][drvrs-1:0];
  logic [pckg_sz-1:0]    D_pop [bits-1:0][drvrs-1:0];
  logic                  pop   [bits-1:0][drvrs-1:0];
 
  logic                  push  [bits-1:0][drvrs-1:0];
  logic [pckg_sz-1:0]    D_push[bits-1:0][drvrs-1:0];
 
  // Modports

  modport driver_mp (
    input  clk, reset, pop,
    output pndng, D_pop
  );
 
  modport monitor_mp (
    input clk, reset, pop, D_pop, push, D_push
  );
 
endinterface