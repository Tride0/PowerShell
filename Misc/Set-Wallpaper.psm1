<#
    Created By: Kyle Hewitt
#>

Function Set-WallPaper ($Path) {
 Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop\' -name wallpaper -value $Path
 Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop\' -name WallpaperStyle -value 6
 Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop\' -name TileWallpaper -value 0

}
