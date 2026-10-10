# Comandos de Hardware

## Linux
- lscpu : Ver información del procesador (CPU)
- cat /proc/cpuinfo : Ver detalle técnico de la CPU
- free -h : Ver memoria RAM libre y usada
- cat /proc/meminfo : Ver detalle completo de la RAM
- lsblk : Ver discos de almacenamiento y particiones
- df -h : Ver espacio libre en los discos
- lspci : Ver componentes en puertos PCI (gráfica, red)
- lsusb : Ver dispositivos USB conectados
- sudo lshw -short : Ver resumen general del hardware

## Windows
- Get-CimInstance Win32_Processor : Ver información del procesador (CPU)
- Get-CimInstance Win32_PhysicalMemory : Ver memoria RAM instalada
- Get-PhysicalDisk : Ver discos físicos (SSD/HDD)
- Get-Volume : Ver unidades de disco y espacio (C:, D:)
- Get-PnpDevice -PresentOnly : Ver dispositivos conectados
- systeminfo : Ver resumen general del sistema en consola
- msinfo32 : Abrir la ventana de información del sistema

## Git y GitHub
- echo "# portafolio-so-jurado-" >> README.md : Crear el archivo README inicial con el título del proyecto
- git init : Inicializar un repositorio local de Git en la carpeta
- git add README.md : Preparar el archivo README para el commit
- git commit -m "first commit" : Guardar el primer estado/versión del proyecto con un mensaje
- git branch -M main : Renombrar la rama principal a main
- git remote add origin https://github.com/emisantacruz06/portafolio-so-jurado-.git : Enlazar el repositorio local con el de GitHub
- git push -u origin main : Subir los archivos por primera vez al repositorio remoto