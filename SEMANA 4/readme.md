# Semana 4: Llamadas al Sistema, Búferes, Errores y Paquetes

Resumen de comandos equivalentes en **Linux (AlmaLinux / Bash)** y **Windows (PowerShell)** correspondientes a los Talleres 1 y 2 (Cap. 2, temas 2.4 – 2.6).

---

## 1. Bibliotecas, Llamadas al Sistema y Terminal

| Propósito | Linux (Bash) | Windows (PowerShell) |
| :--- | :--- | :--- |
| Ver bibliotecas / DLL cargadas por un proceso | `ldd /bin/ls` | `(Get-Process -Id $PID).Modules \| Select-Object -First 8 ModuleName, FileName` |
| Contar bibliotecas / DLL del proceso actual | `ldd /bin/ls \| wc -l` | `(Get-Process -Id $PID).Modules.Count` |
| Filtrar DLL críticas del sistema (`ntdll`, `kernel32`) | `strace -e trace=openat ls /tmp` | `(Get-Process -Id $PID).Modules \| Where-Object ModuleName -in 'ntdll.dll','KERNEL32.DLL','KERNELBASE.dll' \| Select-Object ModuleName, FileName` |
| Resumen estadístico de llamadas al sistema | `strace -c ls /tmp` | *(No nativo; equivalente externo: Process Monitor / Sysinternals)* |
| Identificar quién dibuja la terminal (proceso padre) | `ps -fp $PPID` / `tty` | `Get-Process -Id (Get-CimInstance Win32_Process -Filter "ProcessId=$PID").ParentProcessId` |
| Verificar host de consola activo | `echo $TERM` | `Get-Process conhost, WindowsTerminal -ErrorAction SilentlyContinue \| Select-Object Name, Id` |

---

## 2. Costo de Llamadas al Sistema y Tamaño de Búfer

Pedir datos de byte en byte multiplica los cambios de contexto entre **modo usuario** y **modo núcleo**; usar bloques de `4096` bytes (`4 KiB`) o mayores amortiza el costo por llamada.

### Linux (Bash)
```bash
# Crear archivo binario de 1 MiB (1048576 bytes)
head -c 1048576 /dev/urandom > datos.bin && ls -l datos.bin

# Medir tiempo de copia variando el tamaño de bloque (bs)
for bs in 1 16 512 4096 65536; do
  echo -n "bs=$bs  "
  ( time dd if=datos.bin of=copia.bin bs=$bs status=none ) 2>&1 | grep real
done
```

### Windows (PowerShell)
```powershell
# Crear archivo binario de 1 MiB
$src = "$env:TEMP\datos.bin"; $dst = "$env:TEMP\copia.bin"
$b = New-Object byte[] 1MB; (New-Object Random 42).NextBytes($b); [IO.File]::WriteAllBytes($src,$b)

# Medir tiempo de copia con FileStream sin búfer interno (1 byte)
Add-Type -TypeDefinition @'
using System.IO; using System.Diagnostics;
public static class Ventanilla {
  public static double Copiar(string src, string dst, int B) {
    var sw = Stopwatch.StartNew();
    using (var i = new FileStream(src, FileMode.Open, FileAccess.Read, FileShare.Read, 1))
    using (var o = new FileStream(dst, FileMode.Create, FileAccess.Write, FileShare.None, 1)) {
      var buf = new byte[B]; int n;
      while ((n = i.Read(buf, 0, B)) > 0) o.Write(buf, 0, n);
    }
    return sw.Elapsed.TotalMilliseconds;
  }
}
'@
foreach ($B in 1, 16, 512, 4096, 65536) { '{0,6} bytes -> {1,10:N1} ms' -f $B, [Ventanilla]::Copiar($src, $dst,$B) }
```

---

## 3. Errores del Núcleo, Códigos de Salida y Redirecciones

| Acción | Linux (Bash) | Windows (PowerShell) |
| :--- | :--- | :--- |
| Consultar éxito o código de salida del último comando | `echo $?` (`0` = éxito, `!=0` = error) | `$?` (`True`/`False`) y `$LASTEXITCODE` (ejecutables externos) |
| Ver tipo de excepción o traducir código de error | `errno 2` / `errno 13` | `$Error[0].Exception.GetType().FullName` y `[ComponentModel.Win32Exception]::new(2).Message` |
| Redirigir salida estándar (`stdout`) y errores (`stderr`) | `ls /etc /noexiste > salida.txt 2> errores.txt` | `Get-ChildItem C:\Windows, C:\NoExiste > salida.txt 2> errores.txt` |
| Descartar errores y mostrar mensaje si falla | `cat notas.txt >/dev/null 2>&1 \|\| echo "falta notas.txt"` | `Get-Content notas.txt 2>$null; if (-not $?) { "falta notas.txt" }` |

---

## 4. Tuberías (Texto vs. Objetos) y Gestores de Paquetes

En **Linux**, las tuberías (`|`) transmiten flujos de **texto plano**, por lo que `sort` requiere `-n` para ordenar números. En **Windows (PowerShell)**, las tuberías transmiten **objetos .NET** tipados, por lo que `Sort-Object` reconoce automáticamente si el dato es numérico (`Int32`/`Int64`) o cadena (`String`).

| Operación | Linux (Bash + `dnf`) | Windows (PowerShell + `winget`) |
| :--- | :--- | :--- |
| Top 3 procesos por uso de memoria | `ps -eo comm,pid,rss --sort=-rss \| head -n 4` | `Get-Process \| Sort-Object WS -Descending \| Select-Object -First 3 Name, Id, WS` |
| Inspeccionar propiedades de un objeto | `file` / `stat` | `Get-Process \| Get-Member -MemberType Property \| Select-Object -First 8 Name, Definition` |
| Ordenamiento numérico vs. alfabético | `printf "999\n1000\n25\n" \| sort -n` | `999, 1000, 25 \| Sort-Object` (numérico) vs. `'999', '1000', '25' \| Sort-Object` (texto) |
| Listar repositorios / fuentes configuradas | `dnf repolist` | `winget source list` |
| Buscar y ver detalles de un paquete (`jq`) | `dnf search jq` / `dnf info jq` | `winget search jq` / `winget show jqlang.jq` |
| Instalar paquete y verificar versión | `sudo dnf install -y jq && jq --version` | `winget install --id jqlang.jq -e` y `jq --version` |
| Procesar JSON por tubería con `jq` | `echo '{"plato":"sopa","minutos":20}' \| jq .minutos` | `'{"plato":"sopa","minutos":20}' \| jq .minutos` |

---

## 5. Ejecución de Scripts del Deber 4

```bash
# Linux (AlmaLinux)
chmod +x "SEMANA 4/verificador_entorno.sh"
./"SEMANA 4/verificador_entorno.sh"; echo "código: $?"
```

```powershell
# Windows (PowerShell)
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
.\"SEMANA 4"\verificador_entorno.ps1; $LASTEXITCODE
```