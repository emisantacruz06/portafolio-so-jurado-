<#
Fecha: 14/11/2026
Uso de IA: Se utilizo IA como apoyo para estructurar las funciones y simplificar las consultas del verificador de entorno.
#>

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$fecha = Get-Date -Format 'yyyy-MM-dd'
$equipo = $env:COMPUTERNAME
$archivo = "verificador_${equipo}_${fecha}.txt"
$script:LineasInforme = @()
$script:Herramientas = @(
    @{ Nombre = 'git'; Id = 'Git.Git' },
    @{ Nombre = 'curl.exe'; Id = 'cURL.cURL' },
    @{ Nombre = 'python'; Id = 'Python.Python.3.12' },
    @{ Nombre = 'jq'; Id = 'jqlang.jq' },
    @{ Nombre = 'winget'; Id = 'Microsoft.AppInstaller' }
)
$script:Listas = 0
$script:Faltantes = @()

function Escribir-Informe ($texto) {
    Write-Output $texto
    $script:LineasInforme += $texto
}

function Seccion-1 {
    Escribir-Informe '============================================================'
    Escribir-Informe 'SECCION 1. SISTEMA Y SHELL'
    Escribir-Informe '============================================================'
    $so = Get-CimInstance Win32_OperatingSystem
    Escribir-Informe "Sistema Operativo: $($so.Caption) (Build $($so.BuildNumber))"
    Escribir-Informe "Version PowerShell: $($PSVersionTable.PSVersion)"
}

function Seccion-2 {
    Escribir-Informe ''
    Escribir-Informe '============================================================'
    Escribir-Informe 'SECCION 2. HERRAMIENTAS REQUERIDAS'
    Escribir-Informe '============================================================'
    foreach ($h in $script:Herramientas) {
        $cmd = Get-Command $h.Nombre -ErrorAction SilentlyContinue
        if ($cmd) {
            $ver = (& $h.Nombre --version 2>&1 | Select-Object -First 1)
            Escribir-Informe "[OK]    $($h.Nombre) -> $ver"
            $script:Listas++
        } else {
            Escribir-Informe "[FALTA] $($h.Nombre)"
            $script:Faltantes += $h
        }
    }
}

function Seccion-3 {
    Escribir-Informe ''
    Escribir-Informe '============================================================'
    Escribir-Informe 'SECCION 3. PAQUETES Y ORIGENES'
    Escribir-Informe '============================================================'
    $rutas = @(
        'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*'
    )
    $programas = Get-ItemProperty $rutas -ErrorAction SilentlyContinue | Where-Object DisplayName | Sort-Object DisplayName -Unique
    Escribir-Informe "Programas en registro: $($programas.Count)"
    
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Escribir-Informe 'Origenes de winget:'
        winget source list 2>&1 | ForEach-Object { Escribir-Informe "  $_" }
    }
}

function Seccion-4 {
    Escribir-Informe ''
    Escribir-Informe '============================================================'
    Escribir-Informe 'SECCION 4. ULTIMAS 5 INSTALACIONES'
    Escribir-Informe '============================================================'
    $rutas = @(
        'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*'
    )
    $ultimos = Get-ItemProperty $rutas -ErrorAction SilentlyContinue |
        Where-Object { $_.DisplayName -and $_.InstallDate -match '^\d{8}$' } |
        Sort-Object InstallDate -Descending |
        Select-Object -First 5

    if (-not $ultimos) {
        Escribir-Informe 'No hay registros con InstallDate.'
    } else {
        foreach ($p in $ultimos) {
            Escribir-Informe "  $($p.InstallDate) - $($p.DisplayName)"
        }
    }
}

function Seccion-5 {
    Escribir-Informe ''
    Escribir-Informe '============================================================'
    Escribir-Informe 'SECCION 5. QUE FALTA Y COMO INSTALARLO'
    Escribir-Informe '============================================================'
    if ($script:Faltantes.Count -eq 0) {
        Escribir-Informe 'No falta ninguna herramienta.'
        return
    }
    $comandos = foreach ($item in $script:Faltantes) {
        if ($item.Nombre -ne 'winget') { "winget install --id $($item.Id) -e" }
    }
    if ($comandos) {
        Escribir-Informe "Comando para instalar: $($comandos -join '; ')"
    }
}

function Seccion-6 {
    Escribir-Informe ''
    Escribir-Informe '============================================================'
    Escribir-Informe 'SECCION 6. RESULTADO Y CODIGO DE SALIDA'
    Escribir-Informe '============================================================'
    Escribir-Informe "Herramientas listas: $script:Listas de $($script:Herramientas.Count)"
    Escribir-Informe "Informe guardado en: $archivo"
    if ($script:Listas -eq $script:Herramientas.Count) {
Escribir-Informe 'Resultado: COMPLETO (codigo 0)'
return 0
    }
Escribir-Informe 'Resultado: INCOMPLETO (codigo 1)'
return 1
}

Seccion-1
Seccion-2
Seccion-3
Seccion-4
Seccion-5
$codigoSalida = Seccion-6

$script:LineasInforme | Set-Content -Path $archivo -Encoding UTF8
exit $codigoSalida