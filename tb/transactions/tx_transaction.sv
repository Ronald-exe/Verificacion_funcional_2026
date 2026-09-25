//==============================================================================
// <NOMBRE DEL CURSO>
// Integrantes: <Integrante 1> - <Integrante 2>
//==============================================================================
// Archivo   : tx_transaction.sv
// Componente: Transacción de transmisión
//------------------------------------------------------------------------------
// Descripción:
//   Representa una solicitud de transmisión para una interfaz determinada.
//
//   Comunicación (DUT_BUS_SPEC.md sec. 11):
//     Generator -> Driver[interface_id]   vía tx_mb[interface_id]
//     Generator -> Scoreboard             vía tx_mb_sb
//
//   Campos mínimos requeridos por el spec:
//     interface_id - interfaz/driver que origina la transmisión
//     packet       - paquete completo: [pckg_sz-1 -: 8] = destino,
//                    resto = payload (ver sec. 4)
//
// Parámetros:
//   drvrs   - acota el rango válido de interface_id (0 .. drvrs-1)
//   pckg_sz - ancho en bits del campo packet
//==============================================================================

class tx_transaction #(
  parameter int drvrs   = tb_pkg::DRVRS_DEFAULT,
  parameter int pckg_sz = tb_pkg::PCKG_SZ_DEFAULT
);

  // Interfaz/driver que origina la transmisión (0 .. drvrs-1)
  rand int unsigned interface_id;

  // Paquete completo: [pckg_sz-1 -: DEST_FIELD_WIDTH] = destino, resto = payload
  rand logic [pckg_sz-1:0] packet;

  constraint c_interface_id_range {
    interface_id < drvrs;
  }

  // Distribución de destinos: 70% unicast válido, 20% broadcast, 10% inválido.
  // El broadcast usa BROADCAST_RTL_ACTUAL porque el RTL real lo ignora.
  constraint c_destination {
    packet[pckg_sz-1 -: tb_pkg::DEST_FIELD_WIDTH] dist {
      [0 : drvrs-1]                              :/ 70,
      tb_pkg::BROADCAST_RTL_ACTUAL               :/ 20,
      [drvrs : tb_pkg::BROADCAST_RTL_ACTUAL - 1] :/ 10
    };
  }

  function new();
    interface_id = 0;
    packet       = '0;
  endfunction

  // Extrae el campo de destino (8 bits superiores) del paquete
  function logic [tb_pkg::DEST_FIELD_WIDTH-1:0] get_destination();
    return packet[pckg_sz-1 -: tb_pkg::DEST_FIELD_WIDTH];
  endfunction

  // Utilidades de depuración 

  function void print(string tag = "tx_transaction");
    $display("[%s] if=%0d dest=0x%h pkt=0x%h @%0t",
             tag, interface_id, get_destination(), packet, $time);
  endfunction

  function string sprint();
    return $sformatf("tx{if=%0d, dest=0x%h, pkt=0x%h}",
                     interface_id, get_destination(), packet);
  endfunction

endclass : tx_transaction