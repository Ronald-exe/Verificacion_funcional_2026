# Ambiente de verificacion objetivo

## 1. Proposito

Este documento define el estado objetivo del ambiente de verificacion funcional para `bs_gnrtr_n_rbtr`. Es la referencia para adaptar el ambiente existente en `EDA_VCS/` por modulos, revisar cada cambio y organizarlo en commits pequenos.

Este documento no reemplaza todavia [TestplanV3.md](TestplanV3.md) ni afirma que la arquitectura descrita ya este implementada. El plan vigente se conserva como registro de la version anterior hasta que la nueva referencia y sus casos de uso sean revisados.

## 2. Alcance

El ambiente verificara el DUT usando SystemVerilog orientado a objetos, sin UVM. Se conservaran las responsabilidades separadas de Generator, Driver, Monitor, Scoreboard y Checker.

El reset se utilizara unicamente para inicializar el DUT antes del trafico. El reset durante actividad y los casos asociados quedan fuera del alcance.

La generacion sera constrained-random y reproducible mediante semillas. No se implementara cobertura funcional en esta etapa. Se usaran contadores de ejecucion y resultados para informar si un perfil llego a ejercitar el tipo de trafico que declara.

## 3. Responsabilidades

| Componente | Responsabilidad objetivo |
|---|---|
| `tb_pkg` | Fuente central de tipos, constantes, parametros por defecto, perfiles y funciones compartidas. |
| `tx_transaction` | Representar una solicitud de transmision, sus campos de protocolo y metadata del testbench. |
| Generator | Crear transacciones constrained-random, aplicar la politica del perfil y enviarlas al Driver y al Scoreboard por canales independientes. |
| Driver | Mantener una FIFO de solicitudes por interfaz, respetar el calendario del estimulo y conducir `pndng` y `D_pop` desde el frente de la FIFO. Retirar la solicitud al observar su handshake `pop`. No publica eventos al Scoreboard. |
| Monitor | Observar pasivamente las señales del DUT y publicar los eventos observados, incluidos `POP` y `PUSH`, al Checker. |
| Scoreboard | Construir y conservar los eventos esperados a partir de las transacciones generadas. No realiza el matching principal ni determina el resultado final. |
| Checker | Recibir eventos observados del Monitor y eventos esperados del Scoreboard; realizar el matching, contar errores y determinar `PASS`/`FAIL`. |
| Environment | Construir y conectar los componentes, mailboxes y procesos concurrentes. |
| Test / TB Top | Seleccionar el perfil, leer opciones de ejecucion, configurar DUT y ambiente, aplicar reset inicial y controlar el cierre de la simulacion. |
| Script / Makefile | Compilar las configuraciones estructurales y ejecutar perfiles/seeds, guardar logs y reunir los resultados de regresion. |

### 3.1 FIFO del Driver y observacion de `pop`

La FIFO pertenece al camino activo de estimulo. Cada instancia del Driver mantiene su cola `tx_fifo`; el arreglo de Drivers del Environment equivale a una FIFO por interfaz. Un proceso del Driver recibe transacciones del mailbox mientras otro procesa el frente de la cola.

Se conserva el significado actual de `delay`: ciclos de espera antes de ofrecer ese paquete al DUT. El retardo se aplica cuando la transaccion llega al frente de `tx_fifo`, de modo que las transacciones posteriores pueden acumularse mientras una solicitud espera o se procesa. No se renombra a `arrival_delta` ni se interpreta como tiempo absoluto.

Cuando el frente esta listo para ofrecerse, el Driver utiliza la FIFO para conducir de forma estable:

```text
pndng[i] = 1 cuando la FIFO de i tiene una solicitud pendiente
D_pop[i] = paquete al frente de la FIFO de i
```

El Driver puede muestrear `pop[i]` para retirar el frente y avanzar el protocolo de entrada. Esa operacion no genera un `dut_event`, no comunica el `pop` al Scoreboard y no reemplaza la observacion independiente del Monitor. El Monitor es la fuente de eventos observados para el Checker. El estado `busy` debe permanecer activo mientras haya transacciones recibidas pendientes, incluidas las que esperan su `delay`.

La implementacion debera definir una sola convencion de muestreo para evitar carreras entre Driver, Monitor y DUT. La topologia concreta (un objeto Driver con un arreglo de FIFOs o Drivers por interfaz con una FIFO cada uno) se decidira al adaptar el modulo, manteniendo una FIFO logica por interfaz.

## 4. Flujo de transacciones

```text
                              +--> mailbox --> Driver --> tx_fifo[i] --> DUT
Generator --> tx_transaction-+                              ^             |
                              +--> mailbox --> Scoreboard   +--- pop -----+
                                                               |
DUT --> Monitor --> dut_event --> Checker <-- expected_event <-- Scoreboard
                                      |
                                      +--> resumen PASS/FAIL
```

El Generator conserva una copia independiente de la transaccion que entrega a cada consumidor; los componentes no deben compartir un mismo handle mutable entre procesos concurrentes.

El Driver ejecuta el calendario de llegada de las transacciones y mantiene las señales de entrada hasta el `pop` correspondiente. No informa al Scoreboard de ese handshake. El Monitor observa `pop` y `push` en la interfaz y entrega esos eventos al Checker. El Scoreboard predice los eventos esperados desde la transaccion generada, y el Checker los compara con los eventos observados.

`pop` y `push` son eventos independientes; si aparecen en el mismo ciclo, ambos se reportan y procesan.

## 5. Transacciones y trazabilidad

La transaccion podra ampliarse para identificar y clasificar estimulos. Campos candidatos:

| Campo | Uso |
|---|---|
| `tx_id` | Identificador local del testbench para logs y diagnostico; no es parte del paquete del DUT. |
| `source` | Interfaz origen, tambien conocida por el mailbox/Driver destino. |
| `destination` | Direccion logica extraida o almacenada para construir el paquete. |
| `payload` | Datos transportados, dimensionados segun `pckg_sz`. |
| `arrival_delta` o `arrival_time` | Instante o intervalo de llegada al Driver. Se elegira una unica representacion temporal. |
| `traffic_type` | Clase de trafico seleccionada por el perfil. |
| `payload_type` | Clasificacion del patron de payload cuando aplique. |

`tx_id` facilita la trazabilidad interna, pero no permite recuperar inequívocamente una identidad desde el DUT, porque el identificador no se transmite en el paquete. Los paquetes duplicados se deben comparar respetando su multiplicidad; cualquier atribucion individual de origen o latencia debera considerar esa limitacion.

### 5.1 Convencion de nombres

Cuando un nombre del prompt represente un dato que ya existe en el ambiente, se conservara el nombre del ambiente actual. No se agregaran campos duplicados solo para adoptar otro vocabulario.

| Concepto | Nombre del prompt | Nombre actual a conservar | Tratamiento |
|---|---|---|---|
| Interfaz origen | `source` | `interface_id` | Mantener `interface_id` en `tx_transaction`; es el origen de la solicitud. |
| Paquete completo | `destination` + `payload` | `packet` | Mantener `packet` como dato aleatorio completo. Usar funciones de acceso para destino y payload cuando se necesiten; no aleatorizar copias independientes. |
| Destino | `destination` | `get_destination()` / campo superior de `packet` | Mantener la funcion de acceso existente y centralizar el ancho en `DEST_FIELD_WIDTH`. |
| Tiempo entre solicitudes | `arrival_delta` | `delay` | Mantener `delay` si conserva el significado de ciclos de espera antes de ofrecer esa transaccion. Si se decide usar tiempo absoluto, documentar el cambio semantico antes de reutilizar el nombre. |
| Perfil | `SCENARIO` | `scenario` y `scenario_e` | Mantener `scenario` como variable y `scenario_e` como tipo; reducir los valores del enum, sin renombrar la variable. |
| Cantidad de transacciones | `NUM` | `num_transactions` | `NUM` sera el nombre del plusarg; dentro del testbench se conserva `num_transactions`. |
| Interfaces del DUT | `DRVRS` | `drvrs` / `DRVRS_DEFAULT` | `DRVRS` puede ser la opcion de compilacion; se conservan los nombres SystemVerilog existentes. Aplicar igual criterio a `PCKG_SZ`/`pckg_sz` y `BITS`/`bits`. |
| Broadcast | `BROADCAST` | `broadcast` / `BROADCAST_DEFAULT` / `BROADCAST_RTL_ACTUAL` | Conservar los nombres existentes y aclarar en cada uso si es el parametro configurado o el valor que actualmente compara el RTL. |
| Esperados pendientes de POP | No tiene equivalente directo | `tx_pending` | No renombrar a `tx_fifo`: `tx_pending` es estado del modelo; la FIFO nueva del Driver contiene estimulos activos y tiene otra responsabilidad. |
| Identificador de transaccion | `tx_id` | No existe actualmente | Campo nuevo de metadata del testbench, asignado por el Generator; no se agrega al paquete del DUT. |
| Longitud de burst | `burst_length` | No existe actualmente | Campo nuevo, solo necesario para perfiles que generen rachas. |
| Tipo de trafico | `traffic_type` | No existe actualmente | Campo o variable nueva si clasifica una transaccion individual. No debe confundirse con `scenario`, que selecciona la politica global de la corrida. |
| Tipo de payload | `payload_type` | No existe actualmente | Metadata nueva opcional para identificar la politica de payload aplicada. |
| Seed | `SEED` | No hay variable propia; actualmente se consulta la seed del simulador | `SEED` sera el nombre del plusarg. Se agregara una variable local `seed` solo si se requiere derivar o reportar la semilla efectiva. |

La misma convencion se aplicara a los nombres de parametros y eventos de SystemVerilog: se conservaran `drvrs`, `pckg_sz`, `interface_id`, `packet`, `delay`, `scenario`, `num_transactions`, `event_mb` y `expected_mb` cuando sigan representando la misma interfaz o dato. Un cambio de nombre se justificara solo si cambia el significado o elimina una ambiguedad real.

## 6. Modelo funcional y matching

El Scoreboard construye los eventos esperados a partir de las transacciones del Generator. El Checker consume tanto esos esperados como los eventos observados por el Monitor y es el unico responsable del matching principal y del resultado `PASS`/`FAIL`.

Reglas funcionales candidatas, pendientes de confirmacion contra la especificacion acordada:

- destino igual al origen: descarte, sin recepcion;
- destino valido distinto del origen: unicast al destino;
- destino de broadcast: recepcion en todas las interfaces excepto el origen;
- destino invalido distinto de broadcast: descarte, sin recepcion.

El orden de recepcion no se exigira inicialmente. El Checker buscara una coincidencia por contenido y debera respetar la multiplicidad de paquetes repetidos. El matching no puede usar `tx_id` como dato observado, ya que el DUT no transporta ese campo.

El parametro `broadcast` merece tratamiento separado: el RTL actual presenta una divergencia conocida y utiliza `8'hFF` internamente. La prueba funcional normal debera usar valores compatibles con el comportamiento esperado; una prueba que evidencie la divergencia debe identificarse como diagnostica y tener un resultado esperado definido, no invertir PASS/FAIL.

## 7. Perfiles de trafico

Se sustituyeron los escenarios especificos por cinco perfiles generales. `scenario` y `scenario_e` conservan sus nombres; los valores del enum son:

| Perfil | Politica |
|---|---|
| `SC_RANDOM` | Seleccion uniforme de `traffic_type`; la fuente, destino y delay se randomizan dentro de sus constraints. |
| `SC_BURST` | Selecciona una fuente y una longitud aleatoria entre `BURST_MIN` y `BURST_MAX`; el primer paquete usa un delay aleatorio y los siguientes usan delay cero. |
| `SC_CONCURRENT` | Distribuye origenes en orden ciclico y fija `delay=0`, iniciando una primera solicitud por interfaz cuando `NUM_TX >= DRVRS`. |
| `SC_BOUNDARY` | Elige con igual peso entre destinos `0`, `drvrs-1`, `drvrs`, `0xFE` y `0xFF`; `traffic_type` debe ser coherente con el destino y el origen. |
| `SC_MIXED` | Aplica la distribucion ponderada de `traffic_type`: 60% unicast, 10% self, 20% broadcast y 10% invalido. Es el perfil predeterminado. |

La transaccion utiliza `traffic_type` para seleccionar unicast, self-addressed, broadcast o destino invalido. `payload_type` elige payload aleatorio con peso 60 o uno de cuatro patrones dirigidos con peso 10 cada uno. Los pesos y el rango de burst viven en `tb_pkg`.

Los perfiles no son una prueba independiente por cada funcionalidad. Mediante constraints y pesos generan clases de trafico, back-to-back, bursts, concurrencia, destinos limite y patrones de payload. Varias fuentes hacia un mismo destino y cross traffic pueden aparecer en los perfiles aleatorios; su presencia se informa con contadores cuando estos se incorporen.

No se debe asumir que un caso aparecio solo porque el perfil podia generarlo. Los contadores de ejecucion informaran las clases generadas y los eventos observados; inicialmente estos contadores diagnostican y no sustituyen un criterio de PASS/FAIL.

## 8. Constraints y aleatorizacion

Las variables de transaccion usadas para aleatorizacion son:

```text
interface_id
packet
traffic_type
payload_type
delay
burst_length
```

El nombre actual `interface_id`, `packet` y `delay` se conserva. `traffic_type` determina la relacion entre origen y destino; `payload_type` restringe los bits inferiores de `packet`; `burst_length` esta limitado por `BURST_MIN` y `BURST_MAX`. Los perfiles aplican constraints adicionales o distribuciones `dist` sin repetir los pesos y limites centralizados en `tb_pkg`.

Los pesos iniciales estan centralizados en `tb_pkg`. Una falla de `randomize()` detiene el perfil para evitar continuar con campos sin aleatorizar.

No se implementara cobertura funcional en esta etapa. La exploracion se hara con volumen de transacciones, variedad de seeds y contadores informativos.

## 9. Parametrizacion y ejecucion

Los parametros estructurales se fijan al compilar cada configuracion del DUT y no se cambian durante una simulacion:

```text
BITS
DRVRS
PCKG_SZ
BROADCAST
```

Los valores soportados y sus restricciones se documentaran. `bits` no se aleatoriza. Los estimulos y controles de regresion se seleccionan en ejecucion mediante plusargs, como minimo:

```text
+SEED=<entero>
+NUM=<cantidad>
+SCENARIO=<perfil>
```

Estos tres plusargs ya se leen en `testbench.sv`: `SCENARIO` acepta los cinco valores `SC_*`, `NUM` establece una cantidad exacta y `SEED` inicializa las fuentes aleatorias del Generator. Sus defaults actuales son `SC_MIXED`, `NUM_TRANSACTIONS_DEFAULT` y `SEED_BASE_DEFAULT`.

Se podran agregar opciones de verbosidad y limite de errores si la salida de la regresion lo requiere. El script y el Makefile (si se agrega) deberan exponer una interfaz coherente y permitir pasar configuracion estructural, perfil, cantidad y seed sin editar el testbench.

El testbench ya admite los plusargs, pero `run_vcs.sh` aun no los acepta como argumentos ni organiza los logs por corrida.

La forma de pasar parametros de elaboracion depende de VCS y se definira junto con el comando de compilacion probado; no se mezclaran parametros estructurales con plusargs de simulacion.

## 10. Reset, finalizacion y watchdog

El TB aplicara el reset inicial, esperara la liberacion y comenzara el trafico. No habra reset durante actividad ni logica para descartar paquetes en vuelo por reset.

La finalizacion esperara a que el Generator termine, que los Drivers no tengan solicitudes por presentar y que los eventos esperados/observados hayan podido drenarse. El watchdog marcara la corrida como `FAIL` o `TIMEOUT`; nunca debe permitir que una simulacion detenida se reporte como `PASS`.

Los margenes del watchdog se definiran con mediciones en las configuraciones soportadas, evitando depender de un ciclo fijo que no escale con `NUM`, `DRVRS` o `PCKG_SZ`.

## 11. Resultado por corrida y regresion

Cada simulacion registrara como minimo:

```text
Seed
Configuracion DUT: BITS, DRVRS, PCKG_SZ, BROADCAST
Scenario
NUM_TX
PASS / FAIL / TIMEOUT
Conteos de errores y eventos
```

La seed aplicada debe aparecer en el log y en el resumen de regresion. Repetir la misma configuracion, perfil, cantidad y seed debe reproducir el estimulo aleatorio.

Una regresion ejecutara varias seeds y, cuando corresponda, varias configuraciones de compilacion. El resumen agregado identificara cada combinacion que fallo y conservara la seed necesaria para reproducirla. Los logs individuales no se sobrescribiran entre corridas.

## 12. Criterios de PASS/FAIL

Una corrida sera `PASS` unicamente si:

- todos los eventos observados que requieren correspondencia encuentran un esperado compatible;
- no hay eventos esperados pendientes al cierre;
- no hay eventos espurios, datos corruptos o entregas a interfaces incorrectas;
- la generacion aleatoria no falla;
- no expira el watchdog;
- la corrida termina normalmente.

Los contadores de alcance se imprimiran por perfil y serviran para diagnostico. Hasta que se acuerden requisitos de alcance obligatorios, un contador en cero generara una advertencia, no cambiara por si solo el veredicto funcional.

## 13. Plan de adaptacion por cambios pequenos

Cada etapa se revisara y podra cerrarse como un commit independiente, despues de validar su documentacion y pruebas locales.

| Etapa | Alcance |
|---|---|
| 1. Referencia documental | Definida; se actualiza junto con cada corte. |
| 2. Tipos y paquete | Perfiles, tipos de trafico/payload, pesos y metadata `tx_id` implementados; la configuracion base paso dos corridas reportadas en EDA Playground. |
| 3. Driver | FIFO por instancia, colector concurrente y protocolo de `pndng`/`D_pop`/`pop` implementados; ejercitados en `SC_MIXED` y `SC_CONCURRENT`. |
| 4. Generator | Cinco perfiles y constraints de trafico, payload, burst y concurrencia implementados; `SC_MIXED` y `SC_CONCURRENT` validados hasta ahora. |
| 5. Scoreboard y Checker | Conservar Scoreboard como constructor de esperados y Checker como responsable de matching/veredicto; adaptar colas/eventos para transacciones ampliadas. |
| 6. Monitor y Environment | Confirmar muestreo de eventos, conexiones, construccion de componentes y cierre de procesos. |
| 7. Test y TB Top | `+SCENARIO`, `+NUM` y `+SEED` ejercitados; `+NUM=12` sobreescribe el default. Falta repetir una seed para comprobar reproduccion, validar otros perfiles y completar resumen estructurado. |
| 8. Scripts y regresion | Prototipo local de runner/Makefile sin validar; queda en segundo plano hasta validar primero la configuracion EDA Playground. Falta producir resumen agregado con PASS/FAIL por corrida. |
| 9. Documentacion final | Actualizar el plan de pruebas y documentar comandos y resultados medidos. |

## 14. Decisiones pendientes

Antes de fijar las interfaces entre modulos, se deben confirmar:

1. El contrato temporal inicial queda fijado en el nombre actual `delay`: ciclos de espera aplicados por el Driver antes de ofrecer el frente. No se usa `arrival_time` absoluto.
2. El matching exacto cuando hay paquetes identicos de distintas fuentes. El DUT no transporta `tx_id`; el modelo puede comprobar contenido y multiplicidad, pero no reconstruir identidad individual si las observaciones son indistinguibles.
3. Las reglas funcionales definitivas para self-addressed, broadcast e invalid destination, incluyendo la divergencia conocida del parametro `broadcast`.
4. Los valores validos de `BITS`, `DRVRS`, `PCKG_SZ` y `BROADCAST`, y cuales combinaciones se compilaran en regresion.
5. Si se agrega un modo `ALL` para recorrer los cinco perfiles automaticamente.
6. El numero de seeds que ejecutara el script en modo regresion y si se derivaran seeds diferentes por perfil.
7. Los valores por defecto de `NUM`, pesos `dist`, limites de error, verbosidad y margenes del watchdog.
8. Como reportar paquetes que el Driver conserva en su FIFO al cierre y si el backlog constituye siempre `FAIL`.

## 15. Corridas reportadas

La primera corrida de EDA Playground utilizo
`DRVRS=4`, `PCKG_SZ=16`, `BROADCAST=0xFF`, `SCENARIO=SC_MIXED`, `NUM=50` y
`SEED=1`. El log indica `PASS`, 106 eventos correctos, cero errores, cero
esperados pendientes, 123 verificaciones Round Robin sin violaciones y 56
recepciones registradas en CSV.

La segunda corrida utilizo `SCENARIO=SC_CONCURRENT`, `NUM=12` y `SEED=3` con
la misma configuracion estructural. El log indica `PASS`, 26 eventos correctos,
cero errores, cero esperados pendientes, 18 verificaciones Round Robin sin
violaciones y 14 recepciones CSV. Se observaron las cuatro solicitudes iniciales
en el mismo ciclo. Este resultado tambien comprueba que `+NUM` sobrescribe el
default de 50. Aun no se ha repetido una misma seed para validar que la secuencia
aleatoria se reproduzca exactamente.
