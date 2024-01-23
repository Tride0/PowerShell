<#
    .NOTES
        Created By: Kyle Hewitt
        Created On: 05-26-2020
        Version: 2020.05.26

    .DESCRIPTION
        This script checks all the groups in the current domain for the any groups with members from a different domain that isn't a child domain.
#>

Import-Module ActiveDirectory -ErrorAction Stop

$Domain = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain().Name
$Root = "DC=$($Domain.Split('.') -join ',DC=')"

Get-ADGroup -Filter * -Properties Members -PipelineVariable Group |
    Select-Object -Expand Members |
    Where-Object -Filter { $_ -notlike "*$Root" } -PipelineVariable Member |
    Select-Object @{Name = 'GroupName'; Expression = { $Group.DistinguishedName } }, @{Name = 'GroupDN'; Expression = { $Group.DistinguishedName } }, @{Name = 'Member'; Expression = { $Member } }
