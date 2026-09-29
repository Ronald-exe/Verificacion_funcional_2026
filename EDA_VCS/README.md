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
-timescale=1ns/1ns +vcs+flush+all +warn=all -sverilog +define+SCENARIO=SC_BROADCAST+DRVRS=8
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
| `SCENARIO` | `SC_RANDOM` | Escenario de generación (ver sección 4) |
| `SRC_A`, `SRC_B` | 0, 1 | Interfaces origen para `SC_ONE_IF` / `SC_TWO_IF` |
| `DELAY_MIN`, `DELAY_MAX` | 0, 10 | Retardo aleatorio (ciclos) antes de ofrecer cada paquete |
| `NUM_TX_MIN`, `NUM_TX_MAX` | 30, 80 | Rango de la cantidad de transacciones (se sortea con la semilla) |
| `RESET_AT` | 0 (apagado) | Ciclo en que se aplica un reset en medio del tráfico |
| `RESET_CYCLES` | 5 | Duración de ese reset |
| `CSV_FILE` | `"reporte_paquetes.csv"` | Nombre del archivo de retardos |

---

## 4. Escenarios y casos de prueba

| TP | Prueba | Compile Options (después de las base) |
|---|---|---|
| TP01 | Reset en actividad | `+define+RESET_AT=300` |
| TP02 | Transmisión (una interfaz) | `+define+SCENARIO=SC_ONE_IF` |
| TP03 | Unicast | `+define+SCENARIO=SC_UNICAST` |
| TP03/05 | Bordes de dirección (0, drvrs-1, drvrs, 0xFE, 0xFF) | `+define+SCENARIO=SC_ADDR_EDGES` |
| TP04/06 | Broadcast (consecutivos) | `+define+SCENARIO=SC_BROADCAST` |
| TP05 | Dirección inválida | `+define+SCENARIO=SC_INVALID` |
| TP07 | Contención entre dos | `+define+SCENARIO=SC_TWO_IF+SRC_A=1+SRC_B=3` |
| TP08 | Todas activas (Round Robin) | *(default)* o `+define+DRVRS=8` |
| TP09 | Idle | `+define+DELAY_MIN=50+DELAY_MAX=100` |
| TP10 | Back-to-back | `+define+DELAY_MAX=0` |
| TP11 | Tráfico mixto | *(default, `SC_RANDOM`)* |
| TP12 | Patrones de payload (0, 1…1, 1010…, 0101…) | `+define+SCENARIO=SC_PATTERNS` |
| TP13 | `push` + `pop` simultáneos | ocurre en cualquier corrida con tráfico (ej. idle); el Checker los procesa por separado |
| TP14 | `pckg_sz` | `+define+PCKG_SZ=32` / `+define+PCKG_SZ=64` |
| TP15 | `drvrs` | `+define+DRVRS=2` / `+define+DRVRS=8` |
| TP16 | `broadcast` parametrizable | ver hallazgos (sección 7) |

Los escenarios se pueden combinar con cualquier `DRVRS`, `PCKG_SZ` y retardo.

---

## 5. Cómo leer el log

Encabezado: configuración de la corrida (`drvrs`, `pckg_sz`, `num_transactions`,
`seed`, `scenario`, `delay`, reset).

Durante la corrida:
- `[Generator] tx#N if=… packet=… delay=…` — transacción generada
- `[DRV i] ofrecido / pop recibido` — actividad del Driver
- `[MON] POP / PUSH` — evento observado en el DUT
- `[Checker] PASS / ERROR` — resultado de cada comparación
- `[Checker] RESET: descartado …` — paquete que el reset perdió (esperado)
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
| Reset en actividad | resets aplicados y push descartados por estar en vuelo |
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
3. **Reset en actividad**: los paquetes consumidos pero aún no entregados se
   pierden con el reset y el DUT se recupera correctamente después.

---

## 8. Resultados obtenidos (seed = 1)

| Corrida | Resultado |
|---|---|
| `drvrs` = 2, 4, 8 y `pckg_sz` = 16, 32, 64 | PASS |
| `SC_RANDOM`, `SC_UNICAST`, `SC_BROADCAST`, `SC_INVALID` | PASS |
| `SC_ADDR_EDGES`, `SC_ONE_IF`, `SC_TWO_IF`, `SC_PATTERNS` | PASS |
| Retardos default / back-to-back / idle | PASS |
| Round Robin (`drvrs` = 4 y 8) | 0 violaciones |
| Reset en actividad (`RESET_AT=300`) | PASS, 6 push descartados |
