# Ambiente de verificación — `bs_gnrtr_n_rbtr` (versión EDA Playground / VCS)

**Curso:** Verificación Funcional · **Integrantes:** Ronald - Eric

Esta carpeta contiene el ambiente que corre en EDA Playground con Synopsys VCS.
Esta guía explica cómo correr cada prueba del plan (`docs/TestplanV3.md`), cómo
leer el reporte y cómo generar el histograma de retardos para el análisis.

---

## 1. Archivos

| Archivo | Rol |
|---|---|
| `testbench.sv` | **Test** (módulo `tb_top`): configuración por `+define`, reset, DUT, fin de prueba |
| `environment.sv` | Construye y conecta todos los componentes y mailboxes |
| `generator.sv` | Genera las transacciones según el escenario y los retardos |
| `driver.sv` | Una instancia por interfaz: ofrece paquetes (`pndng`/`D_pop`) y espera `pop` |
| `monitor.sv` | Observa `pop`/`push` y los convierte en `dut_event` |
| `scoreboard.sv` | Modelo funcional: calcula qué `pop`/`push` deben ocurrir |
| `checker.sv` | Compara observado vs esperado, pendientes, retardos (CSV), Round Robin, reset |
| `tx_transaction.sv`, `dut_event.sv`, `expected_event.sv` | Transacciones entre componentes |
| `tb_pkg.sv` | Parámetros por defecto y tipos compartidos (`scenario_e`, `event_type_e`) |
| `bus_if.sv` | Interfaz con el DUT |
| `Library.sv`, `fifo.sv` | RTL provisto (DUT) — no se modifica |
| `histograma.gp` | Script GNUplot que genera el histograma a partir del CSV |

En EDA Playground: `testbench.sv` va como archivo principal de testbench y todos los
demás `.sv` como archivos adicionales (`testbench.sv` los incluye con `` `include ``).

---

## 2. Cómo correr

**Compile Options** (base, siempre):
```
-timescale=1ns/1ns +vcs+flush+all +warn=all -sverilog
```
Para cambiar la configuración se agregan `+define` al final, unidos con `+`:
```
-timescale=1ns/1ns +vcs+flush+all +warn=all -sverilog +define+SCENARIO=SC_CONCURRENT+DRVRS=8
```

**Run Options** (semilla):

| Run Options | Efecto |
|---|---|
| *(vacío)* | Semilla por defecto (`seed=1`), siempre la misma corrida |
| `+ntb_random_seed_automatic` | Semilla distinta en cada corrida |
| `+ntb_random_seed=N` | Repite exactamente la corrida que imprimió `seed=N` |

Para descargar el CSV, marcar **"Download files after run"** en el panel izquierdo.

---

## 3. Opciones (`+define`)

| Define | Default | Descripción |
|---|---|---|
| `DRVRS` | 4 | Cantidad de interfaces (2, 4, 8) |
| `PCKG_SZ` | 16 | Tamaño del paquete en bits (16, 32, 64) |
| `SCENARIO` | `SC_MIXED` | Perfil de generación (ver sección 4) |
| `DELAY_MIN`, `DELAY_MAX` | 0, 10 | Retardo aleatorio (ciclos) antes de ofrecer cada paquete |
| `NUM_TX_MIN`, `NUM_TX_MAX` | 30, 80 | Rango de la cantidad de transacciones (se sortea con la semilla) |
| `CSV_FILE` | `"reporte_paquetes.csv"` | Nombre del archivo de retardos |

## 4. Perfiles de generación

| Perfil | Política |
|---|---|
| `SC_RANDOM` | Selección uniforme entre unicast, self-addressed, broadcast e inválido |
| `SC_BURST` | Rachas de 1 a 4 transacciones de una misma fuente |
| `SC_CONCURRENT` | Solicitudes iniciales coordinadas entre interfaces, con `delay=0` |
| `SC_BOUNDARY` | Destinos `0`, `drvrs-1`, `drvrs`, `0xFE` y `0xFF`, con clase coherente |
| `SC_MIXED` | Tráfico ponderado; perfil predeterminado |

Los patrones de payload se seleccionan mediante constraints en todos los perfiles. Los perfiles describen políticas de generación; los valores estructurales `DRVRS`, `PCKG_SZ` y `broadcast` se cambian entre compilaciones.

---

## 5. Cómo leer el log

Encabezado: configuración de la corrida (`drvrs`, `pckg_sz`, `num_transactions`,
`seed`, `scenario`, `delay`, reset).

Durante la corrida:
- `[Generator] tx#N if=… packet=… delay=…` — transacción generada
- `[DRV i] ofrecido / pop recibido` — actividad del Driver
- `[MON] POP / PUSH` — evento observado en el DUT
- `[Checker] PASS / ERROR` — resultado de cada comparación
- `[TB] trafico terminado` — fin de la prueba por condición
- `[TB] WATCHDOG` — el tráfico no terminó a tiempo (el DUT se colgó)

Reporte final:

| Línea | Significado |
|---|---|
| Transacciones correctas | pop + push que coincidieron con lo esperado |
| Transacciones con error | eventos observados que no coinciden (paquete corrupto, destino equivocado, push inesperado) |
| Esperados no observados | eventos que el modelo esperaba y el DUT nunca produjo (paquetes perdidos) |
| Retardo pop->push | mínimo / máximo / promedio en ns, y cantidad de paquetes recibidos |
| Reporte CSV | cantidad de filas escritas (una por push) |
| Round Robin | verificaciones realizadas y violaciones encontradas |
| RESULTADO | PASS solo si errores = 0, pendientes = 0 y violaciones RR = 0 |

Chequeo: `correctas = num_transactions (pop) + filas del CSV (push)`.

---

## 6. CSV e histograma

`reporte_paquetes.csv` — una fila por paquete **recibido** (un broadcast con
`drvrs=4` genera 3 filas):

```
t_envio_ns,origen,destino,t_recepcion_ns,retardo_ns,tipo,paquete
175,2,1,535,360,unicast,0x138
```

| Columna | Descripción |
|---|---|
| `t_envio_ns` | tiempo del `pop` (el DUT tomó el paquete) |
| `origen` / `destino` | interfaz que envió / que recibió |
| `t_recepcion_ns` | tiempo del `push` en el destino |
| `retardo_ns` | `t_recepcion_ns - t_envio_ns` |
| `tipo` | `unicast` o `broadcast` |
| `paquete` | paquete completo en hex |

Histograma (fuera de EDA Playground, con el CSV descargado en la misma carpeta):
```
gnuplot histograma.gp
gnuplot -e "archivo='idle.csv'; salida='hist_idle.png'; ancho=100" histograma.gp
```
Genera `histograma_retardos.png` con N, mínimo, máximo y promedio en el título.

---

## 7. Hallazgos sobre el DUT

1. **Una interfaz no se escucha a sí misma** (comportamiento correcto, documentado
   en `docs/DUT_BUS_SPEC.md` sec. 5): el broadcast llega a todas menos a la de
   origen, y un unicast a la propia interfaz se consume (`pop`) sin `push`.
2. **TP16 — el RTL ignora el parámetro `broadcast`** (defecto del DUT): la
   detección compara el destino contra `8'hFF` fijo (`Library.sv`, línea 716).
   El modelo usa `8'hFF`; con otro valor configurado el DUT no cumple la
   especificación. Detalle en `docs/DUT_BUS_SPEC.md` sec. 5.
3. El comportamiento de reset durante actividad fue explorado en la version
   anterior, pero queda fuera del alcance de los nuevos perfiles.

## 8. Resultados historicos (seed = 1)

Los resultados siguientes corresponden a la version anterior del ambiente y a
sus escenarios dedicados. No validan los perfiles nuevos; la regresion nueva
queda pendiente de ejecucion con VCS.

| Corrida | Resultado |
|---|---|
| `drvrs` = 2, 4, 8 y `pckg_sz` = 16, 32, 64 | PASS |
| `SC_RANDOM`, `SC_UNICAST`, `SC_BROADCAST`, `SC_INVALID` | PASS |
| `SC_ADDR_EDGES`, `SC_ONE_IF`, `SC_TWO_IF`, `SC_PATTERNS` | PASS |
| Retardos default / back-to-back / idle | PASS |
| Round Robin (`drvrs` = 4 y 8) | 0 violaciones |
| Reset en actividad (`RESET_AT=300`) | PASS, 6 push descartados |
