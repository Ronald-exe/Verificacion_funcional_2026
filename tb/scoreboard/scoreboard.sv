//==============================================================================
// <NOMBRE DEL CURSO>
// Integrantes: <Integrante 1> - <Integrante 2>
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
//   El Checker NO debe manipular estas queues directamente; el acceso debe
//   realizarse mediante los métodos que esta clase exponga (ver TODO al
//   final; interfaz exacta pendiente de definición, sec. 22 del spec).
//
//   Reglas del modelo a implementar (no en este esqueleto):
//     - unicast   -> agregar a rx_expected[destino]
//     - broadcast -> agregar copia a rx_expected[] de cada interfaz que
//                     corresponda según el comportamiento de broadcast
//     - inválido  -> no se agrega a ninguna cola
//     - push y pop se procesan como eventos independientes (sec. 17)
//
// Conexiones:
//   - mailbox #(tx_transaction)  tx_mb_sb     <- desde el Generator
//   - mailbox #(expected_event)  expected_mb  -> hacia el Checker
//
// Parámetros:
//   drvrs     - cantidad de interfaces (tamaño de las queues por interfaz)
//   pckg_sz   - ancho en bits del campo packet
//   broadcast - dirección de broadcast vigente (parametrizable, sec. 5)
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

      exp              = new();
      exp.event_type   = tb_pkg::EVT_POP;
      exp.interface_id = tr.interface_id;
      exp.packet       = tr.packet;
      expected_mb.put(exp);  // hacia el Checker: esperado de este pop

      dest = tr.packet[pckg_sz-1 -: tb_pkg::DEST_FIELD_WIDTH];

      if (dest == tb_pkg::BROADCAST_RTL_ACTUAL) begin
        for (int unsigned i = 0; i < drvrs; i++) begin
          rx_expected[i].push_back(tr);

          exp              = new();
          exp.event_type   = tb_pkg::EVT_PUSH;
          exp.interface_id = i;
          exp.packet       = tr.packet;
          expected_mb.put(exp);  // hacia el Checker: esperado en cada interfaz
        end
      end else if (dest < drvrs) begin
        rx_expected[dest].push_back(tr);

        exp              = new();
        exp.event_type   = tb_pkg::EVT_PUSH;
        exp.interface_id = dest;
        exp.packet       = tr.packet;
        expected_mb.put(exp);  // hacia el Checker: esperado en el destino
      end
      // destino inválido: no se espera ningún push
    end
  endtask

  function automatic void confirm_pop(int unsigned id);
    if (tx_pending[id].size() != 0) void'(tx_pending[id].pop_front());
  endfunction

  function automatic void confirm_push(int unsigned id);
    if (rx_expected[id].size() != 0) void'(rx_expected[id].pop_front());
  endfunction

endclass : scoreboard
