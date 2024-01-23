<#
    Created By: Kyle Hewitt
#>

Function Set-WallPaper ($Path) {
    Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop\' -Name wallpaper -Value $Path
    Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop\' -Name WallpaperStyle -Value 6
    Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop\' -Name TileWallpaper -Value 0

}
