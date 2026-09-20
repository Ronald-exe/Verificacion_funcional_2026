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

interface bus_if #(
  parameter int bits    = tb_pkg::BITS_DEFAULT,
  parameter int drvrs   = tb_pkg::DRVRS_DEFAULT,
  parameter int pckg_sz = tb_pkg::PCKG_SZ_DEFAULT
);

  logic clk;
  logic reset;

  logic [drvrs-1:0]               pndng;
  logic [drvrs-1:0][pckg_sz-1:0]  D_pop;
  logic [drvrs-1:0]               pop;
  logic [drvrs-1:0]               push;
  logic [drvrs-1:0][pckg_sz-1:0]  D_push;

  // ---------------------------------------------------------------------
  // Modports
  // ---------------------------------------------------------------------
  // driver_mp: cada Driver maneja UNA interfaz i. Conduce la solicitud/
  //            transmisión (pndng[i], D_pop[i]) y observa la confirmación
  //            (pop[i]) y lo recibido (push[i], D_push[i]).
  modport driver_mp (
    input  clk, reset, pop, push, D_push,
    output pndng, D_pop
  );

  // monitor_mp: observación pasiva de TODAS las señales del bus, sin
  //             manejar ninguna de ellas.
  modport monitor_mp (
    input clk, reset, pndng, D_pop, pop, push, D_push
  );

  // TODO (equipo): si se requiere, agregar un modport adicional de solo
  // lectura para el propio tb_top (generación de clk/reset), o clocking
  // blocks si se decide muestrear con temporización explícita.

endinterface : bus_if
