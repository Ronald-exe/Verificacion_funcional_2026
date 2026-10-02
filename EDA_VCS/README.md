# Ambiente de verificación — `bs_gnrtr_n_rbtr` (versión EDA Playground / VCS)

**Curso:** Verificación Funcional · **Integrantes:** Ronald - Eric

Esta carpeta contiene el ambiente destinado inicialmente a EDA Playground con
Synopsys VCS. Esta guía explica cómo configurar una corrida, leer el reporte y
generar el histograma de retardos.

---

## 1. Archivos

| Archivo | Rol |
|---|---|
| `testbench.sv` | **Test** (módulo `tb_top`): lee plusargs, inicializa DUT y controla el fin de prueba |
| `environment.sv` | Construye y conecta todos los componentes y mailboxes |
| `generator.sv` | Genera las transacciones según el escenario y los retardos |
| `driver.sv` | Una instancia por interfaz: ofrece paquetes (`pndng`/`D_pop`) y espera `pop` |
| `monitor.sv` | Observa `pop`/`push` y los convierte en `dut_event` |
| `scoreboard.sv` | Modelo funcional: calcula qué `pop`/`push` deben ocurrir |
| `checker.sv` | Compara observado vs esperado, pendientes, retardos (CSV) y Round Robin |
| `tx_transaction.sv`, `dut_event.sv`, `expected_event.sv` | Transacciones entre componentes |
| `tb_pkg.sv` | Parámetros por defecto y tipos compartidos (`scenario_e`, `event_type_e`) |
| `bus_if.sv` | Interfaz con el DUT |
| `Library.sv`, `fifo.sv` | RTL provisto (DUT) — no se modifica |
| `histograma.gp` | Script GNUplot que genera el histograma a partir del CSV |

En EDA Playground: `testbench.sv` va como archivo principal de testbench y todos los
demás `.sv` como archivos adicionales (`testbench.sv` los incluye con `` `include ``).

---

## 2. Cómo correr

### EDA Playground

Seleccionar Synopsys VCS. Usar `testbench.sv` como archivo principal de
testbench; el archivo incluye los componentes y RTL de esta carpeta.

**Compile Options** (base):
```
-timescale=1ns/1ns +vcs+flush+all +warn=all -sverilog
```
Los parámetros estructurales se agregan a Compile Options como `+define`:
```
-timescale=1ns/1ns +vcs+flush+all +warn=all -sverilog +define+DRVRS=8+PCKG_SZ=32+BROADCAST=255
```

**Run Options** controlan el perfil, la cantidad y la seed:

| Plusarg | Default | Efecto |
|---|---|
| `+SCENARIO=SC_MIXED` | `SC_MIXED` | Perfil de generación; admite los cinco perfiles de la sección 4 |
| `+NUM=100` | `50` | Cantidad exacta de transacciones |
| `+SEED=21` | `1` | Seed reproducible del Generator |

En Run Options ingresar, por ejemplo:

```sh
+SCENARIO=SC_CONCURRENT +NUM=100 +SEED=21
```

Repetir los mismos Compile Options y Run Options debe reproducir el mismo
estímulo. Para cambiar entre perfiles, usar `SC_RANDOM`, `SC_BURST`,
`SC_CONCURRENT`, `SC_BOUNDARY` o `SC_MIXED`.

La ejecución local con Makefile/runner es secundaria y aún no está validada;
la primera validación de estos cambios se realizará en EDA Playground.

Para descargar el CSV, marcar **"Download files after run"** en el panel izquierdo.

---

## 3. Opciones de configuración

| `+define` estructural | Default | Descripción |
|---|---|---|
| `DRVRS` | 4 | Cantidad de interfaces (2, 4, 8) |
| `PCKG_SZ` | 16 | Tamaño del paquete en bits (16, 32, 64) |
| `BROADCAST` | 255 | Direccion broadcast pasada al DUT (0 a 255) |
| `DELAY_MIN`, `DELAY_MAX` | 0, 10 | Retardo aleatorio (ciclos) antes de ofrecer cada paquete |
| `CSV_FILE` | `"reporte_paquetes.csv"` | Nombre del archivo de retardos |

`BITS` permanece fijo en 1. `SCENARIO`, `NUM` y `SEED` son plusargs de simulación, no `+define`.

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
`seed`, `scenario` y `delay`).

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

## 8. Primera corrida reportada en EDA Playground

Configuracion reportada: `DRVRS=4`, `PCKG_SZ=16`, `BROADCAST=0xFF`,
`SCENARIO=SC_MIXED`, `NUM=50`, `SEED=1`.

| Metrica | Resultado |
|---|---|
| Resultado final | PASS |
| Eventos correctos | 106 (50 POP y 56 PUSH) |
| Errores / pendientes | 0 / 0 |
| Round Robin | 123 verificaciones, 0 violaciones |
| Retardo POP->PUSH | min=190 ns, max=770 ns, promedio=699.6 ns |
| Filas CSV | 56 |

Esta corrida valida el perfil `SC_MIXED` con esa configuracion y seed. No
valida aun los otros perfiles ni las demas combinaciones estructurales.

## 9. Verificacion de concurrencia y `+NUM`

Configuracion reportada: `DRVRS=4`, `PCKG_SZ=16`, `BROADCAST=0xFF`,
`SCENARIO=SC_CONCURRENT`, `NUM=12`, `SEED=3`.

| Metrica | Resultado |
|---|---|
| Resultado final | PASS |
| Transacciones generadas | 12 (`tx#0` a `tx#11`) |
| Eventos correctos | 26 (12 POP y 14 PUSH) |
| Errores / pendientes | 0 / 0 |
| Round Robin | 18 verificaciones, 0 violaciones |
| Retardo POP->PUSH | min=190 ns, max=790 ns, promedio=690.0 ns |
| Filas CSV | 14 |
| Solicitudes iniciales concurrentes | 4 POP observados en el mismo ciclo |

El encabezado y los 12 identificadores confirman que `+NUM=12` sobreescribe el
default. La corrida valida `SC_CONCURRENT` en esta configuracion; repetir la
misma seed y comparar la secuencia sigue pendiente para verificar reproduccion.

## 10. Resultados historicos del ambiente anterior (seed = 1)

Los resultados siguientes corresponden a los escenarios dedicados anteriores;
se conservan como referencia y no como evidencia de los perfiles nuevos.

| Corrida | Resultado |
|---|---|
| `drvrs` = 2, 4, 8 y `pckg_sz` = 16, 32, 64 | PASS |
| `SC_RANDOM`, `SC_UNICAST`, `SC_BROADCAST`, `SC_INVALID` | PASS |
| `SC_ADDR_EDGES`, `SC_ONE_IF`, `SC_TWO_IF`, `SC_PATTERNS` | PASS |
| Retardos default / back-to-back / idle | PASS |
| Round Robin (`drvrs` = 4 y 8) | 0 violaciones |
| Reset en actividad (`RESET_AT=300`) | PASS, 6 push descartados |
