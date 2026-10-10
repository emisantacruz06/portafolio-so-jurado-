# inventario.ps1 - Semana 1
$salida = "SEMANA 1\inventario_$env:COMPUTERNAME.txt"
$cpu    = Get-CimInstance Win32_Processor
$os     = Get-CimInstance Win32_OperatingSystem
$ram    = Get-CimInstance Win32_PhysicalMemory

& {
    "== Equipo: $env:COMPUTERNAME | $(Get-Date)"
    "== SO: $($os.Caption) $($os.Version)"
    "== CPU"
    $cpu | Format-List Name, NumberOfCores, NumberOfLogicalProcessors, MaxClockSpeed, L2CacheSize, L3CacheSize
    "== Memoria RAM Total"
    $ramTotalGB = [math]::Round(($ram | Measure-Object -Property Capacity -Sum).Sum / 1GB, 2)
    "RAM Total: $ramTotalGB GB"
    "== Discos"
    Get-PhysicalDisk | Format-Table FriendlyName, MediaType, @{Name="Size (GB)"; Expression={[math]::Round($_.Size / 1GB, 2)}} -AutoSize
    "== Red (Extra)"
    Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -notlike "*Loopback*" } | Select-Object InterfaceAlias, IPAddress | Format-Table -AutoSize
} | Out-File -FilePath $salida -Encoding utf8

Write-Host "Reporte generado en: $salida"