<#
    .NOTES
        Created By: Kyle Hewitt
        Created On: 08-05-2020
        Version: 2020.08.05

    .DESCRIPTION
        This script is used to install cleanmgr.exe
#>

$OS = Get-WmiObject Win32_OperatingSystem -Property Caption | Select-Object -ExpandProperty Caption

If (Test-Path -Path 'C:\windows\system32\cleanmgr.exe') {
    Write-Warning -Message 'cleanmgr already installed'
    Continue
}

If ($OS -notlike '*2008*') {
    Write-Warning "This script is not for your OS. Operating System: $OS"
    Continue
}

If ($OS -like '*R2*') {
    Copy-Item -Path 'C:\Windows\winsxs\amd64_microsoft-windows-cleanmgr_31bf3856ad364e35_6.1.7600.16385_none_c9392808773cd7da\cleanmgr.exe' -Destination 'C:\WIndows\System32' -Force
    Copy-Item -Path 'C:\Windows\winsxs\amd64_microsoft-windows-cleanmgr.resources_31bf3856ad364e35_6.1.7600.16385_en-us_b9cb6194b257cc63\cleanmgr.exe.mui' -Destination 'C:\WIndows\System32\en-US' -Force
}
ElseIf (Test-Path 'C:\Program Files (x86)') {
    Copy-Item -Path 'C:\Windows\winsxs\amd64_microsoft-windows-cleanmgr_31bf3856ad364e35_6.0.6001.18000_none_c962d1e515e94269\cleanmgr.exe.mui' -Destination 'C:\WIndows\System32' -Force
    Copy-Item -Path 'C:\Windows\winsxs\amd64_microsoft-windows-cleanmgr.resources_31bf3856ad364e35_6.0.6001.18000_en-us_b9f50b71510436f2\cleanmgr.exe.mui' -Destination 'C:\WIndows\System32\en-US' -Force
}
Else {
    Copy-Item -Path 'C:\Windows\winsxs\x86_microsoft-windows-cleanmgr_31bf3856ad364e35_6.0.6001.18000_none_6d4436615d8bd133\cleanmgr.exe' -Destination 'C:\WIndows\System32' -Force
    Copy-Item -Path 'C:\Windows\winsxs\x86_microsoft-windows-cleanmgr.resources_31bf3856ad364e35_6.0.6001.18000_en-us_5dd66fed98a6c5bc\cleanmgr.exe.mui' -Destination 'C:\WIndows\System32\en-US' -Force
}