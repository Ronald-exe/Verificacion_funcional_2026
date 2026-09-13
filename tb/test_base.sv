//==============================================================================
// <NOMBRE DEL CURSO>
// Integrantes: <Integrante 1> - <Integrante 2>
//==============================================================================
// Archivo   : test_base.sv
// Componente: Test base
//------------------------------------------------------------------------------
// Descripción:
//   Crea el Environment, lo configura con los parámetros vigentes, y expone
//   el punto de extensión para los escenarios de prueba TP01-TP16
//   (TestplanV3.md sec. 8), que se implementarán como clases derivadas en
//   una fase posterior (p.ej. extendiendo run() o configurando el Generator
//   antes de invocar env.run()).
//
//   En esta etapa NO se implementa ningún escenario concreto.
//
// Parámetros:
//   drvrs, pckg_sz, broadcast - configuración del ambiente para esta corrida.
//==============================================================================

class test_base #(
  parameter int drvrs             = tb_pkg::DRVRS_DEFAULT,
  parameter int pckg_sz           = tb_pkg::PCKG_SZ_DEFAULT,
  parameter logic [7:0] broadcast = tb_pkg::BROADCAST_DEFAULT
);

  environment #(drvrs, pckg_sz, broadcast) env;
  virtual bus_if #(.drvrs(drvrs), .pckg_sz(pckg_sz)) vif;

  function new(virtual bus_if #(.drvrs(drvrs), .pckg_sz(pckg_sz)) vif);
    // TODO: asignar this.vif; env = new(vif);
  endfunction

  virtual task run();
    // TODO: env.build(); env.run();
    // Los escenarios concretos (TP01..TP16) se implementarán extendiendo
    // esta clase (class test_TP01 extends test_base #(...); ...) y
    // sobreescribiendo run() o la configuración del Generator antes de
    // llamar a env.run().
  endtask

endclass : test_base
