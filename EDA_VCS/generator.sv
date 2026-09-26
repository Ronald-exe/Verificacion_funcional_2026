//==============================================================================
// <NOMBRE DEL CURSO>
// Integrantes: <Integrante 1> - <Integrante 2>
//==============================================================================
// Archivo   : generator.sv
// Componente: Generator
//------------------------------------------------------------------------------
// Descripción:
//   Genera objetos tx_transaction y los distribuye:
//     - una copia a Driver[interface_id]  vía tx_mb[interface_id]
//     - una copia (independiente) al Scoreboard  vía tx_mb_sb
//
//   La estrategia de generación por capas (TestplanV3.md sec. 6):
//     Scenario -> tipo de tráfico -> interfaz origen -> destino -> payload
//     -> momento de solicitud
//   se implementará en fases posteriores. run() contiene únicamente un
//   placeholder claramente identificado.
//
//   IMPORTANTE: la copia enviada al Scoreboard debe ser un objeto
//   independiente del enviado al Driver (no el mismo handle), para evitar
//   que ambos componentes compartan y modifiquen el mismo objeto en
//   procesos concurrentes distintos.
//
// Conexiones:
//   - mailbox #(tx_transaction) tx_mb[drvrs]  -> uno por Driver
//   - mailbox #(tx_transaction) tx_mb_sb      -> hacia el Scoreboard
//
// Parámetros:
//   drvrs   - cantidad de Drivers/mailboxes destino
//   pckg_sz - ancho en bits del campo packet
//==============================================================================

class generator #(
  parameter int drvrs   = tb_pkg::DRVRS_DEFAULT,
  parameter int pckg_sz = tb_pkg::PCKG_SZ_DEFAULT
);

  mailbox #(tx_transaction #(drvrs, pckg_sz)) tx_mb    [drvrs]; // Generator -> Driver[i]
  mailbox #(tx_transaction #(drvrs, pckg_sz)) tx_mb_sb;         // Generator -> Scoreboard

  // Criterio de finalización de la generación (cantidad de transacciones,
  // tiempo, o combinación con el escenario activo). A definir por el test;
  // si el test no lo cambia, se usa el default de tb_pkg.
  int unsigned num_transactions = tb_pkg::NUM_TRANSACTIONS_DEFAULT;

  function new(
    mailbox #(tx_transaction #(drvrs, pckg_sz)) tx_mb    [drvrs],
    mailbox #(tx_transaction #(drvrs, pckg_sz)) tx_mb_sb
  );
    this.tx_mb    = tx_mb;
    this.tx_mb_sb = tx_mb_sb;
  endfunction

  task run();
    for (int unsigned n = 0; n < num_transactions; n++) begin
      tx_transaction #(drvrs, pckg_sz) tr, tr_sb;

      tr = new();
      void'(tr.randomize());

      tr_sb = new tr;  // copia independiente para el Scoreboard

      tx_mb[tr.interface_id].put(tr);  // hacia el Driver de esa interfaz
      tx_mb_sb.put(tr_sb);             // hacia el Scoreboard

      $display("T=%0t [Generator] tx#%0d if=%0d packet=0x%0h",
                $time, n, tr.interface_id, tr.packet);
    end
  endtask

endclass : generator
