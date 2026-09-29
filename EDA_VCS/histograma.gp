#==============================================================================
# histograma.gp - Histograma de retardos de paquetes (pop -> push)
#------------------------------------------------------------------------------
# Lee el CSV que genera el Checker (reporte_paquetes.csv) y dibuja la
# distribución de la columna retardo_ns.
#
# Formato del CSV (una fila por paquete recibido; un broadcast genera una fila
# por cada interfaz que lo recibe):
#   t_envio_ns,origen,destino,t_recepcion_ns,retardo_ns,tipo,paquete
#
# Uso:
#   gnuplot histograma.gp
#   gnuplot -e "archivo='otra_corrida.csv'; ancho=100" histograma.gp
#
# Variables opcionales:
#   archivo - CSV de entrada           (default: reporte_paquetes.csv)
#   salida  - imagen de salida         (default: histograma_retardos.png)
#   ancho   - ancho de cada barra (ns) (default: 50)
#==============================================================================

if (!exists("archivo")) archivo = "reporte_paquetes.csv"
if (!exists("salida"))  salida  = "histograma_retardos.png"
if (!exists("ancho"))   ancho   = 50

set datafile separator ","

# Estadísticas de la columna 5 (retardo_ns), saltando el encabezado
stats archivo every ::1 using 5 nooutput name "R"

set terminal pngcairo size 1000,600 enhanced font "Arial,11"
set output salida

set title sprintf("Histograma de retardos pop -> push  (N=%d, min=%d ns, max=%d ns, prom=%.1f ns)", \
                  R_records, R_min, R_max, R_mean)
set xlabel "Retardo (ns)"
set ylabel "Cantidad de paquetes"
set grid ytics
set key off
set style fill solid 0.7 border -1
set boxwidth ancho * 0.9

# Agrupa cada retardo en su intervalo [k*ancho, (k+1)*ancho) y cuenta
bin(x) = ancho * floor(x / ancho) + ancho / 2.0

plot archivo every ::1 using (bin($5)):(1.0) smooth frequency with boxes lc rgb "#3b75af"

print sprintf("Histograma generado: %s  (%d paquetes)", salida, R_records)
