# =============================================================================
# Deber 5 - Auditoria de seguridad del equipo (Windows)
# Sistemas Operativos - EPN - Semana 5
# Autores: Emily Jurado
# Fecha: 2026-11-20
# Uso de IA: IA generativa utilizada para revisar el esqueleto del script y completar ciertas partes.
# =============================================================================
param([int]$Umbral = 5, [string]$Muestra = "")

$riesgosas = 21, 23, 3306, 3389, 5900
$script:estado = @{}
$equipo = $env:COMPUTERNAME
$salida = "auditoria_{0}_{1}.txt" -f $equipo, (Get-Date -Format "yyyyMMdd_HHmm")

function Titulo([string]$t) { ""; "=== $t ===" }
function Marca([int]$n, [string]$v) {
$script:estado["$n"] = $v
"-> Seccion ${n}: $v"
}

function Seccion1 {
Titulo "1 - Llavero maestro"
$alerta = $false
try {
$miembros = @(Get-LocalGroupMember -SID 'S-1-5-32-544' -ErrorAction Stop)
"Miembros de Administradores:"
$miembros | ForEach-Object { "  $($_.Name) [$($_.ObjectClass)]" }
} catch {
"No se pudo consultar Administradores: $($_.Exception.Message)"
$alerta = $true
}
try {
$integrada = @(Get-LocalUser -ErrorAction Stop | Where-Object { $_.SID.Value -like '*-500' })
foreach ($cuenta in $integrada) {
"Cuenta integrada: $($cuenta.Name) - Habilitada: $($cuenta.Enabled)"
if ($cuenta.Enabled) { $alerta = $true }
}
} catch {
"No se pudo consultar la cuenta integrada: $($_.Exception.Message)"
$alerta = $true
}
if ($alerta) { Marca 1 "ALERTA" } else { Marca 1 "OK" }
}

function Seccion2 {
Titulo "2 - Puertas abiertas"
$alerta = $false
try {
$conexiones = @(Get-NetTCPConnection -State Listen -ErrorAction Stop |
Sort-Object LocalPort, LocalAddress -Unique)
foreach ($c in $conexiones) {
$local = $c.LocalAddress
$alcance = if ($local -eq '127.0.0.1' -or $local -eq '::1') { "solo el equipo" } else { "abierta a la red" }
"Puerto $($c.LocalPort) - Direccion $local - $alcance"
if (($c.LocalPort -in $riesgosas) -and $alcance -eq "abierta a la red") { $alerta = $true }
}
if ($conexiones.Count -eq 0) { "No hay puertos TCP en escucha." }
} catch {
"No se pudieron consultar conexiones: $($_.Exception.Message)"
$alerta = $true
}
if ($alerta) { Marca 2 "ALERTA" } else { Marca 2 "OK" }
}

function Seccion3 {
    Titulo "3 - Portero activo"
    $alerta = $false
    try {
        $perfiles = @(Get-NetFirewallProfile -ErrorAction Stop)
        foreach ($p in $perfiles) {
            "Perfil $($p.Name) - Habilitado: $($p.Enabled)"
            if (-not $p.Enabled) { $alerta = $true }
        }
    } catch {
        "No se pudieron consultar los perfiles: $($_.Exception.Message)"
        $alerta = $true
    }
    if ($alerta) { Marca 3 "ALERTA" } else { Marca 3 "OK" }
}

function Seccion4 {
    Titulo "4 - Intentos fallidos (umbral: $Umbral por IP)"
    $eventos = @()
    if ($Muestra) {
        if (Test-Path -LiteralPath $Muestra) {
            try {
                $eventos = @(Import-Csv -LiteralPath $Muestra | Where-Object { "$($_.Id)" -eq '4625' })
                "Fuente: muestra $Muestra"
            } catch { "Error al leer muestra: $($_.Exception.Message)" }
        } else { "No existe la muestra: $Muestra" }
    } else {
        try {
            $raw = @(Get-WinEvent -FilterHashtable @{
                LogName='Security'; Id=4625; StartTime=(Get-Date).AddHours(-24)
            } -ErrorAction Stop)
            foreach ($ev in $raw) {
                $ip = $null
                if ($ev.Message -match 'Source Network Address:\s*([^\s]+)') { $ip = $Matches[1] }
                elseif ($ev.Message -match 'Dirección de red de origen:\s*([^\s]+)') { $ip = $Matches[1] }
                if ($ip -and $ip -ne '-') { $eventos += [pscustomobject]@{ IpAddress=$ip } }
            }
            "Fuente: registro Seguridad, ultimas 24 horas"
        } catch {
            "No se pudo leer Seguridad. Puede requerir administrador; use -Muestra."
        }
    }
    $ips = @($eventos | ForEach-Object {
        $ip = "$($_.IpAddress)".Trim()
        if ($ip -and $ip -ne '-') { $ip }
    } | Group-Object | Sort-Object Count -Descending)
    foreach ($g in $ips) { "IP $($g.Name): $($g.Count) intento(s)" }
    if ($ips.Count -eq 0) { "No se encontraron intentos con IP." }
    $alerta = @($ips | Where-Object { $_.Count -ge $Umbral }).Count -gt 0
    if ($alerta) { Marca 4 "ALERTA" } else { Marca 4 "OK" }
}

function Seccion5 {
    Titulo "5 - Veredicto"
    $alertas = 0
    foreach ($n in 1..4) {
        $estadoSeccion = $script:estado["$n"]
        "Seccion ${n}: $estadoSeccion"
        if ($estadoSeccion -eq "ALERTA") { $alertas++ }
    }
    if ($alertas -gt 0) {
        "Resultado general: ALERTA ($alertas seccion/es requieren revision)."
        $script:codigo = 1
    } else {
        "Resultado general: OK (sin alertas detectadas)."
        $script:codigo = 0
    }
}

$script:codigo = 0
& {
    "Auditoria de seguridad - $equipo - $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
    Seccion1
    Seccion2
    Seccion3
    Seccion4
    Seccion5
} | Tee-Object -FilePath $salida
""
"Informe guardado en: $salida"
exit $script:codigo
