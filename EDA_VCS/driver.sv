//==============================================================================
// Verificación Funcional
// Integrantes: Ronald - Eric
//==============================================================================
// Archivo   : driver.sv
// Componente: Driver (una instancia por interfaz del bus)
//------------------------------------------------------------------------------
// Descripción:
//   Convierte objetos tx_transaction en actividad sobre la interfaz física
//   del DUT, para UNA interfaz específica identificada por 'id'.
//
//   Responsabilidad EXCLUSIVA:
//     tx_transaction  -->  pndng[0][id] / D_pop[0][id]
//     observar la confirmación de consumo: pop[0][id]
//
//   El Driver NO debe:
//     - decidir PASS/FAIL
//     - acceder al Scoreboard
//     - implementar predicción funcional
//     - comparar paquetes
//
// Conexiones:
//   - virtual interface (modport driver_mp) -> señales físicas del DUT
//   - mailbox de tx_transaction              -> recibe transacciones del Generator
//
// Parámetros:
//   drvrs   - cantidad total de interfaces (para tipar vif/mailbox)
//   pckg_sz - ancho en bits del campo packet
//==============================================================================

class driver #(
  parameter int drvrs   = tb_pkg::DRVRS_DEFAULT,
  parameter int pckg_sz = tb_pkg::PCKG_SZ_DEFAULT
);

  int unsigned id;
  virtual bus_if #(.drvrs(drvrs), .pckg_sz(pckg_sz)).driver_mp vif;
  mailbox #(tx_transaction #(drvrs, pckg_sz)) tx_mb;
  tx_transaction #(drvrs, pckg_sz) tx_fifo[$];
  event tx_available;
  int unsigned outstanding_count = 0;

  // Timeout por paquete (ciclos negedge)
  localparam int TIMEOUT_CYCLES = 2000;

  // 1 mientras el Driver tiene un paquete en curso (esperando su retardo o
  // esperando pop); el test lo consulta para saber si ya terminó el tráfico
  bit busy = 0;

  function new(
    int unsigned                                                  id,
    virtual bus_if #(.drvrs(drvrs), .pckg_sz(pckg_sz)).driver_mp  vif,
    mailbox #(tx_transaction #(drvrs, pckg_sz))                   tx_mb
  );
    this.id    = id;
    this.vif   = vif;
    this.tx_mb = tx_mb;
  endfunction

  task run();
    vif.pndng[0][id] = 1'b0;
    vif.D_pop[0][id] = '0;

    fork
      collect_transactions();
      drive_transactions();
    join
  endtask

  task collect_transactions();
    tx_transaction #(drvrs, pckg_sz) tr;

    forever begin
      tx_mb.get(tr);
      tx_fifo.push_back(tr);
      outstanding_count++;
      busy = 1;
      -> tx_available;
    end
  endtask

  task drive_transactions();
    tx_transaction #(drvrs, pckg_sz) tr;
    bit timed_out;

    forever begin
      while (tx_fifo.size() == 0)
        @tx_available;

      tr = tx_fifo[0];

      // arrival_delta ciclos antes de ofrecer el paquete (0 = back-to-back)
      repeat (tr.arrival_delta) @(negedge vif.clk);

      // Escribe en negedge: no compite con el DUT que muestrea en posedge.
      @(negedge vif.clk);
      vif.D_pop[0][id] = tr.packet;
      vif.pndng[0][id] = 1'b1;

      $display("[DRV %0d] ofrecido tx#%0d pkt=0x%h @%0t",
           id, tr.tx_id, tr.packet, $time);

      timed_out = 0;
      fork
        begin
          while (vif.pop[0][id] !== 1'b1)
            @(negedge vif.clk);
          $display("[DRV %0d] pop recibido tx#%0d @%0t", id, tr.tx_id, $time);
        end
        begin
          repeat (TIMEOUT_CYCLES) @(negedge vif.clk);
          timed_out = 1;
          $display("[DRV %0d] TIMEOUT esperando pop @%0t", id, $time);
        end
      join_any
      disable fork;

      // Limpia aunque haya timeout (permite continuar al siguiente paquete)
      vif.pndng[0][id] = 1'b0;
      @(negedge vif.clk);
      void'(tx_fifo.pop_front());
      outstanding_count--;
      busy = (outstanding_count != 0);
    end
  endtask

endclass : driver