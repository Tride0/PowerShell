Function Wait-Ping {
    <#
    .SYNOPSIS
        Waits for a computer to go offline and then come back online.

    .DESCRIPTION
        This function is typically used after initiating a reboot on a remote computer. It first waits for the computer to stop responding to pings, and then waits for it to become responsive again. This function will wait indefinitely.

    .PARAMETER ComputerName
        The name of the computer to ping.

    .PARAMETER Delay
        The delay between ping attempts, in seconds. Defaults to 5.

    .EXAMPLE
        Wait-Ping -ComputerName "SERVER01"
        Waits indefinitely for SERVER01 to go offline, and then indefinitely for it to come back online, checking every 5 seconds.

    .EXAMPLE
        Wait-Ping -ComputerName "SERVER01" -Delay 10
        Waits indefinitely for SERVER01 to go offline, and then indefinitely for it to come back online, checking every 10 seconds.

    .OUTPUTS
        [boolean] Returns $true once the computer has come back online.
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [string]$ComputerName,

        [Parameter()]
        [int]$Delay = 5
    )
    
    write-host ("`n" * 5)

    # Phase 1: Wait for the server to go offline
    Write-Verbose "[$((Get-Date))] Phase 1: Waiting for $ComputerName to go offline..."
    while ($true) {
        if (-not (Test-Connection -ComputerName $ComputerName -Count 1 -Quiet -ErrorAction SilentlyContinue)) {
            Write-Host "[$((Get-Date))] $ComputerName is offline." -ForegroundColor Green
            Write-Verbose "[$((Get-Date))] $ComputerName is offline. Proceeding to Phase 2."
            break
        }
        $status = "Last check at $(Get-Date -Format 'T'): Responding"
        Write-Progress -Activity "Waiting for $ComputerName to go offline" -Status $status -Id 1
        Write-Verbose "($ComputerName) Still responding, waiting..."
        Start-Sleep -Seconds $Delay
    }

    # Phase 2: Wait for the server to come online
    Write-Verbose "[$((Get-Date))] Phase 2: Waiting for $ComputerName to come online..."
    while ($true) {
        if (Test-Connection -ComputerName $ComputerName -Count 1 -Quiet -ErrorAction SilentlyContinue) {
            Write-Host "[$((Get-Date))] $ComputerName is back online." -ForegroundColor Green
            Write-Progress -Activity "Monitoring $ComputerName" -Status "Online" -Completed -Id 1
            Write-Verbose "[$((Get-Date))] $ComputerName is back online. Script finished."
            return $true
        }

        $status = "Last check at $(Get-Date -Format 'T'): Offline"
        Write-Progress -Activity "Waiting for $ComputerName to come online" -Status $status -Id 1
        Write-Verbose "[$((Get-Date))] ($ComputerName) Still offline, waiting..."
        Start-Sleep -Seconds $Delay
    }
}