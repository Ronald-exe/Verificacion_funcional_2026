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
    // TODO: asignar this.tx_mb_sb, this.expected_mb
  endfunction

  task run();
    // -----------------------------------------------------------------
    // TODO (equipo):
    //   forever begin
    //     tx_transaction #(drvrs, pckg_sz) tr;
    //     tx_mb_sb.get(tr);
    //     tx_pending[tr.interface_id].push_back(tr);
    //     // determinar destino (unicast / broadcast / inválido, sec. 5)
    //     // actualizar rx_expected[] según el destino (sec. 12)
    //     // construir y enviar expected_event(s) correspondientes a expected_mb
    //   end
    // -----------------------------------------------------------------
  endtask

  // -------------------------------------------------------------------
  // TODO (equipo): interfaz de consulta/confirmación para el Checker.
  // Pendiente de definición exacta (DUT_BUS_SPEC.md sec. 13 y sec. 22).
  // Ejemplos de firma a considerar:
  //   function automatic void confirm_pop(int unsigned id);
  //   function automatic void confirm_push(int unsigned id);
  // Estos métodos serían el ÚNICO mecanismo permitido para que el
  // Checker provoque el pop_front() de tx_pending[]/rx_expected[].
  // -------------------------------------------------------------------

endclass : scoreboard
