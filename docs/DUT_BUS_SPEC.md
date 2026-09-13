# DUT_BUS_SPEC

## `bs_gnrtr_n_rbtr`

Documento de referencia para el desarrollo del ambiente de verificación funcional del bus de datos.

## 1. DUT bajo verificación

El módulo principal es:

```systemverilog
module bs_gnrtr_n_rbtr #(
  parameter bits = 1,
  parameter drvrs = 4,
  parameter pckg_sz = 16,
  parameter broadcast = 8'hFF
)(
  input  logic                    clk,
  input  logic                    reset,
  input  logic [drvrs-1:0]        pndng,
  input  logic [drvrs-1:0][pckg_sz-1:0] D_pop,
  output logic [drvrs-1:0]        pop,
  output logic [drvrs-1:0]        push,
  output logic [drvrs-1:0][pckg_sz-1:0] D_push
);
```

### Configuración

| Parámetro | Configuración |
|---|---|
| `bits` | Fijo = 1 |
| `drvrs` | Parametrizable |
| `pckg_sz` | Parametrizable, máximo 64 bits |
| `broadcast` | Parametrizable |
| Número de buses | 1 |

## 2. Función general

El DUT implementa un bus serial compartido por varias interfaces.

Cada interfaz puede solicitar acceso al bus, transmitir un paquete, recibir paquetes dirigidos a ella, recibir broadcast e ignorar destinos que no le correspondan.

Todas las interfaces comparten el mismo bus y el arbitraje debe evitar transmisiones simultáneas sobre el mismo recurso.

## 3. Señales externas

| Señal | Dirección | Función |
|---|---|---|
| `clk` | Input | Reloj |
| `reset` | Input | Reset inicial |
| `pndng[i]` | Input | Indica que la interfaz `i` tiene un paquete pendiente |
| `D_pop[i]` | Input | Paquete que la interfaz `i` desea transmitir |
| `pop[i]` | Output | Indica que el DUT consumió el paquete ofrecido en `D_pop[i]` |
| `push[i]` | Output | Indica que el DUT presenta un paquete recibido |
| `D_push[i]` | Output | Paquete recibido por la interfaz `i` |

### `pop`

`pop[i]` es una confirmación de consumo del paquete ofrecido en `D_pop[i]`.

El modelo externo debe retirar ese paquete de su cola únicamente después de observar `pop[i] = 1`.

### `push`

Cuando `push[i] = 1`, `D_push[i]` contiene el paquete recibido por la interfaz `i`.

`D_push` es el dato recibido presentado por el DUT; no representa directamente una cola interna.

`push` y `pop` pueden ocurrir simultáneamente y deben tratarse como eventos independientes.

## 4. Formato del paquete

Para un paquete de tamaño `pckg_sz`:

```text
[pckg_sz-1 : pckg_sz-8] [pckg_sz-9 : 0]
|       destino          |      payload     |
```

Los 8 bits superiores corresponden al destino y el resto al payload.

Ejemplo para `pckg_sz = 16`:

```text
[15:8] = destino
[7:0]  = payload
```

Ejemplo para `pckg_sz = 64`:

```text
[63:56] = destino
[55:0]  = payload
```

El tamaño mínimo debe ser compatible con un campo de destino de 8 bits.

## 5. Direccionamiento

### Unicast

Un destino válido corresponde a una única interfaz.

Para `drvrs = 4`, los destinos válidos son `0, 1, 2, 3`.

### Broadcast

El valor configurado mediante `broadcast` representa la dirección de broadcast.

Por ejemplo:

```text
broadcast = 8'hFF
destination = 8'hFF
```

El paquete debe ser recibido por las interfaces correspondientes al comportamiento de broadcast del DUT.

### Dirección inválida

Un destino que no corresponde a una interfaz válida ni a `broadcast` no debe producir una recepción válida.

### Revisión de parametrización

El comportamiento de broadcast debe verificarse con diferentes valores del parámetro `broadcast`; el ambiente no debe asumir que `8'hFF` es siempre la dirección broadcast.

## 6. Arbitraje

El DUT utiliza Round Robin para distribuir el acceso al bus.

Conceptualmente:

```text
ID 0 -> ID 1 -> ID 2 -> ... -> ID N-1 -> ID 0 -> ...
```

`pndng` indica qué interfaces tienen solicitudes pendientes. La presencia de varias solicitudes no implica transmisión simultánea.

Para diagnóstico pueden observarse:

- `pndng`;
- `bs_grnt`;
- `bs_bsy`;
- `trn_chng`;
- estado del arbitraje;
- contador de arbitraje.

El cambio de turno está relacionado con `trn_chng`.

Las señales internas no sustituyen la verificación funcional de las salidas externas.

## 7. Serialización

Trayectoria de transmisión:

```text
D_pop -> serializer TX -> BUS
```

Trayectoria de recepción:

```text
BUS -> serializer RX -> D_push
```

La verificación debe comprobar la integridad del paquete a nivel de transacciones y no reproducir innecesariamente la implementación interna del serializer.

## 8. Estructura funcional relevante del RTL

```text
bs_gnrtr_n_rbtr
|
+-- bs_ntrfs_n_rbtr
|   |
|   +-- ntrfs_cntrl_n_rbtr
|   |   +-- Write_st_Mchn
|   |   +-- Read_st_Mchn
|   |   +-- Counter
|   |   +-- Counter_arb
|   |   +-- Arbiter_st_Mchn
|   |
|   +-- serializer TX
|   +-- serializer RX
|
+-- bs_ntrfs_n_rbtr
|   +-- misma estructura
|
+-- ...
|
+-- bs_ntrfs_n_rbtr
    +-- misma estructura
```

## 9. Señales internas de interés

| Señal | Uso |
|---|---|
| `bus` | Actividad serial del bus |
| `bs_bsy` | Estado de ocupación |
| `trn_chng` | Cambio de turno |
| `bs_grnt` | Permiso de transmisión |
| `Counter` | Conteo asociado al procesamiento de bits |
| `Counter_arb` | Estado del turno de arbitraje |
| `Write_st_Mchn` | Estado de transmisión |
| `Read_st_Mchn` | Estado de recepción |

Se utilizan principalmente para diagnóstico.

## 10. Arquitectura del ambiente

La arquitectura acordada es:

```text
                         GENERATOR
                             |
                     tx_transaction
                             |
              +--------------+--------------+
              |              |              |
            mb[0]          mb[1]          mb[N-1]
              |              |              |
           Driver 0       Driver 1       Driver N-1
              |              |              |
              +--------------+--------------+
                             |
                             v
                            DUT
                             |
                             v
                          Monitor
                             |
                          dut_event
                             |
                          mailbox
                             |
                          Checker
                          /      \
                         /        \
                  observed      expected
                         \        /
                          \      /
                        Scoreboard
```

El diagrama representa el flujo conceptual; la implementación concreta de clases y mailboxes se define posteriormente.

## 11. Transacciones

Se definen tres paquetes conceptuales principales.

### `tx_transaction`

Comunicación:

```text
Generator -> Driver
Generator -> Scoreboard
```

Campos mínimos:

| Campo | Descripción |
|---|---|
| `interface_id` | Interfaz/driver que origina la transmisión |
| `packet` | Paquete completo |

El `interface_id` identifica el origen y permite asociar la transacción con el Driver correspondiente.

### `dut_event`

Comunicación:

```text
Monitor -> Checker
```

Campos mínimos:

| Campo | Descripción |
|---|---|
| `event_type` | `POP` o `PUSH` |
| `interface_id` | Interfaz donde ocurrió el evento |
| `packet` | Paquete asociado |

Para `POP`, el Monitor utiliza `pop[i]` y `D_pop[i]`. Para `PUSH`, utiliza `push[i]` y `D_push[i]`.

El paquete asociado a `POP` se conserva para facilitar el diagnóstico de fallos.

### `expected_event`

Comunicación:

```text
Scoreboard -> Checker
```

Campos mínimos:

| Campo | Descripción |
|---|---|
| `event_type` | `POP` o `PUSH` |
| `interface_id` | Interfaz esperada |
| `packet` | Paquete esperado, cuando aplica |

Su estructura debe permitir compararlo directamente con `dut_event`.

## 12. Modelo funcional del Scoreboard

El Scoreboard mantiene el estado mediante queues de SystemVerilog.

### `tx_pending[]`

```text
tx_pending[0]
tx_pending[1]
...
tx_pending[drvrs-1]
```

Contiene paquetes entregados al DUT mediante `D_pop` cuyo consumo todavía no ha sido confirmado mediante `pop`.

Regla fundamental:

```text
NO pop_front() antes de confirmar pop.
```

Ejemplo:

```text
tx_pending[2]

+-----+-----+-----+
|  A  |  B  |  C  |
+-----+-----+-----+
   ^
 front
```

Mientras `pop[2] = 0`, `A` permanece en la cola.

Cuando se observa `pop[2] = 1` y el evento es validado, se confirma su consumo y se realiza `pop_front()`.

Si la comparación falla, el elemento no debe descartarse automáticamente.

### `rx_expected[]`

```text
rx_expected[0]
rx_expected[1]
...
rx_expected[drvrs-1]
```

Contiene los paquetes que el modelo espera recibir en cada interfaz.

Para unicast:

```text
source -> destination
```

el paquete se agrega a `rx_expected[destination]`.

Para broadcast se agrega una copia a cada cola de recepción correspondiente.

Para un destino inválido no se agrega ningún paquete.

Cuando se observa `push[i] = 1`, el Checker compara contra `rx_expected[i].front()`.

El esperado no se retira antes de la comparación. Tras una comparación válida se confirma el consumo y se ejecuta `pop_front()`.

## 13. Propiedad del estado

Las queues pertenecen al Scoreboard.

El Checker no debe manipular directamente:

```text
tx_pending[]
rx_expected[]
```

El acceso debe realizarse mediante operaciones definidas por el Scoreboard.

Conceptualmente:

```text
Checker
   |
   +-- consultar esperado
   |
   +-- validar evento
   |
   +-- confirmar consumo
   |
   v
Scoreboard
   |
   +-- tx_pending[]
   +-- rx_expected[]
```

Esto concentra el estado del modelo en un único componente.

## 14. Sincronización

Los mailboxes se utilizan para comunicación y sincronización entre procesos concurrentes.

La separación de responsabilidades es:

```text
mailbox = comunicación / sincronización
queue   = estado del modelo
```

No se utilizará un mailbox como sustituto de las queues del Scoreboard.

Una transacción debe retirarse de una queue únicamente cuando el evento correspondiente haya sido confirmado.

## 15. Flujo de transmisión

```text
1. Generator crea tx_transaction
2. Se identifica interface_id
3. Driver correspondiente recibe la transacción
4. Driver presenta D_pop[i] y pndng[i]
5. Scoreboard registra el paquete en tx_pending[i]
6. Scoreboard determina el destino mediante el modelo
7. Scoreboard actualiza rx_expected[]
8. DUT procesa la transmisión
9. DUT genera pop[i]
10. Monitor observa pop[i] y D_pop[i]
11. Monitor genera dut_event
12. Checker consulta el esperado al Scoreboard
13. Se compara observado vs esperado
14. Tras una confirmación válida se actualiza el estado correspondiente
```

La implementación puede ajustar el orden interno de los pasos, pero debe conservar la propiedad de no eliminar una transacción antes de que el DUT confirme su consumo.

## 16. Flujo de recepción

```text
Generator
    |
    v
tx_transaction
    |
    v
Scoreboard
    |
    v
modelo de destino
    |
    v
rx_expected[i]
    |
    v
   DUT
    |
    +-- push[i]
    +-- D_push[i]
    |
    v
 Monitor
    |
    v
 dut_event
    |
    v
 Checker
    |
    v
rx_expected[i].front()
    |
    v
 comparación
    |
    +-- OK   -> confirmar y retirar
    |
    +-- FAIL -> conservar para diagnóstico
```

## 17. Eventos simultáneos

`push` y `pop` son eventos independientes.

Si ocurren simultáneamente:

```text
pop[i]  = 1
push[i] = 1
```

se procesan como dos eventos:

```text
POP  -> afecta tx_pending
PUSH -> afecta rx_expected
```

Uno no invalida ni sustituye al otro.

## 18. Identificación de interfaz

Cada `tx_transaction` contiene:

```text
interface_id
```

Conceptualmente:

```text
interface_id = 0 -> Driver 0
interface_id = 1 -> Driver 1
...
interface_id = N -> Driver N
```

Una implementación posible es un mailbox por interfaz:

```systemverilog
mailbox tx_mb[drvrs];
```

con:

```text
Generator
   |
   +--> tx_mb[0] --> Driver 0
   +--> tx_mb[1] --> Driver 1
   +--> ...
   +--> tx_mb[N] --> Driver N
```

La decisión final sobre la distribución de mailboxes queda para la implementación del Agent/Driver.

## 19. Límites del modelo

El modelo funcional no debe copiar la implementación RTL.

Debe representar las reglas funcionales de direccionamiento, recepción, consumo y arbitraje.

El Round Robin se verifica mediante el comportamiento observable, sin reproducir innecesariamente las FSM internas.

Las señales internas se conservan como apoyo de diagnóstico.

## 20. Configuraciones relevantes

Configuración principal:

```text
bits      = 1
drvrs     = 4
pckg_sz   = 16
broadcast = 8'hFF
```

Configuraciones previstas:

```text
drvrs   = 2, 4, 8
pckg_sz = 16, 32, 64
```

## 21. Decisiones de arquitectura establecidas

1. `bits = 1` es fijo.
2. `drvrs` es parametrizable.
3. `pckg_sz` es parametrizable hasta 64 bits.
4. `broadcast` es parametrizable.
5. El FIFO RTL no forma parte del modelo funcional.
6. El modelo utiliza queues de SystemVerilog.
7. `tx_pending[]` mantiene paquetes hasta confirmar `pop`.
8. `rx_expected[]` mantiene paquetes hasta validar `push`.
9. El Monitor observa señales y las convierte en transacciones.
10. El Monitor no determina pass/fail.
11. El Checker realiza la comparación.
12. El Scoreboard mantiene el modelo y su estado.
13. `dut_event` incluye el paquete asociado a `POP` para diagnóstico.
14. `push` y `pop` se procesan independientemente.
15. Los mailboxes se utilizan para comunicación y sincronización.
16. Las queues se utilizan para representar el estado del modelo.
17. No se implementarán assertions.
18. No se implementará functional coverage en SystemVerilog.
19. Las señales internas son principalmente de diagnóstico.

## 22. Pendientes de implementación

Antes de codificar los transactors falta concretar:

- definición SystemVerilog de `tx_transaction`;
- definición SystemVerilog de `dut_event`;
- definición SystemVerilog de `expected_event`;
- cantidad y dirección exacta de cada mailbox;
- interfaz del Scoreboard para consulta y confirmación;
- mecanismo mediante el cual Generator distribuye transacciones a los Drivers;
- sincronización exacta entre Driver, Scoreboard, Monitor y Checker;
- representación concreta de las queues por interfaz.

