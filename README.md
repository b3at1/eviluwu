# eviluwu ÙwÚ

A proof-of-concept prank script designed to annoy friends by injecting "uwu" into their keystrokes.

## ⚠️ Disclaimer
**This project is for educational purposes only.** Do not use this software on systems you do not own or have explicit permission to test on. The author is not responsible for any misuse or damage caused by this program.

## Overview
`eviluwu` is a multi-stage payload that ultimately runs a background PowerShell script. This script **does not** monitor keyboard input, instead it simply interrupts typing flow by automatically typing "uwu" after a set number of keystrokes.

## Architecture & How it Works

The execution flow involves four main components chaining together to hide execution and persistence.

## Usage

1. run the starter.ps1 (doesn't have to be ps1, it's a one-liner!)
2. timuwue to watch the wouwurld burn!
### 1. `starter.ps1`
This is the entry point. It contains the initial logic to bootstrap the process. 
- It locates and executes the Windows Script Component (`.wsc`) remotely.
- Registers a scheduled task to keep persistence.

### 2. `WPXService.wsc`
Acts as an intermediary to invoke the VBScript.
- Invokes the hidden PowerShell logic via `HP.vbs`.

### 3. `HP.vbs`
Based on the [HiddenPowershell](https://github.com/UNT-CAS/HiddenPowershell) technique.
- This script is saved to a temporary directory.
- It executes a PowerShell command window in a hidden state (WindowStyle Hidden).
- It fetches and executes the final payload (`uwu.ps1`) from a remote source.

### 4. `uwu.ps1` (The Payload)
The core logic resides here.
- It runs in the background.
- Every 21 characters typed (including previous "uwu"s), it simulates keystrokes to type "uwu".

## Removal
powershell: `Unregister-ScheduledTask -TaskName "MicrosoftEdgeUpdateUpdaterTaskMachineCore" -Confirm:$false`
cmd: `schtasks /delete /tn "MicrosoftEdgeUpdateUpdaterTaskMachineCore" /f`

## Credits
- UNT-CAS for the [Hidden PowerShell Script technique](https://github.com/UNT-CAS/HiddenPowershell/blob/master/HiddenPowershell.vbs) used in `HP.vbs`.