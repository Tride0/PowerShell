<#
    Created By: Kyle Hewitt
    Created On: 10/03/2018
    Version: 2020.08.07

    Purpose: To check if AD OUs are being used for anything

    Template:
        Check for any Objects in OU
        Check for any GPO linked to OU

        If either are empty: report
#>

$ExportPath = "$env:USERPROFILE\desktop\CheckADOUUsage.csv"

$ADSearcher = New-Object DirectoryServices.DirectorySearcher
$ADSearcher.Filter = 'objectClass=organizationalUnit'
[Void] $ADSearcher.PropertiesToLoad.Add('distinguishedname')
[Void] $ADSearcher.PropertiesToLoad.Add('gplink')

$OUs = $ADSearcher.FindAll().Properties

$ADSearcher.PropertiesToLoad.Clear()
[Void] $ADSearcher.PropertiesToLoad.Add('name')
$ADSearcher.SizeLimit = 50

Foreach ($OU in $OUs) {
    Write-Progress -Activity 'Checking OUs' -Status $OU.distinguishedname -PercentComplete (($OUs.IndexOf($OU) + 1) / $OUs.Count * 100)
    Remove-Variable ObjectCount, GPOLinks, Info -ErrorAction SilentlyContinue

    $ADSearcher.Filter = '(|(objectclass=user)(objectclass=group))'
    [Void] $ADSearcher.PropertiesToLoad.Add('distinguishedname')
    $ADSearcher.SearchRoot.Path = "LDAP://$($OU.distinguishedname)"
    $ObjectCount = $ADSearcher.FindAll().Count

    If ($ObjectCount -eq 0) {
        If ($OU.gplink.count -gt 0) {
            $GPOLinks = @()
    
            $Links = $OU.gplink.split('\[', [StringSplitOptions]::RemoveEmptyEntries) | ForEach-Object {
                $_.Split(';')[0]
            }

            Foreach ($Link in $Links) {
                $GPOLinks += ([ADSI]$Link).displayname
            }
            $GPOLinks = $GPOLinks -join ', '
        }
        Else {
            $GPOLinks = 0
        }
        
        $Info = [PSCustomObject]@{
            OU          = $($OU.distinguishedname)
            ObjectCount = $ObjectCount
            GPLinks     = $GPOLinks
        }
        Write-Output $Info
        $Info | Export-Csv -Path $ExportPath -NoTypeInformation -Force -Append
    }
}
&  $ExportPath