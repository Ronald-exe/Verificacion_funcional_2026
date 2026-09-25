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

//==============================================================================
// <NOMBRE DEL CURSO>
// Integrantes: <Integrante 1> - <Integrante 2>
//==============================================================================
// Archivo   : tb_pkg.sv
// Componente: Paquete de verificación (constantes y tipos compartidos)
//------------------------------------------------------------------------------
// Descripción:
//   Define parámetros por defecto, tipos de evento y utilidades comunes a
//   todos los componentes del ambiente de verificación.
//==============================================================================

package tb_pkg;

  // Parámetros por defecto del DUT bs_gnrtr_n_rbtr
  parameter int BITS_DEFAULT              = 1;    // fijo, no varía entre configs
  parameter int DRVRS_DEFAULT             = 4;    // configs previstas: 2, 4, 8
  parameter int PCKG_SZ_DEFAULT           = 16;   // configs previstas: 16, 32, 64
  parameter logic [7:0] BROADCAST_DEFAULT = 8'hFF;

  parameter int NUM_TRANSACTIONS_DEFAULT = 50;
  parameter logic [7:0] BROADCAST_RTL_ACTUAL = 8'hFF;

  // Ancho fijo del campo de destino dentro del paquete (sec. 4 del spec).
  // El destino siempre ocupa los 8 bits superiores, sin importar pckg_sz.
  parameter int DEST_FIELD_WIDTH = 8;

  typedef enum logic [0:0] {
    EVT_POP  = 1'b0,
    EVT_PUSH = 1'b1
  } event_type_e;

  function automatic logic [DEST_FIELD_WIDTH-1:0] get_destination(
    logic [63:0] packet,
    int          pckg_sz
  );
    return packet[pckg_sz-1 -: DEST_FIELD_WIDTH];
  endfunction

  function automatic bit is_broadcast(logic [63:0] packet, int pckg_sz);
    return (get_destination(packet, pckg_sz) == BROADCAST_RTL_ACTUAL);
  endfunction

  function automatic bit is_valid_unicast(logic [63:0] packet,
                                          int pckg_sz,
                                          int drvrs);
    logic [DEST_FIELD_WIDTH-1:0] d;
    d = get_destination(packet, pckg_sz);
    return (d < drvrs);
  endfunction

endpackage : tb_pkg
