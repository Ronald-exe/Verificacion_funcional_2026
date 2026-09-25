module tb_top;

  localparam int bits        = 1;
  localparam int drvrs       = 4;
  localparam int pckg_sz     = 16;
  localparam bit [7:0] broadcast = 8'hFF;

  // 8 transacciones por interfaz
  localparam int NUM_TX_PER_IF = 8;

  logic clk;
  initial clk = 0;
  always #5 clk = ~clk;

  bus_if #(.bits(bits), .drvrs(drvrs), .pckg_sz(pckg_sz)) bus_if_inst(.clk(clk));

  bs_gnrtr_n_rbtr #(
    .bits(bits), .drvrs(drvrs), .pckg_sz(pckg_sz), .broadcast(broadcast)
  ) dut (
    .clk(clk),
    .reset(bus_if_inst.reset),
    .pndng(bus_if_inst.pndng),
    .D_pop(bus_if_inst.D_pop),
    .pop(bus_if_inst.pop),
    .push(bus_if_inst.push),
    .D_push(bus_if_inst.D_push)
  );

  driver  #(.drvrs(drvrs), .pckg_sz(pckg_sz)) drv[drvrs];
  monitor #(.drvrs(drvrs), .pckg_sz(pckg_sz)) mon;

  mailbox #(tx_transaction #(drvrs, pckg_sz)) tx_mb   [drvrs];
  mailbox #(dut_event      #(drvrs, pckg_sz)) event_mb;

  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, dut);

    // Reset
    bus_if_inst.reset = 1;
    repeat(5) @(posedge clk);
    bus_if_inst.reset = 0;

    // Construcción
    for (int i = 0; i < drvrs; i++) begin
      tx_mb[i] = new();
      drv[i]   = new(i, bus_if_inst, tx_mb[i]);
    end
    event_mb = new();
    mon      = new(bus_if_inst, event_mb);

    // Lanzar todo en paralelo
    fork
      // Generador fake: N tx por interfaz
      for (int i = 0; i < drvrs; i++) begin
        automatic int idx = i;
        fork
          begin
            tx_transaction #(drvrs, pckg_sz) tr;
            repeat (NUM_TX_PER_IF) begin
              tr = new();
              if (!tr.randomize())
                $fatal(1, "[TB] randomize fallo");
              tr.interface_id = idx;
              tx_mb[idx].put(tr);
            end
          end
        join_none
      end

      // Drivers
      for (int i = 0; i < drvrs; i++) begin
        automatic int idx = i;
        fork
          drv[idx].run();
        join_none
      end

      // Monitor
      mon.run();

      // Drena event_mb (el monitor ya imprime)
      begin
        dut_event #(drvrs, pckg_sz) ev;
        forever event_mb.get(ev);
      end
    join_none

    // Tiempo de simulación generoso
    repeat(20000) @(posedge clk);

    $display("[TB] fin de simulacion @%0t", $time);
    $finish;
  end

endmodule