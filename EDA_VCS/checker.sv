//==============================================================================
// Verificación Funcional
// Integrantes: Ronald - Eric
//==============================================================================
// Archivo   : checker.sv
// Componente: Checker
//------------------------------------------------------------------------------
// Descripción:
//   Compara los dut_event observados por el Monitor contra los
//   expected_event generados por el Scoreboard, y reporta PASS/FAIL.
//
//   El Checker NO administra las queues internas del Scoreboard
//   (tx_pending[]/rx_expected[]); tras una comparación válida confirma el
//   consumo con sb.confirm_pop() / sb.confirm_push().
//
//   Responsabilidades:
//     - comparar pop/push observados vs esperados (PASS/ERROR)
//     - al final, reportar esperados que nunca ocurrieron (pendientes)
//     - reporte de retardos pop->push: CSV + min/max/promedio
//     - chequeo de Round Robin con señales externas (rr_run)
//     - descartar paquetes en vuelo cuando hay reset en actividad
//
// Conexiones:
//   - mailbox #(dut_event)      event_mb     <- desde el Monitor
//   - mailbox #(expected_event) expected_mb  <- desde el Scoreboard
//   - referencia al Scoreboard, únicamente para confirmar consumo
//   - vif (monitor_mp, solo lectura) para el chequeo de Round Robin
//
// Parámetros:
//   drvrs   - cantidad de interfaces
//   pckg_sz - ancho en bits del campo packet
//==============================================================================

// NOTA: la clase se llama "checker_c" y no "checker" porque 'checker' es
// una palabra reservada de SystemVerilog desde IEEE 1800-2012 (construcción
// checker/endchecker para "assertion checkers"). Usar ese nombre como clase
// rompe la compilación en herramientas que implementan el LRM completo
// (confirmado con Verilator).
class checker_c #(
  parameter int drvrs   = tb_pkg::DRVRS_DEFAULT,
  parameter int pckg_sz = tb_pkg::PCKG_SZ_DEFAULT
);

  mailbox #(dut_event #(drvrs, pckg_sz))      event_mb;
  mailbox #(expected_event #(drvrs, pckg_sz)) expected_mb;

  scoreboard #(drvrs, pckg_sz) sb;

  // Esperado pendiente, demultiplexado por (interfaz, tipo de evento).
  expected_event #(drvrs, pckg_sz) pop_q  [drvrs][$];
  expected_event #(drvrs, pckg_sz) push_q [drvrs][$];

  int transacciones_ok;
  int transacciones_error;
  int transacciones_pendientes;  // esperados que el DUT nunca produjo

  // --- Reporte de retardos (CSV) ------------------------------------------
  // Por cada pop confirmado se guarda cuándo ocurrió y cuántos push faltan
  // (1 unicast, drvrs-1 broadcast). Al confirmarse cada push se calcula
  // retardo = t_push - t_pop y se escribe una fila en el CSV.
  typedef struct {
    logic [pckg_sz-1:0] packet;
    time                t_pop;
    int unsigned        pending;
  } pop_rec_t;

  pop_rec_t pop_log [drvrs][$];

  int  csv_fd;         // 0 = CSV deshabilitado
  int  lat_n;
  time lat_min, lat_max;
  real lat_sum;

  // --- Chequeo de Round Robin (TP07/TP08) ----------------------------------
  // Vista de solo lectura de las señales del bus (la asigna el Environment)
  virtual bus_if #(.drvrs(drvrs), .pckg_sz(pckg_sz)).monitor_mp vif;
  int rr_checks;    // veces que se evaluó la regla
  int rr_errores;   // violaciones detectadas

  function new(
    mailbox #(dut_event #(drvrs, pckg_sz))      event_mb,
    mailbox #(expected_event #(drvrs, pckg_sz)) expected_mb,
    scoreboard #(drvrs, pckg_sz)                sb
  );
    this.event_mb    = event_mb;
    this.expected_mb = expected_mb;
    this.sb          = sb;
  endfunction

  // Abre el CSV y escribe el encabezado. Si no se llama, no se genera CSV.
  function void abrir_csv(string fname);
    csv_fd = $fopen(fname, "w");
    if (csv_fd == 0) begin
      $display("[Checker] WARNING: no se pudo abrir %s, no se generara CSV", fname);
      return;
    end
    $fdisplay(csv_fd, "t_envio_ns,origen,destino,t_recepcion_ns,retardo_ns,tipo,paquete");
  endfunction

  // Se llama al confirmar un push: busca el pop de ese paquete en la interfaz
  // origen, calcula el retardo y escribe la fila del CSV.
  function void registrar_retardo(int unsigned src, int unsigned dst,
                                  logic [pckg_sz-1:0] packet);
    int  idx[$];
    time lat;
    logic [tb_pkg::DEST_FIELD_WIDTH-1:0] dest_field;

    idx = pop_log[src].find_first_index(r) with (r.packet == packet && r.pending > 0);
    if (idx.size() == 0) begin
      $display("T=%0t [Checker] WARNING: push if=%0d pkt=0x%0h sin pop previo en if=%0d (retardo no registrado)",
               $time, dst, packet, src);
      return;
    end

    lat = $time - pop_log[src][idx[0]].t_pop;
    dest_field = packet[pckg_sz-1 -: tb_pkg::DEST_FIELD_WIDTH];

    if (csv_fd != 0)
      $fdisplay(csv_fd, "%0d,%0d,%0d,%0d,%0d,%s,0x%0h",
                pop_log[src][idx[0]].t_pop, src, dst, $time, lat,
                (dest_field == tb_pkg::BROADCAST_RTL_ACTUAL) ? "broadcast" : "unicast",
                packet);

    if (lat_n == 0 || lat < lat_min) lat_min = lat;
    if (lat_n == 0 || lat > lat_max) lat_max = lat;
    lat_sum += lat;
    lat_n++;

    pop_log[src][idx[0]].pending--;
    if (pop_log[src][idx[0]].pending == 0) pop_log[src].delete(idx[0]);
  endfunction

  task file_one_expected();
    expected_event #(drvrs, pckg_sz) exp;
    expected_mb.get(exp);  // llega del Scoreboard
    if (exp.event_type == tb_pkg::EVT_POP) pop_q[exp.interface_id].push_back(exp);
    else                                    push_q[exp.interface_id].push_back(exp);
  endtask

  task run();
    dut_event      #(drvrs, pckg_sz) obs;
    expected_event #(drvrs, pckg_sz) exp;
    int idx[$];

    forever begin
      event_mb.get(obs);  // llega del Monitor

      if (obs.event_type == tb_pkg::EVT_POP) begin
        // POP: cada interfaz origen presenta sus propios paquetes en el
        // orden en que el Generator los entregó a ESE driver; no hay
        // contención entre fuentes distintas para el mismo pop_q[i], así
        // que FIFO estricto es correcto.
        while (pop_q[obs.interface_id].size() == 0) file_one_expected();
        exp = pop_q[obs.interface_id].pop_front();
      end else begin
        // PUSH: varias interfaces ORIGEN distintas pueden converger en la
        // misma interfaz DESTINO. El Round Robin decide el turno de
        // transmisión, no el orden en que el Generator creó los paquetes,
        // así que el orden de llegada a rx_expected[destino] no está
        // garantizado. Se busca por contenido (no por posición) dentro de
        // lo ya esperado para esa interfaz; solo se marca error si no
        // existe ningún paquete esperado que coincida.
        idx = push_q[obs.interface_id].find_first_index(item) with (item.packet == obs.packet);
        while (idx.size() == 0 && expected_mb.num() > 0) begin
          file_one_expected();
          idx = push_q[obs.interface_id].find_first_index(item) with (item.packet == obs.packet);
        end
        if (idx.size() == 0) begin
          // No quedó ningún expected pendiente que coincida: paquete no
          // esperado en esta interfaz (posible corrupción o entrega al
          // destino equivocado). Se reporta de inmediato en vez de
          // bloquear el Checker esperando un match que ya no puede llegar.
          transacciones_error++;
          $display("T=%0t [Checker] ERROR [%0d] if=%0d type=EVT_PUSH obs=0x%0h exp=<ninguno coincide>",
                    $time, transacciones_error, obs.interface_id, obs.packet);
          continue;
        end
        exp = push_q[obs.interface_id][idx[0]];
        push_q[obs.interface_id].delete(idx[0]);
      end

      if (obs.packet !== exp.packet) begin
        transacciones_error++;
        $display("T=%0t [Checker] ERROR [%0d] tx#%0d if=%0d type=%s obs=0x%0h exp=0x%0h",
                  $time, transacciones_error, exp.tx_id, obs.interface_id,
                  obs.event_type.name(), obs.packet, exp.packet);
      end else begin
        transacciones_ok++;
        $display("T=%0t [Checker] PASS  [%0d] tx#%0d if=%0d type=%s packet=0x%0h",
                  $time, transacciones_ok, exp.tx_id, obs.interface_id,
                  obs.event_type.name(), obs.packet);

        // avisa al Scoreboard que puede liberar la entrada confirmada
        if (obs.event_type == tb_pkg::EVT_POP) sb.confirm_pop(obs.interface_id);
        else                                    sb.confirm_push(obs.interface_id);

        // datos para el reporte de retardos
        if (obs.event_type == tb_pkg::EVT_POP) begin
          if (exp.n_rx > 0) begin
            pop_rec_t rec;
            rec.packet  = obs.packet;
            rec.t_pop   = $time;
            rec.pending = exp.n_rx;
            pop_log[obs.interface_id].push_back(rec);
          end
        end else begin
          registrar_retardo(exp.src_id, obs.interface_id, obs.packet);
        end
      end
    end
  endtask

  // Round Robin (TP07/TP08), verificado con señales externas:
  //   Mientras una interfaz i espera turno (pndng[i]=1 sin pop), ninguna otra
  //   interfaz j debe ser atendida más de una vez. Como cada interfaz puede
  //   hacer además un pop de "carga" (buffer interno vacío, sin usar el bus),
  //   se toleran hasta 2 pop de j por espera de i; un tercer pop de j implica
  //   que j recibió el bus dos veces antes que i => violación de Round Robin.
  task rr_run();
    int unsigned cnt [drvrs][drvrs];   // cnt[i][j]: pops de j mientras i espera
    logic        prev_pop [drvrs];
    bit          edge_pop [drvrs];

    foreach (prev_pop[i]) prev_pop[i] = 1'b0;
    foreach (cnt[i, j])   cnt[i][j]   = 0;

    forever @(posedge vif.clk) begin
      if (vif.reset === 1'b1) begin
        foreach (cnt[i, j])   cnt[i][j]   = 0;
        foreach (prev_pop[i]) prev_pop[i] = 1'b0;
        continue;
      end

      for (int j = 0; j < drvrs; j++)
        edge_pop[j] = (vif.pop[0][j] === 1'b1 && prev_pop[j] !== 1'b1);

      for (int i = 0; i < drvrs; i++) begin
        // i fue atendida o dejó de pedir el bus: termina su espera
        if (edge_pop[i] || vif.pndng[0][i] !== 1'b1)
          for (int j = 0; j < drvrs; j++) cnt[i][j] = 0;
      end

      for (int j = 0; j < drvrs; j++) begin
        if (!edge_pop[j]) continue;
        for (int i = 0; i < drvrs; i++) begin
          if (i == j || edge_pop[i] || vif.pndng[0][i] !== 1'b1) continue;
          rr_checks++;
          cnt[i][j]++;
          if (cnt[i][j] > 2) begin
            rr_errores++;
            $display("T=%0t [Checker] ERROR Round Robin: if=%0d atendida %0d veces mientras if=%0d esperaba turno",
                     $time, j, cnt[i][j], i);
            cnt[i][j] = 0;  // un reporte por episodio de espera
          end
        end
      end

      for (int j = 0; j < drvrs; j++) prev_pop[j] = vif.pop[0][j];
    end
  endtask

  // Revisión de fin de prueba: todo esperado que siga en pop_q/push_q es un
  // evento que el DUT nunca produjo (paquete perdido o no consumido). Sin
  // esta revisión, una pérdida no genera error (TestplanV3.md sec. 11).
  task revisar_pendientes();
    // Primero se archivan los expected_event que aún estén en el mailbox
    while (expected_mb.num() > 0) file_one_expected();

    for (int i = 0; i < drvrs; i++) begin
      foreach (pop_q[i][k]) begin
        transacciones_pendientes++;
        $display("T=%0t [Checker] ERROR pendiente if=%0d type=EVT_POP  packet=0x%0h (nunca se observo)",
                  $time, i, pop_q[i][k].packet);
      end
      foreach (push_q[i][k]) begin
        transacciones_pendientes++;
        $display("T=%0t [Checker] ERROR pendiente if=%0d type=EVT_PUSH packet=0x%0h (nunca se observo)",
                  $time, i, push_q[i][k].packet);
      end
    end
  endtask

  task reporte_final();
    revisar_pendientes();

    $display("");
    $display("================================================================");
    $display("  CHECKER - REPORTE FINAL   @%0t ns", $time);
    $display("================================================================");
    $display("  Transacciones correctas  : %0d", transacciones_ok);
    $display("  Transacciones con error  : %0d", transacciones_error);
    $display("  Esperados no observados  : %0d", transacciones_pendientes);
    if (lat_n > 0)
      $display("  Retardo pop->push (ns)   : min=%0d  max=%0d  prom=%0.1f  (%0d paquetes recibidos)",
                lat_min, lat_max, lat_sum / lat_n, lat_n);
    if (csv_fd != 0) begin
      $fclose(csv_fd);
      csv_fd = 0;
      $display("  Reporte CSV              : escrito (%0d filas)", lat_n);
    end
    $display("  Round Robin              : %0d verificaciones, %0d violaciones", rr_checks, rr_errores);
    $display("----------------------------------------------------------------");
    if (transacciones_error == 0 && transacciones_pendientes == 0 && rr_errores == 0)
      $display("  >>  RESULTADO: ** PASS ** - sin errores detectados");
    else
      $display("  >>  RESULTADO: !! FAIL !! - %0d errores en total",
                transacciones_error + transacciones_pendientes + rr_errores);
    $display("================================================================");
    $display("");
  endtask

endclass : checker_c
