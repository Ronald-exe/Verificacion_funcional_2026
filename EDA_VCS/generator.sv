//==============================================================================
// Verificación Funcional
// Integrantes: Ronald - Eric
//==============================================================================
// Archivo   : generator.sv
// Componente: Generator
//------------------------------------------------------------------------------
// Descripción:
//   Genera objetos tx_transaction y los distribuye:
//     - una copia a Driver[interface_id]  vía tx_mb[interface_id]
//     - una copia (independiente) al Scoreboard  vía tx_mb_sb
//
//   Generación por capas (TestplanV3.md sec. 6):
//     escenario (scenario_e) -> interfaz origen -> destino -> payload
//     -> momento de solicitud (delay)
//   Cada escenario agrega constraints inline sobre los de tx_transaction.
//   Al terminar de entregar todas las transacciones pone done = 1.
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

  // Cantidad de transacciones a generar; la fija el test (sorteada en
  // [NUM_TX_MIN : NUM_TX_MAX]). Si no la cambia, se usa el default de tb_pkg.
  int unsigned num_transactions = tb_pkg::NUM_TRANSACTIONS_DEFAULT;

  // Escenario activo; lo fija el test antes de run(). Cada escenario agrega
  // constraints inline sobre los que ya trae tx_transaction.
  tb_pkg::scenario_e scenario = tb_pkg::SC_RANDOM;

  // Rango de retardo (ciclos) antes de ofrecer cada paquete; lo fija el test
  int unsigned delay_min = 0;
  int unsigned delay_max = 0;

  // Se pone en 1 cuando ya se entregaron todas las transacciones; el test lo
  // usa para decidir el fin de la prueba
  bit done = 0;

  // Interfaces origen para SC_ONE_IF (src_a) y SC_TWO_IF (src_a, src_b)
  int unsigned src_a = 0;
  int unsigned src_b = 1;

  // Patrones de payload para SC_PATTERNS (TestplanV3.md sec. 6). El payload
  // ocupa los pckg_sz-8 bits inferiores (8, 24 o 56 bits, siempre par).
  localparam int PAYLOAD_W = pckg_sz - tb_pkg::DEST_FIELD_WIDTH;
  localparam logic [PAYLOAD_W-1:0] PAT_ZEROS = '0;
  localparam logic [PAYLOAD_W-1:0] PAT_ONES  = '1;
  localparam logic [PAYLOAD_W-1:0] PAT_1010  = {(PAYLOAD_W/2){2'b10}};
  localparam logic [PAYLOAD_W-1:0] PAT_0101  = {(PAYLOAD_W/2){2'b01}};

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

      bit ok;

      tr = new();
      tr.tx_id = n;
      tr.delay_min = delay_min;
      tr.delay_max = delay_max;
      case (scenario)
        // Unicast a una interfaz válida distinta del origen
        tb_pkg::SC_UNICAST:
          ok = tr.randomize() with {
            packet[pckg_sz-1 -: tb_pkg::DEST_FIELD_WIDTH] <  drvrs;
            packet[pckg_sz-1 -: tb_pkg::DEST_FIELD_WIDTH] != interface_id;
          };
        tb_pkg::SC_BROADCAST:
          ok = tr.randomize() with {
            packet[pckg_sz-1 -: tb_pkg::DEST_FIELD_WIDTH] == tb_pkg::BROADCAST_RTL_ACTUAL;
          };
        // Destino fuera de [0, drvrs-1] y distinto de broadcast
        tb_pkg::SC_INVALID:
          ok = tr.randomize() with {
            packet[pckg_sz-1 -: tb_pkg::DEST_FIELD_WIDTH] inside {[drvrs : tb_pkg::BROADCAST_RTL_ACTUAL - 1]};
          };
        // Bordes: 0 y drvrs-1 (primer/último ID válido), drvrs y 0xFE
        // (primer/último inválido) y broadcast, con el mismo peso cada uno.
        // Se apaga el dist 70/20/10 de tx_transaction: repartiría el 10% de
        // inválidos entre ~250 valores y los bordes inválidos casi no saldrían.
        tb_pkg::SC_ADDR_EDGES: begin
          tr.c_destination.constraint_mode(0);
          ok = tr.randomize() with {
            packet[pckg_sz-1 -: tb_pkg::DEST_FIELD_WIDTH] dist {
              0                                := 1,
              drvrs-1                          := 1,
              drvrs                            := 1,
              tb_pkg::BROADCAST_RTL_ACTUAL - 1 := 1,
              tb_pkg::BROADCAST_RTL_ACTUAL     := 1
            };
          };
        end
        // Una sola interfaz transmite: sin contención en el bus
        tb_pkg::SC_ONE_IF:
          ok = tr.randomize() with { interface_id == src_a; };
        // Dos interfaces compiten por el bus (Round Robin entre src_a y src_b)
        tb_pkg::SC_TWO_IF:
          ok = tr.randomize() with { interface_id inside {src_a, src_b}; };
        // Payload con patrones de máxima/mínima alternancia, mismo peso cada
        // uno; el destino sigue el dist normal de tx_transaction
        tb_pkg::SC_PATTERNS:
          ok = tr.randomize() with {
            packet[PAYLOAD_W-1:0] dist {
              PAT_ZEROS := 1,
              PAT_ONES  := 1,
              PAT_1010  := 1,
              PAT_0101  := 1
            };
          };
        default:  // SC_RANDOM: solo los constraints de tx_transaction
          ok = tr.randomize();
      endcase

      // Si los constraints son contradictorios randomize() devuelve 0 y el
      // paquete quedaría sin aleatorizar: se reporta en lugar de ignorarlo.
      if (!ok)
        $error("T=%0t [Generator] randomize() fallo en tx#%0d (scenario=%s)",
               $time, n, scenario.name());

      tr_sb = new tr;  // copia independiente para el Scoreboard

      tx_mb[tr.interface_id].put(tr);  // hacia el Driver de esa interfaz
      tx_mb_sb.put(tr_sb);             // hacia el Scoreboard

      $display("T=%0t [Generator] tx#%0d if=%0d packet=0x%0h delay=%0d",
            $time, tr.tx_id, tr.interface_id, tr.packet, tr.delay);
    end
    done = 1;
  endtask

endclass : generator
