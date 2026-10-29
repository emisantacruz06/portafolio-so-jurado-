

#!/bin/bash
# ============================================================
# Informe de arranque - Sistemas Operativos
# Autores: Dilan Agila y Emily Jurado
# Fecha: 28/10/2026
# Uso de IA: Se utilizó IA como apoyo para comprender,
# elaborar y revisar el script.
# ============================================================

equipo=$(hostname)
fecha=$(date +%Y%m%d_%H%M%S)
archivo="informe_arranque_${equipo}_${fecha}.txt"

# Imprime en pantalla y guarda en el archivo.
seccion() {
    echo
    echo "=== $1 ==="
    echo "=== $1 ===" >> "$archivo"
}

dato() {
    echo "$1"
    echo "$1" >> "$archivo"
}

# 1. Sistema operativo, versión y núcleo
seccion "1. Sistema operativo, versión y núcleo"

if [ -r /etc/os-release ]; then
    . /etc/os-release
    dato "Sistema: ${PRETTY_NAME:-No disponible}"
else
    dato "Aviso: no se pudo leer /etc/os-release."
fi

dato "Núcleo: $(uname -r)"
dato "Arquitectura: $(uname -m)"

# 2. Último arranque y tiempo encendido
seccion "2. Último arranque y tiempo encendido"

if command -v uptime >/dev/null 2>&1; then
    dato "Arrancó: $(uptime -s 2>/dev/null || echo 'No disponible')"
    dato "Encendida: $(uptime -p 2>/dev/null || echo 'No disponible')"
else
    dato "Aviso: el comando uptime no está disponible."
fi

# 3. Desglose del arranque
seccion "3. Desglose del arranque (systemd-analyze)"

if command -v systemd-analyze >/dev/null 2>&1; then
    resultado=$(systemd-analyze time 2>&1)
    dato "$resultado"
else
    dato "Aviso: systemd-analyze no está disponible."
fi

# 4. Cinco unidades más lentas
seccion "4. Cinco unidades más lentas (blame)"

if command -v systemd-analyze >/dev/null 2>&1; then
    resultado=$(systemd-analyze blame --no-pager 2>&1 | head -n 5)
    dato "$resultado"
else
    dato "Aviso: no se puede consultar systemd-analyze."
fi

# 5. Módulos del núcleo
seccion "5. Módulos del núcleo"

if command -v lsmod >/dev/null 2>&1; then
    total=$(lsmod 2>/dev/null | tail -n +2 | wc -l)
    dato "Total de módulos cargados: $total"
    dato "Cinco módulos de mayor tamaño (bytes):"

    lsmod 2>/dev/null | awk 'NR > 1 {print $2, $1}' |
        sort -nr | head -n 5 |
        while read -r tam nombre; do
            dato "$nombre: $tam bytes"
        done
else
    dato "Aviso: el comando lsmod no está disponible."
fi

# 6. Cierre y estado de servicios fallidos
seccion "6. Cierre"

if command -v systemctl >/dev/null 2>&1; then
    dato "Objetivo predeterminado:"
    dato "$(systemctl get-default 2>&1)"

    dato "Unidades fallidas:"
    resultado=$(systemctl --failed --no-pager 2>&1)
    dato "$resultado"
else
    dato "Aviso: systemctl no está disponible."
fi

echo
echo "Informe guardado en: $archivo"
