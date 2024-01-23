<#
    Created By: Kyle Hewitt
    Created On: 10/03/2018
    Version: 2018.10.03
#>

$ExportPath = "$PSScriptRoot\AD_Group_Usage.csv"

$90Days = [DateTime]::Now.AddDays(-90)

$ADFilter = { (WhenCreated -lt $90Days) -and (WhenChanged -lt $90Days) }

$WhereFilter = { $_.Members.Count -eq 0 -and $_.Member.Count -eq 0 -and $_.Memberof.Count -eq 0 }

$ADProperties = 'members', 'member', 'memberof', 'WhenCreated', 'WhenChanged', 'mail'

$SelectProperties = 'Name', 'DistinguishedName', 'WhenCreated', 'WhenChanged', 'mail'

$SortProperty = 'WhenChanged'

Get-ADGroup -Properties $ADProperties -Filter $ADFilter |
    Where-Object -FilterScript $WhereFilter |
    Select-Object -Property $SelectProperties | 
    Sort-Object -Property $SortProperty |
    Export-Csv -Path $ExportPath -NoTypeInformation -Force

