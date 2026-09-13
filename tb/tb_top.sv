//==============================================================================
// <NOMBRE DEL CURSO>
// Integrantes: <Integrante 1> - <Integrante 2>
//==============================================================================
// Archivo   : tb_top.sv
// Componente: Módulo top (único nivel superior del testbench)
//------------------------------------------------------------------------------
// Descripción:
//   Responsabilidades (ver "formato de esqueletos" sec. 12):
//     - declarar los parámetros de configuración: bits, drvrs, pckg_sz,
//       broadcast
//     - generar clock y reset
//     - instanciar bus_if
//     - instanciar el DUT bs_gnrtr_n_rbtr y conectarlo a bus_if
//     - crear e iniciar el test
//
//   Este es el ÚNICO lugar donde se decide la configuración final del
//   ambiente para una corrida dada (drvrs, pckg_sz, broadcast). Todos los
//   demás componentes reciben estos valores por parámetro, nunca los
//   redefinen.
//==============================================================================

module tb_top;

  import tb_pkg::*;

  // ---------------------------------------------------------------------
  // Parámetros de configuración (único punto de configuración del ambiente)
  //   drvrs, pckg_sz y broadcast se modifican aquí para correr las
  //   configuraciones previstas: drvrs = 2,4,8 | pckg_sz = 16,32,64
  //   | broadcast = distintos valores (TestplanV3.md sec. 2).
  // ---------------------------------------------------------------------
  parameter int bits              = tb_pkg::BITS_DEFAULT;       // fijo = 1
  parameter int drvrs             = tb_pkg::DRVRS_DEFAULT;      // 2, 4, 8
  parameter int pckg_sz           = tb_pkg::PCKG_SZ_DEFAULT;    // 16, 32, 64
  parameter logic [7:0] broadcast = tb_pkg::BROADCAST_DEFAULT;  // p.ej. 8'hFF

  // ---------------------------------------------------------------------
  // Interfaz
  // ---------------------------------------------------------------------
  bus_if #(.bits(bits), .drvrs(drvrs), .pckg_sz(pckg_sz)) vif ();

  // ---------------------------------------------------------------------
  // DUT
  // ---------------------------------------------------------------------
  bs_gnrtr_n_rbtr #(
    .bits      (bits),
    .drvrs     (drvrs),
    .pckg_sz   (pckg_sz),
    .broadcast (broadcast)
  ) dut (
    .clk    (vif.clk),
    .reset  (vif.reset),
    .pndng  (vif.pndng),
    .D_pop  (vif.D_pop),
    .pop    (vif.pop),
    .push   (vif.push),
    .D_push (vif.D_push)
  );

  // ---------------------------------------------------------------------
  // Reloj
  // ---------------------------------------------------------------------
  // TODO (equipo): definir el periodo real de verificación
  // initial begin
  //   vif.clk = 0;
  //   forever #5 vif.clk = ~vif.clk;
  // end

  // ---------------------------------------------------------------------
  // Reset
  // ---------------------------------------------------------------------
  // TODO (equipo): definir secuencia de reset (ver TP01)
  // initial begin
  //   vif.reset = 1;
  //   repeat (N) @(posedge vif.clk);
  //   vif.reset = 0;
  // end

  // ---------------------------------------------------------------------
  // Test
  // ---------------------------------------------------------------------
  test_base #(.drvrs(drvrs), .pckg_sz(pckg_sz), .broadcast(broadcast)) test;

  initial begin
    // TODO: test = new(vif); test.run();
  end

endmodule : tb_top
