Function Execute-RemoteProcess {
    <#
        .NOTES
            Created By: Kyle Hewitt
            Created On: 08-07-2020
            Version: 2020.08.07

        .DESCRIPTION
            THis script will execute a process remotely
    #>

    Param(
        [String]$Computer = $env:COMPUTERNAME,
        [String]$FilePath,
        [String]$Arguments,
        [Switch]$Wait,
        [int]$RecheckSeconds = 2
    )

    $WMIProcess = ([Management.ManagementClass]"\\$Computer\ROOT\CIMV2:win32_process")
    $ProcessResults = $WMIProcess.Create("`"$FilePath`" $Arguments")

    If ($Wait.IsPresent) {
        If ($ProcessResults.ReturnValue -eq 0) {
            while ($null -ne (Get-Process -Id $ProcessResults.ProcessId -ComputerName $Computer -ErrorAction SilentlyContinue)) {
                Write-Host "Waiting for '$FilePath' ($($ProcessResults.ProcessId)) to finish. Checking in $RecheckSeconds seconds."
                Start-Sleep -Seconds $RecheckSeconds
            }
        }
    }
    Return $ProcessResults.ReturnValue
}