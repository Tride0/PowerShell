function Start-SmartSleep {
    param(
        [DateTime]$WaitDateTime,
        [int]$Seconds,
        $CheckIntervalSeconds = 600,
        $IntervalReductionRatePercentage = 20,
        [Boolean]$PreventIdle = $True
    )
    if (![Boolean]$Global:StartTime) { $Global:StartTime = Get-Date }

    if (![Boolean]$Global:ObjShell -and $PreventIdle) {
        $Global:ObjShell = New-Object -ComObject wscript.shell
    }

    if ([Boolean]$Seconds -and ![Boolean]$WaitDateTime) {
        $WaitDateTime = (Get-Date).AddSeconds($Seconds)
    }
    $SecondsLeft = ($WaitDateTime - (Get-Date)).TotalSeconds
    
    while ($SecondsLeft -gt 0 -and $SecondsLeft -le $CheckIntervalSeconds) {
        $CheckIntervalSeconds = $SecondsLeft * $IntervalReductionRatePercentage / 100
        if ($SecondsLeft -lt $CheckIntervalSeconds) { $CheckIntervalSeconds = 1 }
        elseif ($CheckIntervalSeconds -lt 1) { $CheckIntervalSeconds = ($WaitDateTime - (Get-Date)).TotalSeconds }
    }

    while ((Get-Date) -lt $WaitDateTime -and $SecondsLeft -gt $CheckIntervalSeconds) {
        if ($PreventIdle) { $Global:ObjShell.SendKeys('{SCROLLLOCK}') }
        #Write-Host "[$(Get-Date)] $CheckIntervalSeconds Seconds checks until $WaitDateTime. $(($WaitDateTime-(Get-Date)).TotalSeconds) Seconds Left."
        Start-Sleep -Seconds $CheckIntervalSeconds

        $SecondsLeft = ($WaitDateTime - (Get-Date)).TotalSeconds
        if ($SecondsLeft -lt 1 -and $SecondsLeft -gt 0) {
            #Write-Host "[$(Get-Date)] Waiting $SecondsLeft Seconds to finish."
            Start-Sleep -Seconds $SecondsLeft
        }
    }

    # Set new interval
    if ((Get-Date) -lt $WaitDateTime -and $SecondsLeft -gt 0) {
        Start-SmartSleep -WaitDateTime $WaitDateTime -CheckIntervalSeconds $CheckIntervalSeconds -IntervalReductionRate $IntervalReductionRatePercentage
    }
    else { ((Get-Date) - $StartTime).TotalSeconds }
}

Start-SmartSleep -Seconds 4