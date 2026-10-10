#!/usr/bin/env bash
# inventario.sh - Semana 1
# Nota: Este script fue realizado con asistencia de IA.

salida="inventario_$(hostname).txt"

{
    echo "=== DATOS DEL EQUIPO ==="
    echo "Host: $(hostname)"
    echo "Fecha: $(date)"
    echo "SO: $(. /etc/os-release 2>/dev/null; echo $PRETTY_NAME || uname -sr)"
    echo ""

    echo "=== CPU ==="
    lscpu | grep -E 'Model name|Nombre del modelo|CPU\(s\)|Thread\(s\) per core|Core\(s\) per socket'
    echo ""

    echo "=== RAM ==="
    free -h
    echo ""

    echo "=== DISCOS ==="
    lsblk -d -o NAME,TYPE,SIZE,MODEL 2>/dev/null || lsblk -d -o NAME,TYPE,SIZE
    echo ""

    echo "=== RED ==="
    ip -o -4 addr show | awk '{print "Interfaz: " $2 " | IP: " $4}' 2>/dev/null || ifconfig
} > "$salida"

echo "Reporte listo en: $salida"