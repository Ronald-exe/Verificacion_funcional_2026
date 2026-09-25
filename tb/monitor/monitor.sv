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

// Monitor minimo:
// - se conecta a la interface por modport mon
// - observa pop y push en cada ciclo
// - reporta con $display
//
// No determina pass/fail. Solo observa.

class monitor;

  virtual bus_if.monitor_mp vif;
  int                drvrs;

  // Valores previos para detectar flancos
  logic prev_pop  [0:0][3:0];
  logic prev_push [0:0][3:0];

  function new(virtual bus_if.monitor_mp vif, int drvrs);
    this.vif   = vif;
    this.drvrs = drvrs;
  endfunction

  task run();

    // Inicializa previos
    for (int i = 0; i < drvrs; i++) begin
      prev_pop[0][i]  = 0;
      prev_push[0][i] = 0;
    end

    forever begin
      @(posedge vif.clk);

      for (int i = 0; i < drvrs; i++) begin

        // POP: flanco de subida
        if (vif.pop[0][i] === 1'b1 && prev_pop[0][i] === 1'b0)
          $display("[MON] POP  if=%0d pkt=0x%h @%0t",
                   i, vif.D_pop[0][i], $time);

        // PUSH: flanco de subida
        if (vif.push[0][i] === 1'b1 && prev_push[0][i] === 1'b0)
          $display("[MON] PUSH if=%0d pkt=0x%h @%0t",
                   i, vif.D_push[0][i], $time);

        // Actualiza previos
        prev_pop[0][i]  = vif.pop[0][i];
        prev_push[0][i] = vif.push[0][i];

      end
    end

  endtask

endclass
