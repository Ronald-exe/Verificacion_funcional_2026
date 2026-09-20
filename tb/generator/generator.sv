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
  // tiempo, o combinación con el escenario activo). A definir por el test.
  int unsigned num_transactions;

  function new(
    mailbox #(tx_transaction #(drvrs, pckg_sz)) tx_mb    [drvrs],
    mailbox #(tx_transaction #(drvrs, pckg_sz)) tx_mb_sb
  );
    // TODO: asignar this.tx_mb, this.tx_mb_sb
  endfunction

  task run();
    // -----------------------------------------------------------------
    // PLACEHOLDER DE GENERACIÓN (TestplanV3.md sec. 6 y 8: TP01-TP16)
    //   Aquí se implementará la generación por capas. Esqueleto esperado
    //   por cada transacción:
    //     1. tr = new(); tr.randomize();  // con constraints según escenario
    //     2. tx_mb[tr.interface_id].put(tr);
    //     3. tx_mb_sb.put(tr_copia);       // objeto independiente
    // -----------------------------------------------------------------
  endtask

endclass : generator
