//==============================================================================
// <NOMBRE DEL CURSO>
// Integrantes: <Integrante 1> - <Integrante 2>
//==============================================================================
// Archivo   : test_full_environment.sv
// Componente: Top-level de la prueba de integración completa
//------------------------------------------------------------------------------
// Descripción:
//   Integra DUT + bus_if + Generator + driver[] + Monitor + Scoreboard +
//   Checker + mailboxes.
//
//   Flujo:
//     1. Reset
//     2. Construcción de todos los componentes y mailboxes
//     3. Fork paralelo:
//        - Generator.run()  -> distribuye tx_transaction a Driver[i] y al
//          Scoreboard (copia independiente por cada uno)
//        - Driver[i].run()  (uno por interfaz)
//        - Monitor.run()    -> observa el DUT y genera dut_event
//        - Scoreboard.run() -> mantiene el modelo funcional y genera
//          expected_event
//        - Checker.run()    -> compara dut_event vs expected_event
//     4. Tiempo de simulación fijo
//     5. Checker.reporte_final() + $finish
//
//   A diferencia de test_unitario_driver_plus_monitor.sv, aquí SI hay
//   Scoreboard y Checker: cada push/pop observado se valida contra lo que
//   el modelo funcional esperaba, no solo se cuenta actividad.
//==============================================================================

`include "Library.sv"
`include "tb_pkg.sv"
`include "bus_if.sv"
`include "tx_transaction.sv"
`include "dut_event.sv"
`include "expected_event.sv"
`include "driver.sv"
`include "monitor.sv"
`include "generator.sv"
`include "scoreboard.sv"
`include "checker.sv"

module tb_top;

  // Parámetros de la prueba
  localparam int bits        = tb_pkg::BITS_DEFAULT;
  localparam int drvrs       = tb_pkg::DRVRS_DEFAULT;
  localparam int pckg_sz     = tb_pkg::PCKG_SZ_DEFAULT;
  localparam bit [7:0] broadcast = tb_pkg::BROADCAST_DEFAULT;

  localparam int NUM_TRANSACTIONS = 50;  // total de transacciones a generar
  localparam int SIM_CYCLES       = 20000;

  // Reloj
  logic clk;
  initial clk = 0;
  always #5 clk = ~clk;

  // Interface
  bus_if #(
    .bits(bits),
    .drvrs(drvrs),
    .pckg_sz(pckg_sz)
  ) bus_if_inst ();
  assign bus_if_inst.clk = clk;

  // DUT
  bs_gnrtr_n_rbtr #(
    .bits(bits),
    .drvrs(drvrs),
    .pckg_sz(pckg_sz),
    .broadcast(broadcast)
  ) dut (
    .clk(clk),
    .reset(bus_if_inst.reset),
    .pndng(bus_if_inst.pndng),
    .D_pop(bus_if_inst.D_pop),
    .pop(bus_if_inst.pop),
    .push(bus_if_inst.push),
    .D_push(bus_if_inst.D_push)
  );

  // Mailboxes
  mailbox #(tx_transaction #(drvrs, pckg_sz)) tx_mb    [drvrs]; // Generator -> Driver[i]
  mailbox #(tx_transaction #(drvrs, pckg_sz)) tx_mb_sb;         // Generator -> Scoreboard
  mailbox #(dut_event      #(drvrs, pckg_sz)) event_mb;        // Monitor -> Checker
  mailbox #(expected_event #(drvrs, pckg_sz)) expected_mb;     // Scoreboard -> Checker

  // Componentes del ambiente
  // NOTA: el Scoreboard NO recibe .broadcast(broadcast) explícito. Si se
  // pasa, su especialización de clase deja de coincidir con la que espera
  // checker_c internamente (scoreboard #(drvrs, pckg_sz) sb, sin ese tercer
  // parámetro) y falla la construcción del Checker. Usamos el default de
  // scoreboard (tb_pkg::BROADCAST_DEFAULT), que es el mismo valor que
  // configura el DUT arriba.
  driver     #(.drvrs(drvrs), .pckg_sz(pckg_sz)) drv [drvrs];
  monitor    #(.drvrs(drvrs), .pckg_sz(pckg_sz)) mon;
  generator  #(.drvrs(drvrs), .pckg_sz(pckg_sz)) gen;
  scoreboard #(.drvrs(drvrs), .pckg_sz(pckg_sz)) sb;
  checker_c  #(.drvrs(drvrs), .pckg_sz(pckg_sz)) chk;

  // Secuencia principal
  initial begin
    // Ondas
    $dumpfile("dump.vcd");
    $dumpvars(0, dut);

    // Reset
    bus_if_inst.reset = 1;
    repeat (5) @(posedge clk);
    bus_if_inst.reset = 0;

    $display("================================================================");
    $display("  PRUEBA DE INTEGRACION COMPLETA");
    $display("  Generator + Driver + Monitor + Scoreboard + Checker + DUT");
    $display("  drvrs=%0d  pckg_sz=%0d  broadcast=0x%h  num_transactions=%0d",
              drvrs, pckg_sz, broadcast, NUM_TRANSACTIONS);
    $display("================================================================");

    // Construcción
    for (int i = 0; i < drvrs; i++) begin
      tx_mb[i] = new();
      drv[i]   = new(i, bus_if_inst, tx_mb[i]);
    end
    tx_mb_sb    = new();
    event_mb    = new();
    expected_mb = new();

    mon = new(bus_if_inst, event_mb);
    gen = new(tx_mb, tx_mb_sb);
    gen.num_transactions = NUM_TRANSACTIONS;
    sb  = new(tx_mb_sb, expected_mb);
    chk = new(event_mb, expected_mb, sb);

    // Lanzar todo en paralelo
    fork
      gen.run();

      // Drivers en paralelo
      begin : drv_block
        for (int i = 0; i < drvrs; i++) begin
          automatic int idx = i;
          fork
            drv[idx].run();
          join_none
        end
        wait fork;   // nunca termina (los drivers tienen forever)
      end

      mon.run();
      sb.run();
      chk.run();
    join_none

    // Tiempo de simulación
    repeat (SIM_CYCLES) @(posedge clk);

    // Reporte final del Checker (PASS/FAIL real, no solo actividad)
    chk.reporte_final();

    $display("[TB] fin de simulacion @%0t", $time);
    $finish;
  end

endmodule
