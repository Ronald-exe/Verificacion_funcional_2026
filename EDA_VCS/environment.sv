//==============================================================================
// Verificación Funcional
// Integrantes: Ronald - Eric
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
//   Conexiones (TestplanV3.md sec. 3, DUT_BUS_SPEC.md sec. 10):
//     Generator  -> tx_mb[i]     -> Driver[i]   (i = 0 .. drvrs-1)
//     Generator  -> tx_mb_sb     -> Scoreboard
//     Driver[i]  -> DUT (vía vif)
//     DUT        -> Monitor (vía vif)
//     Monitor    -> event_mb     -> Checker
//     Scoreboard -> expected_mb  -> Checker
//
// Parámetros:
//   drvrs, pckg_sz - se propagan a todos los componentes hijos.
//
// NOTA: el Scoreboard se declara sin el parámetro broadcast porque checker_c
// guarda una referencia de tipo scoreboard #(drvrs, pckg_sz); si se
// especializa con otro broadcast, los tipos no coinciden y falla
// chk = new(..., sb).
//==============================================================================

class environment #(
  parameter int drvrs   = tb_pkg::DRVRS_DEFAULT,
  parameter int pckg_sz = tb_pkg::PCKG_SZ_DEFAULT
);

  // Virtual interface "completa" (sin modport): se asigna a las vistas
  // driver_mp/monitor_mp de cada componente hijo al construirlos.
  virtual bus_if #(.drvrs(drvrs), .pckg_sz(pckg_sz)) vif;

  generator  #(drvrs, pckg_sz) gen;
  driver     #(drvrs, pckg_sz) drv [drvrs];
  monitor    #(drvrs, pckg_sz) mon;
  scoreboard #(drvrs, pckg_sz) sb;
  checker_c  #(drvrs, pckg_sz) chk;  // 'checker' es palabra reservada en SV

  mailbox #(tx_transaction #(drvrs, pckg_sz)) tx_mb    [drvrs]; // Generator -> Driver[i]
  mailbox #(tx_transaction #(drvrs, pckg_sz)) tx_mb_sb;         // Generator -> Scoreboard
  mailbox #(dut_event      #(drvrs, pckg_sz)) event_mb;         // Monitor -> Checker
  mailbox #(expected_event #(drvrs, pckg_sz)) expected_mb;      // Scoreboard -> Checker

  function new(virtual bus_if #(.drvrs(drvrs), .pckg_sz(pckg_sz)) vif);
    this.vif = vif;
  endfunction

  // Crea mailboxes y componentes, y los conecta entre sí
  function void build();
    for (int i = 0; i < drvrs; i++) begin
      tx_mb[i] = new();
      drv[i]   = new(i, vif, tx_mb[i]);
    end
    tx_mb_sb    = new();
    event_mb    = new();
    expected_mb = new();

    gen = new(tx_mb, tx_mb_sb);
    mon = new(vif, event_mb);
    sb  = new(tx_mb_sb, expected_mb);
    chk = new(event_mb, expected_mb, sb);
    chk.vif = vif;  // solo lectura, para el chequeo de Round Robin
  endfunction

  // Lanza todos los procesos en paralelo y retorna de inmediato
  // (drivers, monitor, scoreboard y checker tienen forever).
  task run();
    fork
      gen.run();
      mon.run();
      sb.run();
      chk.run();
      chk.rr_run();
    join_none

    for (int i = 0; i < drvrs; i++) begin
      automatic int idx = i;
      fork
        drv[idx].run();
      join_none
    end
  endtask

  // 1 cuando ya no queda tráfico por ofrecer: el Generator terminó, los
  // mailboxes hacia los Drivers están vacíos y ningún Driver tiene un
  // paquete en curso. Lo usa el test para terminar por condición.
  function bit idle();
    if (!gen.done) return 0;
    for (int i = 0; i < drvrs; i++)
      if (tx_mb[i].num() != 0 || drv[i].busy) return 0;
    return 1;
  endfunction

endclass : environment
