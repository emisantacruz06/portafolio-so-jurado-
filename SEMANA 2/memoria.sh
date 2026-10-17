#!/bin/bash
# Deber 2 - Reporte de Hardware en Linux
# Se utilizó como apoyo la IA.

salida="memoria_$(hostname).txt"

{
    echo "REPORTE DE HARDWARE"
    echo "Equipo: $(hostname)"
    echo "Sistema Operativo: $(cat /etc/os-release | grep PRETTY_NAME | cut -d= -f2 | tr -d '\"')"
    echo "Fecha de generación: $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""

    echo "ARQUITECTURA"
    echo "Arquitectura: $(uname -m)"
    lscpu | grep -i 'Byte Order'
    echo ""

    echo "MEMORIA CACHE"
    lscpu --caches
    echo ""

    echo "CONJUNTOS DE LA CACHE L1d"
    echo "Fórmula: S = C / (L * A)"
    echo "Cálculo manual resuelto: S = 32768 / (64 * 8) = 64 conjuntos"
    echo ""

    echo "RAM Y MEMORIA VIRTUAL"
    free -h
    echo ""

    echo "DISCOS FISICOS"
    echo "Nota: En la columna ROTA, 0 significa SSD y 1 significa HDD."
    lsblk -d -o NAME,MODEL,SIZE,ROTA | grep -v loop
    echo ""

    echo "TIEMPOS DE EJECUCION DE MATRIZ"
    if [ -x "./matriz" ]; then
        echo "-> Ejecución normal (por filas):"
        { time ./matriz > /dev/null ; } 2>&1
        echo ""
        echo "-> Ejecución con argumento 'c' (por columnas):"
        { time ./matriz c > /dev/null ; } 2>&1
    else
        echo "No se midieron tiempos: no se encontró el ejecutable ./matriz."
        echo "Recuerda compilar el código en C usando: gcc matriz.c -o matriz"
    fi

} > "$salida"

echo "Reporte generado con éxito en: $salida"