<#
    Created By: Kyle Hewitt
    Created On: 10/03/2018
    Last Edit: 10/03/2018

    Purpose: Check for Groups that have no memberships
#>

$ExportPath = "$env:USERPROFILE\desktop\CheckADGroupUsage.txt"

$ADSearcher = New-Object DirectoryServices.DirectorySearcher
$ADSearcher.Filter = 'objectClass=group'
$ADSearcher.PageSize = 100
$ADSearcher.SizeLimit = 1000
[Void] $ADSearcher.PropertiesToLoad.Add('name')
[Void] $ADSearcher.PropertiesToLoad.Add('memberof')
[Void] $ADSearcher.PropertiesToLoad.Add('member')
[Void] $ADSearcher.PropertiesToLoad.Add('member;range=0-1500')
[Void] $ADSearcher.PropertiesToLoad.Add('distinguishedname')

$Groups = $ADSearcher.FindAll().Properties

Write-Host "`n`n`n$(($Groups | Where-Object -FilterScript { $_.'member;range=0-*'.Count -eq 0 -and $_.'member;range=0-1499'.Count -eq 0 -and $_.'memberof'.Count -eq 0 }).Count) groups without any members or memberships.`n`n`n"

Foreach ($Group in $Groups) {
    Write-Progress -Activity "Checking Groups' memberships" -Status $Group.name -PercentComplete (($Groups.IndexOf($Group) + 1) / $Groups.count * 100)

    If ($Group.'member;range=0-*'.count -eq 0 -and $Group.'member;range=0-1499'.count -eq 0 -and $Group.memberof.count -eq 0) {
        Write-Host $Group.name
        $Group.name >> $ExportPath
    }
}
Write-Host "`n`n`n$(($Groups | Where-Object { $_.'member;range=0-*'.Count -eq 0 -and $_.'member;range=0-1499'.Count -eq 0 -and $_.'memberof'.Count -eq 0 }).Count) groups without any members or memberships."

& $ExportPath