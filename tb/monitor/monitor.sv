// Monitor minimo:
// - se conecta a la interface por modport mon
// - observa pop y push en cada ciclo
// - reporta con $display
//
// No determina pass/fail. Solo observa.

class monitor;

  virtual bus_if.monitor_mp vif;
  int                drvrs;

  // Valores previos para detectar flancos
  logic prev_pop  [0:0][3:0];
  logic prev_push [0:0][3:0];

  function new(virtual bus_if.monitor_mp vif, int drvrs);
    this.vif   = vif;
    this.drvrs = drvrs;
  endfunction

  task run();

    // Inicializa previos
    for (int i = 0; i < drvrs; i++) begin
      prev_pop[0][i]  = 0;
      prev_push[0][i] = 0;
    end

    forever begin
      @(posedge vif.clk);

      for (int i = 0; i < drvrs; i++) begin

        // POP: flanco de subida
        if (vif.pop[0][i] === 1'b1 && prev_pop[0][i] === 1'b0)
          $display("[MON] POP  if=%0d pkt=0x%h @%0t",
                   i, vif.D_pop[0][i], $time);

        // PUSH: flanco de subida
        if (vif.push[0][i] === 1'b1 && prev_push[0][i] === 1'b0)
          $display("[MON] PUSH if=%0d pkt=0x%h @%0t",
                   i, vif.D_push[0][i], $time);

        // Actualiza previos
        prev_pop[0][i]  = vif.pop[0][i];
        prev_push[0][i] = vif.push[0][i];

      end
    end

  endtask

endclass