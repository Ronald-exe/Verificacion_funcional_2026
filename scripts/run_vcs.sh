#!/bin/bash

# Cargar variables de entorno de Synopsys
source /mnt/vol_NFS_rh003/estudiantes/archivos_config/synopsys_tools2.sh

# Asegurar que estamos parados en la carpeta sim/
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CD_SIM="$(dirname "$SCRIPT_DIR")/sim"
cd "$CD_SIM" || exit 1

echo "Compilando con VCS desde: $(pwd)"

vcs -Mupdate \
    -f files.f \
    -o salida \
    -full64 \
    -sverilog \
    -kdb \
    -lca \
    -debug_acc+all \
    -debug_region+cell+encrypt \
    -l log_test \
    +lint=TFIPC-L \
    -top testbench

if [ $? -eq 0 ]; then
    echo "Compilación exitosa. Ejecutando simulación... "
    ./salida -l log_simulacion.log
else
    echo "ERROR: Falló la compilación. Revisa log_test"
fi
