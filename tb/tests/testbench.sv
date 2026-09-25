// Top-level basico
// - genera clk
// - genera reset
// - instancia bus_if
// - instancia el DUT y lo conecta a la interface
//
// Todavia no hay driver ni monitor. Solo se verifica
// que el DUT se instancia y que reset/clk funcionan.

`include "Library.sv"
`include "driver.sv"
`include "monitor.sv"

module tb_top;

  localparam int bits    = 1;
  localparam int drvrs   = 4;
  localparam int pckg_sz = 16;
  localparam bit [7:0] broadcast = 8'hFF;

  logic clk;

  // Reloj
  initial clk = 0;
  always #5 clk = ~clk;

  // Interface
  bus_if #(
    .bits(bits),
    .drvrs(drvrs),
    .pckg_sz(pckg_sz)
  ) bus_if_inst (
    .clk(clk)
  );

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

  driver  driver_mp[drvrs];
  monitor monitor_mp;

  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, dut);

    bus_if_inst.reset = 1;
    repeat(5) @(posedge clk);
    bus_if_inst.reset = 0;

    for (int i = 0; i < drvrs; i++)
      driver_mp[i] = new(bus_if_inst, i);

    monitor_mp = new(bus_if_inst, drvrs);

    fork
      begin : run_drivers
        for (int i = 0; i < drvrs; i++) begin
          automatic int idx = i;
          fork
            driver_mp[idx].run(1);
          join_none
        end
        wait fork;
      end
      monitor_mp.run();
    join_any

    repeat(200) @(posedge clk);
    $display("[TB] fin de simulacion @%0t", $time);
    $finish;
  end

endmodule