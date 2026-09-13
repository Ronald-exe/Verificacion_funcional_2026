//==============================================================================
// <NOMBRE DEL CURSO>
// Integrantes: <Integrante 1> - <Integrante 2>
//==============================================================================
// Archivo   : monitor.sv
// Componente: Monitor
//------------------------------------------------------------------------------
// Descripción:
//   Observa PASIVAMENTE la interfaz física del DUT y traduce la actividad
//   en objetos dut_event, enviados al Checker.
//
//   Flujo conceptual (DUT_BUS_SPEC.md sec. 10-11):
//     DUT -> Monitor -> dut_event -> event_mb -> Checker
//
//   Debe capturar, por cada interfaz i:
//     - pop[i]  + D_pop[i]   -> dut_event(EVT_POP,  i, D_pop[i])
//     - push[i] + D_push[i]  -> dut_event(EVT_PUSH, i, D_push[i])
//
//   pop y push son eventos independientes y pueden ocurrir en el mismo
//   ciclo (DUT_BUS_SPEC.md sec. 17); deben generar DOS dut_event separados,
//   uno nunca sustituye al otro.
//
//   IMPORTANTE: el Monitor NO determina PASS/FAIL.
//
// Conexiones:
//   - virtual interface (modport monitor_mp) -> lectura de todas las señales
//   - mailbox #(dut_event) event_mb           -> hacia el Checker
//
// Parámetros:
//   drvrs   - cantidad de interfaces a observar
//   pckg_sz - ancho en bits del campo packet
//==============================================================================

class monitor #(
  parameter int drvrs   = tb_pkg::DRVRS_DEFAULT,
  parameter int pckg_sz = tb_pkg::PCKG_SZ_DEFAULT
);

  virtual bus_if #(.drvrs(drvrs), .pckg_sz(pckg_sz)).monitor_mp vif;

  mailbox #(dut_event #(drvrs, pckg_sz)) event_mb;

  function new(
    virtual bus_if #(.drvrs(drvrs), .pckg_sz(pckg_sz)).monitor_mp vif,
    mailbox #(dut_event #(drvrs, pckg_sz))                        event_mb
  );
    // TODO: asignar this.vif, this.event_mb
  endfunction

  task run();
    // -----------------------------------------------------------------
    // TODO (equipo):
    //   forever @(posedge vif.clk) begin
    //     for (interfaz i = 0 .. drvrs-1) begin
    //       if (vif.pop[i])  -> construir dut_event(EVT_POP,  i, vif.D_pop[i])
    //                           y event_mb.put()
    //       if (vif.push[i]) -> construir dut_event(EVT_PUSH, i, vif.D_push[i])
    //                           y event_mb.put()
    //     end
    //   end
    // -----------------------------------------------------------------
  endtask

endclass : monitor
