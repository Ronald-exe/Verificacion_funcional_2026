//==============================================================================
// <NOMBRE DEL CURSO>
// Integrantes: <Integrante 1> - <Integrante 2>
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

  // Timeout por paquete (ciclos negedge)
  localparam int TIMEOUT_CYCLES = 2000;

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
    tx_transaction #(drvrs, pckg_sz) tr;
    bit timed_out;

    vif.pndng[0][id] = 1'b0;
    vif.D_pop[0][id] = '0;

    forever begin
      tx_mb.get(tr);

      // Escribe en negedge: no compite con el DUT que muestrea en posedge.
      @(negedge vif.clk);
      vif.D_pop[0][id] = tr.packet;
      vif.pndng[0][id] = 1'b1;

      $display("[DRV %0d] ofrecido pkt=0x%h @%0t", id, tr.packet, $time);

      timed_out = 0;
      fork
        begin
          while (vif.pop[0][id] !== 1'b1)
            @(negedge vif.clk);
          $display("[DRV %0d] pop recibido @%0t", id, $time);
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
    end
  endtask

endclass : driver