# ============================================================
# TECLA QUE EMPIEZA A ESCRIBIR
# Cambia estas dos lineas, guarda, cierra el icono de la bandeja
# (clic derecho, Salir) y vuelve a abrir iniciar-powershell.bat.
#
#   F8 = 0x77    F9 = 0x78    F10 = 0x79    F11 = 0x7A    F12 = 0x7B
#   Q = 0x51
#
# Modificadores (se pueden sumar):
#   0 ninguno    1 Alt    2 Ctrl    4 Mayus    8 Win
#
#   F8            TeclaVK = 0x77    TeclaMod = 0
#   F9            TeclaVK = 0x78    TeclaMod = 0
#   Ctrl+F8       TeclaVK = 0x77    TeclaMod = 2
#   Alt+Q         TeclaVK = 0x51    TeclaMod = 1
#
# Si usas una tecla de un teclado Razer, en Synapse esa tecla
# solo tiene que enviar esta misma tecla. El texto no va en Synapse.
# ============================================================
$TeclaVK = 0x77
$TeclaMod = 0

$Carpeta = $PSScriptRoot
if (-not $Carpeta) { $Carpeta = Split-Path -Parent $MyInvocation.MyCommand.Path }
$ArchivoTexto = Join-Path $Carpeta "texto.txt"
$ArchivoAjustes = Join-Path $Carpeta "ajustes.ini"

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$codigo = @'
using System;
using System.Drawing;
using System.Runtime.InteropServices;
using System.Windows.Forms;

public class EscritorHotkey : NativeWindow {
    public int Vk;
    public int Mod;
    public bool HotkeyOk;
    public bool Pendiente;
    const int WM_HOTKEY = 0x0312;

    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool RegisterHotKey(IntPtr hWnd, int id, uint fsModifiers, uint vk);

    [DllImport("user32.dll")]
    public static extern bool UnregisterHotKey(IntPtr hWnd, int id);

    [DllImport("user32.dll")]
    public static extern short GetAsyncKeyState(int vKey);

    [DllImport("user32.dll")]
    public static extern IntPtr GetForegroundWindow();

    public EscritorHotkey(int mod, int vk) {
        Mod = mod;
        Vk = vk;
        CreateParams cp = new CreateParams();
        cp.Caption = "escritor_humano_V3";
        cp.X = -32000;
        cp.Y = -32000;
        cp.Width = 1;
        cp.Height = 1;
        cp.Style = 0;
        cp.ExStyle = 0x08000000;
        this.CreateHandle(cp);
        HotkeyOk = RegisterHotKey(this.Handle, 1, (uint)Mod, (uint)Vk);
    }

    protected override void WndProc(ref Message m) {
        if (m.Msg == WM_HOTKEY)
            Pendiente = true;
        base.WndProc(ref m);
    }

    public void Cerrar() {
        try { UnregisterHotKey(this.Handle, 1); } catch { }
        try { this.DestroyHandle(); } catch { }
    }
}
'@

Add-Type -TypeDefinition $codigo -ReferencedAssemblies System.Windows.Forms, System.Drawing

function Remove-SaltoFinal([string]$t) {
    if ([string]::IsNullOrEmpty($t)) { return "" }
    if ($t.EndsWith("`r`n")) { return $t.Substring(0, $t.Length - 2) }
    if ($t.EndsWith("`n") -or $t.EndsWith("`r")) { return $t.Substring(0, $t.Length - 1) }
    return $t
}

function Read-TextoArchivo {
    if (-not (Test-Path -LiteralPath $ArchivoTexto)) { return "" }
    $lector = New-Object System.IO.StreamReader($ArchivoTexto, $true)
    try { $t = $lector.ReadToEnd() } finally { $lector.Close() }
    return (Remove-SaltoFinal $t)
}

function Read-AjustesArchivo {
    $ms = 60
    $vari = 30
    $pausas = $true
    $errores = $true
    $cada = 100
    $dudas = $true
    if (Test-Path -LiteralPath $ArchivoAjustes) {
        $lector = New-Object System.IO.StreamReader($ArchivoAjustes, $true)
        try { $raw = $lector.ReadToEnd() } finally { $lector.Close() }
        foreach ($linea in ($raw -split "`r?`n")) {
            $linea = $linea.Trim()
            if ($linea -eq "" -or $linea.StartsWith(";")) { continue }
            if ($linea -match '^(?i)ms\s*=\s*(\d+)\s*$') { $ms = [int]$Matches[1] }
            elseif ($linea -match '^(?i)variacion\s*=\s*(\d+)\s*$') { $vari = [int]$Matches[1] }
            elseif ($linea -match '^(?i)pausas\s*=\s*([01])\s*$') { $pausas = ($Matches[1] -eq "1") }
            elseif ($linea -match '^(?i)errores\s*=\s*([01])\s*$') { $errores = ($Matches[1] -eq "1") }
            elseif ($linea -match '^(?i)cada\s*=\s*(\d+)\s*$') { $cada = [int]$Matches[1] }
            elseif ($linea -match '^(?i)dudas\s*=\s*([01])\s*$') { $dudas = ($Matches[1] -eq "1") }
        }
    }
    if ($ms -lt 0) { $ms = 0 }
    if ($ms -gt 120000) { $ms = 120000 }
    if ($vari -lt 0) { $vari = 0 }
    if ($vari -gt 120000) { $vari = 120000 }
    if ($cada -lt 8) { $cada = 8 }
    if ($cada -gt 20000) { $cada = 20000 }
    return [pscustomobject]@{ ms = $ms; variacion = $vari; pausas = $pausas; errores = $errores; cada = $cada; dudas = $dudas }
}

function ConvertTo-SendKeys([string]$ch) {
    switch ($ch) {
        '+' { return '{+}' }
        '^' { return '{^}' }
        '%' { return '{%}' }
        '~' { return '{~}' }
        '(' { return '{(}' }
        ')' { return '{)}' }
        '{' { return '{{}' }
        '}' { return '{}}' }
        "`t" { return '{TAB}' }
        default { return $ch }
    }
}

# Misma regla que escritor_humano_V3.ahk.
# Mas milisegundos = mas lento. No hay tope bajo: 50, 80, 120, 200 o mas.
function Get-Pausa([string]$ch, [int]$ms, [int]$vari, [bool]$humano) {
    if ($vari -gt 0) {
        $min = $ms - $vari
        $max = $ms + $vari
        if ($min -lt 0) { $min = 0 }
        if ($max -lt $min) { $max = $min }
        $d = Get-Random -Minimum $min -Maximum ($max + 1)
    } else {
        $d = $ms
        if ($d -lt 0) { $d = 0 }
    }
    if (-not $humano) { return [int]$d }
    if ($ch -eq "." -or $ch -eq "!" -or $ch -eq "?" -or $ch -eq ([string][char]0x2026)) {
        $d += [int][Math]::Round($ms * 2.5, [MidpointRounding]::AwayFromZero) + (Get-Random -Minimum 40 -Maximum 160)
    } elseif ($ch -eq ",") {
        $d += [int][Math]::Round($ms * 1.2, [MidpointRounding]::AwayFromZero) + (Get-Random -Minimum 20 -Maximum 90)
    } elseif ($ch -eq " " -or $ch -eq ([string][char]160)) {
        $d += [int][Math]::Round($ms * 0.4, [MidpointRounding]::AwayFromZero) + (Get-Random -Minimum 10 -Maximum 45)
    } elseif ($ch -eq "`n") {
        $d += [int][Math]::Round($ms * 2.0, [MidpointRounding]::AwayFromZero) + (Get-Random -Minimum 20 -Maximum 81)
    }
    return [int]$d
}

function Test-TeclaEscape {
    return (([EscritorHotkey]::GetAsyncKeyState(0x1B) -band 0x8000) -ne 0)
}

function Wait-Milisegundos([int]$ms) {
    if ($ms -lt 0) { $ms = 0 }
    $fin = [Environment]::TickCount + $ms
    while ($true) {
        if (Test-TeclaEscape) { return $false }
        $resta = $fin - [Environment]::TickCount
        if ($resta -le 0) { return $true }
        $paso = [Math]::Min(30, [int]$resta)
        if ($paso -lt 1) { $paso = 1 }
        Start-Sleep -Milliseconds $paso
        [System.Windows.Forms.Application]::DoEvents()
    }
}

function Send-TeclaTexto([string]$secuencia) {
    [System.Windows.Forms.SendKeys]::SendWait($secuencia)
}

function Test-Borrable([string]$ch) {
    return $ch -match '^[0-9A-Za-zÁÉÍÓÚÜÑáéíóúüñ]$'
}

function Get-Vecino([string]$ch) {
    $mayus = $false
    $letra = $ch
    if ($ch -match '^[A-Z]$') {
        $mayus = $true
        $letra = $ch.ToLower()
    }
    $mapa = @{
        a = "sqzw"; b = "vngh"; c = "xvdf"; d = "sfercx"; e = "wrsd"
        f = "dgrtcv"; g = "fhtybv"; h = "gjyunb"; i = "uokj"; j = "hkuinm"
        k = "jliom"; l = "kop"; m = "njk"; n = "bmhj"; o = "iplk"; p = "ol"
        q = "was"; r = "etdf"; s = "adwezx"; t = "ryfg"; u = "yihj"
        v = "cbfg"; w = "qeas"; x = "zcsd"; y = "tugh"; z = "asx"
    }
    if (-not $mapa.ContainsKey($letra)) { return "" }
    $grupo = $mapa[$letra]
    $malo = $grupo.Substring((Get-Random -Minimum 0 -Maximum $grupo.Length), 1)
    if ($mayus) { $malo = $malo.ToUpper() }
    return $malo
}

function Add-Reciente([string]$recientes, [string]$ch) {
    if (-not (Test-Borrable $ch)) { return "" }
    $recientes += $ch
    if ($recientes.Length -gt 16) { $recientes = $recientes.Substring($recientes.Length - 16) }
    return $recientes
}

function Get-EstadoDestino([IntPtr]$destino) {
    if (Test-TeclaEscape) { return "escape" }
    if ([EscritorHotkey]::GetForegroundWindow() -ne $destino) { return "ventana" }
    return "ok"
}

function Wait-Controlado([int]$ms, [IntPtr]$destino) {
    if (-not (Wait-Milisegundos $ms)) { return "escape" }
    return (Get-EstadoDestino $destino)
}

function Send-Uno([string]$ch, [IntPtr]$destino) {
    $est = Get-EstadoDestino $destino
    if ($est -ne "ok") { return $est }
    if ($ch -eq "`n" -or $ch -eq "`r") { Send-TeclaTexto "{ENTER}" }
    else { Send-TeclaTexto (ConvertTo-SendKeys $ch) }
    return (Get-EstadoDestino $destino)
}

function Send-Retroceso([IntPtr]$destino) {
    $est = Get-EstadoDestino $destino
    if ($est -ne "ok") { return $est }
    Send-TeclaTexto "{BACKSPACE}"
    return (Get-EstadoDestino $destino)
}

function Get-PausaRetroceso([int]$ms, [bool]$primero) {
    if ($primero) {
        $d = [int][Math]::Round($ms * 0.9, [MidpointRounding]::AwayFromZero) + (Get-Random -Minimum 70 -Maximum 161)
    } else {
        $d = [int][Math]::Round($ms * 0.72, [MidpointRounding]::AwayFromZero) + (Get-Random -Minimum 45 -Maximum 111)
    }
    if ($d -lt 45) { $d = 45 }
    return $d
}

function Get-PausaReescribir([int]$ms) {
    $base = $ms
    if ($base -lt 40) { $base = 40 }
    $bajo = [int]($base * 0.2)
    $alto = [int]($base * 0.25)
    if ($alto -lt 1) { $alto = 1 }
    $d = $base + (Get-Random -Minimum (-1 * $bajo) -Maximum ($alto + 1))
    $suelo = [int][Math]::Round($base * 0.7, [MidpointRounding]::AwayFromZero)
    if ($d -lt $suelo) { $d = $suelo }
    return $d
}

function Get-PausaCuenta([int]$ms) {
    return [int][Math]::Round($ms * 1.15, [MidpointRounding]::AwayFromZero) + (Get-Random -Minimum 110 -Maximum 281)
}

function Get-PausaTrasBorrar([int]$ms) {
    return [int][Math]::Round($ms * 0.9, [MidpointRounding]::AwayFromZero) + (Get-Random -Minimum 90 -Maximum 241)
}

function Get-PausaArranque([int]$ms) {
    return [int][Math]::Round($ms * 1.2, [MidpointRounding]::AwayFromZero) + (Get-Random -Minimum 80 -Maximum 241)
}

function Get-PausaDuda([int]$ms) {
    $d = [int][Math]::Round($ms * 2.8, [MidpointRounding]::AwayFromZero) + (Get-Random -Minimum 280 -Maximum 721)
    if ((Get-Random -Minimum 1 -Maximum 9) -eq 1) { $d += Get-Random -Minimum 400 -Maximum 901 }
    return $d
}

function Get-NuevaEspera([int]$cada, [bool]$primera) {
    if ($primera) {
        $bajo = [int][Math]::Round($cada * 0.2, [MidpointRounding]::AwayFromZero)
        $alto = $cada * 2
    } else {
        $bajo = [int][Math]::Round($cada * 0.55, [MidpointRounding]::AwayFromZero)
        $alto = [int][Math]::Round($cada * 1.45, [MidpointRounding]::AwayFromZero)
    }
    if ($bajo -lt 0) { $bajo = 0 }
    if ($alto -lt $bajo) { $alto = $bajo }
    return (Get-Random -Minimum $bajo -Maximum ($alto + 1))
}

function Send-Trozo([string]$trozo, [int]$ms, [IntPtr]$destino) {
    for ($k = 0; $k -lt $trozo.Length; $k++) {
        $est = Send-Uno $trozo.Substring($k, 1) $destino
        if ($est -ne "ok") { return $est }
        if ($k -lt ($trozo.Length - 1)) {
            $est = Wait-Controlado (Get-PausaReescribir $ms) $destino
            if ($est -ne "ok") { return $est }
        }
    }
    return (Get-EstadoDestino $destino)
}

function Invoke-Tropiezo([string]$ch, [string]$recientes, [int]$ms, [IntPtr]$destino) {
    $tiene = $recientes.Length -ge 3
    $vecino = Get-Vecino $ch
    $dado = Get-Random -Minimum 1 -Maximum 11
    $tipo = ""
    if ($tiene -and $dado -le 4) { $tipo = "trozo" }
    elseif ($vecino -ne "" -and $dado -le 8) { $tipo = "vecino" }
    elseif (Test-Borrable $ch) { $tipo = "repite" }
    elseif ($tiene) { $tipo = "trozo" }
    if ($tipo -eq "") { return [pscustomobject]@{ estado = "nada"; recientes = $recientes } }

    if ($tipo -eq "trozo") {
        $n = $recientes.Length
        if ($dado -eq 1) { $n = [Math]::Min($n, 5) }
        else { $n = Get-Random -Minimum 2 -Maximum ([Math]::Min(3, $recientes.Length) + 1) }
        $trozo = $recientes.Substring($recientes.Length - $n)
        for ($k = 0; $k -lt $n; $k++) {
            $est = Send-Retroceso $destino
            if ($est -ne "ok") { return [pscustomobject]@{ estado = $est; recientes = $recientes } }
            $est = Wait-Controlado (Get-PausaRetroceso $ms ($k -eq 0)) $destino
            if ($est -ne "ok") { return [pscustomobject]@{ estado = $est; recientes = $recientes } }
        }
        $est = Wait-Controlado (Get-PausaCuenta $ms) $destino
        if ($est -ne "ok") {
            $queda = ""
            if ($recientes.Length -gt $n) { $queda = $recientes.Substring(0, $recientes.Length - $n) }
            return [pscustomobject]@{ estado = $est; recientes = $queda }
        }
        $est = Send-Trozo $trozo $ms $destino
        if ($est -ne "ok") { return [pscustomobject]@{ estado = $est; recientes = $recientes } }
    } elseif ($tipo -eq "vecino") {
        $est = Send-Uno $vecino $destino
        if ($est -ne "ok") { return [pscustomobject]@{ estado = $est; recientes = $recientes } }
        $est = Wait-Controlado (Get-PausaCuenta $ms) $destino
        if ($est -ne "ok") { return [pscustomobject]@{ estado = $est; recientes = $recientes } }
        $est = Send-Retroceso $destino
        if ($est -ne "ok") { return [pscustomobject]@{ estado = $est; recientes = $recientes } }
        $est = Wait-Controlado (Get-PausaTrasBorrar $ms) $destino
        if ($est -ne "ok") { return [pscustomobject]@{ estado = $est; recientes = $recientes } }
    } else {
        $est = Send-Uno $ch $destino
        if ($est -ne "ok") { return [pscustomobject]@{ estado = $est; recientes = (Add-Reciente $recientes $ch) } }
        $est = Wait-Controlado (Get-PausaCuenta $ms) $destino
        if ($est -ne "ok") { return [pscustomobject]@{ estado = $est; recientes = (Add-Reciente $recientes $ch) } }
        $est = Send-Retroceso $destino
        if ($est -ne "ok") { return [pscustomobject]@{ estado = $est; recientes = $recientes } }
        $est = Wait-Controlado (Get-PausaTrasBorrar $ms) $destino
        if ($est -ne "ok") { return [pscustomobject]@{ estado = $est; recientes = $recientes } }
    }

    $est = Send-Uno $ch $destino
    return [pscustomobject]@{ estado = $est; recientes = (Add-Reciente $recientes $ch) }
}

function Invoke-Escritura {
    if ($script:escribiendo) { return }
    $script:escribiendo = $true
    $script:hk.Pendiente = $false
    try {
        $limite = [Environment]::TickCount + 500
        while (([EscritorHotkey]::GetAsyncKeyState($TeclaVK) -band 0x8000) -ne 0) {
            $script:hk.Pendiente = $false
            if (Test-TeclaEscape) { return }
            if (([Environment]::TickCount - $limite) -gt 0) { break }
            Start-Sleep -Milliseconds 10
            [System.Windows.Forms.Application]::DoEvents()
        }
        $script:hk.Pendiente = $false

        $ajustes = Read-AjustesArchivo
        $texto = Read-TextoArchivo
        if ([string]::IsNullOrEmpty($texto)) {
            $script:icono.ShowBalloonTip(4000, "escritor_humano_V3", "texto.txt esta vacio.", [System.Windows.Forms.ToolTipIcon]::Warning)
            return
        }

        if (-not (Wait-Milisegundos 30)) {
            $script:icono.ShowBalloonTip(3000, "escritor_humano_V3", "Escritura cancelada.", [System.Windows.Forms.ToolTipIcon]::Info)
            return
        }

        $destino = [EscritorHotkey]::GetForegroundWindow()
        $chars = $texto.ToCharArray()
        $i = 0
        $cancelado = $false
        $cambioVentana = $false
        $recientes = ""
        $espera = 0
        $esperaDuda = Get-Random -Minimum 1 -Maximum 5
        $acabo = $false
        if ($ajustes.errores) { $espera = Get-NuevaEspera $ajustes.cada $true }
        if ($ajustes.dudas -and -not (Wait-Milisegundos (Get-PausaArranque $ajustes.ms))) {
            $script:icono.ShowBalloonTip(3000, "escritor_humano_V3", "Escritura cancelada.", [System.Windows.Forms.ToolTipIcon]::Info)
            return
        }
        while ($i -lt $chars.Length) {
            if (Test-TeclaEscape) { $cancelado = $true; break }
            $ahora = [EscritorHotkey]::GetForegroundWindow()
            if ($ahora -ne $destino) { $cambioVentana = $true; break }
            $c = $chars[$i]
            $enviado = [string]$c
            if ($c -eq [char]13 -or $c -eq [char]10) {
                $enviado = "`n"
                $recientes = ""
                Send-TeclaTexto "{ENTER}"
                if ($c -eq [char]13 -and ($i + 1) -lt $chars.Length -and $chars[$i + 1] -eq [char]10) { $i++ }
            } else {
                $elegible = $ajustes.errores -and $espera -le 0 -and ((Test-Borrable $enviado) -or $recientes.Length -ge 3)
                if ($elegible) {
                    $r = Invoke-Tropiezo $enviado $recientes $ajustes.ms $destino
                    $recientes = $r.recientes
                    if ($r.estado -eq "nada") {
                        Send-TeclaTexto (ConvertTo-SendKeys $enviado)
                        $recientes = Add-Reciente $recientes $enviado
                    } elseif ($r.estado -eq "escape") {
                        $cancelado = $true
                        break
                    } elseif ($r.estado -eq "ventana") {
                        $cambioVentana = $true
                        break
                    } else {
                        $espera = Get-NuevaEspera $ajustes.cada $false
                        $acabo = $true
                    }
                } else {
                    Send-TeclaTexto (ConvertTo-SendKeys $enviado)
                    $recientes = Add-Reciente $recientes $enviado
                    if ($ajustes.errores -and $espera -gt 0) { $espera-- }
                }
            }
            $i++
            if ($i -lt $chars.Length) {
                $pausa = Get-Pausa $enviado $ajustes.ms $ajustes.variacion $ajustes.pausas
                if ($acabo) {
                    $pausa += [int][Math]::Round($ajustes.ms * 0.7, [MidpointRounding]::AwayFromZero) + (Get-Random -Minimum 50 -Maximum 161)
                    $acabo = $false
                }
                if ($ajustes.dudas -and ($enviado -eq " " -or $enviado -eq "`n")) {
                    if ($esperaDuda -le 0) {
                        $pausa += Get-PausaDuda $ajustes.ms
                        $esperaDuda = Get-Random -Minimum 6 -Maximum 14
                    } else {
                        $esperaDuda--
                    }
                }
                if (-not (Wait-Milisegundos $pausa)) { $cancelado = $true; break }
            }
        }
        if ($cancelado) {
            $script:icono.ShowBalloonTip(3000, "escritor_humano_V3", "Escritura cancelada.", [System.Windows.Forms.ToolTipIcon]::Info)
        } elseif ($cambioVentana) {
            $script:icono.ShowBalloonTip(4000, "escritor_humano_V3", "Se paro porque cambio la ventana activa.", [System.Windows.Forms.ToolTipIcon]::Warning)
        }
    } catch {
        $script:icono.ShowBalloonTip(5000, "escritor_humano_V3", $_.Exception.Message, [System.Windows.Forms.ToolTipIcon]::Error)
    } finally {
        $script:hk.Pendiente = $false
        $script:escribiendo = $false
    }
}

function Show-Ayuda {
    $ajustes = Read-AjustesArchivo
    $msg = "F8 escribe este archivo, letra a letra:`r`n$ArchivoTexto`r`n`r`nEscape cancela.`r`n`r`nMilisegundos: $($ajustes.ms)`r`nVariacion: $($ajustes.variacion)`r`nPausas humanas: $(if ($ajustes.pausas) { 'si' } else { 'no' })`r`nTropiezos: $(if ($ajustes.errores) { 'si, cada ' + $ajustes.cada + ' letras' } else { 'no' })`r`nPausas de duda: $(if ($ajustes.dudas) { 'si' } else { 'no' })`r`n`r`nEsos numeros estan en ajustes.ini.`r`nClic derecho en el icono y Salir para cerrar."
    [System.Windows.Forms.MessageBox]::Show($msg, "escritor_humano_V3")
}

if ($args -contains "-Comprobar") {
    $t = Read-TextoArchivo
    $a = Read-AjustesArchivo
    Write-Output ("caracteres=" + $t.Length)
    Write-Output ("ms=" + $a.ms)
    Write-Output ("variacion=" + $a.variacion)
    Write-Output ("pausas=" + [int]$a.pausas)
    Write-Output ("errores=" + [int]$a.errores)
    Write-Output ("cada=" + $a.cada)
    Write-Output ("dudas=" + [int]$a.dudas)
    Write-Output ("tecla=" + $TeclaVK)
    Write-Output ("mod=" + $TeclaMod)
    exit 0
}

$script:escribiendo = $false
$script:tieneMutex = $false
$script:mutex = New-Object System.Threading.Mutex($false, "Local\escritor_humano_V3PowerShell")
try {
    $script:tieneMutex = $script:mutex.WaitOne(0, $false)
} catch [System.Threading.AbandonedMutexException] {
    $script:tieneMutex = $true
}
if (-not $script:tieneMutex) {
    [System.Windows.Forms.MessageBox]::Show("escritor_humano_V3 (PowerShell) ya esta abierto. Mira el icono de la bandeja y, si quieres cerrarlo, clic derecho y Salir.", "escritor_humano_V3")
    exit 1
}

$script:hk = $null
$script:icono = $null
$script:timer = $null
$script:ctx = $null

try {
    $script:hk = New-Object EscritorHotkey -ArgumentList @($TeclaMod, $TeclaVK)
    $script:ctx = New-Object System.Windows.Forms.ApplicationContext

    $script:icono = New-Object System.Windows.Forms.NotifyIcon
    $script:icono.Icon = [System.Drawing.SystemIcons]::Application
    $script:icono.Visible = $true
    $script:icono.Text = "escritor_humano_V3: F8 escribe, Esc cancela"

    $menu = New-Object System.Windows.Forms.ContextMenuStrip
    $itemAyuda = $menu.Items.Add("Como usarlo")
    $itemAyuda.Add_Click({ Show-Ayuda })
    $itemSalir = $menu.Items.Add("Salir")
    $itemSalir.Add_Click({
        try { $script:hk.Cerrar() } catch { }
        $script:icono.Visible = $false
        $script:ctx.ExitThread()
    })
    $script:icono.ContextMenuStrip = $menu
    $script:icono.Add_DoubleClick({ Show-Ayuda })

    $script:timer = New-Object System.Windows.Forms.Timer
    $script:timer.Interval = 30
    $script:avisado = $false
    $script:timer.Add_Tick({
        if (-not $script:avisado) {
            $script:avisado = $true
            if (-not $script:hk.HotkeyOk) {
                [System.Windows.Forms.MessageBox]::Show("No se pudo registrar F8. Si ya hay una copia, cierrala desde el icono de la bandeja, Salir.", "escritor_humano_V3")
                try { $script:hk.Cerrar() } catch { }
                $script:icono.Visible = $false
                $script:ctx.ExitThread()
                return
            }
            $script:icono.ShowBalloonTip(4000, "escritor_humano_V3", "Pulsa F8 en el cuadro de destino. Escape cancela.", [System.Windows.Forms.ToolTipIcon]::Info)
        }
        if ($script:hk.Pendiente -and -not $script:escribiendo) {
            $script:hk.Pendiente = $false
            Invoke-Escritura
        }
    })
    $script:timer.Start()

    [System.Windows.Forms.Application]::Run($script:ctx)
} catch {
    try {
        [System.Windows.Forms.MessageBox]::Show($_.Exception.Message, "escritor_humano_V3")
    } catch { }
    exit 1
} finally {
    if ($script:timer) {
        try { $script:timer.Stop() } catch { }
        try { $script:timer.Dispose() } catch { }
    }
    if ($script:hk) {
        try { $script:hk.Cerrar() } catch { }
    }
    if ($script:icono) {
        $script:icono.Visible = $false
        try { $script:icono.Dispose() } catch { }
    }
    if ($script:tieneMutex) {
        try { $script:mutex.ReleaseMutex() | Out-Null } catch { }
    }
}
