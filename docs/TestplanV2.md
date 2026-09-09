# PLAN DE VERIFICACIÓN: `bs_gnrtr_n_rbtr`

---

## 1. MÓDULO BAJO PRUEBA (DUT)

### 1.1 Identificación del DUT
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

### 1.2 Jerarquía interna
```
bs_gnrtr_n_rbtr
├── bs_ntrfs_n_rbtr [0] (ID=0)
│   ├── ntrfs_cntrl_n_rbtr
│   │   ├── Write_st_Mchn
│   │   ├── Read_st_Mchn
│   │   ├── Counter_arb
│   │   └── Contadores (TX/RX)
│   ├── serializer TX
│   └── serializer RX
├── bs_ntrfs_n_rbtr [1] (ID=1)
│   └── (misma estructura)
├── bs_ntrfs_n_rbtr [2] (ID=2)
│   └── (misma estructura)
└── bs_ntrfs_n_rbtr [3] (ID=3)
    └── (misma estructura)
```

---

## 2. INTERFACES EXTERNA E INTERNA

### 2.1 Interfaz externa (puertos del DUT)

| Señal | Dirección | Ancho | Descripción |
|-------|-----------|-------|-------------|
| `clk` | Input | 1 | Reloj del sistema |
| `reset` | Input | 1 | Reset asíncrono/síncrono |
| `pndng[i]` | Input | 1 por driver | Indica paquete pendiente en driver `i` |
| `D_pop[i]` | Input | `pckg_sz` por driver | Paquete a transmitir desde driver `i` |
| `pop[i]` | Output | 1 por driver | Confirma extracción del paquete del driver `i` |
| `push[i]` | Output | 1 por driver | Indica recepción de paquete en driver `i` |
| `D_push[i]` | Output | `pckg_sz` por driver | Paquete recibido por driver `i` |

### 2.2 Interfaz interna (entre módulos del DUT)

| Señal | Origen | Destino | Descripción |
|-------|--------|---------|-------------|
| `bus[bits-1:0]` | Todos los drivers | Todos los drivers | Línea serial compartida (tristate) |
| `bs_bsy[bits-1:0]` | Cada driver | Todos los drivers | Indica ocupación del bus |
| `trn_chng[bits-1:0]` | Cada driver | Todos los drivers | Evento de cambio de turno |
| `bs_grnt` | Cada driver | Serializer TX | Permiso para transmitir en el bus |

**Nota**: Las señales internas `bus`, `bs_bsy` y `trn_chng` NO son puertos del DUT. Solo son observables jerárquicamente para depuración.

---

## 3. SEÑALES INTERNAS DE DEPURACIÓN

| Señal | Jerarquía | Descripción | Uso en verificación |
|-------|-----------|-------------|---------------------|
| `bus` | `dut.bus[0]` | Línea serial compartida | **Opcional**: Monitoreo para depuración |
| `bs_bsy` | `dut.bs_bsy[0]` | Ocupación del bus | **Opcional**: Verificar exclusividad |
| `trn_chng` | `dut.trn_chng[0]` | Evento de cambio de turno | **Opcional**: Seguimiento de arbitraje |
| `tx_enable` | `dut.bs_ntrfs_n_rbtr[i].bs_grnt` | Habilitación de transmisión | **Opcional**: Verificar contención |
| `Write_st_Mchn` | `dut.bs_ntrfs_n_rbtr[i].ntrfs_cntrl.Write_st_Mchn.state` | Estado de máquina TX | **Depuración**: Seguimiento de FSM |
| `Read_st_Mchn` | `dut.bs_ntrfs_n_rbtr[i].ntrfs_cntrl.Read_st_Mchn.state` | Estado de máquina RX | **Depuración**: Seguimiento de FSM |

**Política de uso**:
- Las señales internas **NO** se usan para la verificación funcional principal.
- Se utilizan **SOLO** para depuración cuando falla una prueba.
- El scoreboard se basa **EXCLUSIVAMENTE** en puertos externos (`pop`, `push`, `D_pop`, `D_push`).

---

## 4. PARÁMETROS DE VERIFICACIÓN

### 4.1 Parámetros del DUT

| Parámetro | Valor en DUT | Valores a probar | Nota |
|-----------|--------------|------------------|------|
| `bits` | 1 | Fijo = 1 | Bus serial único |
| `drvrs` | 4 | 4 (principal), 2, 8 | Verificar generación de turnos |
| `pckg_sz` | 16 | 9, 16, 32, 64 | 9 es mínimo (1 bit payload) |
| `broadcast` | 8'hFF | 8'hFF, 8'hAA, 8'h00, 8'h01 | Probar distintos valores |

### 4.2 Matriz de regresión

| Configuración | drvrs | pckg_sz | broadcast | Semillas | Prioridad |
|---------------|-------|---------|-----------|----------|-----------|
| Principal | 4 | 16 | 8'hFF | 100 | Alta |
| Mínimo | 4 | 9 | 8'hFF | 50 | Alta |
| Máximo | 4 | 64 | 8'hFF | 50 | Media |
| Broadcast personalizado | 4 | 16 | 8'hAA | 50 | Media |
| drvrs=2 | 2 | 16 | 8'hFF | 30 | Baja |
| drvrs=8 | 8 | 16 | 8'hFF | 30 | Baja |

**Criterio**: La configuración principal (drvrs=4, pckg_sz=16) es obligatoria con 100 semillas. Las demás configuraciones son regresión secundaria.

---

## 5. FORMATO DEL PAQUETE

### 5.1 Estructura del paquete

```
[pckg_sz-1 : pckg_sz-8] [pckg_sz-9 : 0]
|       ID destino       |      Payload      |
```

**Ejemplo** (`pckg_sz = 16`):
```
[15:8] = ID destino (8 bits)
[7:0]  = Payload (8 bits)
```

### 5.2 Tipos de direccionamiento

| Tipo | Condición | Comportamiento esperado |
|------|-----------|------------------------|
| **Unicast válido** | `0 ≤ ID < drvrs` | Solo el driver con `ntrfs_id == ID` hace `push` |
| **Broadcast** | `ID == broadcast` (RTL: `8'hFF`) | **Todos** los drivers hacen `push` |
| **ID inválido** | `ID ≥ drvrs` y `ID ≠ broadcast` | **Ningún** driver hace `push` |

**Nota sobre el RTL**: El código actual compara el ID destino con `{8{1'b1}}` (8'hFF), no con el parámetro `broadcast`. Esto debe verificarse:

| Prueba | Estímulo | Esperado (según parámetro) | Real (RTL actual) |
|--------|----------|---------------------------|-------------------|
| `broadcast=8'hAA` | Enviar ID=8'hAA | Todos los drivers hacen `push` | **Ninguno** hace `push` (falla) |
| `broadcast=8'hAA` | Enviar ID=8'hFF | Ninguno hace `push` | **Todos** hacen `push` (falla) |

---

## 6. ESTRATEGIA DE ALEATORIZACIÓN

### 6.1 Variables aleatorias por transacción

Cada driver `i` genera transacciones con:

| Variable | Rango / Valores | Descripción |
|----------|-----------------|-------------|
| `ID_origen` | Fijo = `i` | Identificador del driver emisor |
| `ID_destino` | `{0..drvrs-1, broadcast, inválido}` | Destino del paquete |
| `payload` | Aleatorio de `pckg_sz-8` bits | Datos útiles |
| `pndng_initial` | `{0, 1}` | Estado inicial de `pndng` |
| `delay_before_request` | `0..100` ciclos | Tiempo antes de activar `pndng` |
| `pndng_duration` | `1 ciclo`, `varios ciclos`, `hasta pop` | Duración de la solicitud |

### 6.2 Escenarios de tráfico a mezclar

| Escenario | Descripción | Frecuencia |
|-----------|-------------|------------|
| Tráfico aislado | Un solo driver transmite | 20% |
| Tráfico simultáneo | Múltiples drivers con `pndng=1` | 40% |
| Todos activos | Los 4 drivers con `pndng=1` | 15% |
| Todos idle | Ningún driver con `pndng=1` | 10% |
| Back-to-back | Un driver envía paquetes consecutivos | 10% |
| Cancelación | `pndng` se desactiva antes de `pop` | 5% |

### 6.3 Mezcla de tipos de destino

| Tipo de destino | Porcentaje | Nota |
|-----------------|------------|------|
| Unicast válido | 50% | ID en `[0..drvrs-1]` |
| Broadcast | 25% | ID == broadcast |
| Inválido | 25% | ID ≥ drvrs y ≠ broadcast |

### 6.4 Gestión de semillas

- Cada prueba usa una **semilla reproducible**.
- Ejecutar **100 semillas** en la configuración principal.
- Reportar semillas que encontraron bugs.
- Ejemplo de comando: `simv +ntb_random_seed=<seed>`

### 6.5 Restricciones de aleatorización

```systemverilog
// Restricciones para la generación de transacciones
constraint c_traffic {
  // Destino válido vs inválido
  dest_id inside {[0:drvrs-1], broadcast, invalid};
  invalid > drvrs;
  
  // Payload aleatorio
  payload dist {
    [0:(2**(pckg_sz-8)-1)] :/ 95,  // Aleatorio normal
    0                           :/ 2,   // Todo ceros
    -1                          :/ 2,   // Todo unos
    'hAAAA...                   :/ 1    // Patrón alternante
  };
  
  // Duración de pndng
  if (pndng_initial == 1) {
    pndng_duration inside {[1:10]};  // 1-10 ciclos
  }
}
```

---

## 7. ARQUITECTURA DEL AMBIENTE DE VERIFICACIÓN

### 7.1 Espacio de módulos

El ambiente de verificación consta de los siguientes módulos:

```

```

### 7.2 Interfaces de comunicación entre módulos

| Interfaz | Desde | Hacia | Datos transmitidos |
|----------|-------|-------|-------------------|
| `tx_agent` | Generador | Driver | Transacción (ID_destino, payload, duración) |
| `driver_dut` | Driver | DUT | `pndng`, `D_pop` |
| `dut_monitor` | DUT | Monitor | `pop`, `push`, `D_pop`, `D_push` |
| `monitor_scoreboard` | Monitor | Scoreboard | Eventos `pop` y `push` con datos |
| `scoreboard_reporter` | Scoreboard | Reporte | Errores, estadísticas, resultados |

### 7.3 Flujo de datos

1. **Generador** produce transacciones aleatorias según estrategia definida.
2. **Driver** aplica estímulos al DUT (`pndng` y `D_pop`).
3. **Monitor** captura eventos de salida (`pop`, `push`, `D_pop`, `D_push`).
4. **Scoreboard** valida la integridad de extremo a extremo.
5. **Coverage Collector** mide métricas de cobertura funcional.

---

## 8. CASOS DE PRUEBA DIRIGIDOS Y CASOS ESQUINA

### 8.1 Casos de reset

| # | Caso | Estímulo | Resultado esperado | Qué se verifica |
|---|------|----------|-------------------|-----------------|
| 1 | Reset inicial | Activar `reset` al inicio | `pop=0`, `push=0` | Inicialización de FSM y salidas |
| 14 | Reset durante TX | Activar `reset` durante transmisión | Recuperación a estado conocido | Robustez ante reset asíncrono |
| 15 | Reset durante cambio de turno | Activar `reset` en momento de `trn_chng` | Contador de arbitraje reiniciado | Integridad del contador |

### 8.2 Casos de transmisión

| # | Caso | Estímulo | Resultado esperado | Qué se verifica |
|---|------|----------|-------------------|-----------------|
| 2 | Un solo driver transmite | `pndng[0]=1` | `pop[0]=1`, transmisión completa | Flujo básico TX |
| 3 | Todos los drivers individuales | Cada driver transmite por separado | Cada `pop[i]` ocurre cuando corresponde | Cada driver accede al bus |
| 11 | Back-to-back | Mismo driver con `pndng` consecutivo | Múltiples `pop` sin pérdida | Cola de solicitudes |

### 8.3 Casos de recepción

| # | Caso | Estímulo | Resultado esperado | Qué se verifica |
|---|------|----------|-------------------|-----------------|
| 4 | Unicast a cada ID | Enviar paquete con ID=0,1,2,3 | `push` solo en el driver destino | Direccionamiento exacto |
| 5 | ID inválido | Enviar paquete con ID=4 (drvrs=4) | Ningún `push` | Filtrado de destinos inválidos |
| 6 | Broadcast | Enviar paquete con ID=8'hFF | `push` en todos los drivers | Recepción múltiple |

### 8.4 Casos de arbitraje

| # | Caso | Estímulo | Resultado esperado | Qué se verifica |
|---|------|----------|-------------------|-----------------|
| 8 | Dos drivers simultáneos | `pndng[0]=1`, `pndng[1]=1` | Acceso orden round-robin | Exclusividad de acceso |
| 9 | Cuatro drivers simultáneos | `pndng[0:3]=1` | Todos acceden sin starvation | Fairness y no bloqueo |
| 10 | Todos idle | `pndng=0` en todos | Token rota sin bloqueos | Comportamiento en reposo |

### 8.5 Casos de broadcast y parámetros

| # | Caso | Estímulo | Resultado esperado | Qué se verifica |
|---|------|----------|-------------------|-----------------|
| 7 | Broadcasts consecutivos | Múltiples paquetes broadcast seguidos | Cada broadcast recibido por todos | Múltiple broadcast |
| 12 | Mezcla unicast/broadcast | Alternar destinos | Cada paquete llega a los receptores correctos | Conmutación de modo |
| 16 | pckg_sz variable | Probar 9, 16, 32, 64 | ID y payload separados correctamente | Tamaños de paquete |
| 17 | broadcast personalizado | Probar 8'hAA, 8'h00, 8'h01 | Comportamiento según parámetro | Parametrización |

### 8.6 Casos de cancelación y borde

| # | Caso | Estímulo | Resultado esperado | Qué se verifica |
|---|------|----------|-------------------|-----------------|
| 13 | Cancelación de `pndng` | `pndng=1`, luego `pndng=0` antes de `pop` | Solicitud cancelada o ignorada | Manejo de cancelación |
| 18 | Paquete todo ceros | `D_pop=0` | Recepción correcta de ceros | Datos mínimos |
| 19 | Paquete todo unos | `D_pop=-1` | Recepción correcta de unos | Datos máximos |
| 20 | Patrones alternantes | `payload=1010...` y `0101...` | Detección de errores de bit | Integridad de bits |
| 21 | pckg_sz mínimo | `pckg_sz=9` (1 bit payload) | Funcionamiento correcto | Límite inferior |
| 22 | Caracterización temporal | Medir `pop→bus→push` | Documentar latencias | Comportamiento temporal |


---

## 9. RESUMEN DE ERRORES QUE SE BUSCAN EN CADA CASO

| Categoría | Casos | Error buscado | Enfoque de verificación |
|-----------|-------|---------------|------------------------|
| **Reset** | 1, 14, 15 | Estados colgados, salidas inválidas, contadores corruptos | Verificar estado conocido post-reset |
| **Transmisión** | 2, 3, 11 | Pérdida de paquetes, `pop` sin `pndng`, datos corruptos | Seguimiento de `pop` y datos |
| **Recepción** | 4, 5, 6 | `push` en driver incorrecto, pérdida de broadcast, datos corruptos | Validación de destinatarios y datos |
| **Arbitraje** | 8, 9, 10 | Contención, starvation, deadlock, token perdido | Verificar exclusividad y fairness |
| **Parámetros** | 16, 17 | Mala separación ID/payload, broadcast no configurable | Probar límites y valores extremos |
| **Cancelación** | 13 | Comportamiento indefinido, pérdida de estado | Manejo de solicitudes canceladas |
| **Datos extremos** | 18, 19, 20 | Errores de bit, corrupción de datos | Patrones conocidos y límites |
| **Temporales** | 22 | Latencias inesperadas, timeout incorrecto | Medición y documentación |

---


