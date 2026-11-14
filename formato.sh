#!/usr/bin/env bash
# Fecha: 13/11/2026
# Uso de IA: Se utilizo IA como apoyo para estructurar las funciones y simplificar las consultas del verificador de entorno.

FECHA=$(date +%F)
EQUIPO=$(hostname -s)
ARCHIVO="verificador_${EQUIPO}_${FECHA}.txt"
HERRAMIENTAS=(git curl python3 jq strace tree)
LISTAS=0
FALTANTES=()

escribir_informe() {
    echo "$1" | tee -a "$ARCHIVO"
}

> "$ARCHIVO"

seccion_1() {
escribir_informe "============================================================"
escribir_informe "SECCION 1. SISTEMA Y SHELL"
escribir_informe "============================================================"
SO=$(grep -E '^PRETTY_NAME=' /etc/os-release | cut -d'"' -f2)
escribir_informe "Sistema Operativo: $SO"
escribir_informe "Kernel: $(uname -r)"
escribir_informe "Version Bash: $BASH_VERSION"
}

seccion_2() {
    escribir_informe ""
    escribir_informe "============================================================"
    escribir_informe "SECCION 2. HERRAMIENTAS REQUERIDAS"
    escribir_informe "============================================================"
    for h in "${HERRAMIENTAS[@]}"; do
        if command -v "$h" >/dev/null 2>&1; then
            ver=$("$h" --version 2>&1 | head -n 1)
            escribir_informe "[OK]    $h -> $ver"
            ((LISTAS++))
        else
            escribir_informe "[FALTA] $h"
            FALTANTES+=("$h")
        fi
    done
}

seccion_3() {
    escribir_informe ""
    escribir_informe "============================================================"
    escribir_informe "SECCION 3. PAQUETES Y ORIGENES"
    escribir_informe "============================================================"
    TOTAL_PAQ=$(rpm -qa | wc -l)
    escribir_informe "Total de paquetes instalados: $TOTAL_PAQ"
    escribir_informe "Repositorios activos:"
    dnf repolist 2>&1 | while IFS= read -r linea; do escribir_informe "  $linea"; done
    escribir_informe "Origen de herramientas:"
    for h in "${HERRAMIENTAS[@]}"; do
        ruta=$(command -v "$h" 2>/dev/null)
        if [ -n "$ruta" ]; then
            paq=$(rpm -qf "$ruta" 2>/dev/null)
            escribir_informe "  $h -> $paq"
        fi
    done
}

seccion_4() {
    escribir_informe ""
    escribir_informe "============================================================"
    escribir_informe "SECCION 4. ULTIMAS 5 INSTALACIONES"
    escribir_informe "============================================================"
    dnf history list 2>&1 | head -n 7 | while IFS= read -r linea; do escribir_informe "  $linea"; done
}

seccion_5() {
    escribir_informe ""
    escribir_informe "============================================================"
    escribir_informe "SECCION 5. QUE FALTA Y COMO INSTALARLO"
    escribir_informe "============================================================"
    if [ ${#FALTANTES[@]} -eq 0 ]; then
        escribir_informe "No falta ninguna herramienta."
    else
        escribir_informe "Comando para instalar: sudo dnf install -y ${FALTANTES[*]}"
    fi
}

seccion_6() {
    escribir_informe ""
    escribir_informe "============================================================"
    escribir_informe "SECCION 6. RESULTADO Y CODIGO DE SALIDA"
    escribir_informe "============================================================"
    TOTAL=${#HERRAMIENTAS[@]}
    escribir_informe "Herramientas listas: $LISTAS de $TOTAL"
    escribir_informe "Informe guardado en: $ARCHIVO"
    if [ "$LISTAS" -eq "$TOTAL" ]; then
escribir_informe "Resultado: COMPLETO (codigo 0)"
return 0
else
escribir_informe "Resultado: INCOMPLETO (codigo 1)"
return 1
    fi
}

seccion_1
seccion_2
seccion_3
seccion_4
seccion_5
seccion_6
exit $?