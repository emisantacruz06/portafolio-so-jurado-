# Semana 5: Mecanismos de Seguridad (Puertos, Cortafuegos, Privilegios y Bitácoras)

**Asignatura:** Sistemas Operativos  
**Docente:** Rubén Rumipamba, Ph.D.  
**Integrantes:** Emily Jurado y Dilan Agila  
**Paralelo:** GR1  
**Fecha:** 16/11/2026  

---

## Descripción General

En esta semana se abordaron los mecanismos fundamentales de seguridad del sistema operativo en **Linux (AlmaLinux / Ubuntu)** y **Windows (PowerShell)**:
1. **Guardias en la puerta (Taller 1):** Inspección de puertos en escucha, gestión de reglas y políticas del cortafuegos (`firewalld` / `nftables` y `Windows Defender Firewall` / `WFP`), comportamiento de `DROP` frente a `REJECT`, y análisis de bitácoras para detección de intrusiones (IDS manual).
2. **Las llaves de la casa (Taller 2):** Identidad de usuarios y grupos (`UID`/`GID` vs `SID`), control de acceso y privilegios (`sudoers`, `wheel` y `UAC` / nivel de integridad), registro de uso de privilegios y scripts de auditoría de seguridad.

---

## 1. Taller 1: Guardias en la Puerta (Puertos, Cortafuegos y Bitácoras)

### Tabla Comparativa: Puertas Abiertas (Puertos y Servicios)

| Acción | Linux (Bash) | Windows (PowerShell) | Concepto |
| :--- | :--- | :--- | :--- |
| **Ver puertos TCP en escucha** | `ss -tln` | `Get-NetTCPConnection -State Listen` | Lista puertos abiertos esperando conexiones (`0.0.0.0` = red/calle, `127.0.0.1` = local). |
| **Identificar proceso por puerto** | `sudo ss -tlnp` | `Get-NetTCPConnection -State Listen -LocalPort <PUERTO>`<br>`Get-Process -Id <PID>` | Asocia cada puerto abierto con el servicio o programa que lo atiende. |
| **Levantar servidor HTTP de prueba** | `python3 -m http.server 8080 &>/dev/null &` | `python -m http.server 8080` | Crea un servicio en escucha temporal para pruebas de conectividad. |
| **Probar conexión y medir tiempo** | `time curl -s -o /dev/null -m 5 http://127.0.0.1:8080 ; echo $?` | `curl.exe -s -o NUL -m 5 http://127.0.0.1:8080 ; $LASTEXITCODE` | Evalúa respuesta: `0` (OK), `28` (Timeout / `DROP`), `7` (Rechazo / `REJECT`). |

### Tabla Comparativa: El Portero (Cortafuegos del SO)

| Acción | Linux (Bash) | Windows (PowerShell) | Concepto |
| :--- | :--- | :--- | :--- |
| **Verificar estado del cortafuegos** | `sudo firewall-cmd --state` | `Get-NetFirewallProfile \| Select Name, Enabled, DefaultInboundAction` | Comprueba si el servicio del firewall está activo y su política por defecto. |
| **Ver zonas y reglas activas** | `sudo firewall-cmd --get-active-zones`<br>`sudo firewall-cmd --list-all` | `Get-NetFirewallRule -Enabled True -Direction Inbound` | Muestra perfiles/zonas y servicios permitidos. |
| **Verificar servicios del motor** | `systemctl status firewalld` | `Get-Service mpssvc, BFE` | `mpssvc` (Firewall Defender) y `BFE` (Motor de filtrado de base WFP). |
| **Inspeccionar el motor interno** | `sudo nft list tables`<br>`sudo nft list table inet firewalld` | `netsh wfp show filters` | Muestra las tablas de `nftables` o filtros `WFP` generados en el núcleo. |
| **Bloquear puerto (DROP)** | `sudo nft add rule inet taller entrada tcp dport 8080 drop` | `New-NetFirewallRule -DisplayName 'Taller5' -Direction Inbound -Protocol TCP -LocalPort 8080 -Action Block` | Descarta paquetes en silencio (genera *timeout* al cliente). |
| **Rechazar puerto (REJECT)** | `sudo nft add rule inet taller entrada tcp dport 8080 reject with tcp reset` | *(No nativo en regla simple de Windows Firewall)* | Responde inmediatamente rechazando la conexión (`TCP Reset`). |
| **Eliminar reglas / limpiar tabla** | `sudo nft flush chain inet taller entrada`<br>`sudo nft delete table inet taller` | `Remove-NetFirewallRule -DisplayName 'Taller5'` | Restaura el estado original eliminando reglas temporales. |

### Tabla Comparativa: Bitácoras e IDS Manual

| Acción | Linux (Bash) | Windows (PowerShell) | Concepto |
| :--- | :--- | :--- | :--- |
| **Consultar intentos fallidos** | `journalctl -u sshd --since '10 min ago' \| grep -E 'Failed\|Invalid'` | `Get-WinEvent -FilterHashtable @{LogName='Security'; Id=4625} -MaxEvents 5` | Filtra registros de autenticación fallida (SSH en Linux, Evento `4625` en Windows). |
| **Contar fallos por IP** | `journalctl -u sshd \| grep 'Failed password' \| awk '{for(i=1;i<=NF;i++) if($i=="from") print $(i+1)}' \| sort \| uniq -c \| sort -rn` | `$ev \| Where-Object Id -eq '4625' \| Group-Object IpAddress \| Sort-Object Count -Descending` | Agrupa y ordena direcciones IP según cantidad de intentos fallidos. |
| **IDS manual en archivo (Umbral ≥ 3)** | `grep 'Failed password' muestras_auth.log \| awk '{for(i=1;i<=NF;i++) if($i=="from") print $(i+1)}' \| sort \| uniq -c \| sort -rn \| awk '$1>=3'` | `$ev = Import-Csv .\muestras_eventos_4625.csv; $ev \| Where-Object Id -eq '4625' \| Group-Object IpAddress \| Where-Object Count -ge 3 \| Select-Object Count, Name` | Detecta IPs sospechosas que superan el umbral de fallos configurado. |

---

## 2. Taller 2: Las Llaves de la Casa (Identidad, Privilegios y Auditoría)

### Tabla Comparativa: Identidad y Permisos

| Acción | Linux (Bash) | Windows (PowerShell) | Concepto |
| :--- | :--- | :--- | :--- |
| **Ver identificador de usuario** | `id` | `whoami /user` | Muestra `UID` y `GID` en Linux; `SID` (identificador de seguridad) en Windows. |
| **Ver grupos y nivel de integridad** | `id ; getent group wheel` | `whoami /groups` | En Windows, los administradores operan en **Nivel Medio** (`S-1-16-8192`) hasta elevar con UAC. |
| **Listar cuentas con privilegio maestro** | `awk -F: '$3==0 {print $1}' /etc/passwd`<br>`getent group wheel` | `Get-LocalGroupMember -SID 'S-1-5-32-544'` | `UID 0` (`root`) y grupo `wheel`/`sudo` frente a `Administrators` (`S-1-5-32-544`). |
| **Ver privilegios disponibles** | `sudo -l` | `whoami /priv` | Lista permisos administrativos asignados al usuario actual. |
| **Intentar leer archivo de claves** | `cat /etc/shadow` | `Get-Content C:\Windows\System32\config\SAM -TotalCount 1` | Verifica control de acceso (`EACCES` / *Acceso denegado* sin elevación). |
| **Solicitar elevación de privilegios** | `sudo <comando>` | `Start-Process powershell -Verb RunAs` | Préstamo temporal de privilegios administrativos (`sudo` vs `UAC`). |
| **Auditar uso de privilegios** | `journalctl -t sudo -n 3 --no-pager` | `Get-WinEvent -FilterHashtable @{LogName='Security'; Id=4672} -MaxEvents 3` | Registra en bitácora quién solicitó o usó privilegios elevados. |
| **Configuración de elevación** | `sudo grep -E '^%wheel' /etc/sudoers` | Políticas locales (`secpol.msc` / UAC) | Define qué grupos tienen autorización para ejecutar comandos como administrador. |

---

## 3. Estructura de Archivos de la Semana 5

```text
semana05/
├── README.md                  # Esta guía y ayuda memoria de comandos
├── auditoria_seguridad.sh     # Script de auditoría en Bash (Linux)
├── auditoria_seguridad.ps1    # Script de auditoría en PowerShell (Windows)
├── auditoria_linux.txt        # Informe de salida generado en Linux
└── auditoria_windows.txt      # Informe de salida generado en Windows