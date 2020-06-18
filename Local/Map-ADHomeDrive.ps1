<#
    .NOTES
        Created By: Kyle Hewitt
        Created On: 3/17/20
        Last Edit: 3/17/20
        Version: 1.0.0

    .DESCRIPTION
        This script is to be used to map the drive that is listed on the currently logged in user's AD attribute fields
#>

$UserSamAccountname = $ENV:USERNAME

$ADSearcher = [adsisearcher]@{ }
[Void] $ADSearcher.PropertiesToLoad.Add( 'homedirectory' )
[Void] $ADSearcher.PropertiesToLoad.Add( 'homedrive' )
$ADSearcher.Filter = "samaccountname=$UserSamAccountname"

$UserInfo = $ADSearcher.FindOne().Properties
$HomeDriveLetter = $UserInfo.homedrive
$HomeDrivePath = $UserInfo.homedirectory

# OPTION 1
net use $HomeDriveLetter $HomeDrivePath

# OPTION 2
New-PSDrive -Name $HomeDriveLetter.TrimEnd(':') -Root $HomeDrivePath -PSProvider FileSystem -Description HomeDrive -Persist

