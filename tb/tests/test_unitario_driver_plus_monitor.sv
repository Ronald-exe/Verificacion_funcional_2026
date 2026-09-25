//==============================================================================
// <NOMBRE DEL CURSO>
// Integrantes: <Integrante 1> - <Integrante 2>
//==============================================================================
// Archivo   : testbench.sv
// Componente: Top-level de la prueba unitaria (sin Scoreboard ni Checker)
//------------------------------------------------------------------------------
// Descripción:
//   Integra DUT + bus_if + driver[] + monitor + mailboxes.
//
//   Flujo:
//     1. Reset
//     2. Construcción de drivers, monitor y mailboxes
//     3. Fork paralelo:
//        - Fake Generator: N tx por interfaz -> tx_mb[i]
//        - Driver[i].run()  (uno por interfaz)
//        - Monitor.run()
//        - Drenaje de event_mb
//     4. Tiempo de simulación fijo
//     5. $finish
//
//   NO hay Scoreboard ni Checker. Esta prueba verifica que:
//     - los drivers presentan paquetes al DUT
//     - el DUT confirma pop
//     - el DUT entrega push a destino
//     - el monitor observa y empaqueta dut_event
//==============================================================================

`include "Library.sv"
`include "tb_pkg.sv"
`include "tx_transaction.sv"
`include "dut_event.sv"
`include "driver.sv"
`include "monitor.sv"

module tb_top;

  // Parámetros de la prueba
  // ---------------------------------------------------------------------
  localparam int bits        = tb_pkg::BITS_DEFAULT;
  localparam int drvrs       = tb_pkg::DRVRS_DEFAULT;
  localparam int pckg_sz     = tb_pkg::PCKG_SZ_DEFAULT;
  localparam bit [7:0] broadcast = tb_pkg::BROADCAST_DEFAULT;

  localparam int NUM_TX_PER_IF = 8;      // 8 paquetes por interfaz
  localparam int SIM_CYCLES    = 20000;  // ciclos de simulación

  // ---------------------------------------------------------------------
  // Reloj
  // ---------------------------------------------------------------------
  logic clk;
  initial clk = 0;
  always #5 clk = ~clk;

  // ---------------------------------------------------------------------
  // Interface
  // ---------------------------------------------------------------------
  bus_if #(
    .bits(bits),
    .drvrs(drvrs),
    .pckg_sz(pckg_sz)
  ) bus_if_inst (
    .clk(clk)
  );

  // ---------------------------------------------------------------------
  // DUT
  // ---------------------------------------------------------------------
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

  // ---------------------------------------------------------------------
  // Mailboxes
  // ---------------------------------------------------------------------
  mailbox #(tx_transaction #(drvrs, pckg_sz)) tx_mb    [drvrs];  // Gen -> Driver[i]
  mailbox #(dut_event      #(drvrs, pckg_sz)) event_mb;          // Monitor -> drenaje

  // ---------------------------------------------------------------------
  // Componentes del ambiente
  // ---------------------------------------------------------------------
  driver  #(.drvrs(drvrs), .pckg_sz(pckg_sz)) drv [drvrs];
  monitor #(.drvrs(drvrs), .pckg_sz(pckg_sz)) mon;

  // ---------------------------------------------------------------------
  // Contadores para reporte final
  // ---------------------------------------------------------------------
  int pop_count  = 0;
  int push_count = 0;

  // ---------------------------------------------------------------------
  // Secuencia principal
  // ---------------------------------------------------------------------
  initial begin
    // Ondas
    $dumpfile("dump.vcd");
    $dumpvars(0, dut);

    // Reset
    bus_if_inst.reset = 1;
    repeat (5) @(posedge clk);
    bus_if_inst.reset = 0;

    $display("================================================================");
    $display("  PRUEBA UNITARIA: driver + monitor + DUT");
    $display("  drvrs=%0d  pckg_sz=%0d  broadcast=0x%h", drvrs, pckg_sz, broadcast);
    $display("  tx por interfaz = %0d  (total = %0d)", NUM_TX_PER_IF, NUM_TX_PER_IF*drvrs);
    $display("================================================================");

    // Construcción
    for (int i = 0; i < drvrs; i++) begin
      tx_mb[i] = new();
      drv[i]   = new(i, bus_if_inst, tx_mb[i]);
    end
    event_mb = new();
    mon      = new(bus_if_inst, event_mb);

    // Lanzar todo en paralelo
    fork
      // ---------------------------------------------------------------
      // Fake Generator: NUM_TX_PER_IF tx por interfaz
      // ---------------------------------------------------------------
      begin : gen_block
        for (int i = 0; i < drvrs; i++) begin
          automatic int idx = i;
          fork
            begin
              tx_transaction #(drvrs, pckg_sz) tr;
              repeat (NUM_TX_PER_IF) begin
                tr = new();
                if (!tr.randomize())
                  $fatal(1, "[TB] randomize() fallo");
                tr.interface_id = idx;   // forzar origen = idx
                tx_mb[idx].put(tr);
              end
            end
          join_none
        end
        wait fork;   // espera a que terminen todos los generadores
      end

      // ---------------------------------------------------------------
      // Drivers en paralelo
      // ---------------------------------------------------------------
      begin : drv_block
        for (int i = 0; i < drvrs; i++) begin
          automatic int idx = i;
          fork
            drv[idx].run();
          join_none
        end
        wait fork;   // nunca termina (los drivers tienen forever)
      end

      // ---------------------------------------------------------------
      // Monitor
      // ---------------------------------------------------------------
      mon.run();

      // ---------------------------------------------------------------
      // Drenaje de event_mb (el monitor ya imprime por $display)
      // ---------------------------------------------------------------
      begin : drain_block
        dut_event #(drvrs, pckg_sz) ev;
        forever begin
          event_mb.get(ev);
          if (ev.event_type == tb_pkg::EVT_POP)  pop_count++;
          else                                   push_count++;
        end
      end

    join_none

    // -----------------------------------------------------------------
    // Tiempo de simulación
    // -----------------------------------------------------------------
    repeat (SIM_CYCLES) @(posedge clk);

    // -----------------------------------------------------------------
    // Reporte final
    // -----------------------------------------------------------------
    $display("");
    $display("================================================================");
    $display("  REPORTE PRUEBA UNITARIA  @%0t", $time);
    $display("================================================================");
    $display("  Paquetes ofrecidos (por driver) : %0d", NUM_TX_PER_IF*drvrs);
    $display("  POP observados por el monitor   : %0d", pop_count);
    $display("  PUSH observados por el monitor  : %0d", push_count);
    $display("----------------------------------------------------------------");
    if (pop_count == 0)
      $display("  >>  NO hubo actividad: revisar driver/DUT");
    else if (pop_count < NUM_TX_PER_IF*drvrs)
      $display("  >>  Actividad parcial: %0d de %0d paquetes consumidos",
                pop_count, NUM_TX_PER_IF*drvrs);
    else
      $display("  >>  Actividad completa: todos los paquetes consumidos");
    $display("================================================================");
    $display("");

    $finish;
  end

endmodule