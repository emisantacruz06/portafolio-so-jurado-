
# ============================================================
# Informe de arranque - Sistemas Operativos
# Autores: Dilan Agila y Emily Jurado
# Fecha: 28/10/2026
# Uso de IA: Se utilizó IA como apoyo para revisar
# el script. Los resultados se obtienen del equipo ejecutado.
# ============================================================

$ErrorActionPreference = "Continue"
$fecha = Get-Date -Format "yyyyMMdd_HHmmss"
$equipo = $env:COMPUTERNAME
$archivo = Join-Path $PSScriptRoot "informe_arranque_${equipo}_${fecha}.txt"

function Escribir-Seccion {
    param([string]$Titulo)

    $linea = "`r`n=== $Titulo ==="
    Write-Host $linea -ForegroundColor Cyan
    Add-Content -Path $archivo -Value $linea
}

function Escribir-Dato {
    param([string]$Texto)

    Write-Host $Texto
    Add-Content -Path $archivo -Value $Texto
}

function EsAdministrador {
    $identidad = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]::new($identidad)
    return $principal.IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator
    )
}

# Crear el informe
"INFORME DE ARRANQUE DEL EQUIPO: $equipo" |
    Set-Content -Path $archivo

Escribir-Dato "Fecha de generación: $(Get-Date)"
Escribir-Dato "Usuario: $env:USERNAME"

# ============================================================
# 1. SISTEMA OPERATIVO, VERSION Y NUCLEO
# ============================================================

Escribir-Seccion "1 - Sistema operativo, version y nucleo"

try {
    $so = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop

    Escribir-Dato "Sistema: $($so.Caption)"
    Escribir-Dato "Version: $($so.Version)"
    Escribir-Dato "Compilacion: $($so.BuildNumber)"
    Escribir-Dato "Arquitectura: $($so.OSArchitecture)"
} catch {
    Escribir-Dato "AVISO: No se pudo obtener la informacion del sistema."
}

# ============================================================
# 2. ULTIMO ARRANQUE Y TIEMPO ENCENDIDO
# ============================================================

Escribir-Seccion "2 - Ultimo arranque y tiempo encendido"

try {
    $so = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop
    $arranque = $so.LastBootUpTime
    $encendida = (Get-Date) - $arranque

    Escribir-Dato "Ultimo arranque: $arranque"
    Escribir-Dato ("Tiempo encendido: {0} dias, {1} horas, {2} minutos" -f `
        [math]::Floor($encendida.TotalDays),
        $encendida.Hours,
        $encendida.Minutes)
} catch {
    Escribir-Dato "AVISO: No se pudo consultar el ultimo arranque."
}

# ============================================================
# 3. DESGLOSE DEL ARRANQUE
# ============================================================

Escribir-Seccion "3 - Desglose del arranque"

try {
    $sistema = Get-CimInstance Win32_ComputerSystem -ErrorAction Stop
    $propiedadFw = $sistema.PSObject.Properties["FwPOSTTime"]

    if ($null -ne $propiedadFw) {
        Escribir-Dato "FwPOSTTime: $($propiedadFw.Value)"
    } else {
        Escribir-Dato "FwPOSTTime: No disponible mediante Win32_ComputerSystem."
    }
} catch {
    Escribir-Dato "AVISO: No se pudo consultar FwPOSTTime."
}

if (EsAdministrador) {
    try {
        $evento = Get-WinEvent -FilterHashtable @{
            LogName = "Microsoft-Windows-Diagnostics-Performance/Operational"
            Id = 100
        } -MaxEvents 1 -ErrorAction Stop

        Escribir-Dato "Evento 100 - Rendimiento del arranque:"
        Escribir-Dato $evento.TimeCreated.ToString()
        Escribir-Dato $evento.Message
    } catch {
        Escribir-Dato "AVISO: No se pudo leer el evento 100. Puede no existir un registro disponible."
    }
} else {
    Escribir-Dato "AVISO: Abre PowerShell como administrador para consultar el evento 100."
}

# ============================================================
# 4. SERVICIOS
# ============================================================

Escribir-Seccion "4 - Servicios en ejecucion y automaticos detenidos"

try {
    $servicios = @(Get-CimInstance Win32_Service -ErrorAction Stop)

    $ejecucion = @($servicios | Where-Object {
        $_.State -eq "Running"
    })

    $automaticosDetenidos = @($servicios | Where-Object {
        $_.StartMode -eq "Auto" -and $_.State -eq "Stopped"
    })

    Escribir-Dato "Total de servicios en ejecucion: $($ejecucion.Count)"
    Escribir-Dato "Servicios en ejecucion:"
    $ejecucion |
        Select-Object -First 10 Name, DisplayName, State |
        Format-Table -AutoSize |
        Out-String |
        ForEach-Object { Escribir-Dato $_ }

    Escribir-Dato "Servicios automaticos detenidos: $($automaticosDetenidos.Count)"
    $automaticosDetenidos |
        Select-Object -First 10 Name, DisplayName, StartMode, State |
        Format-Table -AutoSize |
        Out-String |
        ForEach-Object { Escribir-Dato $_ }
} catch {
    Escribir-Dato "AVISO: No se pudieron consultar los servicios."
}

# ============================================================
# 5. CONTROLADORES
# ============================================================

Escribir-Seccion "5 - Controladores de Windows"

try {
    Escribir-Dato "Listado de controladores mediante driverquery:"
    $controladores = @(driverquery.exe 2>&1)

    foreach ($linea in $controladores) {
        Escribir-Dato ([string]$linea)
    }
} catch {
    Escribir-Dato "AVISO: No se pudo ejecutar driverquery."
}

try {
    $driversActivos = @(Get-CimInstance Win32_SystemDriver |
        Where-Object { $_.State -eq "Running" })

    Escribir-Dato "Controladores en ejecucion: $($driversActivos.Count)"
    $driversActivos |
        Select-Object -First 10 Name, DisplayName, State, StartMode |
        Format-Table -AutoSize |
        Out-String |
        ForEach-Object { Escribir-Dato $_ }
} catch {
    Escribir-Dato "AVISO: No se pudieron consultar los controladores activos."
}

# ============================================================
# 6. CIERRE - INICIO RAPIDO
# ============================================================

Escribir-Seccion "6 - Estado del inicio rapido"

try {
    $registro = Get-ItemProperty `
        -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power" `
        -Name HiberbootEnabled `
        -ErrorAction Stop

    Escribir-Dato "HiberbootEnabled: $($registro.HiberbootEnabled)"

    if ($registro.HiberbootEnabled -eq 1) {
        Escribir-Dato "Inicio rapido: Activado"
    } elseif ($registro.HiberbootEnabled -eq 0) {
        Escribir-Dato "Inicio rapido: Desactivado"
    } else {
        Escribir-Dato "Inicio rapido: Valor no reconocido"
    }
} catch {
    Escribir-Dato "AVISO: No se pudo consultar HiberbootEnabled."
}

Escribir-Dato ""
Escribir-Dato "Informe guardado en: $archivo"
Write-Host "`nInforme generado: $archivo" -ForegroundColor Green
