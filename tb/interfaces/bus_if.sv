//==============================================================================
// <NOMBRE DEL CURSO>
// Integrantes: <Integrante 1> - <Integrante 2>
//==============================================================================
// Archivo   : bus_if.sv
// Componente: Interfaz de conexión entre el testbench y el DUT bs_gnrtr_n_rbtr
//------------------------------------------------------------------------------
// Descripción:
//   Contiene ÚNICAMENTE las señales físicas del DUT (DUT_BUS_SPEC.md sec. 3):
//     clk, reset, pndng, D_pop, pop, push, D_push
//
//   Esta interfaz es solo el mecanismo de conexión. NO contiene:
//     - Scoreboard, Checker, Generator
//     - lógica de predicción
//     - queues
//     - mailboxes
//   Toda esa lógica vive en las clases del testbench, no en la interfaz.
//
// Parámetros:
//   bits    - fijo = 1 (se mantiene como parámetro por consistencia con el DUT)
//   drvrs   - cantidad de interfaces/drivers del bus (2, 4, 8, ...)
//   pckg_sz - tamaño del paquete en bits (16, 32, 64)
//
// Conexión:
//   tb_top.sv instancia esta interfaz y la conecta físicamente a los puertos
//   del módulo bs_gnrtr_n_rbtr. Driver y Monitor acceden a ella mediante
//   virtual interfaces tipadas con los modports definidos abajo.
//==============================================================================

// Interfase generica para que la interfase virtual se conecte
// de forma directa, ya inicializa clk y define modports del 
// dut que puertos son:
//
// reset, pndng, D_pop, pop, push y D_push


interface bus_if #(
  parameter int bits = 1, 
  parameter int drvrs = 4,
  parameter int pckg_sz = 16
)(

  input logic clk

);


  logic reset;

  logic				        reset;
  logic 			        pndng[bits-1:0][drvrs-1:0];
  logic [pckg_sz-1:0] D_pop[bits-1:0][drvrs-1:0];
  logic 			        pop[bits-1:0][drvrs-1:0];
  logic 			        push[bits-1:0][drvrs-1:0];
  logic [pckg_sz-1:0] D_push[bits-1:0][drvrs-1:0];

  modport dut (
    input  reset, pndng, D_pop
    output pop, push, D_push

  );

  modport driver_mp (
    input  pop, clk
    output pndng, D_pop,
  );

  modport monitor_mp (
    input  pndng, D_pop, pop, push,D_push, clk
  );

endinterface
