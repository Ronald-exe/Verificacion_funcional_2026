# Proyecto 1 — Verificación Funcional del Bus de Interconexión — Arquitectura de Organización

## 1. Descripción General

El proyecto consiste en construir un **ambiente de verificación funcional aleatorizado y controlado** (constrained-random) para el DUT `prll_bs_gnrtr_n_rbtr_fifo`: un bus de interconexión que conecta `drvrs` terminales, cada una con una FIFO de entrada y una de salida, un árbitro (`prll_intrfs_cntrl` + `Counter_arb` + `Arbiter_st_Mchn`) y un bloque de serialización/paralelización (`serializer`) para transmitir paquetes de `pckg_sz` bits sobre un bus compartido de 8 líneas de dirección + datos.

El ambiente sigue una arquitectura por capas típica de un testbench SystemVerilog constrained-random (generador → driver → DUT → monitor → scoreboard/checker), con unidades independientes por terminal para permitir tráfico concurrente entre dispositivos.

Este documento describe la estrategia de organización del proyecto (no el test plan en sí, que es el primer entregable) y sirve de referencia para que ambos integrantes de la pareja trabajen bajo las mismas convenciones.

---

## 2. Entorno de Desarrollo

| Herramienta | Propósito |
|---|---|
| **Synopsys VCS** (TEC DCI lab server) | Compilación y simulación del DUT + testbench |
| **SystemVerilog (OOP)** | Lenguaje del ambiente de pruebas (clases, randomización, mailboxes/eventos) |
| **Git / GitHub** | Control de versiones y coordinación entre los dos integrantes |
| **GNUplot** | Generación de histogramas de retardo de paquetes a partir del reporte CSV |
| **Python (opcional, csv/pandas)** | Post-procesamiento del CSV si el análisis en GNUplot no es suficiente |

> Ambos integrantes deben tener acceso funcional al DCI lab server antes de escribir código de verificación.

---

## 3. Estructura de Carpetas

```
Github/
└── Verificacion_Funcional/
    └── Proyecto1_Bus/
        ├── docs/
        │   ├── arquitectura.md
        │   ├── testplan.md
        │   └── diagrama_ambiente.png   (Lucidchart / Draw.io)
        ├── rtl/
        │   ├── fifo.sv
        │   ├── Library.sv
        │   └── top_dut.sv              (wrapper de prll_bs_gnrtr_n_rbtr_fifo)
        ├── tb/
        │   ├── if/
        │   │   └── bus_if.sv           (interfaz con clocking blocks)
        │   ├── pkg/
        │   │   └── bus_pkg.sv          (paquete: transacción + parámetros)
        │   ├── gen/
        │   │   └── generator.sv
        │   ├── drv/
        │   │   └── driver.sv           (uno por terminal, parametrizado)
        │   ├── mon/
        │   │   └── monitor.sv          (uno por terminal + uno de bus)
        │   ├── sb/
        │   │   └── scoreboard.sv
        │   ├── cov/
        │   │   └── coverage.sv
        │   ├── env/
        │   │   └── environment.sv
        │   └── test/
        │       └── test_top.sv
        ├── scripts/
        │   ├── run_vcs.sh
        │   └── plot_histograma.gp
        ├── reports/
        │   └── paquetes.csv
        └── sim/                        (logs y resultados, no versionado)
```

- **`rtl/`** — DUT provisto (no se modifica), solo se envuelve en un `top_dut.sv` para exponer los puertos requeridos por la interfaz.
- **`tb/`** — Todo el ambiente de verificación, dividido por responsabilidad de clase.
- **`scripts/`** — Automatización de simulación (VCS) y post-proceso (GNUplot).
- **`reports/`** — Salida generada en tiempo de simulación (CSV, log de casos de esquina).

---

## 4. División en Módulos (Componentes del Ambiente)

Cada componente tiene una responsabilidad única y corre en su propio proceso (`fork`/`initial`), tal como lo pide el entregable de unidades independientes.

### 4.1 Transacción — `bus_pkg.sv`

Clase `packet` (o `bus_transaction`) con los campos aleatorizables y restricciones (`constraint`):

| Campo | Restricción / Randomización |
|---|---|
| `id_destino` | Aleatorio entre `[0, drvrs-1]`, con peso extra para el identificador de `broadcast` |
| `id_erroneo` | Direcciones fuera de rango (`drvrs..255`), para el caso de "mensajes con errores" |
| `largo_paquete` | `{16, 32, 64}`, vía `constraint` con distribución configurable |
| `tiempo_envio` | Delay entre transacciones, aleatorizado por terminal |
| `n_transacciones` | Número de transacciones por terminal, configurable por test |
| `bs_bcast` | Bit que marca la transacción como broadcast |

### 4.2 Generador — `generator.sv`

Crea objetos `packet`, los randomiza respetando las restricciones anteriores y los coloca en un mailbox por terminal. Un generador por terminal, o un generador central que reparte a `drvrs` mailboxes — decisión a fijar en el test plan.

### 4.3 Drivers — `driver.sv`

Uno por terminal (`drvrs` instancias). Traduce cada `packet` a la secuencia de pines de la interfaz (`push`, `D_push`, y espera `pndng`/arbitraje) usando el `clocking block` de `bus_if`. Corre en un proceso independiente por terminal.

### 4.4 Monitores — `monitor.sv`

- **Monitor de terminal** (uno por `drvrs`): observa `pop`, `D_pop`, y reconstruye el paquete recibido, con marca de tiempo.
- **Monitor de bus**: observa `bus`, `trn_chng`, `wrt`, `bs_grnt` para verificar la arbitración (solo un maestro con `bs_grnt` a la vez) y alimentar el reporte de retardo.

### 4.5 Scoreboard — `scoreboard.sv`

Recibe transacciones esperadas (del generador/monitor de entrada) y observadas (del monitor de salida), compara contenido y destino, calcula el retardo (`tiempo_recibido - tiempo_envio`) y clasifica los casos de esquina (broadcast, dirección inexistente, FIFO llena, colisión de arbitraje).

### 4.6 Coverage — `coverage.sv`

`covergroup` con los *bins* de interés: largo de paquete (16/32/64), destino válido/broadcast/inválido, terminal origen, y transiciones del árbitro — soporta el requisito de casos de esquina.

### 4.7 Ambiente y Test — `environment.sv`, `test_top.sv`

`environment` instancia y conecta generador(es), drivers, monitores, scoreboard y coverage. `test_top` es el punto de entrada: instancia DUT + interfaz + ambiente, y expone los parámetros de cada corrida (semilla, número de transacciones, distribución de largos, etc.).

### 4.8 Reporte y análisis — `scripts/`

- El scoreboard escribe `reports/paquetes.csv` con: tiempo de envío, terminal origen, terminal destino, tiempo de recibido, retardo.
- `scripts/plot_histograma.gp` lee el CSV y genera el histograma de retardos vía GNUplot.

---


## 6. Flujo de Dependencias

### 6.1 Dependencias de compilación/ejecución

```
test_top.sv
  ├── environment.sv
  │     ├── generator.sv
  │     ├── driver.sv         (x drvrs)
  │     ├── monitor.sv        (x drvrs + 1 de bus)
  │     ├── scoreboard.sv
  │     └── coverage.sv
  ├── bus_pkg.sv (packet, parámetros)
  ├── bus_if.sv  (clocking block)
  └── top_dut.sv
        ├── Library.sv (prll_bs_gnrtr_n_rbtr_fifo y bloques internos)
        └── fifo.sv    (fifo_flops)
```

La dependencia fluye de arriba hacia abajo: `test_top` conoce al `environment`, el `environment` conoce a los componentes concretos, y todos dependen de `bus_pkg` e `bus_if`. Ningún componente del testbench instancia el DUT directamente salvo `test_top`.

### 6.2 Orden de desarrollo sugerido

1. Test plan: enumerar capacidades del DUT a verificar y diagrama del ambiente (**entregable actual, 1 semana**).
2. Definir `bus_pkg.sv` (transacción + constraints) y `bus_if.sv`.
3. Implementar `driver.sv` y `monitor.sv` para un solo terminal; validar contra el DUT en modo dirigido.
4. Extender a `drvrs` terminales concurrentes (procesos independientes).
5. Implementar `scoreboard.sv` y `coverage.sv`.
6. Agregar generación de reporte CSV y script de GNUplot.
7. Identificar e implementar casos de esquina (broadcast, direcciones inválidas, FIFO llena/vacía, colisión de arbitraje).
8. Revisión final e integración antes de la demostración.

---

## 7. Documentación (`docs/`)

| Archivo | Contenido |
|---|---|
| `arquitectura.md` | Este documento: organización del proyecto |
| `testplan.md` | **Primer entregable (5%)** — capacidades del DUT a verificar + diagramas de módulos, interfaces y formato de paquetes |
| `diagrama_ambiente.png` | Diagrama completo del ambiente (bloques + paquetes de comunicación entre bloques) |

### 7.1 `testplan.md` — contenido mínimo esperado

- Lista de capacidades del DUT a verificar (arbitraje, push/pop de FIFO, serialización, broadcast, detección de dirección inválida, backpressure).
- Diagrama de módulos del DUT y de sus interfaces de comunicación.
- Formato de los paquetes (campos, ancho de bits, codificación de dirección/broadcast).
- Mapeo de cada capacidad a una o más pruebas concretas del ambiente.

---

## 8. Roles y Responsabilidades (pareja)

Al ser un equipo de 2, los roles se dividen por **lado del ambiente** en vez de por jerarquía, alternando la revisión de Pull Requests entre ambos.

### Integrante A — Lado de estímulo (Generación/Driver)
* Define `bus_pkg.sv` (transacción y constraints) junto con el Integrante B.
* Implementa `generator.sv` y `driver.sv` para todos los terminales.
* Responsable de los casos de esquina relacionados con generación (direcciones inválidas, broadcast, tiempos de envío).

### Integrante B — Lado de observación (Monitor/Scoreboard/Reporte)
* Implementa `monitor.sv` (terminales + bus) y `scoreboard.sv`.
* Responsable del reporte CSV, el script de GNUplot y la `covergroup`.
* Responsable de los casos de esquina relacionados con recepción (FIFO llena, colisión de arbitraje).

### Responsabilidad compartida
* Ambos revisan los Pull Requests del otro antes de integrar a `main`.
* Ambos participan en la demostración final del ambiente.

---

## 9. Entregables y Ponderación

| Entregable | % | Estado |
|---|---|---|
| Test plan (capacidades + diagramas de módulos/interfaces/paquetes) | 5% | **Próximo a entregar — revisión en 1 semana** |
| Diagrama completo del ambiente (bloques + paquetes entre bloques) | 5% | Pendiente |
| Unidades del ambiente aleatorizado vistas en clase, cada una en proceso independiente | 10% | Pendiente |
| Código comentado | 10% | Pendiente |
| Capacidad de aleatorización (transacciones/terminal, largo de paquete, tiempos de envío, mensajes con error, direcciones de destino, identificador de broadcast) | 40% | Pendiente |
| Identificación e implementación de casos de esquina | 10% | Pendiente |
| Generación de datos: reporte CSV de paquetes + histograma GNUplot de retardos | 20% | Pendiente |
| **Total** | **100%** | |

**Requisitos mínimos de revisión:** el proyecto debe compilar y correr en VCS, sin plagio, coordinado por GitHub, con demostración en vivo por pareja.

---

## 10. Convenciones de Código

| Aspecto | Convención |
|---|---|
| **Estilo** | Un `always_comb`/`always_ff` por bloque lógico; nombres de señal consistentes con el DUT provisto (`push`, `pop`, `pndng`, `D_push`, `D_pop`) |
| **Documentación** | Comentario de encabezado en cada clase/módulo describiendo su rol en el ambiente |
| **Nombres de archivo** | Descriptivos y en snake_case (`driver.sv`, `scoreboard.sv`) |
| **Control de versiones** | Ramas `feature/<componente>` (ej. `feature/driver`, `feature/scoreboard`); Pull Request obligatorio para integrar a `main` |
| **Comunicación** | Canal acordado por la pareja + repositorio compartido para diagramas y CSVs |