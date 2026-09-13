//==============================================================================
// <NOMBRE DEL CURSO>
// Integrantes: <Integrante 1> - <Integrante 2>
//==============================================================================
// Archivo   : environment.sv
// Componente: Environment
//------------------------------------------------------------------------------
// Descripción:
//   Construye e interconecta todos los componentes del ambiente:
//     Generator, Driver[drvrs], Monitor, Scoreboard, Checker
//   y crea los mailboxes que los comunican.
//
//   NO contiene lógica funcional del Scoreboard ni de comparación del
//   Checker; su única responsabilidad es "cablear" el ambiente.
//
//   Conexiones a construir (TestplanV3.md sec. 3, DUT_BUS_SPEC.md sec. 10):
//     Generator -> tx_mb[i]      -> Driver[i]     (para i = 0 .. drvrs-1)
//     Generator -> tx_mb_sb      -> Scoreboard
//     Driver[i] -> DUT (vía vif)
//     DUT       -> Monitor (vía vif)
//     Monitor   -> event_mb      -> Checker
//     Scoreboard -> expected_mb  -> Checker
//
// Parámetros:
//   drvrs, pckg_sz, broadcast - se propagan a todos los componentes hijos.
//==============================================================================

class environment #(
  parameter int drvrs             = tb_pkg::DRVRS_DEFAULT,
  parameter int pckg_sz           = tb_pkg::PCKG_SZ_DEFAULT,
  parameter logic [7:0] broadcast = tb_pkg::BROADCAST_DEFAULT
);

  // Virtual interface "completa" (sin modport): se asigna a las vistas
  // driver_mp/monitor_mp de cada componente hijo al construirlos (SV
  // permite esta conversión implícita hacia un modport).
  virtual bus_if #(.drvrs(drvrs), .pckg_sz(pckg_sz)) vif;

  generator  #(drvrs, pckg_sz)             gen;
  driver     #(drvrs, pckg_sz)             drv [drvrs];
  monitor    #(drvrs, pckg_sz)             mon;
  scoreboard #(drvrs, pckg_sz, broadcast)  sb;
  checker    #(drvrs, pckg_sz)             chk;

  mailbox #(tx_transaction #(drvrs, pckg_sz)) tx_mb    [drvrs];
  mailbox #(tx_transaction #(drvrs, pckg_sz)) tx_mb_sb;
  mailbox #(dut_event #(drvrs, pckg_sz))      event_mb;
  mailbox #(expected_event #(drvrs, pckg_sz)) expected_mb;

  function new(virtual bus_if #(.drvrs(drvrs), .pckg_sz(pckg_sz)) vif);
    // TODO: asignar this.vif
  endfunction

  function void build();
    // -----------------------------------------------------------------
    // TODO (equipo):
    //   - crear cada mailbox (tx_mb[i] para i=0..drvrs-1, tx_mb_sb,
    //     event_mb, expected_mb)
    //   - gen = new(tx_mb, tx_mb_sb);
    //   - for (int i = 0; i < drvrs; i++) drv[i] = new(i, vif, tx_mb[i]);
    //   - mon = new(vif, event_mb);
    //   - sb  = new(tx_mb_sb, expected_mb);
    //   - chk = new(event_mb, expected_mb);
    // -----------------------------------------------------------------
  endfunction

  task run();
    // -----------------------------------------------------------------
    // TODO (equipo): lanzar todos los procesos en paralelo, por ejemplo:
    //   fork
    //     gen.run();
    //     mon.run();
    //     sb.run();
    //     chk.run();
    //     foreach (drv[i]) drv[i].run();
    //   join_none
    // -----------------------------------------------------------------
  endtask

endclass : environment
