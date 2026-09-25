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
//     tx_transaction  -->  pndng[id] / D_pop[id]  (señales de entrada del DUT)
//     y observar la confirmación de consumo: pop[id]
//
//   El Driver NO debe:
//     - decidir PASS/FAIL
//     - acceder al Scoreboard
//     - implementar predicción funcional
//     - comparar paquetes
//
//   El Environment instancia 'drvrs' Drivers (uno por interfaz):
//     driver #(drvrs, pckg_sz) drv [drvrs];
//   cada uno con su propio 'id' (0 .. drvrs-1) y su propio mailbox tx_mb[id].
//
// Conexiones:
//   - virtual interface (modport driver_mp) -> señales físicas del DUT
//   - mailbox de tx_transaction              -> recibe transacciones del Generator
//
// Parámetros:
//   drvrs   - cantidad total de interfaces (para tipar vif/mailbox)
//   pckg_sz - ancho en bits del campo packet
//==============================================================================

// Driver minimo:
// - se conecta a la interface por modport drv
// - presenta un paquete hardcodeado en D_pop
// - espera pop del DUT
//
// Todavia no usa tx_transaction ni mailbox.
// Solo sirve para ver senales en EPWave.

class driver;

  virtual bus_if.driver_mp vif;
  int                interface_id;

  function new(virtual bus_if.driver_mp vif, int interface_id);
    this.vif          = vif;
    this.interface_id = interface_id;
  endfunction

  task run(int num_pkts = 1);

    vif.pndng[0][interface_id] = 0;
    vif.D_pop[0][interface_id] = '0;

    repeat (num_pkts) begin
      @(posedge vif.clk);

      // Paquete: destino = interface_id + 1 (mod drvrs), payload = id
      vif.D_pop[0][interface_id] = {8'( (interface_id + 1) % 4 ), 8'(interface_id)};
      vif.pndng[0][interface_id] = 1;

      $display("[DRV %0d] paquete ofrecido @%0t", interface_id, $time);

      fork
        begin
          while (vif.pop[0][interface_id] !== 1'b1)
            @(posedge vif.clk);
          $display("[DRV %0d] pop recibido @%0t", interface_id, $time);
        end
        begin
          repeat (200) @(posedge vif.clk);
          $display("[DRV %0d] TIMEOUT esperando pop @%0t", interface_id, $time);
        end
      join_any
      disable fork;

      vif.pndng[0][interface_id] = 0;
      @(posedge vif.clk);
    end

  endtask

endclass