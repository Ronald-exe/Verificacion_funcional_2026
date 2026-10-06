//==============================================================================
// Verificación Funcional
// Integrantes: Ronald - Eric
//==============================================================================
// Archivo   : testbench.sv
// Componente: Test (módulo top de la prueba)
//------------------------------------------------------------------------------
// Descripción:
//   Integra DUT + bus_if + environment (Generator + driver[] + Monitor +
//   Scoreboard + Checker + mailboxes) y define la configuración de la
//   corrida. Los parámetros estructurales usan +define; SCENARIO, NUM y SEED
//   son plusargs. NUM indica transacciones por interfaz.
//
//   Flujo:
//     1. Reset inicial
//     2. Lectura de escenario, NUM transacciones/source y seed
//     3. env.build(): construcción de todos los componentes y mailboxes
//     4. env.run(): fork paralelo de Generator, Driver[i], Monitor,
//        Scoreboard, Checker y chequeo de Round Robin
//     5. Fin por condición: env.idle() + DRAIN_CYCLES, con SIM_CYCLES
//        como watchdog
//     6. Checker.reporte_final() (PASS/FAIL, retardos, Round Robin, CSV)
//        + $finish
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
`include "environment.sv"

// Configuración del bus (TP14 pckg_sz = 16/32/64, TP15 drvrs = 2/4/8).
// Se cambia aquí o desde las opciones de compilación, sin tocar el código:
//   +define+DRVRS=8+PCKG_SZ=32
`ifndef DRVRS
  `define DRVRS tb_pkg::DRVRS_DEFAULT
`endif
`ifndef PCKG_SZ
  `define PCKG_SZ tb_pkg::PCKG_SZ_DEFAULT
`endif
`ifndef BROADCAST
  `define BROADCAST tb_pkg::BROADCAST_DEFAULT
`endif
// Rango de arrival_delta (ciclos) antes de cada paquete, p. ej.:
//   back-to-back (TP10): +define+DELAY_MAX=0
//   idle         (TP09): +define+DELAY_MIN=50+DELAY_MAX=100
`ifndef DELAY_MIN
  `define DELAY_MIN 0
`endif
`ifndef DELAY_MAX
  `define DELAY_MAX 10
`endif
// Archivo del reporte de retardos por paquete (entrada del histograma GNUplot)
`ifndef CSV_FILE
  `define CSV_FILE "reporte_paquetes.csv"
`endif

module tb_top;

  // Parámetros de la prueba
  localparam int bits        = tb_pkg::BITS_DEFAULT;
  localparam int drvrs       = `DRVRS;
  localparam int pckg_sz     = `PCKG_SZ;
  localparam bit [7:0] broadcast = `BROADCAST;

  tb_pkg::scenario_e scenario;
  localparam int DELAY_MIN = `DELAY_MIN;
  localparam int DELAY_MAX = `DELAY_MAX;
  int unsigned seed;
  string scenario_arg;

  // Ciclos extra tras el último pop para que llegue el último push
  // (serialización de un paquete completo más margen)
  localparam int DRAIN_CYCLES = 4*pckg_sz + 50;

  int unsigned num_transactions;
  int unsigned total_transactions;

  longint unsigned SIM_CYCLES;

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

  // Environment: construye y conecta Generator, Driver[], Monitor,
  // Scoreboard, Checker y todos los mailboxes (ver environment.sv)
  environment #(.drvrs(drvrs), .pckg_sz(pckg_sz)) env;

  // Secuencia principal
  initial begin
    scenario = tb_pkg::SC_MIXED;
    num_transactions = tb_pkg::NUM_TRANSACTIONS_DEFAULT;
    seed = tb_pkg::SEED_BASE_DEFAULT;

    if ($value$plusargs("SCENARIO=%s", scenario_arg)) begin
      case (scenario_arg)
        "SC_RANDOM":     scenario = tb_pkg::SC_RANDOM;
        "SC_BURST":      scenario = tb_pkg::SC_BURST;
        "SC_CONCURRENT": scenario = tb_pkg::SC_CONCURRENT;
        "SC_BOUNDARY":   scenario = tb_pkg::SC_BOUNDARY;
        "SC_MIXED":      scenario = tb_pkg::SC_MIXED;
        default: $fatal(1, "[TB] SCENARIO='%s' invalido", scenario_arg);
      endcase
    end
    void'($value$plusargs("NUM=%d", num_transactions));
    void'($value$plusargs("SEED=%d", seed));

    if (broadcast < drvrs)
      $fatal(1, "[TB] BROADCAST=%0d colisiona con IDs validos 0..%0d", broadcast, drvrs-1);
    if (drvrs == 0 || num_transactions > (32'hFFFF_FFFF / drvrs))
      $fatal(1, "[TB] NUM=%0d por terminal excede el rango para drvrs=%0d", num_transactions, drvrs);
    total_transactions = num_transactions * drvrs;
    SIM_CYCLES = (longint'(total_transactions) * (pckg_sz + 16) * 3) +
                 (longint'(total_transactions) * (DELAY_MAX + 1)) +
                 DRAIN_CYCLES + 1000;

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
      $display("  drvrs=%0d  pckg_sz=%0d  broadcast=0x%h  num/source=%0d  total=%0d",
          drvrs, pckg_sz, broadcast, num_transactions, total_transactions);
    $display("  seed=%0d", seed);
    $display("  scenario=%s", scenario.name());
    if (DELAY_MIN > DELAY_MAX)
      $fatal(1, "[TB] DELAY_MIN=%0d > DELAY_MAX=%0d", DELAY_MIN, DELAY_MAX);
    $display("  arrival_delta=[%0d:%0d] ciclos", DELAY_MIN, DELAY_MAX);
    $display("================================================================");

    // Construcción y arranque del ambiente
    env = new(bus_if_inst);
    env.build();
    env.gen.num_transactions = num_transactions;
    env.gen.scenario         = scenario;
    env.gen.seed             = seed;
    env.gen.broadcast_stimulus = broadcast;
    env.gen.delay_min        = DELAY_MIN;
    env.gen.delay_max        = DELAY_MAX;
    env.sb.broadcast_expected = broadcast;
    env.chk.abrir_csv(`CSV_FILE);
    env.run();

    // Fin de la prueba por condición: se espera a que ya no quede tráfico
    // (env.idle) y luego DRAIN_CYCLES para que lleguen los últimos push.
    // SIM_CYCLES queda como watchdog por si el DUT se queda colgado.
    // El fork externo aísla el 'disable fork' para que solo detenga estas
    // dos ramas y no los procesos del ambiente (hijos del mismo initial).
    fork
      begin
        fork
          begin
            while (!env.idle()) @(posedge clk);
            repeat (DRAIN_CYCLES) @(posedge clk);
            $display("[TB] trafico terminado @%0t", $time);
          end
          begin
            repeat (SIM_CYCLES) @(posedge clk);
            $display("[TB] WATCHDOG: se alcanzaron %0d ciclos sin terminar el trafico @%0t",
                     SIM_CYCLES, $time);
          end
        join_any
        disable fork;
      end
    join

    // Reporte final del Checker (PASS/FAIL real, no solo actividad)
    env.chk.reporte_final(total_transactions);

    $display("");
    $display("========================================");
    $display("VERIFICATION SUMMARY");
    $display("========================================");
    $display("SEED        : %0d", seed);
    $display("SCENARIO    : %s", scenario.name());
    $display("DRVRS       : %0d", drvrs);
    $display("PCKG_SZ     : %0d", pckg_sz);
    $display("BROADCAST   : %0d", broadcast);
    $display("NUM/TERM    : %0d", num_transactions);
    $display("TOTAL       : %0d", total_transactions);
    $display("PASS        : %0d", env.chk.tx_passed_count);
    $display("FAIL        : %0d", env.chk.tx_failed_count);
    $display("EVENT ERRORS: %0d", env.chk.transacciones_error +
         env.chk.transacciones_pendientes + env.chk.rr_errores);
    $display("RESULT      : %s", env.chk.final_pass ? "PASS" : "FAIL");
    $display("========================================");

    $display("[TB] fin de simulacion @%0t", $time);
    if (env.chk.final_pass)
      $finish;
    else
      $fatal(1, "[TB] Verificacion funcional fallida");
  end

endmodule
