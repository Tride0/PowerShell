Function Retry-Action {
    Param (
        $ReAttemptCount = 3,
        $WaitSeconds = 30,
        [ScriptBlock]$ScriptBlock
    )
    Remove-Variable AttemptCount -ErrorAction SilentlyContinue
    :ReTryAction While ([Boolean](++$AttemptCount)) {
        Try {
            $ScriptBlockResults = $ScriptBlock.Invoke()
            Break ReTryAction
        }
        Catch {
            If ($AttemptCount -ge 3) { Break ReTryAction }
            If ($WaitSeconds -gt 0) {
                Write-Host "[$(Get-Date)] Waiting $WaitSeconds seconds to re-try. Error: $_" -ForegroundColor Cyan
            }
        }
    }

    Return $ScriptBlockResults
}