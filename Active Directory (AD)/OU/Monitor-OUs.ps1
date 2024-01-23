<#
    .NOTES
        Created By: Kyle Hewitt
        Created On: 07-27-2020
        Version: 2020.07.27

    .DESCRIPTION
        This tool is used to monitor when OUs are removed or added.
        This script should be used on a regular basis using Task Scheduler or other scheduling means.
#>

Param(
    $MonitorLogFilePath = "$PSScriptRoot\OUMonitorLogs\OUPreviousState.txt",
    $ChangeLogFilePath = "$PSScriptRoot\OUMOnitorLogs\OUChangeLog.log",
    $SMTPServer = 'smtp.relay.com',
    $SMTPPort = 25,
    $EMailFrom = 'OU_Monitor@Domain.com',
    $EmailTo = 'your@email.com',
    $EMailSubject = "OU Monitor $(Get-Date -Format yyyyMMdd hh:mm)"
)

# Get Previous List
If (Test-Path -Path $MonitorLogFilePath) {
    $PreviousOUList = Get-Content $MonitorLogFilePath
}
Else {
    $PreviousOUList = ''
}

# Get Current List
$ADSearcher = New-Object System.DirectoryServices.DirectorySearcher
$ADSearcher.PageSize = 3
$ADSearcher.Filter = 'objectclass=organizationalUnit'
[void] $ADSearcher.PropertiesToLoad.Add('distinguishedname')

$CurrentOUs = $ADSearcher.FindAll().distinguishedname

# Replace Previous List with Current List
Set-Item -Path $MonitorLogFilePath -Value $CurrentOUs -Force

# Compare Previous List to Current List
$Comparison = Compare-Object -ReferenceObject $PreviousOUList -DifferenceObject $CurrentOUs

# Extract Additions and Aemovals
$Added = $Comparison | Where-Object -FilterScript { $_.SideIndicator -eq '=>' } | Select-Object -ExpandProperty InputObject
$Removed = $Comparison | Where-Object -FilterScript { $_.SideIndicator -eq '<=' } | Select-Object -ExpandProperty InputObject

# Add Additions to Change Log
Foreach ($OU in $Added) {
    "[$([DateTime]::Now)] ADDED :: $OU" >> $ChangeLogFilePath
}

# Add Removals to Change Log
Foreach ($OU in $Removed) {
    "[$([DateTime]::Now)] REMOVED :: $OU" >> $ChangeLogFilePath
}


# E-Mail Results
If ([Boolean]$EmailTo) {

    $MailBody = "
    Ran from Computer: $ENV:COMPUTERNAME
    Ran with User: $ENV:USERNAME

    Complete Change Log: <$ChangeLogFilePath>

    Added:`n`t$($Added -join "`n`t")

    Removed:`n`t$($Removed -join "`n`t")"

    Send-MailMessage -From $EMailFrom -To $EmailTo `
        -SmtpServer $SMTPServer -Port $SMTPPort `
        -Subject $EMailSubject -Body $MailBody -Attachments $ChangeLogFilePath
}