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
//   corrida. Todo se elige desde las opciones de compilación con +define
//   (ver EDA_VCS/README.md): drvrs, pckg_sz, escenario, retardos, cantidad
//   de transacciones, reset en actividad y archivo CSV.
//
//   Flujo:
//     1. Reset inicial
//     2. Sorteo de num_transactions (con la semilla de la corrida)
//     3. env.build(): construcción de todos los componentes y mailboxes
//     4. env.run(): fork paralelo de Generator, Driver[i], Monitor,
//        Scoreboard, Checker y chequeo de Round Robin
//     5. (opcional) reset en actividad en el ciclo RESET_AT
//     6. Fin por condición: env.idle() + DRAIN_CYCLES, con SIM_CYCLES
//        como watchdog
//     7. Checker.reporte_final() (PASS/FAIL, retardos, Round Robin, CSV)
//        + $finish
//==============================================================================

`include "rtl/Library.sv"
`include "tb/pkg/tb_pkg.sv"
`include "tb/interfaces/bus_if.sv"
`include "tb/transactions/tx_transaction.sv"
`include "tb/transactions/dut_event.sv"
`include "tb/transactions/expected_event.sv"
`include "tb/drivers/driver.sv"
`include "tb/generator/generator.sv"
`include "tb/monitor/monitor.sv"
`include "tb/scoreboard/scoreboard.sv"
`include "tb/checker/checker.sv"
`include "tb/environment/environment.sv"

// Configuración del bus (TP14 pckg_sz = 16/32/64, TP15 drvrs = 2/4/8).
// Se cambia aquí o desde las opciones de compilación, sin tocar el código:
//   +define+DRVRS=8+PCKG_SZ=32
`ifndef DRVRS
  `define DRVRS tb_pkg::DRVRS_DEFAULT
`endif
`ifndef PCKG_SZ
  `define PCKG_SZ tb_pkg::PCKG_SZ_DEFAULT
`endif
// Escenario de generación (ver tb_pkg::scenario_e), p. ej.:
//   +define+SCENARIO=SC_BROADCAST
`ifndef SCENARIO
  `define SCENARIO SC_RANDOM
`endif
// Interfaces origen para SC_ONE_IF (SRC_A) y SC_TWO_IF (SRC_A, SRC_B), p. ej.:
//   +define+SCENARIO=SC_TWO_IF+SRC_A=1+SRC_B=3
`ifndef SRC_A
  `define SRC_A 0
`endif
`ifndef SRC_B
  `define SRC_B 1
`endif
// Retardo aleatorio (ciclos) antes de cada paquete, p. ej.:
//   back-to-back (TP10): +define+DELAY_MAX=0
//   idle         (TP09): +define+DELAY_MIN=50+DELAY_MAX=100
`ifndef DELAY_MIN
  `define DELAY_MIN 0
`endif
`ifndef DELAY_MAX
  `define DELAY_MAX 10
`endif
// Cantidad de transacciones: se elige al azar en [NUM_TX_MIN : NUM_TX_MAX]
// con la semilla de la corrida, p. ej. cantidad fija: +define+NUM_TX_MIN=50+NUM_TX_MAX=50
`ifndef NUM_TX_MIN
  `define NUM_TX_MIN 30
`endif
`ifndef NUM_TX_MAX
  `define NUM_TX_MAX 80
`endif
// Reset durante actividad (TP01): ciclos después del arranque del tráfico en
// que se aplica un reset de RESET_CYCLES ciclos. 0 = deshabilitado, p. ej.:
//   +define+RESET_AT=300
`ifndef RESET_AT
  `define RESET_AT 0
`endif
`ifndef RESET_CYCLES
  `define RESET_CYCLES 5
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
  localparam bit [7:0] broadcast = tb_pkg::BROADCAST_DEFAULT;

  tb_pkg::scenario_e scenario = tb_pkg::`SCENARIO;
  localparam int SRC_A = `SRC_A;
  localparam int SRC_B = `SRC_B;
  localparam int DELAY_MIN = `DELAY_MIN;
  localparam int DELAY_MAX = `DELAY_MAX;

  // Ciclos extra tras el último pop para que llegue el último push
  // (serialización de un paquete completo más margen)
  localparam int DRAIN_CYCLES = 4*pckg_sz + 50;

  localparam int RESET_AT     = `RESET_AT;
  localparam int RESET_CYCLES = `RESET_CYCLES;

  localparam int NUM_TX_MIN = `NUM_TX_MIN;
  localparam int NUM_TX_MAX = `NUM_TX_MAX;
  int unsigned   num_transactions;          // se sortea al inicio de la prueba

  localparam int SIM_CYCLES = 20000;        // watchdog: tiempo máximo de la prueba

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
    // Ondas
    $dumpfile("dump.vcd");
    $dumpvars(0, dut);

    // Reset
    bus_if_inst.reset = 1;
    repeat (5) @(posedge clk);
    bus_if_inst.reset = 0;

    if (NUM_TX_MIN > NUM_TX_MAX)
      $fatal(1, "[TB] NUM_TX_MIN=%0d > NUM_TX_MAX=%0d", NUM_TX_MIN, NUM_TX_MAX);
    num_transactions = $urandom_range(NUM_TX_MAX, NUM_TX_MIN);

    $display("================================================================");
    $display("  PRUEBA DE INTEGRACION COMPLETA");
    $display("  Generator + Driver + Monitor + Scoreboard + Checker + DUT");
    $display("  drvrs=%0d  pckg_sz=%0d  broadcast=0x%h  num_transactions=%0d (rango [%0d:%0d])",
              drvrs, pckg_sz, broadcast, num_transactions, NUM_TX_MIN, NUM_TX_MAX);
    // Semilla inicial del simulador (Run Options: +ntb_random_seed=<N> o
    // +ntb_random_seed_automatic). Con ella se reproduce la corrida exacta.
    $display("  seed=%0d", $unsigned($get_initial_random_seed()));
    $display("  scenario=%s", scenario.name());
    if (scenario == tb_pkg::SC_ONE_IF || scenario == tb_pkg::SC_TWO_IF) begin
      if (SRC_A >= drvrs || SRC_B >= drvrs || SRC_A == SRC_B)
        $fatal(1, "[TB] SRC_A=%0d / SRC_B=%0d invalidos para drvrs=%0d (deben ser distintos y < drvrs)",
               SRC_A, SRC_B, drvrs);
      $display("  src_a=%0d  src_b=%0d", SRC_A, SRC_B);
    end
    if (DELAY_MIN > DELAY_MAX)
      $fatal(1, "[TB] DELAY_MIN=%0d > DELAY_MAX=%0d", DELAY_MIN, DELAY_MAX);
    $display("  delay=[%0d:%0d] ciclos", DELAY_MIN, DELAY_MAX);
    if (RESET_AT > 0)
      $display("  reset en actividad: ciclo %0d, duracion %0d ciclos", RESET_AT, RESET_CYCLES);
    $display("================================================================");

    // Construcción y arranque del ambiente
    env = new(bus_if_inst);
    env.build();
    env.gen.num_transactions = num_transactions;
    env.gen.scenario         = scenario;
    env.gen.src_a            = SRC_A;
    env.gen.src_b            = SRC_B;
    env.gen.delay_min        = DELAY_MIN;
    env.gen.delay_max        = DELAY_MAX;
    env.chk.abrir_csv(`CSV_FILE);
    env.run();

    // Reset durante actividad (TP01). Se aplica en negedge para no competir
    // con el muestreo del DUT/Monitor en posedge; el Checker descarta los
    // paquetes que el DUT tenía en vuelo en ese momento.
    if (RESET_AT > 0) begin
      fork
        begin
          repeat (RESET_AT) @(posedge clk);
          @(negedge clk);
          $display("[TB] RESET en actividad @%0t (%0d ciclos)", $time, RESET_CYCLES);
          bus_if_inst.reset = 1;
          env.chk.descartar_en_vuelo();
          repeat (RESET_CYCLES) @(posedge clk);
          @(negedge clk);
          bus_if_inst.reset = 0;
          $display("[TB] RESET liberado @%0t", $time);
        end
      join_none
    end

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
    env.chk.reporte_final();

    $display("[TB] fin de simulacion @%0t", $time);
    $finish;
  end

endmodule
