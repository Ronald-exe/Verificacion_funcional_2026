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

// NOTA: la clase se llama "checker_c" y no "checker" porque 'checker' es
// una palabra reservada de SystemVerilog desde IEEE 1800-2012 (construcción
// checker/endchecker para "assertion checkers"). Usar ese nombre como clase
// rompe la compilación en herramientas que implementan el LRM completo
// (confirmado con Verilator).
class checker_c #(
  parameter int drvrs   = tb_pkg::DRVRS_DEFAULT,
  parameter int pckg_sz = tb_pkg::PCKG_SZ_DEFAULT
);

  mailbox #(dut_event #(drvrs, pckg_sz))      event_mb;
  mailbox #(expected_event #(drvrs, pckg_sz)) expected_mb;

  scoreboard #(drvrs, pckg_sz) sb;

  // Esperado pendiente, demultiplexado por (interfaz, tipo de evento).
  expected_event #(drvrs, pckg_sz) pop_q  [drvrs][$];
  expected_event #(drvrs, pckg_sz) push_q [drvrs][$];

  int transacciones_ok;
  int transacciones_error;

  function new(
    mailbox #(dut_event #(drvrs, pckg_sz))      event_mb,
    mailbox #(expected_event #(drvrs, pckg_sz)) expected_mb,
    scoreboard #(drvrs, pckg_sz)                sb
  );
    this.event_mb    = event_mb;
    this.expected_mb = expected_mb;
    this.sb          = sb;
  endfunction

  task file_one_expected();
    expected_event #(drvrs, pckg_sz) exp;
    expected_mb.get(exp);  // llega del Scoreboard
    if (exp.event_type == tb_pkg::EVT_POP) pop_q[exp.interface_id].push_back(exp);
    else                                    push_q[exp.interface_id].push_back(exp);
  endtask

  task run();
    dut_event      #(drvrs, pckg_sz) obs;
    expected_event #(drvrs, pckg_sz) exp;

    forever begin
      event_mb.get(obs);  // llega del Monitor

      if (obs.event_type == tb_pkg::EVT_POP) begin
        while (pop_q[obs.interface_id].size() == 0) file_one_expected();
        exp = pop_q[obs.interface_id].pop_front();
      end else begin
        while (push_q[obs.interface_id].size() == 0) file_one_expected();
        exp = push_q[obs.interface_id].pop_front();
      end

      if (obs.packet !== exp.packet) begin
        transacciones_error++;
        $display("T=%0t [Checker] ERROR [%0d] if=%0d type=%s obs=0x%0h exp=0x%0h",
                  $time, transacciones_error, obs.interface_id, obs.event_type.name(), obs.packet, exp.packet);
      end else begin
        transacciones_ok++;
        $display("T=%0t [Checker] PASS  [%0d] if=%0d type=%s packet=0x%0h",
                  $time, transacciones_ok, obs.interface_id, obs.event_type.name(), obs.packet);

        // avisa al Scoreboard que puede liberar la entrada confirmada
        if (obs.event_type == tb_pkg::EVT_POP) sb.confirm_pop(obs.interface_id);
        else                                    sb.confirm_push(obs.interface_id);
      end
    end
  endtask

  task reporte_final();
    $display("");
    $display("================================================================");
    $display("  CHECKER - REPORTE FINAL   @%0t ns", $time);
    $display("================================================================");
    $display("  Transacciones correctas  : %0d", transacciones_ok);
    $display("  Transacciones con error  : %0d", transacciones_error);
    $display("----------------------------------------------------------------");
    if (transacciones_error == 0)
      $display("  >>  RESULTADO: ** PASS ** - sin errores detectados");
    else
      $display("  >>  RESULTADO: !! FAIL !! - %0d errores en total", transacciones_error);
    $display("================================================================");
    $display("");
  endtask

endclass : checker_c
