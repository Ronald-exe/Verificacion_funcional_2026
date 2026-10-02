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

  // Cantidad exacta de transacciones por cada source/interface_id.
  int unsigned num_transactions = tb_pkg::NUM_TRANSACTIONS_DEFAULT;
  int unsigned seed = tb_pkg::SEED_BASE_DEFAULT;

  // Perfil activo; lo fija el test antes de run().
  tb_pkg::scenario_e scenario = tb_pkg::SC_RANDOM;
  logic [7:0] broadcast_stimulus = tb_pkg::BROADCAST_DEFAULT;

  // Rango de arrival_delta (ciclos) antes de ofrecer cada paquete; lo fija el test
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
    int unsigned next_tx_id = 0;

    process_seed = seed;
    void'($urandom(process_seed));

    for (int unsigned source_id = 0; source_id < drvrs; source_id++) begin
      int unsigned sent_for_source = 0;
      int unsigned burst_remaining = 0;
      int unsigned burst_size = 0;
      int unsigned burst_gap = 0;

      while (sent_for_source < num_transactions) begin
        tx_transaction #(drvrs, pckg_sz) tr, tr_sb;
        bit ok;

        if (scenario == tb_pkg::SC_BURST && burst_remaining == 0) begin
          burst_size = $urandom_range(tb_pkg::BURST_MAX, tb_pkg::BURST_MIN);
          if (burst_size > num_transactions - sent_for_source)
            burst_size = num_transactions - sent_for_source;
          burst_gap = $urandom_range(delay_max, delay_min);
          burst_remaining = burst_size;
        end

        tr = new();
        tr.tx_id = next_tx_id;
        tr.srandom(seed + next_tx_id);
        tr.delay_min = delay_min;
        tr.delay_max = delay_max;
        tr.broadcast_value = broadcast_stimulus;

        case (scenario)
          tb_pkg::SC_RANDOM: begin
            tr.c_traffic_distribution.constraint_mode(0);
            ok = tr.randomize() with { interface_id == source_id; };
          end
          tb_pkg::SC_BURST: begin
            tr.c_arrival_delta.constraint_mode(0);
            ok = tr.randomize() with {
              interface_id == source_id;
              burst_length == burst_size;
              arrival_delta == ((burst_remaining == burst_size) ? burst_gap : 0);
            };
          end
          tb_pkg::SC_CONCURRENT: begin
            tr.c_arrival_delta.constraint_mode(0);
            ok = tr.randomize() with {
              interface_id == source_id;
              arrival_delta == 0;
            };
          end
          tb_pkg::SC_BOUNDARY: begin
            tr.c_traffic_distribution.constraint_mode(0);
            tr.c_destination.constraint_mode(0);
            if (sent_for_source == 0) begin
              ok = tr.randomize() with {
                interface_id == source_id;
                traffic_type == tb_pkg::TR_BROADCAST;
                packet[pckg_sz-1 -: tb_pkg::DEST_FIELD_WIDTH] == broadcast_stimulus;
              };
            end else begin
              ok = tr.randomize() with {
                interface_id == source_id;
                packet[pckg_sz-1 -: tb_pkg::DEST_FIELD_WIDTH] dist {
                  0                                := 1,
                  drvrs-1                          := 1,
                  drvrs                            := 1,
                  tb_pkg::BROADCAST_RTL_ACTUAL - 1 := 1,
                  tb_pkg::BROADCAST_RTL_ACTUAL     := 1
                };
                if (packet[pckg_sz-1 -: tb_pkg::DEST_FIELD_WIDTH] == broadcast_stimulus)
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
          end
          tb_pkg::SC_MIXED:
            ok = tr.randomize() with { interface_id == source_id; };
          default:
            ok = 0;
        endcase

        if (!ok)
          $fatal(1, "T=%0t [Generator] randomize() fallo en tx#%0d (scenario=%s)",
                 $time, tr.tx_id, scenario.name());

        if (scenario == tb_pkg::SC_BURST)
          burst_remaining--;

        tr_sb = new tr;  // copia independiente para el Scoreboard

        tx_mb[source_id].put(tr);
        tx_mb_sb.put(tr_sb);

        $display("T=%0t [Generator] tx#%0d if=%0d packet=0x%0h arrival_delta=%0d",
                 $time, tr.tx_id, tr.interface_id, tr.packet, tr.arrival_delta);

        next_tx_id++;
        sent_for_source++;
      end
    end

    done = 1;
  endtask

endclass : generator
