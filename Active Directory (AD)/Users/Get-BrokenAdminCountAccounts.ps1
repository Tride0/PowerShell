<#
    .NOTES
        Created By: Kyle Hewitt
        Created On: 07-29-2020
        Version: 2020.07.29

    .DESCRIPTION
        This script will check if there are any accounts that have adminCount set to 1 when it shouldn't.
#>

$AdminGroups = 'Account Operators', 'Administrators', 'Backup Operators', 'Domain Admins', 'Domain Controllers', 'Enterprise Admins', 'Print Operators', 'Read-only Domain Controllers', 'Replicator', 'Schema Admins', 'Server Operators'

[string[]]$ActualProtectedObjects = $admingroups | Get-ADGroupMember -Recursive | Select-Object -ExpandProperty distinguishedname -Unique
$ActualProtectedObjects += $AdminGroups | % { Get-ADGroup $_ | Select-Object -ExpandProperty distinguishedname } 
$ActualProtectedObjects += $AdminGroups | % { Get-ADGroup $_ -Properties members | Select-Object -ExpandProperty members } 

Get-ADObject -LDAPFilter "(adminCount=1)" | 
    Select-Object -ExpandProperty distinguishedname | 
    Where-Object -FilterScript { !$ActualProtectedObjects.Contains($_) } | 
    Sort-Object -Property { ($_ -split ',[A-Za,z]{2}=')[1..20] -join ' \ ' }