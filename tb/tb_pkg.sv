//==============================================================================
// <NOMBRE DEL CURSO>
// Integrantes: <Integrante 1> - <Integrante 2>
//==============================================================================
// Archivo   : tb_pkg.sv
// Componente: Paquete central de parámetros por defecto y tipos compartidos
//------------------------------------------------------------------------------
// Descripción:
//   Punto único para evitar valores mágicos y la duplicación de parámetros
//   y tipos entre los distintos archivos del testbench (interfaces/,
//   transactions/, drivers/, monitor/, generator/, scoreboard/, checker/,
//   environment/, tests/).
//
//   Contiene:
//     - Valores por defecto de los parámetros del DUT (bits, drvrs, pckg_sz,
//       broadcast). tb_top.sv es quien decide los valores finales; estos
//       defaults solo garantizan que, si algún componente no recibe un
//       valor explícito, todos coincidan en el mismo default.
//     - El tipo enumerado event_type_e, compartido por dut_event y
//       expected_event, de forma que ambas clases sean directamente
//       comparables (mismo tipo, no dos enums independientes).
//
//   Referencia: DUT_BUS_SPEC.md secciones 1, 4 y 20; TestplanV3.md sección 2.
//==============================================================================

package tb_pkg;

  // ---------------------------------------------------------------------
  // Parámetros por defecto del DUT bs_gnrtr_n_rbtr
  // ---------------------------------------------------------------------
  parameter int BITS_DEFAULT            = 1;     // fijo, no varía entre configs
  parameter int DRVRS_DEFAULT           = 4;     // configs previstas: 2, 4, 8
  parameter int PCKG_SZ_DEFAULT         = 16;    // configs previstas: 16, 32, 64
  parameter logic [7:0] BROADCAST_DEFAULT = 8'hFF;

  // Ancho fijo del campo de destino dentro del paquete (sec. 4 del spec).
  // El destino siempre ocupa los 8 bits superiores, sin importar pckg_sz.
  parameter int DEST_FIELD_WIDTH        = 8;

  // ---------------------------------------------------------------------
  // Tipo de evento: usado por dut_event (Monitor) y expected_event
  // (Scoreboard) para que ambos sean comparables directamente.
  // ---------------------------------------------------------------------
  typedef enum logic [0:0] {
    EVT_POP  = 1'b0,
    EVT_PUSH = 1'b1
  } event_type_e;

  // TODO (equipo): agregar aquí cualquier otro tipo/constante que se
  // identifique como compartido entre componentes durante la implementación
  // (p.ej. helpers para extraer el campo de destino de un packet).

endpackage : tb_pkg
