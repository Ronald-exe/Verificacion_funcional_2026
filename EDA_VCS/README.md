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
| `+NUM=100` | `50` | Transacciones por source; el total es `NUM * DRVRS` |
| `+SEED=21` | `1` | Seed reproducible del Generator |

En Run Options ingresar, por ejemplo:

```sh
+SCENARIO=SC_CONCURRENT +NUM=10 +SEED=21
```

Con `DRVRS=4`, `+NUM=10` genera 10 transacciones por interfaz y 40 en total.

Repetir los mismos Compile Options y Run Options debe reproducir el mismo
estímulo. Para cambiar entre perfiles, usar `SC_RANDOM`, `SC_BURST`,
`SC_CONCURRENT`, `SC_BOUNDARY` o `SC_MIXED`.

### Ejecución local separando compilación y pruebas

La compilación fija los parámetros estructurales del DUT. Se realiza una vez
por cada combinación de `DRVRS`, `PCKG_SZ` y `BROADCAST`:

```sh
make compile DRVRS=4 PCKG_SZ=16 BROADCAST=255
```

Después, cada prueba reutiliza ese ejecutable y solo cambia los plusargs de
simulación (`SCENARIO`, `NUM`, `SEED`):

```sh
make run DRVRS=4 PCKG_SZ=16 BROADCAST=255 SCENARIO=SC_MIXED NUM=10 SEED=21
make verdi DRVRS=4 PCKG_SZ=16 BROADCAST=255 SCENARIO=SC_MIXED NUM=10 SEED=21
make regression DRVRS=4 PCKG_SZ=16 BROADCAST=255 SCENARIOS="SC_RANDOM SC_MIXED" SEEDS="1 2 3" NUM=10
```

`make run` y `make regression` no compilan automáticamente. Si no existe un
ejecutable para esa combinación estructural, primero hay que ejecutar
`make compile`. Los ejecutables se guardan en `sim/eda_vcs/.../build/`; cada
corrida guarda su log, `dump.vcd` y CSV en un directorio separado.
`make verdi` abre la base KDB generada al compilar junto con el `dump.vcd` de la
corrida seleccionada. Se debe ejecutar después de `make compile` y `make run`,
con los mismos parámetros estructurales y de prueba; en una conexión remota el
servidor necesita una sesión gráfica/X11 disponible.

Para descargar el CSV, marcar **"Download files after run"** en el panel izquierdo.

---

## 3. Opciones de configuración

| `+define` estructural | Default | Descripción |
|---|---|---|
| `DRVRS` | 4 | Cantidad de interfaces (2, 4, 8) |
| `PCKG_SZ` | 16 | Tamaño del paquete en bits (16, 32, 64) |
| `BROADCAST` | 255 | Direccion broadcast pasada al DUT (0 a 255) |
| `DELAY_MIN`, `DELAY_MAX` | 0, 10 | Rango de `arrival_delta` en ciclos antes de ofrecer cada paquete |
| `CSV_FILE` | `"reporte_paquetes.csv"` | Nombre del archivo de retardos |

`BITS` permanece fijo en 1. `SCENARIO`, `NUM` y `SEED` son plusargs de simulación, no `+define`.

## 4. Perfiles de generación

| Perfil | Política |
|---|---|
| `SC_RANDOM` | Selección uniforme entre unicast, self-addressed, broadcast e inválido |
| `SC_BURST` | Rachas de 1 a 4 transacciones de una misma fuente; las siguientes llegan con `arrival_delta=0` |
| `SC_CONCURRENT` | Solicitudes iniciales coordinadas entre interfaces, con `arrival_delta=0` |
| `SC_BOUNDARY` | Fuerza el broadcast configurado en la primera transacción de cada source y mezcla destinos límite, incluido `0xFF` del RTL |
| `SC_MIXED` | Tráfico ponderado; perfil predeterminado |

Los patrones de payload se seleccionan mediante constraints en todos los perfiles. Los perfiles describen políticas de generación; los valores estructurales `DRVRS`, `PCKG_SZ` y `broadcast` se cambian entre compilaciones.

Para diagnosticar el parámetro broadcast del DUT (el RTL actual compara contra
`8'hFF` fijo), ejecutar en Linux/VCS:

```sh
make run DRVRS=4 PCKG_SZ=16 BROADCAST=170 SCENARIO=SC_BOUNDARY NUM=1 SEED=1
```

El primer paquete de cada source usa el destino configurado `0xAA`. El modelo
espera broadcast en las otras tres interfaces; como el RTL no reconoce `0xAA`,
el resultado funcional esperado es `FAIL` por los `PUSH` pendientes. La misma
prueba con `BROADCAST=255` debe permitir esas entregas. El Makefile ejecuta el
runner local; en EDA Playground se pasa `BROADCAST=170` en Compile Options y los
otros parámetros en Run Options.

---

## 5. Cómo leer el log

Encabezado: configuración de la corrida (`drvrs`, `pckg_sz`, `num/source`,
`total`, `seed`, `scenario` y `arrival_delta`).

Durante la corrida:
- `[Generator] tx#N if=… packet=… arrival_delta=…` — transacción generada
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
| Transacciones PASS/FAIL | resultado por `tx_id`; un broadcast se considera PASS si completan sus entregas esperadas |
| Retardo send->receive | mínimo / máximo / promedio en ns por entrega recibida |
| Reporte CSV | cantidad total de filas, incluyendo drops esperados y resultados FAIL |
| Round Robin | verificaciones realizadas y violaciones encontradas |
| RESULTADO | PASS solo si errores = 0, pendientes = 0 y violaciones RR = 0 |

El total esperado de transacciones es `NUM * DRVRS`; los eventos POP/PUSH y las
filas CSV no son equivalentes a cantidad de transacciones (broadcast genera
varias filas de recepción).

---

## 6. CSV e histograma

`reporte_paquetes.csv` contiene una fila por entrega esperada/observada. Un
broadcast genera una fila por interfaz receptora. Un drop self/invalid genera
una fila PASS sin `receive_time` ni `delay`; una entrega no observada genera una
fila FAIL.

```
tx_id,source,destination,send_time,receive_time,delay,packet,result
1,0,2,15,18,3,0x1234,PASS
```

| Columna | Descripción |
|---|---|
| `tx_id` | Identificador local; no forma parte de `packet` |
| `source` | Interfaz origen (`interface_id`) |
| `destination` | Receptor para PUSH; dirección solicitada para drop sin recepción |
| `send_time` | Primer `posedge` donde el Monitor observa `pndng` activo |
| `receive_time` | `posedge` donde el Monitor observa `push` |
| `delay` | `receive_time - send_time`, en ns según `-timescale=1ns/1ns` |
| `packet` | Paquete completo en hexadecimal |
| `result` | `PASS` o `FAIL` para esa entrega/evento esperado |

`tx_id` es metadata del testbench, no viaja en el DUT. Si dos fuentes generan
paquetes idénticos para el mismo destino, el Checker valida contenido y
multiplicidad; la atribución individual de `tx_id`/source en las filas
indistinguibles no puede garantizarse.

En EDA Playground, descargar el CSV y ejecutar GNUplot en un entorno que lo
tenga instalado. Para una corrida local, reutilizar `make plot` con los mismos
parámetros de configuración. `ANCHO` controla el ancho de cada barra en ns
(default 50); prueba un valor menor para ver más detalle o uno mayor para
agrupar más observaciones:

```
make plot DRVRS=8 PCKG_SZ=32 BROADCAST=200 SCENARIO=SC_RANDOM NUM=5000 SEED=1 ANCHO=10
make plot DRVRS=8 PCKG_SZ=32 BROADCAST=200 SCENARIO=SC_RANDOM NUM=5000 SEED=1 ANCHO=100
make plot CSV=reporte_paquetes.csv PLOT=histograma.png ANCHO=25
```

El script `histograma.gp` usa únicamente la columna `delay` del CSV; las filas
sin recepción y sin delay se omiten. El histograma no genera datos sintéticos.
Los parámetros estructurales usados para `make plot` deben coincidir con los
de la corrida que produjo el CSV. `PCKG_SZ` soportados son 16, 32 y 64; 35 no es
una configuración válida del runner.

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

## 8. Primera validacion de entregables pendientes

Corrida reportada en EDA Playground: `DRVRS=4`, `PCKG_SZ=16`,
`BROADCAST=255`, `SCENARIO=SC_MIXED`, `NUM=10`, `SEED=1`.

| Metrica | Resultado |
|---|---|
| Resultado final | PASS |
| Transacciones generadas | 40, diez por source (`tx#0` a `tx#39`) |
| Transacciones PASS/FAIL | 40 / 0 |
| Errores de eventos | 0 |
| Round Robin | 105 verificaciones, 0 violaciones |
| Entregas con latencia | 39 |
| Delay | min=210 ns, max=1570 ns, promedio=1359.5 ns |
| Filas CSV reportadas | 48 |

Esta corrida valida en EDA Playground `NUM` por source, el resumen, el flujo
timestamps/Checker y la generacion del CSV para esta configuracion. GNUplot y
los otros perfiles/configuraciones aun no se han validado.

## 9. Corrida historica de `SC_MIXED`

Esta corrida se ejecuto antes de cambiar `NUM` a transacciones por source y
antes del nuevo esquema CSV; no valida esos cambios.

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

El resultado solo es evidencia de la version anterior del perfil `SC_MIXED`.

## 10. Corrida historica de concurrencia

Esta corrida tambien precede la semantica `NUM` por source y el CSV nuevo.

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

El encabezado y los 12 identificadores confirman el override de `+NUM` en la
version anterior, donde `NUM` era el total global. No valida el requisito actual
de 12 transacciones por source ni el nuevo CSV. La repetibilidad de seed tambien
requiere repetir una misma configuracion.

## 11. Resultados historicos del ambiente anterior (seed = 1)

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
