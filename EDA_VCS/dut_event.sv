//==============================================================================
// <NOMBRE DEL CURSO>
// Integrantes: <Integrante 1> - <Integrante 2>
//==============================================================================
// Archivo   : dut_event.sv
// Componente: Evento observado en el DUT
//------------------------------------------------------------------------------
// Descripción:
//   Representa un evento capturado a partir de la actividad física del DUT.
//
//   Comunicación (DUT_BUS_SPEC.md sec. 11):
//     Monitor -> Checker   vía event_mb
//
//   event_type distingue (tb_pkg::event_type_e):
//     EVT_POP  - el Monitor observó pop[i]; se captura el D_pop[i] asociado
//                (se conserva para diagnóstico, ver sec. 11)
//     EVT_PUSH - el Monitor observó push[i]; se captura el D_push[i] asociado
//
//   IMPORTANTE: el Monitor NO determina PASS/FAIL. Solo reporta lo observado;
//   la comparación es responsabilidad exclusiva del Checker.
//
// Parámetros:
//   drvrs   - rango válido de interface_id
//   pckg_sz - ancho en bits del campo packet
//==============================================================================

class dut_event #(
  parameter int drvrs   = tb_pkg::DRVRS_DEFAULT,
  parameter int pckg_sz = tb_pkg::PCKG_SZ_DEFAULT
);

  tb_pkg::event_type_e event_type;   // EVT_POP o EVT_PUSH
  int unsigned          interface_id;
  logic [pckg_sz-1:0]   packet;

  function new();
    event_type   = tb_pkg::EVT_POP;
    interface_id = 0;
    packet       = '0;
  endfunction

  function void print(string tag = "dut_event");
    $display("[%s] type=%s if=%0d pkt=0x%h @%0t",
             tag, event_type.name(), interface_id, packet, $time);
  endfunction

endclass : dut_event