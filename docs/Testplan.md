# Guía para el Avance 1 (Test Plan) — Proyecto 1

Es el proceso para que lo construyan ustedes, viendo directamente `fifo.sv` y `Library.sv`. Cada paso trae la pregunta que tienen que contestar.

---

## 0. Qué se pide (5%)

> "Test plan de todas las capacidades del diseño y diagramas mostrando los módulos, interfaces de comunicación entre módulos y formato de los paquetes de comunicación."

Tres cosas, ni más ni menos:
1. **Capacidades del diseño** → qué hace el DUT, en una lista.
2. **Diagramas** → módulos + cómo se conectan.
3. **Formato de paquete** → qué significan los bits que viajan por el bus.


---

## 1. Identifiquen el DUT correcto

El DUT corresponde al módulo bs_gnrtr_n_rbtr de Library.sv. Su nombre, sus parámetros (bits, drvrs, pckg_sz, broadcast) y la declaración de sus puertos como arreglos 2D coinciden exactamente con el prototipo mostrado en la diapositiva

---

## 2. Listen las capacidades leyendo el código.

### 1. Bus de interconexión — `bs_gnrtr_n_rbtr`
 
| Bloque | Función | Qué se prueba |
|---|---|---|
| `bs_gnrtr_n_rbtr` (top) | Replica `bits` buses independientes, cada uno con `drvrs` terminales | Que cada instancia de bus opera de forma aislada de las demás (si `bits>1`) |
| `bs_ntrfs_n_rbtr` (x drvrs) | Interfaz completa de un terminal: serializa, controla, arbitra su turno | Un terminal puede transmitir y recibir de forma independiente |
| `serializer` (srlzr_wt) | Convierte `D_pop` (paralelo) a bit serial hacia el bus | El dato paralelo se transmite bit a bit sin pérdida ni corrupción |
| `serializer` (srlzr_rd) | Convierte el bit serial del bus a `D_push` (paralelo) | El dato recibido se reconstruye igual a como se transmitió |
| `ntrfs_cntrl_n_rbtr` | Cerebro del terminal: decide cuándo leer, cuándo escribir, compara dirección | Orquesta correctamente el ciclo completo de una transacción |
| `Write_st_Mchn` | Máquina de estados de transmisión | Un terminal con `pndng=1` solicita el bus, transmite, y libera el turno al terminar |
| `Read_st_Mchn` | Máquina de estados de recepción | Un terminal desplaza el paquete entrante completo y decide si lo captura (`push`) según dirección |
| `Counter` (count_w, count_r) | Cuenta bits desplazados dentro de una transacción | El conteo llega exactamente a `pckg_sz` sin desfase, marcando fin de paquete |
| `Counter_arb` (uno por terminal) | Contador de turno round-robin distribuido | Los `drvrs` terminales rotan el turno en orden `0,1,2,...,drvrs-1,0,...` |
| `Arbiter_st_Mchn` | Decide cuándo pasar el turno (`trn_chng`) | El turno avanza solo cuando el terminal actual ya no tiene nada que transmitir |
| `tri_buf` (bus, `trn_chng`, `bs_bsy`) | Aislamiento eléctrico de las líneas compartidas | Solo el terminal con `bs_grnt` maneja cada línea; los demás quedan en alta impedancia |
| Sistema completo | Dirección de destino (8 bits altos de `D_in`) | Un paquete es capturado solo por el terminal cuyo `id` coincide |
| Sistema completo | Broadcast (`bdcst`, por defecto `{8{1'b1}}`) | Un paquete con dirección broadcast es capturado por **todos** los terminales |


### 2. FIFOs — `fifo_flops` (de `fifo.sv`)
 
| Bloque | Función | Qué se prueba |
|---|---|---|
| `fifo_flops` (entrada, x drvrs) | FIFO de entrada — almacena lo que el terminal quiere transmitir | Push/pop en orden correcto (FIFO), datos no se pierden ni duplican |
| `fifo_flops` (salida, x drvrs) | FIFO de salida — almacena lo que el terminal recibió del bus | Igual que la de entrada, del lado de recepción |
| `count` (registro interno) | Contador de ocupación de la FIFO | Incrementa en `push`, decrementa en `pop`, se mantiene igual en `push+pop` simultáneo (`2'b11`) |
| `pndng` | Bandera de "hay datos disponibles" | `pndng=0` solo cuando `count==0`; `pndng=1` en cualquier otro caso |
| `full` | Bandera de FIFO llena | `full=1` exactamente cuando `count==depth` |
| Backpressure — FIFO llena | Comportamiento ante `push` con `count==depth` | El `count` se mantiene igual (no crece más allá de `depth`, según el `case` de `count`); confirmar que no se corrompe ni se pierde el contenido existente |
| FIFO vacía | Comportamiento ante `pop` con `count==0` | El `count` se mantiene en 0 (no baja de 0); confirmar que `Dout` no entrega dato basura |
| `prll_d_reg` (registro por posición, dentro de cada etapa de la FIFO) | Desplazamiento del dato en cada `push` (clock del registro = `push`) | El dato avanza una posición por cada `push`, y el `aux_mux`/`aux_mux_or` selecciona correctamente la posición que corresponde a `count` para `Dout` |
| Reset (`rst`) | Estado conocido tras reset | `count` vuelve a 0; `pndng` y `full` reflejan FIFO vacía |

---

## 3. Rastreen el formato del paquete ustedes mismos

Pregunta concreta a responder con el código: **¿qué parte de `D_push`/`D_pop` es dirección y qué parte es dato?**

Pistas de dónde mirar (no la respuesta):
- Busquen dónde se instancia el controlador de interfaz (`ntrfs_cntrl_n_rbtr` o `ntrfs_cntrl`, según cuál DUT eligieron en el paso 1) y qué le conectan al puerto `D_in`.
- Ese puerto `D_in` en la instancia va a estar conectado a un *slice* de `D_push` (ej. `D_push[algo:algo]`). Ese slice es su respuesta.

Repitan el ejercicio para confirmar si esa relación cambia con `pckg_sz`, o si siempre son los mismos bits (altos o bajos) sin importar el tamaño del paquete.

---

## 4. Entiendan el handshake de transmisión/recepción trazando la máquina de estados

Método sugerido:
1. Dibujen el diagrama de estados a mano (3 bits de estado = hasta 8 estados) usando la tabla `case` de next-state de `Read_st_Mchn` y `Write_st_Mchn`.
2. Para cada estado, anoten qué señales de salida están activas (de la tabla de output logic).
3. Ubiquen en qué estado se activa `push` (o `pop`) y en qué estado el dato de salida ya es válido y estable.

Esto es lo que el profe pide como "interfaces de comunicación entre módulos": que entiendan el protocolo, no solo que dibujen cajas conectadas.

---

## 5. Diagrama de bloques (el 5% aparte)

Partan del diagrama del profesor ("El DUT será un bus como el que se muestra a continuación") y agréguenle encima, con otro color, las cajas del testbench: dónde va el generador, el driver, el monitor, el scoreboard, por cada terminal y para el bus. Uno de ustedes lo puede bosquejar en papel/pizarra primero y el otro lo pasa a Draw.io o Lucidchart.

---

## Checklist antes de entregar el avance 1

- [ ] Cada afirmación técnica del documento la puede explicar cualquiera de los dos sin leer el texto, en la demo.
- [ ] El formato de paquete y el DUT elegido están confirmados contra el código, no copiados de una explicación externa.
- [ ] El diagrama tiene el DUT del profesor + testbench superpuesto, hecho por ustedes.
- [ ] La tabla de capacidades cubre todos los submódulos que recorrieron en el paso 2.

---
