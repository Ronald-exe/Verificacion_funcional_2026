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

class driver #(
  parameter int drvrs   = tb_pkg::DRVRS_DEFAULT,
  parameter int pckg_sz = tb_pkg::PCKG_SZ_DEFAULT
);

  // Identificador de la interfaz que maneja esta instancia (0 .. drvrs-1)
  int unsigned id;

  virtual bus_if #(.drvrs(drvrs), .pckg_sz(pckg_sz)).driver_mp vif;

  mailbox #(tx_transaction #(drvrs, pckg_sz)) tx_mb;

  function new(
    int unsigned                                              id,
    virtual bus_if #(.drvrs(drvrs), .pckg_sz(pckg_sz)).driver_mp vif,
    mailbox #(tx_transaction #(drvrs, pckg_sz))               tx_mb
  );
    // TODO: asignar this.id, this.vif, this.tx_mb
  endfunction

  task run();
    // -----------------------------------------------------------------
    // TODO (equipo):
    //   forever begin
    //     tx_transaction #(drvrs, pckg_sz) tr;
    //     tx_mb.get(tr);
    //     // presentar pndng[id] = 1 y D_pop[id] = tr.packet
    //     // esperar (por ciclo de reloj) hasta observar pop[id] == 1
    //     // limpiar pndng[id] según corresponda antes de atender la
    //     // siguiente transacción
    //   end
    // -----------------------------------------------------------------
  endtask

endclass : driver
