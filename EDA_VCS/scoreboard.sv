//==============================================================================
// Verificación Funcional
// Integrantes: Ronald - Eric
//==============================================================================
// Archivo   : scoreboard.sv
// Componente: Scoreboard
//------------------------------------------------------------------------------
// Descripción:
//   Mantiene el modelo funcional del DUT (independiente de su RTL interno)
//   mediante queues de SystemVerilog, y genera los expected_event enviados
//   al Checker.
//
//   Estado del modelo (PROPIEDAD EXCLUSIVA del Scoreboard, DUT_BUS_SPEC.md
//   sec. 12-13, 19):
//     tx_pending[i]  - paquetes ofrecidos al DUT (D_pop) cuyo consumo aún
//                      no ha sido confirmado por pop[i].
//                      Regla: NO pop_front() antes de confirmar pop.
//     rx_expected[i] - paquetes que el modelo espera recibir en la
//                      interfaz i (push[i]).
//                      Regla: no se retira antes de validar la comparación.
//
//   El Checker NO manipula estas queues directamente: confirma el consumo
//   con confirm_pop(id) / confirm_push(id).
//
//   Reglas del modelo:
//     - unicast   -> agregar a rx_expected[destino]
//     - broadcast -> agregar copia a rx_expected[] de cada interfaz,
//                     EXCEPTO la de origen
//     - inválido  -> no se agrega a ninguna cola
//     - destino == origen -> no se agrega a ninguna cola
//     Regla: una interfaz nunca recibe sus propios paquetes (no se
//     escucha a sí misma), tanto en broadcast como en unicast.
//     - push y pop se procesan como eventos independientes (sec. 17)
//
// Conexiones:
//   - mailbox #(tx_transaction)  tx_mb_sb     <- desde el Generator
//   - mailbox #(expected_event)  expected_mb  -> hacia el Checker
//
// Parámetros:
//   drvrs     - cantidad de interfaces (tamaño de las queues por interfaz)
//   pckg_sz   - ancho en bits del campo packet
//   broadcast - dirección de broadcast configurada. El modelo usa
//               tb_pkg::BROADCAST_RTL_ACTUAL (8'hFF) porque el RTL ignora
//               este parámetro (hallazgo TP16, DUT_BUS_SPEC.md sec. 5) y
//               avisa con un WARNING si se configura otro valor.
//
//   Además, en cada expected_event informa src_id (origen de un push) y
//   n_rx (cuántos push genera un pop) para el reporte de retardos.
//==============================================================================

class scoreboard #(
  parameter int drvrs               = tb_pkg::DRVRS_DEFAULT,
  parameter int pckg_sz             = tb_pkg::PCKG_SZ_DEFAULT,
  parameter logic [7:0] broadcast   = tb_pkg::BROADCAST_DEFAULT
);

  mailbox #(tx_transaction #(drvrs, pckg_sz)) tx_mb_sb;     // Generator -> Scoreboard
  mailbox #(expected_event #(drvrs, pckg_sz)) expected_mb;  // Scoreboard -> Checker

  // Modelo funcional: una queue por interfaz (sec. 12)
  tx_transaction #(drvrs, pckg_sz) tx_pending  [drvrs][$];
  tx_transaction #(drvrs, pckg_sz) rx_expected [drvrs][$];

  function new(
    mailbox #(tx_transaction #(drvrs, pckg_sz)) tx_mb_sb,
    mailbox #(expected_event #(drvrs, pckg_sz)) expected_mb
  );
    this.tx_mb_sb    = tx_mb_sb;
    this.expected_mb = expected_mb;
  endfunction

  task run();
    tx_transaction    #(drvrs, pckg_sz) tr;
    expected_event    #(drvrs, pckg_sz) exp;
    logic [tb_pkg::DEST_FIELD_WIDTH-1:0] dest;

    if (broadcast !== tb_pkg::BROADCAST_RTL_ACTUAL) begin
      $display("T=%0t [Scoreboard] WARNING: broadcast=0x%0h configurado, pero el RTL siempre usa 0x%0h.",
                $time, broadcast, tb_pkg::BROADCAST_RTL_ACTUAL);
    end

    forever begin
      tx_mb_sb.get(tr);  // llega del Generator

      tx_pending[tr.interface_id].push_back(tr);

      dest = tr.packet[pckg_sz-1 -: tb_pkg::DEST_FIELD_WIDTH];

      exp              = new();
      exp.event_type   = tb_pkg::EVT_POP;
      exp.interface_id = tr.interface_id;
      exp.tx_id        = tr.tx_id;
      exp.packet       = tr.packet;
      // Cantidad de push que generará este paquete (lo usa el reporte CSV)
      if (dest == tb_pkg::BROADCAST_RTL_ACTUAL)             exp.n_rx = drvrs - 1;
      else if (dest < drvrs && dest != tr.interface_id)     exp.n_rx = 1;
      else                                                  exp.n_rx = 0;
      expected_mb.put(exp);  // hacia el Checker: esperado de este pop

      if (dest == tb_pkg::BROADCAST_RTL_ACTUAL) begin
        for (int unsigned i = 0; i < drvrs; i++) begin
          if (i == tr.interface_id) continue;  // el origen no se escucha a sí mismo
          rx_expected[i].push_back(tr);

          exp              = new();
          exp.event_type   = tb_pkg::EVT_PUSH;
          exp.interface_id = i;
          exp.tx_id        = tr.tx_id;
          exp.packet       = tr.packet;
          exp.src_id       = tr.interface_id;
          expected_mb.put(exp);  // hacia el Checker: esperado en cada interfaz
        end
      end else if (dest < drvrs && dest != tr.interface_id) begin
        rx_expected[dest].push_back(tr);

        exp              = new();
        exp.event_type   = tb_pkg::EVT_PUSH;
        exp.interface_id = dest;
        exp.tx_id        = tr.tx_id;
        exp.packet       = tr.packet;
        exp.src_id       = tr.interface_id;
        expected_mb.put(exp);  // hacia el Checker: esperado en el destino
      end
      // destino inválido o destino == origen: no se espera ningún push
    end
  endtask

  function automatic void confirm_pop(int unsigned id, int unsigned tx_id, time send_time);
    int idx[$];
    idx = tx_pending[id].find_first_index(tr) with (tr.tx_id == tx_id);
    if (idx.size() != 0) begin
      tx_pending[id][idx[0]].send_time = send_time;
      tx_pending[id].delete(idx[0]);
    end
  endfunction

  function automatic void confirm_push(int unsigned id, int unsigned tx_id, time receive_time);
    int idx[$];
    idx = rx_expected[id].find_first_index(tr) with (tr.tx_id == tx_id);
    if (idx.size() != 0) begin
      rx_expected[id][idx[0]].receive_time = receive_time;
      rx_expected[id][idx[0]].delay = receive_time - rx_expected[id][idx[0]].send_time;
      rx_expected[id].delete(idx[0]);
    end
  endfunction

endclass : scoreboard
