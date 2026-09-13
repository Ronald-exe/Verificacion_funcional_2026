//==============================================================================
// <NOMBRE DEL CURSO>
// Integrantes: <Integrante 1> - <Integrante 2>
//==============================================================================
// Archivo   : checker.sv
// Componente: Checker
//------------------------------------------------------------------------------
// Descripción:
//   Compara los dut_event observados por el Monitor contra los
//   expected_event generados por el Scoreboard, y reporta PASS/FAIL.
//
//   El Checker NO debe administrar directamente las queues internas del
//   Scoreboard (tx_pending[]/rx_expected[]). Cualquier confirmación de
//   consumo tras una comparación válida debe realizarse mediante la
//   interfaz que exponga el Scoreboard (ver scoreboard.sv; la firma exacta
//   está pendiente de definición, DUT_BUS_SPEC.md sec. 13 y sec. 22).
//
// Conexiones:
//   - mailbox #(dut_event)      event_mb     <- desde el Monitor
//   - mailbox #(expected_event) expected_mb  <- desde el Scoreboard
//   - referencia opcional al Scoreboard, únicamente para confirmar consumo
//     (no para leer/escribir sus queues directamente)
//
// Parámetros:
//   drvrs   - cantidad de interfaces
//   pckg_sz - ancho en bits del campo packet
//==============================================================================

class checker #(
  parameter int drvrs   = tb_pkg::DRVRS_DEFAULT,
  parameter int pckg_sz = tb_pkg::PCKG_SZ_DEFAULT
);

  mailbox #(dut_event #(drvrs, pckg_sz))      event_mb;
  mailbox #(expected_event #(drvrs, pckg_sz)) expected_mb;

  // Referencia opcional al Scoreboard, solo para invocar su interfaz de
  // confirmación (ver TODO en scoreboard.sv). Se deja comentada porque su
  // firma exacta aún no está definida.
  // scoreboard #(drvrs, pckg_sz) sb;

  function new(
    mailbox #(dut_event #(drvrs, pckg_sz))      event_mb,
    mailbox #(expected_event #(drvrs, pckg_sz)) expected_mb
  );
    // TODO: asignar this.event_mb, this.expected_mb
  endfunction

  task run();
    // -----------------------------------------------------------------
    // PLACEHOLDER DE COMPARACIÓN
    //   forever begin
    //     dut_event      #(drvrs, pckg_sz) obs;
    //     expected_event #(drvrs, pckg_sz) exp;
    //     event_mb.get(obs);
    //     expected_mb.get(exp);
    //     compare(obs, exp);
    //     // si la comparación es válida: confirmar consumo en el
    //     // Scoreboard (sb.confirm_pop / sb.confirm_push, a definir)
    //     // si falla: reportar y conservar evidencia para diagnóstico
    //   end
    // -----------------------------------------------------------------
  endtask

  // TODO (equipo): lógica de comparación completa
  // function void compare(dut_event #(drvrs, pckg_sz) obs,
  //                        expected_event #(drvrs, pckg_sz) exp);
  // endfunction

endclass : checker
