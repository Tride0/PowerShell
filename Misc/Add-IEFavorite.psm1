Function Add-IEFavorite {
    <#
        .NOTES    
            Created By: Kyle Hewitt
            Created In: 2018
            Version: 2018.0.0

        .DESCRIPTION
            This function will add favorites in internet explorer.
    #>
    Param(
        [String]$Name, 
        [String]$Url
    ) 
    $Shell = New-Object -ComObject WScript.Shell

    $IEFavFilePath = "$([Environment]::GetFolderPath('Favorites','None'))\Helpful\$Name.url"

    $Shortcut = $Shell.CreateShortcut($IEFavFilePath)
    $Shortcut.TargetPath = $url
    $Shortcut.Save()
}