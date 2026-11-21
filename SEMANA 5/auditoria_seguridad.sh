
#!/usr/bin/env bash
# =============================================================================
# Deber 5 - Auditoria de seguridad del equipo (Linux)
# Sistemas Operativos - EPN - Semana 5
# -----------------------------------------------------------------------------
# Autores: Emily Jurado
# Fecha: 2026-11-20
# Uso de IA: Se utilizo IA generativa para apoyar la elaboracion,
# revision y correccion del codigo.
# -----------------------------------------------------------------------------
# Sistema de referencia: Ubuntu 26.04.1 LTS
# Equipo: emi-VirtualBox
# =============================================================================

set -u
export LC_ALL=C

UMBRAL=5
MUESTRA=""
RIESGOSAS=(21 23 3306 3389 5900)
declare -A ESTADO

while getopts "u:m:h" op; do
    case "$op" in
        u) UMBRAL="$OPTARG" ;;
        m) MUESTRA="$OPTARG" ;;
        h)
            echo "Uso: $0 [-u UMBRAL] [-m ARCHIVO_MUESTRA]"
            exit 0
            ;;
        *)
            echo "Uso: $0 [-u UMBRAL] [-m ARCHIVO_MUESTRA]"
            exit 2
            ;;
    esac
done

EQUIPO="$(hostname -s 2>/dev/null || echo equipo)"
SALIDA="auditoria_${EQUIPO}_$(date +%Y%m%d_%H%M).txt"

titulo() {
    printf '\n=== %s ===\n' "$1"
}

marca() {
    ESTADO["$1"]="$2"
    echo "-> Seccion $1: $2"
}

# --- 1. Llavero maestro ----------------------------------

seccion1() {
    titulo "1 - Llavero maestro"

    echo "Cuentas con UID 0:"
    awk -F: '$3 == 0 {print "  " $1}' /etc/passwd

    echo "Miembros de wheel:"
    wheel=$(getent group wheel | cut -d: -f4)
    if [[ -n "$wheel" ]]; then
        echo "  $wheel"
    else
        echo "  No existe el grupo wheel o no tiene miembros"
    fi

    echo "Miembros de sudo:"
    sudo_group=$(getent group sudo | cut -d: -f4)
    if [[ -n "$sudo_group" ]]; then
        echo "  $sudo_group"
    else
        echo "  No hay miembros registrados en sudo"
    fi

    cuentas=$(awk -F: '$3 == 0 && $1 != "root" {print $1}' /etc/passwd)

    if [[ -n "$cuentas" ]]; then
        echo "ALERTA: existen cuentas adicionales con UID 0"
        marca 1 ALERTA
    else
        echo "No existen cuentas adicionales con UID 0"
        marca 1 OK
    fi
}

# --- 2. Puertas abiertas ---------------------------------

seccion2() {
    titulo "2 - Puertas abiertas"

    alerta=0

    while read -r direccion; do
        [[ -z "$direccion" ]] && continue

        puerto="${direccion##*:}"

        if [[ "$direccion" == 127.* ||
              "$direccion" == "::1:"* ||
              "$direccion" == "[::1]:"* ]]; then
            tipo="solo el equipo"
        else
            tipo="abierta a la red"
        fi

        echo "Puerto $puerto - Direccion $direccion - $tipo"

        if [[ "$tipo" == "abierta a la red" ]]; then
            for riesgo in "${RIESGOSAS[@]}"; do
                if [[ "$puerto" == "$riesgo" ]]; then
                    alerta=1
                fi
            done
        fi
    done < <(ss -H -tln | awk '{print $4}' | sort -u)

    if [[ "$alerta" -eq 1 ]]; then
        marca 2 ALERTA
    else
        marca 2 OK
    fi
}

# --- 3. Portero activo -----------------------------------

seccion3() {
    titulo "3 - Portero activo"

    if systemctl is-active --quiet firewalld; then
        echo "firewalld: activo"
        marca 3 OK
    else
        echo "firewalld: inactivo o no instalado"

        if command -v ufw >/dev/null 2>&1; then
            echo "Estado de UFW:"
            ufw status 2>&1
        fi

        marca 3 ALERTA
    fi
}

# --- 4. Intentos fallidos -------------------------------

seccion4() {
    titulo "4 - Intentos fallidos (umbral: $UMBRAL por IP)"

    if [[ -n "$MUESTRA" ]]; then
        if [[ -f "$MUESTRA" ]]; then
            registros=$(grep 'Failed password' "$MUESTRA" || true)
        else
            echo "No se encontro el archivo de muestra: $MUESTRA"
            marca 4 ALERTA
            return
        fi
    else
        registros=$(journalctl -q --since "24 hours ago" \
            -u ssh -u sshd 2>/dev/null | grep 'Failed password' || true)
    fi

    if [[ -z "$registros" ]]; then
        echo "No se encontraron intentos fallidos."
        marca 4 OK
        return
    fi

    conteos=$(printf '%s\n' "$registros" |
        awk '{for(i=1;i<=NF;i++) if($i=="from") print $(i+1)}' |
        sort | uniq -c | sort -rn)

    alerta=0

    if [[ -z "$conteos" ]]; then
        echo "No se encontraron direcciones IP."
        marca 4 OK
        return
    fi

    echo "Intentos fallidos por IP:"
    echo "$conteos"

    while read -r cantidad ip; do
        [[ -z "${cantidad:-}" ]] && continue

        if (( cantidad >= UMBRAL )); then
            alerta=1
        fi
    done <<< "$conteos"

    if [[ "$alerta" -eq 1 ]]; then
        marca 4 ALERTA
    else
        marca 4 OK
    fi
}

# --- 5. Veredicto ---------------------------------------

seccion5() {
    titulo "5 - Veredicto"

    alertas=0

    for n in 1 2 3 4; do
        resultado="${ESTADO[$n]:-ALERTA}"
        echo "Seccion $n: $resultado"

        if [[ "$resultado" == "ALERTA" ]]; then
            ((alertas+=1))
        fi
    done

    if (( alertas == 0 )); then
        echo "Resultado general: OK (sin alertas detectadas)."
        return 0
    else
        echo "Resultado general: ALERTA ($alertas secciones con problemas)."
        return 1
    fi
}

# --- Programa principal ---------------------------------

principal() {
    echo "Auditoria de seguridad - $EQUIPO - $(date '+%Y-%m-%d %H:%M')"

    seccion1
    seccion2
    seccion3
    seccion4
    seccion5
}

principal > >(tee "$SALIDA")
codigo=$?

echo
echo "Informe guardado en: $SALIDA"

exit "$codigo"
