# Comandos de Memoria y Hardware

## Linux
* `lscpu --caches`: Muestra una tabla con los estantes de memoria rápida (cachés L1, L2, L3) del procesador, donde indica su tamaño y cómo están organizados.
* `getconf LEVEL1_DCACHE_LINESIZE`: Te dice cuántos bytes trae la caché L1 en cada viaje a la RAM.
* `free -h`: Muestra un resumen de cuánta memoria RAM total se tiene, cuánta está ocupada y cuánta memoria Swap se usa.
* `lsblk -do NAME,ROTA,SIZE`: Lista los discos de almacenamiento indicando su nombre, tamaño y si son discos mecánicos (ROTA=1) o SSD (ROTA=0).
* `uname -m`: Imprime la arquitectura del procesador.
* `hostname`: Muestra el nombre de la computadora.

## Windows
* `Get-CimInstance Win32_CacheMemory | Select-Object Purpose, InstalledSize`: Extrae las memorias caché instaladas y su tamaño en KB.
* `Get-CimInstance Win32_OperatingSystem`: Consulta la información del sistema operativo para obtener datos como la RAM total y libre.
* `Get-PhysicalDisk`: Lista los discos físicos conectados para ver el tipo (SSD o HDD) y capacidad.
* `[BitConverter]::IsLittleEndian`: Devuelve True o False para confirmar si tu equipo lee los bytes de derecha a izquierda (Little-Endian).
* `$env:COMPUTERNAME`: Imprime el nombre de la máquina.
* `$env:PROCESSOR_ARCHITECTURE`: Muestra la arquitectura del procesador.