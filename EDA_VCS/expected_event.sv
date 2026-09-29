//==============================================================================
// Verificación Funcional
// Integrantes: Ronald - Eric
//==============================================================================
// Archivo   : expected_event.sv
// Componente: Evento esperado generado por el Scoreboard
//------------------------------------------------------------------------------
// Descripción:
//   Representa el evento que el modelo funcional del Scoreboard espera que
//   ocurra en el DUT.
//
//   Comunicación (DUT_BUS_SPEC.md sec. 11):
//     Scoreboard -> Checker   vía expected_mb
//
//   Estructura compatible campo a campo con dut_event para permitir
//   comparación directa dentro del Checker (mismo tipo event_type_e,
//   mismo ancho de packet).
//
// Parámetros:
//   drvrs   - rango válido de interface_id
//   pckg_sz - ancho en bits del campo packet
//==============================================================================

class expected_event #(
  parameter int drvrs   = tb_pkg::DRVRS_DEFAULT,
  parameter int pckg_sz = tb_pkg::PCKG_SZ_DEFAULT
);

  tb_pkg::event_type_e event_type;   // EVT_POP o EVT_PUSH esperado
  int unsigned          interface_id;
  logic [pckg_sz-1:0]   packet;      // paquete esperado, cuando aplica

  // Datos para el reporte de retardos (CSV); no se usan en la comparación
  int unsigned          src_id;      // EVT_PUSH: interfaz que originó el paquete
  int unsigned          n_rx;        // EVT_POP : cuántos push generará este paquete

  function new();
    event_type   = tb_pkg::EVT_POP;
    interface_id = 0;
    packet       = '0;
    src_id       = 0;
    n_rx         = 0;
  endfunction

  function void print(string tag = "expected_event");
    $display("[%s] type=%s if=%0d pkt=0x%h @%0t",
             tag, event_type.name(), interface_id, packet, $time);
  endfunction

endclass : expected_event
