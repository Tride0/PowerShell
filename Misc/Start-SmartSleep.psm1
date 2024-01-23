Function Start-SmartSleep {
    Param(
        [DateTime]$WaitDateTime,
        [int]$Seconds,
        $CheckIntervalSeconds = 600,
        $IntervalReductionRatePercentage = 20,
        [Boolean]$PreventIdle = $True
    )
    If (![Boolean]$Global:StartTime) { $Global:StartTime = Get-Date }

    If (![Boolean]$Global:ObjShell -and $PreventIdle) {
        $Global:ObjShell = New-Object -ComObject wscript.shell
    }

    If ([Boolean]$Seconds -and ![Boolean]$WaitDateTime) {
        $WaitDateTime = (Get-Date).AddSeconds($Seconds)
    }
    $SecondsLeft = ($WaitDateTime - (Get-Date)).TotalSeconds
    
    While ($SecondsLeft -gt 0 -and $SecondsLeft -le $CheckIntervalSeconds) {
        $CheckIntervalSeconds = $SecondsLeft * $IntervalReductionRatePercentage / 100
        If ($SecondsLeft -lt $CheckIntervalSeconds) { $CheckIntervalSeconds = 1 }
        ElseIf ($CheckIntervalSeconds -lt 1) { $CheckIntervalSeconds = ($WaitDateTime - (Get-Date)).TotalSeconds }
    }

    While ((Get-Date) -lt $WaitDateTime -and $SecondsLeft -gt $CheckIntervalSeconds) {
        If ($PreventIdle) { $Global:ObjShell.SendKeys('{SCROLLLOCK}') }
        #Write-Host "[$(Get-Date)] $CheckIntervalSeconds Seconds checks until $WaitDateTime. $(($WaitDateTime-(Get-Date)).TotalSeconds) Seconds Left."
        Start-Sleep -Seconds $CheckIntervalSeconds

        $SecondsLeft = ($WaitDateTime - (Get-Date)).TotalSeconds
        If ($SecondsLeft -lt 1 -and $SecondsLeft -gt 0) {
            #Write-Host "[$(Get-Date)] Waiting $SecondsLeft Seconds to finish."
            Start-Sleep -Seconds $SecondsLeft
        }
    }

    # Set new interval
    If ((Get-Date) -lt $WaitDateTime -and $SecondsLeft -gt 0) {
        Start-SmartSleep -WaitDateTime $WaitDateTime -CheckIntervalSeconds $CheckIntervalSeconds -IntervalReductionRate $IntervalReductionRatePercentage
    }
    Else { ((Get-Date) - $StartTime).TotalSeconds }
}

Start-SmartSleep -Seconds 4