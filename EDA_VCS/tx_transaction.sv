//==============================================================================
// Verificación Funcional
// Integrantes: Ronald - Eric
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

  // Identificador local del testbench; no forma parte del paquete del DUT.
  int unsigned tx_id;

  rand tb_pkg::traffic_type_e traffic_type;
  rand tb_pkg::payload_type_e payload_type;
  rand int unsigned burst_length;
  logic [tb_pkg::DEST_FIELD_WIDTH-1:0] broadcast_value;

  // Paquete completo: [pckg_sz-1 -: DEST_FIELD_WIDTH] = destino, resto = payload
  rand logic [pckg_sz-1:0] packet;

  // Tiempo de espera en ciclos antes de presentar el paquete al DUT.
  rand int unsigned arrival_delta;
  int unsigned      delay_min = 0;
  int unsigned      delay_max = 0;

  // Tiempos de aceptación y recepción, en unidades de $time.
  time send_time;
  time receive_time;
  time delay;

  localparam int PAYLOAD_W = pckg_sz - tb_pkg::DEST_FIELD_WIDTH;

  constraint c_interface_id_range {
    interface_id < drvrs;
  }

  constraint c_arrival_delta {
    arrival_delta inside {[delay_min : delay_max]};
  }

  constraint c_traffic_distribution {
    traffic_type dist {
      tb_pkg::TR_UNICAST   := tb_pkg::TRAFFIC_UNICAST_WEIGHT,
      tb_pkg::TR_SELF      := tb_pkg::TRAFFIC_SELF_WEIGHT,
      tb_pkg::TR_BROADCAST := tb_pkg::TRAFFIC_BROADCAST_WEIGHT,
      tb_pkg::TR_INVALID   := tb_pkg::TRAFFIC_INVALID_WEIGHT
    };
  }

  constraint c_destination {
    if (traffic_type == tb_pkg::TR_UNICAST) {
      packet[pckg_sz-1 -: tb_pkg::DEST_FIELD_WIDTH] inside {[0 : drvrs-1]};
      packet[pckg_sz-1 -: tb_pkg::DEST_FIELD_WIDTH] != interface_id;
    } else if (traffic_type == tb_pkg::TR_SELF) {
      packet[pckg_sz-1 -: tb_pkg::DEST_FIELD_WIDTH] == interface_id;
    } else if (traffic_type == tb_pkg::TR_BROADCAST) {
      packet[pckg_sz-1 -: tb_pkg::DEST_FIELD_WIDTH] == broadcast_value;
    } else {
      packet[pckg_sz-1 -: tb_pkg::DEST_FIELD_WIDTH] inside {[drvrs : 8'hFF]};
      packet[pckg_sz-1 -: tb_pkg::DEST_FIELD_WIDTH] != broadcast_value;
    }
  }

  constraint c_payload_distribution {
    payload_type dist {
      tb_pkg::PT_RANDOM := tb_pkg::PAYLOAD_RANDOM_WEIGHT,
      tb_pkg::PT_ZERO   := tb_pkg::PAYLOAD_PATTERN_WEIGHT,
      tb_pkg::PT_ONES   := tb_pkg::PAYLOAD_PATTERN_WEIGHT,
      tb_pkg::PT_ALT_10 := tb_pkg::PAYLOAD_PATTERN_WEIGHT,
      tb_pkg::PT_ALT_01 := tb_pkg::PAYLOAD_PATTERN_WEIGHT
    };
  }

  constraint c_payload_content {
    if (payload_type == tb_pkg::PT_ZERO)
      packet[PAYLOAD_W-1:0] == '0;
    else if (payload_type == tb_pkg::PT_ONES)
      packet[PAYLOAD_W-1:0] == '1;
    else if (payload_type == tb_pkg::PT_ALT_10)
      packet[PAYLOAD_W-1:0] == {(PAYLOAD_W/2){2'b10}};
    else if (payload_type == tb_pkg::PT_ALT_01)
      packet[PAYLOAD_W-1:0] == {(PAYLOAD_W/2){2'b01}};
  }

  constraint c_burst_length {
    burst_length inside {[tb_pkg::BURST_MIN:tb_pkg::BURST_MAX]};
  }

  function new();
    tx_id        = 0;
    interface_id = 0;
    packet       = '0;
    arrival_delta = 0;
    send_time    = 0;
    receive_time = 0;
    delay        = 0;
    traffic_type = tb_pkg::TR_UNICAST;
    payload_type = tb_pkg::PT_RANDOM;
    burst_length = 1;
    broadcast_value = tb_pkg::BROADCAST_DEFAULT;
  endfunction

  // Extrae el campo de destino (8 bits superiores) del paquete
  function logic [tb_pkg::DEST_FIELD_WIDTH-1:0] get_destination();
    return packet[pckg_sz-1 -: tb_pkg::DEST_FIELD_WIDTH];
  endfunction

  function logic [PAYLOAD_W-1:0] get_payload();
    return packet[PAYLOAD_W-1:0];
  endfunction

  // Utilidades de depuración 

  function void print(string tag = "tx_transaction");
    $display("[%s] tx_id=%0d if=%0d dest=0x%h pkt=0x%h @%0t",
             tag, tx_id, interface_id, get_destination(), packet, $time);
  endfunction

  function string sprint();
    return $sformatf("tx{id=%0d, if=%0d, dest=0x%h, pkt=0x%h, arrival_delta=%0d}",
             tx_id, interface_id, get_destination(), packet, arrival_delta);
  endfunction

endclass : tx_transaction