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
//   Generación por capas:
//     perfil -> traffic_type -> interfaz origen -> destino -> payload -> delay
//   Cada perfil controla constraints de tx_transaction y el calendario.
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

  // Cantidad exacta de transacciones; la fija el test desde +NUM.
  int unsigned num_transactions = tb_pkg::NUM_TRANSACTIONS_DEFAULT;
  int unsigned seed = tb_pkg::SEED_BASE_DEFAULT;

  // Perfil activo; lo fija el test antes de run().
  tb_pkg::scenario_e scenario = tb_pkg::SC_RANDOM;

  // Rango de retardo (ciclos) antes de ofrecer cada paquete; lo fija el test
  int unsigned delay_min = 0;
  int unsigned delay_max = 0;

  // Se pone en 1 cuando ya se entregaron todas las transacciones; el test lo
  // usa para decidir el fin de la prueba
  bit done = 0;

  function new(
    mailbox #(tx_transaction #(drvrs, pckg_sz)) tx_mb    [drvrs],
    mailbox #(tx_transaction #(drvrs, pckg_sz)) tx_mb_sb
  );
    this.tx_mb    = tx_mb;
    this.tx_mb_sb = tx_mb_sb;
  endfunction

  task run();
    int unsigned process_seed;
    int unsigned burst_remaining = 0;
    int unsigned burst_size = 0;
    int unsigned burst_source = 0;
    int unsigned burst_gap = 0;

    process_seed = seed;
    void'($urandom(process_seed));

    for (int unsigned n = 0; n < num_transactions; n++) begin
      tx_transaction #(drvrs, pckg_sz) tr, tr_sb;

      bit ok;

      tr = new();
      tr.tx_id = n;
      tr.srandom(seed + n);
      tr.delay_min = delay_min;
      tr.delay_max = delay_max;

      if (scenario == tb_pkg::SC_BURST && burst_remaining == 0) begin
        burst_size = $urandom_range(tb_pkg::BURST_MAX, tb_pkg::BURST_MIN);
        burst_source = $urandom_range(drvrs - 1, 0);
        burst_gap = $urandom_range(delay_max, delay_min);
        burst_remaining = burst_size;
      end

      case (scenario)
        tb_pkg::SC_RANDOM: begin
          tr.c_traffic_distribution.constraint_mode(0);
          ok = tr.randomize();
        end
        tb_pkg::SC_BURST: begin
          tr.c_delay.constraint_mode(0);
          ok = tr.randomize() with {
            interface_id == burst_source;
            burst_length == burst_size;
            delay == ((burst_remaining == burst_size) ? burst_gap : 0);
          };
        end
        tb_pkg::SC_CONCURRENT: begin
          tr.c_delay.constraint_mode(0);
          ok = tr.randomize() with {
            interface_id == (n % drvrs);
            delay == 0;
          };
        end
        tb_pkg::SC_BOUNDARY: begin
          tr.c_traffic_distribution.constraint_mode(0);
          tr.c_destination.constraint_mode(0);
          ok = tr.randomize() with {
            packet[pckg_sz-1 -: tb_pkg::DEST_FIELD_WIDTH] dist {
              0                                := 1,
              drvrs-1                          := 1,
              drvrs                            := 1,
              tb_pkg::BROADCAST_RTL_ACTUAL - 1 := 1,
              tb_pkg::BROADCAST_RTL_ACTUAL     := 1
            };
            if (packet[pckg_sz-1 -: tb_pkg::DEST_FIELD_WIDTH] == tb_pkg::BROADCAST_RTL_ACTUAL)
              traffic_type == tb_pkg::TR_BROADCAST;
            else if (packet[pckg_sz-1 -: tb_pkg::DEST_FIELD_WIDTH] < drvrs) {
              if (packet[pckg_sz-1 -: tb_pkg::DEST_FIELD_WIDTH] == interface_id)
                traffic_type == tb_pkg::TR_SELF;
              else
                traffic_type == tb_pkg::TR_UNICAST;
            } else
              traffic_type == tb_pkg::TR_INVALID;
          };
        end
        tb_pkg::SC_MIXED:
          ok = tr.randomize();
      endcase

      if (!ok)
        $fatal(1, "T=%0t [Generator] randomize() fallo en tx#%0d (scenario=%s)",
               $time, n, scenario.name());

      if (scenario == tb_pkg::SC_BURST)
        burst_remaining--;

      tr_sb = new tr;  // copia independiente para el Scoreboard

      tx_mb[tr.interface_id].put(tr);  // hacia el Driver de esa interfaz
      tx_mb_sb.put(tr_sb);             // hacia el Scoreboard

      $display("T=%0t [Generator] tx#%0d if=%0d packet=0x%0h delay=%0d",
            $time, tr.tx_id, tr.interface_id, tr.packet, tr.delay);
    end
    done = 1;
  endtask

endclass : generator
