Linux

lscpu : Ver información del procesador (CPU)
cat /proc/cpuinfo : Ver detalle técnico de la CPU
free -h : Ver memoria RAM libre y usada
cat /proc/meminfo : Ver detalle completo de la RAM
lsblk : Ver discos de almacenamiento y particiones
df -h : Ver espacio libre en los discos
lspci : Ver componentes en puertos PCI (gráfica, red)
lsusb : Ver dispositivos USB conectados
sudo lshw -short : Ver resumen general del hardware

Windows

Get-CimInstance Win32_Processor : Ver información del procesador (CPU)
Get-CimInstance Win32_PhysicalMemory : Ver memoria RAM instalada
Get-PhysicalDisk : Ver discos físicos (SSD/HDD)
Get-Volume : Ver unidades de disco y espacio (C:, D:)
Get-PnpDevice -PresentOnly : Ver dispositivos conectados
systeminfo : Ver resumen general del sistema en consola
msinfo32 : Abrir la ventana de información del sistema