# Ambiente de verificación — `bs_gnrtr_n_rbtr`

**Curso:** `<NOMBRE DEL CURSO>`
**Integrantes:** `<Integrante 1>` — `<Integrante 2>`

> Estado actual: **esqueleto estructural**. Los archivos compilan sintácticamente
> (verificado con Verilator 5.020) pero **no contienen lógica de verificación**.
> Cada punto pendiente está marcado con `// TODO` en el código.

---

## 1. Qué se está verificando

El DUT es `bs_gnrtr_n_rbtr`: un **bus serial compartido** por varias interfaces
(`drvrs` de ellas). Cada interfaz puede:

- solicitar acceso al bus y transmitir un paquete (`pndng[i]` + `D_pop[i]`),
- recibir paquetes dirigidos a ella o en broadcast (`push[i]` + `D_push[i]`),
- ignorar paquetes con destino que no le corresponde.

El acceso al bus se arbitra con **Round Robin**. El DUT internamente serializa
(TX) y deserializa (RX) los paquetes, pero **la verificación no reproduce esa
implementación interna** — se valida a nivel de transacciones.

### Puertos del DUT

```systemverilog
module bs_gnrtr_n_rbtr #(
  parameter bits = 1,
  parameter drvrs = 4,
  parameter pckg_sz = 16,
  parameter broadcast = 8'hFF
)(
  input  logic                          clk,
  input  logic                          reset,
  input  logic [drvrs-1:0]              pndng,
  input  logic [drvrs-1:0][pckg_sz-1:0] D_pop,
  output logic [drvrs-1:0]              pop,
  output logic [drvrs-1:0]              push,
  output logic [drvrs-1:0][pckg_sz-1:0] D_push
);
```

| Señal | Dir | Significado |
|---|---|---|
| `pndng[i]` | in | la interfaz `i` tiene un paquete pendiente |
| `D_pop[i]` | in | paquete que `i` desea transmitir |
| `pop[i]` | out | el DUT confirmó que consumió `D_pop[i]` |
| `push[i]` | out | el DUT presenta un paquete recibido en `D_push[i]` |
| `D_push[i]` | out | paquete recibido por `i` |

`pop` y `push` son **eventos independientes** y pueden ocurrir en el mismo ciclo;
uno nunca sustituye al otro.

### Formato del paquete

```
[pckg_sz-1 : pckg_sz-8]   [pckg_sz-9 : 0]
       destino                 payload
```

El campo de destino siempre ocupa los **8 bits superiores**, sin importar
`pckg_sz` (16, 32 o 64).

### Direccionamiento

- **Unicast**: destino = ID de una interfaz válida (`0 .. drvrs-1`).
- **Broadcast**: destino = valor del parámetro `broadcast` (p. ej. `8'hFF`,
  pero es parametrizable — el ambiente no debe asumir que siempre es `0xFF`).
- **Inválido**: cualquier otro valor → no debe producir recepción en ninguna
  interfaz.

### Configuraciones a soportar

```
drvrs     = 2, 4, 8
pckg_sz   = 16, 32, 64
broadcast = distintos valores
bits      = 1 (fijo)
```

Documentación completa del DUT: `DUT_BUS_SPEC.md`. Plan de verificación
completo (casos de prueba TP01–TP16, casos de esquina, matriz de cobertura):
`TestplanV3.md`.

---

## 2. Arquitectura del ambiente

Sin UVM — clases, `interface`, `mailbox` y `queue` nativas de SystemVerilog.

```
tb_top
 ├─ bus_if #(bits,drvrs,pckg_sz)  ───────────────┐
 ├─ bs_gnrtr_n_rbtr (DUT) ◄── conectado a bus_if ─┘
 └─ test_base
      └─ environment
           ├─ generator ──tx_mb[0..N-1]──► driver[0..N-1] ──(vif)──► DUT
           │            └─tx_mb_sb──────► scoreboard
           ├─ monitor ◄──(vif)── DUT
           │      └─event_mb─────────────► checker_c
           └─ scoreboard ──expected_mb───► checker_c
```

**Flujo de transmisión** (resumen): el Generator crea una `tx_transaction`,
la manda al Driver correspondiente **y** una copia al Scoreboard. El Driver
presenta el paquete en `D_pop[i]`/`pndng[i]`; el Scoreboard registra el
paquete en `tx_pending[i]` y calcula a quién debería llegar (`rx_expected[]`).
El Monitor observa `pop`/`push` en el bus y arma un `dut_event`. El Checker
compara ese evento contra el `expected_event` que envía el Scoreboard.

**Regla de oro del modelo**: nada se retira de `tx_pending[]` / `rx_expected[]`
hasta que el evento correspondiente (`pop` / `push`) se confirma. Si la
comparación falla, el elemento se conserva para diagnóstico, no se descarta.

Separación de responsabilidades:

```
mailbox = comunicación / sincronización entre procesos concurrentes
queue   = estado del modelo funcional (vive únicamente en el Scoreboard)
```

---

## 3. Paquetes de comunicación (transacciones)

| Paquete | De → A | Campos mínimos |
|---|---|---|
| `tx_transaction` | Generator → Driver / Scoreboard | `interface_id`, `packet` |
| `dut_event` | Monitor → Checker | `event_type` (`EVT_POP`/`EVT_PUSH`), `interface_id`, `packet` |
| `expected_event` | Scoreboard → Checker | mismo layout que `dut_event`, para comparación directa |

`event_type_e` vive en `tb_pkg` precisamente para que `dut_event` y
`expected_event` compartan el mismo tipo y sean comparables sin fricción.

---

## 4. Estructura de archivos

```
tb/
├── README.md                     ← este archivo
├── filelist.f                    ← orden de compilación (ver sección 6)
├── tb_top.sv                     ← único módulo top
├── pkg/
│   └── tb_pkg.sv                 ← parámetros por defecto + tipos compartidos
├── interfaces/
│   └── bus_if.sv                 ← señales físicas del DUT (sin lógica)
├── transactions/
│   ├── tx_transaction.sv         ← Generator → Driver/Scoreboard
│   ├── dut_event.sv              ← Monitor → Checker
│   └── expected_event.sv         ← Scoreboard → Checker
├── drivers/
│   └── driver.sv                 ← una instancia por interfaz (0..drvrs-1)
├── generator/
│   └── generator.sv              ← genera y distribuye tx_transaction
├── monitor/
│   └── monitor.sv                ← observa el DUT, arma dut_event
├── scoreboard/
│   └── scoreboard.sv             ← modelo funcional (tx_pending[], rx_expected[])
├── checker/
│   └── checker.sv                ← clase checker_c (compara obs vs esperado)
├── environment/
│   └── environment.sv            ← crea y conecta todos los componentes
└── tests/
    └── test_base.sv              ← base para TP01..TP16 (aún sin escenarios)
```

---

## 5. Qué hace cada archivo `.sv`

### `pkg/tb_pkg.sv`
Paquete central: valores por defecto de `bits`, `drvrs`, `pckg_sz`,
`broadcast`, más el `enum event_type_e { EVT_POP, EVT_PUSH }`. Existe para
que ningún otro archivo tenga que redefinir estos valores o tipos por su
cuenta (evita valores mágicos y tipos incompatibles entre `dut_event` y
`expected_event`).

### `interfaces/bus_if.sv`
Interfaz parametrizable (`bits`, `drvrs`, `pckg_sz`) con `clk`, `reset`,
`pndng`, `D_pop`, `pop`, `push`, `D_push`. Define dos `modport`:
`driver_mp` (un Driver conduce `pndng`/`D_pop`, observa el resto) y
`monitor_mp` (solo lectura de todas las señales). No contiene estado,
queues ni mailboxes — es exclusivamente el punto de conexión físico.

### `transactions/tx_transaction.sv`
Clase parametrizada por `drvrs`/`pckg_sz` con `interface_id` y `packet`.
Trae `rand` en ambos campos porque será la clase que se aleatoriza; los
`constraint` reales (por capas: escenario → tráfico → origen → destino →
payload) quedan como TODO.

### `transactions/dut_event.sv` / `transactions/expected_event.sv`
Mismos tres campos (`event_type`, `interface_id`, `packet`), uno viene del
Monitor (lo observado) y el otro del Scoreboard (lo esperado). Estructura
idéntica a propósito, para que el Checker pueda comparar campo a campo.

### `drivers/driver.sv`
Recibe `id` (qué interfaz maneja), una `virtual interface` con vista
`driver_mp` y un `mailbox` de `tx_transaction`. Su única responsabilidad es
traducir transacciones en señales (`pndng[id]`, `D_pop[id]`) y esperar
`pop[id]`. No decide PASS/FAIL, no toca el Scoreboard. El Environment
instancia `drvrs` copias de esta clase.

### `generator/generator.sv`
Recibe `drvrs` mailboxes (uno por Driver) más `tx_mb_sb` (hacia el
Scoreboard). `run()` es un placeholder: ahí se implementará la generación
por capas del plan de verificación y los escenarios TP01–TP16.

### `monitor/monitor.sv`
Recibe la `virtual interface` con vista `monitor_mp` y el `mailbox` hacia
el Checker. Debe traducir actividad de `pop`/`push` en objetos `dut_event`
y publicarlos — sin juzgar si son correctos.

### `scoreboard/scoreboard.sv`
El único dueño de las queues `tx_pending[drvrs][$]` y
`rx_expected[drvrs][$]`. Recibe `tx_transaction` desde el Generator y debe
producir `expected_event` hacia el Checker. La interfaz exacta de
consulta/confirmación que usará el Checker (sin tocar las queues
directamente) queda pendiente de definir — ver sección 7.

### `checker/checker.sv` (clase `checker_c`)
Recibe `event_mb` y `expected_mb`, y debe comparar. **Nota de nombre**: la
clase se llama `checker_c` y no `checker` porque `checker` es palabra
reservada en SystemVerilog desde IEEE 1800-2012 (construcción
`checker...endchecker`); usar ese nombre rompe la compilación en
herramientas que implementan el LRM completo (confirmado con Verilator).

### `environment/environment.sv`
"Cablea" el ambiente completo: crea todos los mailboxes, instancia
Generator, `drvrs` Drivers, Monitor, Scoreboard y Checker, y les pasa la
`virtual interface` y los mailboxes correspondientes. No contiene lógica
de predicción ni de comparación.

### `tests/test_base.sv`
Crea el Environment con los parámetros vigentes. Los escenarios concretos
(TP01–TP16) se implementarán como clases que extiendan `test_base`.

### `tb_top.sv`
Único módulo de nivel superior. Declara los `parameter` de configuración,
instancia `bus_if` y el DUT, los conecta, y arrancará el test (clk/reset y
la creación del test están marcados como TODO).

---

## 6. Cómo compilar

No se usan paquetes para envolver las clases (se mantiene "un archivo = un
componente" como pide el proyecto), así que **todas las clases dependen de
estar en la misma unidad de compilación**. Compilar los archivos juntos, en
el orden indicado en `filelist.f`:

```
pkg/tb_pkg.sv
interfaces/bus_if.sv
transactions/tx_transaction.sv
transactions/dut_event.sv
transactions/expected_event.sv
drivers/driver.sv
generator/generator.sv
monitor/monitor.sv
scoreboard/scoreboard.sv
checker/checker.sv
environment/environment.sv
tests/test_base.sv
tb_top.sv
```

Ejemplo con Verilator (chequeo de sintaxis, sin simular):

```bash
verilator --lint-only -sv -Wall -f filelist.f <ruta_al_RTL_real>/bs_gnrtr_n_rbtr.sv --top-module tb_top
```

Ejemplo con Questa/VCS: pasar los mismos archivos, en el mismo orden, junto
con el RTL del DUT, en una sola invocación de compilación (`vlog -f
filelist.f`). Si su flujo trata cada archivo como unidad de compilación
separada, la alternativa es envolver las clases en un paquete e importarlo.

---

## 7. Decisiones de arquitectura tomadas

- **`pkg/tb_pkg.sv`** se agregó (no estaba en el árbol original solicitado)
  para centralizar parámetros por defecto y el tipo `event_type_e`.
- **`checker_c`** en vez de `checker`, por colisión con palabra reservada de
  SystemVerilog.
- **Mailboxes tipados explícitamente** (`mailbox #(tx_transaction#(drvrs,pckg_sz))`,
  no `mailbox` genérico) para que el compilador detecte errores de tipo.
- **`environment.vif`** se declara sin modport y se asigna a las vistas
  `driver_mp`/`monitor_mp` de cada componente hijo al construirlos —
  SystemVerilog permite esa conversión implícita.

## 8. Pendiente / decisiones abiertas

- **Interfaz Scoreboard ↔ Checker para confirmar consumo**: el spec exige
  que el Checker no manipule `tx_pending[]`/`rx_expected[]` directamente,
  pero la firma exacta de los métodos de confirmación (`confirm_pop`,
  `confirm_push`, etc.) todavía no está definida. Hay un placeholder
  comentado en `checker.sv`.
- **`<NOMBRE DEL CURSO>` / `<Integrante 1>` / `<Integrante 2>`**: reemplazar
  en el encabezado de cada uno de los 13 archivos `.sv` y de este README.
- Todo lo marcado `// TODO` en el código: constraints de aleatorización,
  lógica de `run()` en cada componente, generación de clk/reset en
  `tb_top`, escenarios TP01–TP16 en `tests/`.

## 9. Referencias

- `DUT_BUS_SPEC.md` — especificación funcional completa del DUT.
- `TestplanV3.md` — plan de verificación, casos de prueba y matriz de cobertura.