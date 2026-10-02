//==============================================================================
// Verificación Funcional
// Integrantes: Ronald - Eric
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
//   pop y push son eventos independientes y pueden ocurrir en el mismo
//   ciclo (sec. 17); deben generar DOS dut_event separados, uno nunca
//   sustituye al otro.
//
//   Se detecta flanco de subida para no reportar el mismo evento en cada
//   ciclo mientras la señal permanece en 1.
//
//   IMPORTANTE: el Monitor NO determina PASS/FAIL.
//
// Conexiones:
//   - virtual interface (modport monitor_mp) -> lectura de todas las señales
//   - mailbox #(dut_event) event_mb          -> hacia el Checker
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

  // Detección de flanco. Dimensionado con drvrs, no hardcodeado.
  logic prev_pop  [0:0][drvrs-1:0];
  logic prev_push [0:0][drvrs-1:0];
  bit   pndng_seen [drvrs];
  time  request_time [drvrs];

  function new(
    virtual bus_if #(.drvrs(drvrs), .pckg_sz(pckg_sz)).monitor_mp vif,
    mailbox #(dut_event #(drvrs, pckg_sz))                        event_mb
  );
    this.vif      = vif;
    this.event_mb = event_mb;
  endfunction

  task run();
    dut_event #(drvrs, pckg_sz) ev;

    for (int i = 0; i < drvrs; i++) begin
      prev_pop[0][i]  = 1'b0;
      prev_push[0][i] = 1'b0;
      pndng_seen[i] = 0;
      request_time[i] = 0;
    end

    forever @(posedge vif.clk) begin
      for (int i = 0; i < drvrs; i++) begin

        if (vif.pndng[0][i] === 1'b1 && !pndng_seen[i]) begin
          pndng_seen[i] = 1;
          request_time[i] = $time;
        end

        // POP: flanco de subida
        if (vif.pop[0][i] === 1'b1 && prev_pop[0][i] === 1'b0) begin
          ev              = new();
          ev.event_type   = tb_pkg::EVT_POP;
          ev.interface_id = i;
          ev.packet       = vif.D_pop[0][i];
          ev.send_time    = request_time[i];
          ev.event_time   = $time;
          event_mb.put(ev);
          $display("[MON] POP  if=%0d pkt=0x%h @%0t", i, ev.packet, ev.event_time);
        end

        // PUSH: flanco de subida (evento independiente)
        if (vif.push[0][i] === 1'b1 && prev_push[0][i] === 1'b0) begin
          ev              = new();
          ev.event_type   = tb_pkg::EVT_PUSH;
          ev.interface_id = i;
          ev.packet       = vif.D_push[0][i];
          ev.event_time   = $time;
          event_mb.put(ev);
          $display("[MON] PUSH if=%0d pkt=0x%h @%0t", i, ev.packet, ev.event_time);
        end

        prev_pop[0][i]  = vif.pop[0][i];
        prev_push[0][i] = vif.push[0][i];
        if (vif.pndng[0][i] !== 1'b1)
          pndng_seen[i] = 0;

      end
    end
  endtask

endclass : monitor