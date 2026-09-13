//==============================================================================
// <NOMBRE DEL CURSO>
// Integrantes: <Integrante 1> - <Integrante 2>
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

  function new();
    // TODO: inicialización de campos por defecto
  endfunction

  function void print(string tag = "expected_event");
    // TODO: imprimir event_type, interface_id y packet ($display)
  endfunction

endclass : expected_event
