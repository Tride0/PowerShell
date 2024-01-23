<#
    .NOTES
        Created By: Kyle Hewitt
        Created On: 07-30-2020
        Version: 2020.07.30

    .DESCRIPTION
        This tool is used to monitor when AD SS Subnets are removed, added or modified.
        This script should be used on a regular basis using Task Scheduler or other scheduling means.
#>

Param(
    $MonitorLogFilePath = "$PSScriptRoot\OUMonitorLogs\ADSSSubnetsPreviousState.csv",
    $ChangeLogFilePath = "$PSScriptRoot\OUMOnitorLogs\ADSSSubnetsChangeLog.log",
    $SMTPServer = 'smtp.relay.com',
    $SMTPPort = 25,
    $EMailFrom = 'AD_SS_Subnet_Monitor@Domain.com',
    $EmailTo = 'your@email.com',
    $EMailSubject = "AD SS Subnet Monitor $(Get-Date -Format yyyyMMdd hh:mm)"
)

# Get Misc Information for later
$Domain = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain().Name

# Get Previous List
If (Test-Path -Path $MonitorLogFilePath) {
    $PreviousList = Import-Csv $MonitorLogFilePath
}
Else {
    $PreviousList = ''
}

# Get Current List
$ADSearcher = New-Object System.DirectoryServices.DirectorySearcher
$ADSearcher.PageSize = 30
$ADSearcher.Filter = 'objectclass=subnet'
$ADSearcher.SearchRoot = "LDAP://CN=Subnets,CN=Sites,CN=Configuration,DC=$($Domain.Replace('.',',DC='))"
[void] $ADSearcher.PropertiesToLoad.Add('distinguishedname')
[void] $ADSearcher.PropertiesToLoad.Add('site')
[void] $ADSearcher.PropertiesToLoad.Add('name')
$CurrentList = $ADSearcher.FindAll()

# Format Current List Information
$Array = @()
Foreach ($Item in $CurrentList[1]) {
    $Hash = @{}
    Foreach ($Key in $Item.Properties.keys) {
        $Hash.$Key = "$($Item.Properties.$Key)"
    }
    $Array += [PSCustomObject]$Hash
}
$CurrentList = $Hash
Remove-Variable Hash -ErrorAction SilentlyContinue

# Replace Previous List with Current List
Export-Csv -Path $MonitorLogFilePath -Value $CurrentList -NoTypeInformation -Force

# Compare previous list with current list
$Comparison = Compare-Object -ReferenceObject $PreviousList -DifferenceObject $CurrentList -Property distinguishedname -IncludeEqual

# Extra additions and removals
$Added = $Comparison | Where-Object -FilterScript { $_.SideIndicator -eq '=>' } | Select-Object -ExpandProperty InputObject
$Removed = $Comparison | Where-Object -FilterScript { $_.SideIndicator -eq '<=' } | Select-Object -ExpandProperty InputObject
$Equal = $Comparison | Where-Object -FilterScript { $_.SideIndicator -eq '==' } | Select-Object -ExpandProperty InputObject

# Add additions to change log
Foreach ($Item in $Added) {
    "[$([DateTime]::Now)] ADDED :: $Item" >> $ChangeLogFilePath
}

# Add removals to change log
Foreach ($Item in $Removed) {
    "[$([DateTime]::Now)] REMOVED :: $Item" >> $ChangeLogFilePath
}

# Add Changes to Change Log
$Changed = @()
Foreach ($Item in $Equal) {
    $Previous = $PreviousList | Where-Object -FilterScript { $_.distinguishedname -eq $Item }
    $Current = $CurrentList | Where-Object -FilterScript { $_.distinguishedname -eq $Item }

    If ($Previous.Site -ne $Current.Site) {
        $Changed += "$($Current.Name) :: Current Site: $($Current.Site) :: Previous Site: $($Previous.Site)"
        "[$([DateTime]::Now)] CHANGED :: $($Current.Name) :: Site :: Current: $($Current.Site) :: Previous: $($Previous.Site)" >> $ChangeLogFilePath
    }
}

# E-Mail results
If ([Boolean]$EmailTo) {

    $MailBody = "
    Ran from Computer: $ENV:COMPUTERNAME
    Ran with User: $ENV:USERNAME

    Complete Change Log: <$ChangeLogFilePath>

    Changed:`n`t$($Changed -join "`n`t")

    Added:`n`t$($Added -join "`n`t")

    Removed:`n`t$($Removed -join "`n`t")"

    Send-MailMessage -From $EMailFrom -To $EmailTo `
        -SmtpServer $SMTPServer -Port $SMTPPort `
        -Subject $EMailSubject -Body $MailBody -Attachments $ChangeLogFilePath
}