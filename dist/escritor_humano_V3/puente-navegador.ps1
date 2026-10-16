# Keeps typing into the browser field that was focused when writing started,
# after the user clicks another window or another box.
# AutoHotkey talks to this process through a local pipe. One JSON object per line.
$ErrorActionPreference = "Stop"
Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes
Add-Type @"
using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using System.Text;
public class EhChromeWin {
    public delegate bool EnumProc(IntPtr h, IntPtr l);
    [DllImport("user32.dll")] public static extern bool EnumChildWindows(IntPtr parent, EnumProc cb, IntPtr l);
    [DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern int GetClassName(IntPtr h, StringBuilder s, int n);
    [DllImport("user32.dll")] public static extern bool PostMessage(IntPtr h, uint msg, IntPtr w, IntPtr l);
    [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
    [DllImport("oleacc.dll")] public static extern int AccessibleObjectFromPoint(POINT pt, [MarshalAs(UnmanagedType.IDispatch)] out object acc, [MarshalAs(UnmanagedType.Struct)] out object child);
    public struct POINT { public int X; public int Y; }
    public static List<IntPtr> Found = new List<IntPtr>();
    static EnumProc _keep;
    static bool OnChild(IntPtr h, IntPtr l) {
        var sb = new StringBuilder(256);
        GetClassName(h, sb, 256);
        string c = sb.ToString();
        if (c == "Chrome_RenderWidgetHostHWND" || c == "MozillaCompositorWindowClass" || c == "MozillaWindowClass")
            Found.Add(h);
        return true;
    }
    public static void Collect(IntPtr parent) {
        Found.Clear();
        if (_keep == null) _keep = OnChild;
        if (parent != IntPtr.Zero) EnumChildWindows(parent, _keep, IntPtr.Zero);
    }
    public static IntPtr ToPtr(long n) { return new IntPtr(n); }
}
"@

$script:el = $null
$script:text = ""
$script:caret = 0
$script:selLen = 0
$script:vp = $null
$script:render = [IntPtr]::Zero
$script:acc = $null

function Write-Log([string]$m) {
    try {
        $ruta = Join-Path $env:TEMP "eh-puente.log"
        [IO.File]::AppendAllText($ruta, ((Get-Date).ToString("HH:mm:ss.fff") + " " + $m + "`r`n"))
    } catch {}
}

function Reset-State {
    $script:el = $null
    $script:text = ""
    $script:caret = 0
    $script:selLen = 0
    $script:vp = $null
    $script:render = [IntPtr]::Zero
    $script:acc = $null
    $script:accList = @()
}

function Read-PipeLine($pipe) {
    $ms = New-Object System.IO.MemoryStream
    $one = New-Object byte[] 1
    while ($true) {
        $n = 0
        try { $n = $pipe.Read($one, 0, 1) } catch { return $null }
        if ($n -le 0) { return $null }
        if ($one[0] -eq 10) { break }
        if ($one[0] -ne 13) { $ms.WriteByte($one[0]) }
        if ($ms.Length -gt 200000) { break }
    }
    return [Text.Encoding]::UTF8.GetString($ms.ToArray())
}

function Write-PipeLine($pipe, [string]$s) {
    $b = [Text.Encoding]::UTF8.GetBytes($s + "`n")
    $pipe.Write($b, 0, $b.Length)
    $pipe.Flush()
}

function Unescape-Json([string]$s) {
    if ($null -eq $s) { return "" }
    $sb = New-Object System.Text.StringBuilder
    for ($i = 0; $i -lt $s.Length; $i++) {
        $c = $s[$i]
        if ($c -eq "\" -and ($i + 1) -lt $s.Length) {
            $n = $s[$i + 1]
            switch ($n) {
                "n" { [void]$sb.Append("`n") }
                "r" { [void]$sb.Append("`r") }
                "t" { [void]$sb.Append("`t") }
                "\" { [void]$sb.Append("\") }
                '"' { [void]$sb.Append('"') }
                default { [void]$sb.Append($n) }
            }
            $i++
        } else {
            [void]$sb.Append($c)
        }
    }
    return $sb.ToString()
}

function Get-JsonString([string]$line, [string]$key) {
    $pat = '"' + [regex]::Escape($key) + '"\s*:\s*"((?:\\.|[^"\\])*)"'
    $m = [regex]::Match($line, $pat)
    if (-not $m.Success) { return $null }
    return (Unescape-Json $m.Groups[1].Value)
}

function Get-JsonLong([string]$line, [string]$key) {
    $pat = '"' + [regex]::Escape($key) + '"\s*:\s*(-?\d+)'
    $m = [regex]::Match($line, $pat)
    if (-not $m.Success) { return [int64]0 }
    return [int64]$m.Groups[1].Value
}

function Id-Of($el) {
    return ((@($el.GetRuntimeId())) -join ",")
}

function Wake-Browser([int64]$hwnd, [int64]$ctrl) {
    $vistos = @{}
    foreach ($n in @($hwnd, $ctrl)) {
        if ($n -eq 0) { continue }
        $p = [EhChromeWin]::ToPtr($n)
        $k = $p.ToInt64()
        if ($vistos.ContainsKey($k)) { continue }
        $vistos[$k] = $true
        try { [void][System.Windows.Automation.AutomationElement]::FromHandle($p) } catch {}
    }
    if ($hwnd -ne 0) {
        [EhChromeWin]::Collect([EhChromeWin]::ToPtr($hwnd))
        foreach ($h in @([EhChromeWin]::Found)) {
            $k = $h.ToInt64()
            if ($vistos.ContainsKey($k)) { continue }
            $vistos[$k] = $true
            try { [void][System.Windows.Automation.AutomationElement]::FromHandle($h) } catch {}
        }
    }
}

function Get-Editable($start) {
    if ($null -eq $start) { return $null }
    $walker = [System.Windows.Automation.TreeWalker]::ControlViewWalker
    $cur = $start
    for ($i = 0; $i -lt 14 -and $null -ne $cur; $i++) {
        $ct = $null
        try { $ct = $cur.Current.ControlType } catch { break }
        if ($ct -eq [System.Windows.Automation.ControlType]::Document) { break }
        if ($ct -eq [System.Windows.Automation.ControlType]::Window) { break }
        $has = $false
        try {
            $null = $cur.GetCurrentPattern([System.Windows.Automation.ValuePattern]::Pattern)
            $has = $true
        } catch {}
        $sirve = $ct -eq [System.Windows.Automation.ControlType]::Edit `
            -or $ct -eq [System.Windows.Automation.ControlType]::Custom `
            -or $ct -eq [System.Windows.Automation.ControlType]::Group `
            -or $ct -eq [System.Windows.Automation.ControlType]::Document
        if ($has -and $ct -ne [System.Windows.Automation.ControlType]::Document -and $ct -ne [System.Windows.Automation.ControlType]::Window -and $ct -ne [System.Windows.Automation.ControlType]::Pane) {
            if ($sirve -or $ct -eq [System.Windows.Automation.ControlType]::Edit) { return $cur }
            if ($ct -eq [System.Windows.Automation.ControlType]::ComboBox) { return $cur }
            # Address bar and page boxes are Edit. Groups are contenteditable.
            if ($ct -ne [System.Windows.Automation.ControlType]::Button -and $ct -ne [System.Windows.Automation.ControlType]::ToolBar) { return $cur }
        }
        try { $cur = $walker.GetParent($cur) } catch { break }
    }
    return $null
}

function Read-Value {
    $vp = $script:el.GetCurrentPattern([System.Windows.Automation.ValuePattern]::Pattern)
    return [string]$vp.Current.Value
}

function Get-CaretInfo {
    $start = -1
    $len = 0
    try {
        $tp = $script:el.GetCurrentPattern([System.Windows.Automation.TextPattern]::Pattern)
        $sels = @($tp.GetSelection())
        if ($sels.Length -lt 1) { return @{ Start = -1; Len = 0 } }
        $doc = $tp.DocumentRange
        $to = $doc.Clone()
        $to.MoveEndpointByRange(
            [System.Windows.Automation.Text.TextPatternRangeEndpoint]::End,
            $sels[0],
            [System.Windows.Automation.Text.TextPatternRangeEndpoint]::Start)
        $antes = [string]$to.GetText(-1)
        $sel = [string]$sels[0].GetText(-1)
        $start = $antes.Length
        $len = $sel.Length
    } catch {}
    return @{ Start = $start; Len = $len }
}

function Edit-Model([string]$t, [bool]$bs) {
    if ($script:selLen -gt 0) {
        $n = [Math]::Min([int]$script:selLen, [Math]::Max(0, $script:text.Length - $script:caret))
        if ($n -gt 0) { $script:text = $script:text.Remove($script:caret, $n) }
        $script:selLen = 0
        if ($bs) { return }
    }
    if ($bs) {
        if ($script:caret -le 0) { return }
        $n = 1
        if ($script:caret -ge 2) {
            $code = [int]$script:text[$script:caret - 1]
            if ($code -ge 0xDC00 -and $code -le 0xDFFF) { $n = 2 }
        }
        if ($script:caret - $n -lt 0) { $n = $script:caret }
        $script:text = $script:text.Remove($script:caret - $n, $n)
        $script:caret -= $n
        return
    }
    if ($null -eq $t -or $t -eq "") { return }
    $script:text = $script:text.Insert($script:caret, $t)
    $script:caret += $t.Length
}

function Push-Value {
    if ($null -eq $script:vp) {
        $script:vp = $script:el.GetCurrentPattern([System.Windows.Automation.ValuePattern]::Pattern)
    }
    try {
        $script:vp.SetValue($script:text)
    } catch {
        $script:vp = $script:el.GetCurrentPattern([System.Windows.Automation.ValuePattern]::Pattern)
        $script:vp.SetValue($script:text)
    }
}

function Find-FocusedEdit($handles) {
    $cond = New-Object System.Windows.Automation.PropertyCondition(
        [System.Windows.Automation.AutomationElement]::ControlTypeProperty,
        [System.Windows.Automation.ControlType]::Edit)
    foreach ($h in @($handles)) {
        if ($h -eq [IntPtr]::Zero) { continue }
        $root = $null
        try { $root = [System.Windows.Automation.AutomationElement]::FromHandle($h) } catch { continue }
        $edits = $root.FindAll([System.Windows.Automation.TreeScope]::Descendants, $cond)
        foreach ($e in @($edits)) {
            try {
                if ($e.Current.HasKeyboardFocus) { return $e }
            } catch {}
        }
    }
    return $null
}

function Do-Bind([int64]$hwnd, [int64]$ctrl) {
    $script:el = $null
    $script:vp = $null
    $script:hwndTop = $hwnd
    for ($intento = 0; $intento -lt 2; $intento++) {
        Wake-Browser $hwnd $ctrl
        $handles = @()
        if ($hwnd -ne 0) {
            [EhChromeWin]::Collect([EhChromeWin]::ToPtr($hwnd))
            $handles = @([EhChromeWin]::Found)
        }
        if ($ctrl -ne 0) { $handles += [EhChromeWin]::ToPtr($ctrl) }
        $focused = $null
        try { $focused = [System.Windows.Automation.AutomationElement]::FocusedElement } catch {}
        $ed = Get-Editable $focused
        if ($null -eq $ed) { $ed = Find-FocusedEdit $handles }
        if ($null -ne $ed) {
            $script:el = $ed
            break
        }
        Start-Sleep -Milliseconds 90
    }
    if ($null -eq $script:el) { return '{"ok":false}' }
    Remember-Render $script:el
    Remember-Acc $script:el
    $script:text = Read-Value
    $info = Get-CaretInfo
    if ($info.Start -ge 0 -and $info.Start -le $script:text.Length) { $script:caret = [int]$info.Start }
    else { $script:caret = $script:text.Length }
    $script:selLen = 0
    if ($info.Len -gt 0 -and $info.Len -lt $script:text.Length) { $script:selLen = [int]$info.Len }
    Write-Log ("bind n=" + $script:text.Length + " c=" + $script:caret + " r=" + $script:render.ToInt64() + " acc=" + [int]($null -ne $script:acc))
    return ('{"ok":true,"n":' + $script:text.Length + ',"c":' + $script:caret + "}")
}

function Do-Mismo {
    if ($null -eq $script:el) { return '{"ok":true,"mismo":false}' }
    # Metin2 no responde a UI Automation. Preguntarle cuál es el cuadro
    # enfocado deja el puente colgado y la escritura se para.
    $fg = [EhChromeWin]::GetForegroundWindow()
    $csb = New-Object System.Text.StringBuilder 200
    [void][EhChromeWin]::GetClassName($fg, $csb, 200)
    if ($csb.ToString().StartsWith("eter")) { return '{"ok":true,"mismo":true}' }
    $want = ""
    try { $want = Id-Of $script:el } catch { return '{"ok":true,"mismo":false}' }
    $cur = $null
    try { $cur = [System.Windows.Automation.AutomationElement]::FocusedElement } catch { return '{"ok":true,"mismo":false}' }
    $walker = [System.Windows.Automation.TreeWalker]::ControlViewWalker
    for ($i = 0; $i -lt 14 -and $null -ne $cur; $i++) {
        try {
            if ((Id-Of $cur) -eq $want) { return '{"ok":true,"mismo":true}' }
        } catch {}
        try { $cur = $walker.GetParent($cur) } catch { break }
    }
    return '{"ok":true,"mismo":false}'
}

function Do-Foto {
    if ($null -eq $script:el) { return '{"ok":false}' }
    $live = $null
    for ($k = 0; $k -lt 6; $k++) {
        try { $live = Read-Value } catch { $live = $null }
        if ($null -ne $live) {
            $normL = ($live -replace "`r`n", "`n") -replace "`r", "`n"
            $normM = ($script:text -replace "`r`n", "`n") -replace "`r", "`n"
            if ($normL -eq $normM) {
                if ($live -ne $script:text) { $script:text = $live }
                $script:selLen = 0
                Write-Log ("foto igual c=" + $script:caret)
                return '{"ok":true}'
            }
        }
        Start-Sleep -Milliseconds 40
    }
    if ($null -eq $live) { return '{"ok":false}' }
    $antes = $script:caret
    $info = Get-CaretInfo
    $script:text = $live
    $script:selLen = 0
    $todo = $info.Len -gt 0 -and $live.Length -gt 0 -and $info.Len -ge ($live.Length - 1)
    if ($todo) {
        if ($antes -gt $live.Length) { $script:caret = $live.Length } else { $script:caret = $antes }
    } elseif ($info.Start -ge 0 -and $info.Start -le $live.Length) {
        $script:caret = [int]$info.Start
    } else {
        $script:caret = $live.Length
    }
    Write-Log ("foto adopta n=" + $live.Length + " c=" + $script:caret)
    return '{"ok":true}'
}

function Do-Nota([string]$t, [bool]$bs) {
    if ($null -eq $script:el) { return '{"ok":false}' }
    Edit-Model $t $bs
    return '{"ok":true}'
}

function Remember-Render($ed) {
    $script:render = [IntPtr]::Zero
    $walker = [System.Windows.Automation.TreeWalker]::ControlViewWalker
    $cur = $ed
    for ($i = 0; $i -lt 18 -and $null -ne $cur; $i++) {
        try {
            $nh = [IntPtr]$cur.Current.NativeWindowHandle
            if ($nh -ne [IntPtr]::Zero) {
                $sb = New-Object System.Text.StringBuilder 220
                [void][EhChromeWin]::GetClassName($nh, $sb, 220)
                if ($sb.ToString() -eq "Chrome_RenderWidgetHostHWND") {
                    $script:render = $nh
                    return
                }
            }
        } catch {}
        try { $cur = $walker.GetParent($cur) } catch { break }
    }
    if ($script:hwndTop -ne 0) {
        [EhChromeWin]::Collect([EhChromeWin]::ToPtr([int64]$script:hwndTop))
        $best = [IntPtr]::Zero
        $bestN = -1
        foreach ($h in @([EhChromeWin]::Found)) {
            try {
                $root = [System.Windows.Automation.AutomationElement]::FromHandle($h)
                $n = $root.FindAll([System.Windows.Automation.TreeScope]::Descendants, [System.Windows.Automation.Condition]::TrueCondition).Count
                if ($n -gt $bestN) { $bestN = $n; $best = $h }
            } catch {}
        }
        if ($bestN -gt 0) { $script:render = $best }
    }
}

function Do-Enfocar {
    if ($null -eq $script:el) { return '{"ok":false}' }
    try { $script:el.SetFocus() } catch { return '{"ok":false}' }
    return '{"ok":true}'
}

function Remember-Acc($ed) {
    $script:acc = $null
    $script:accList = @()
    try {
        $rect = $ed.Current.BoundingRectangle
        if ($rect.Width -lt 2 -or $rect.Height -lt 2) { return }
        $esperado = ""
        try { $esperado = [string]($ed.GetCurrentPattern([System.Windows.Automation.ValuePattern]::Pattern).Current.Value) } catch {}
        $y = [int]($rect.Y + ($rect.Height / 2))
        $cortes = @(4, 8, 16, 28, 48)
        if ($rect.Width -gt 80) { $cortes += [int]($rect.Width / 2) }
        $lista = @()
        foreach ($dx in $cortes) {
            if ($dx -ge $rect.Width) { continue }
            $pt = New-Object EhChromeWin+POINT
            $pt.X = [int]($rect.X + $dx)
            $pt.Y = $y
            $acc = $null
            $child = $null
            $hr = [EhChromeWin]::AccessibleObjectFromPoint($pt, [ref]$acc, [ref]$child)
            if ($hr -ne 0 -or $null -eq $acc) { continue }
            $val = $null
            try {
                $val = [string]$acc.GetType().InvokeMember("accValue", [Reflection.BindingFlags]::GetProperty, $null, $acc, @(0))
            } catch { continue }
            if ($val -eq $esperado) { $lista += $acc }
        }
        $script:accList = $lista
        if ($lista.Count -gt 0) { $script:acc = $lista[0] }
    } catch {}
}

function Set-AccValue([string]$text) {
    $vistos = New-Object System.Collections.Generic.List[object]
    if ($null -ne $script:acc) { [void]$vistos.Add($script:acc) }
    if ($script:accList) {
        foreach ($a in @($script:accList)) {
            if ($null -ne $a) { [void]$vistos.Add($a) }
        }
    }
    foreach ($a in $vistos) {
        try {
            $null = $a.GetType().InvokeMember(
                "accValue",
                [Reflection.BindingFlags]::SetProperty,
                $null,
                $a,
                @(0, [string]$text))
            $live = Read-Value
            if ($live -eq $text) {
                $script:acc = $a
                return $true
            }
        } catch {}
    }
    return $false
}

function Test-VentanaOriginal([IntPtr]$fg) {
    if ($fg -eq [IntPtr]::Zero) { return $false }
    if ($script:hwndTop -eq $null -or [int64]$script:hwndTop -eq 0) { return $false }
    return ($fg.ToInt64() -eq [int64]$script:hwndTop)
}

function Do-Tecla([string]$t, [bool]$bs) {
    # Siempre el mismo camino: el cuadro guardado al pulsar F8.
    # No depende de quien tenga el foco, no mueve el raton y no pulsa teclas.
    Edit-Model $t $bs
    if (Set-AccValue $script:text) { return '{"ok":true}' }
    if ($null -ne $script:el) { Remember-Acc $script:el }
    if (Set-AccValue $script:text) { return '{"ok":true}' }
    Write-Log "tecla-fallo"
    return '{"ok":false}'
}

function Do-Ins([string]$t, [bool]$bs) {
    if ($null -eq $script:el) { return '{"ok":false}' }
    Edit-Model $t $bs
    Push-Value
    return '{"ok":true}'
}

Write-Log "boot"
while ($true) {
    $pipe = $null
    try {
        $pipe = New-Object System.IO.Pipes.NamedPipeServerStream(
            "escritor_humano_v3_chrome",
            [System.IO.Pipes.PipeDirection]::InOut,
            1,
            [System.IO.Pipes.PipeTransmissionMode]::Byte,
            [System.IO.Pipes.PipeOptions]::None,
            65536,
            65536)
    } catch {
        Write-Log "pipe-ocupado"
        exit 0
    }
    try {
        $pipe.WaitForConnection()
        Reset-State
        Write-Log "conectado"
        while ($pipe.IsConnected) {
            $line = Read-PipeLine $pipe
            if ($null -eq $line -or $line -eq "") {
                if (-not $pipe.IsConnected) { break }
                if ($null -eq $line) { break }
                continue
            }
            $cmd = ""
            if ($line -match '"cmd"\s*:\s*"([a-z]+)"') { $cmd = $Matches[1] }
            $resp = '{"ok":false}'
            try {
                switch ($cmd) {
                    "ping" { $resp = '{"ok":true}' }
                    "bind" { $resp = Do-Bind (Get-JsonLong $line "hwnd") (Get-JsonLong $line "ctrl") }
                    "mismo" { $resp = Do-Mismo }
                    "foto" { $resp = Do-Foto }
                    "nota" {
                        $bs = $line -match '"bs"\s*:\s*true'
                        $resp = Do-Nota (Get-JsonString $line "t") $bs
                    }
                    "ins" {
                        $bs = $line -match '"bs"\s*:\s*true'
                        $resp = Do-Ins (Get-JsonString $line "t") $bs
                    }
                    "tecla" {
                        $bs = $line -match '"bs"\s*:\s*true'
                        $resp = Do-Tecla (Get-JsonString $line "t") $bs
                    }
                    "enfocar" { $resp = Do-Enfocar }
                    "salir" { $resp = '{"ok":true}' }
                    default { $resp = '{"ok":false}' }
                }
            } catch {
                Write-Log ($cmd + " " + $_.Exception.GetType().Name)
                $resp = '{"ok":false}'
            }
            Write-Log $cmd
            try { Write-PipeLine $pipe $resp } catch { break }
            if ($cmd -eq "salir") { exit 0 }
        }
    } catch {
        Write-Log ("bucle " + $_.Exception.GetType().Name)
    } finally {
        if ($pipe) { try { $pipe.Dispose() } catch {} }
    }
    Start-Sleep -Milliseconds 80
}
