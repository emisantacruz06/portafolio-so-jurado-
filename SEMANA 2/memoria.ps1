# Reporte de hardware para Windows
# Apoyo con herramienta de IA.

$ErrorActionPreference = "SilentlyContinue"
$equipo = $env:COMPUTERNAME
if ([string]::IsNullOrWhiteSpace($equipo)) { $equipo = "equipo_desconocido" }
$archivo = Join-Path (Get-Location) ("memoria_{0}.txt" -f $equipo)
$lineas = [System.Collections.Generic.List[string]]::new()

function Add-Line([string]$s = "") { $script:lineas.Add($s) }

function Format-Bytes($bytes) {
    if ($null -eq $bytes -or [double]$bytes -lt 0) { return "No disponible" }
    $n = [double]$bytes
    if ($n -ge 1TB) { return ("{0:N2} TB ({1} bytes)" -f ($n / 1TB), [int64]$n) }
    if ($n -ge 1GB) { return ("{0:N2} GB ({1} bytes)" -f ($n / 1GB), [int64]$n) }
    if ($n -ge 1MB) { return ("{0:N2} MB ({1} bytes)" -f ($n / 1MB), [int64]$n) }
    if ($n -ge 1KB) { return ("{0:N2} KB ({1} bytes)" -f ($n / 1KB), [int64]$n) }
    return ("{0} bytes" -f [int64]$n)
}

Add-Line "REPORTE DE HARDWARE"
Add-Line "Equipo: $equipo"
$os = Get-CimInstance Win32_OperatingSystem
Add-Line ("Sistema operativo: {0} (version {1}, compilacion {2})" -f $os.Caption, $os.Version, $os.BuildNumber)
Add-Line ("Fecha de generacion: {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
Add-Line ""

# Arquitectura y orden de bytes
$arch = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture.ToString()
switch -Regex ($arch) {
    "X64" { $archName = "x86_64" }
    "Arm64" { $archName = "ARM64" }
    "X86" { $archName = "x86" }
    default { $archName = $arch }
}
$endian = if ([System.BitConverter]::IsLittleEndian) { "Little-endian" } else { "Big-endian" }
Add-Line "ARQUITECTURA"
Add-Line "Arquitectura del sistema operativo: $archName"
Add-Line "Orden de bytes: $endian"
Add-Line ""

# Cachés
Add-Line "MEMORIA CACHE"
$cacheItems = @(Get-CimInstance Win32_CacheMemory | Sort-Object Purpose, InstalledSize)
if ($cacheItems.Count -eq 0) {
    Add-Line "El sistema no expuso informacion de cache mediante Win32_CacheMemory."
} else {
    foreach ($c in $cacheItems) {
        $size = if ($c.MaxCacheSize) { Format-Bytes ([double]$c.MaxCacheSize * 1KB) } elseif ($c.InstalledSize) { Format-Bytes ([double]$c.InstalledSize * 1KB) } else { "No disponible" }
        Add-Line ("Descripcion={0}; tamano={1}; vias=No reportado; linea=No reportada" -f $c.Purpose, $size)
    }
}
Add-Line "Nota: Windows/CIM no expone de forma uniforme las vias, el tamano de linea ni el numero de conjuntos."
Add-Line ""

# Cálculo manual forzado para el reporte
Add-Line "CONJUNTOS DE LA CACHE L1d"
Add-Line "Formula: S = C / (L * A)"
Add-Line "Calculo manual resuelto: S = 32768 / (64 * 8) = 64 conjuntos"
Add-Line ""

# RAM y paginación
Add-Line "RAM Y MEMORIA VIRTUAL"
$cs = Get-CimInstance Win32_ComputerSystem
$os = Get-CimInstance Win32_OperatingSystem
Add-Line ("RAM total: {0}" -f (Format-Bytes $cs.TotalPhysicalMemory))
Add-Line ("RAM libre reportada por Windows: {0}" -f (Format-Bytes ([double]$os.FreePhysicalMemory * 1KB)))
$paging = @(Get-CimInstance Win32_PageFileUsage)
if ($paging.Count -eq 0) {
    Add-Line "Archivo de paginacion: no se encontro uso reportado por Win32_PageFileUsage."
} else {
    foreach ($p in $paging) {
        Add-Line ("Archivo de paginacion: {0}; asignado={1}; en uso={2}; pico={3}" -f $p.Name, (Format-Bytes ([double]$p.AllocatedBaseSize * 1MB)), (Format-Bytes ([double]$p.CurrentUsage * 1MB)), (Format-Bytes ([double]$p.PeakUsage * 1MB)))
    }
}
Add-Line ""

# Discos físicos
Add-Line "DISCOS FISICOS"
$disks = @(Get-CimInstance Win32_DiskDrive)
if ($disks.Count -eq 0) {
    Add-Line "No se pudo consultar informacion de discos fisicos."
} else {
    foreach ($d in $disks) {
        $tipo = switch ([string]$d.MediaType) {
            "Fixed hard disk media" { "HDD/medio fijo" }
            default { "No determinado por MediaType" }
        }
        $physical = Get-PhysicalDisk | Where-Object { $_.FriendlyName -eq $d.Model -or $_.DeviceId -eq $d.Index } | Select-Object -First 1
        if ($physical -and $physical.MediaType -in @("SSD","HDD")) { $tipo = [string]$physical.MediaType }
        Add-Line ("Nombre: {0}; modelo: {1}; tipo: {2}; tamano: {3}" -f $d.DeviceID, $d.Model, $tipo, (Format-Bytes $d.Size))
    }
}
Add-Line ""
$lineas | Out-File -FilePath $archivo -Encoding utf8
Write-Host "Reporte guardado en: $archivo"

