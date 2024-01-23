<#
    Created By: Kyle Hewitt
    Created On: 04/18/2020
    Version: 1.0.0

    Description:
        This script downloads afile from the internet then runs it.

#>
Param(
    [String] $Url = '',
    [String] $DownloadToPath = $PSScriptRoot,
    [String[]] $ExecuteArgument,
    [ValidateSet($True, $False)] [Boolean] $Execute = $True
)
Begin {
    If (!(Test-Path -Path (Split-Path -Path $DownloadToPath -Parent))) {
        [Void] (New-Item -Path (Split-Path -Path $DownloadToPath -Parent) -ItemType Directory -Force)
    }
}
Process {
    # Download File
    $WebClient = New-Object System.Net.WebClient
    #$WebClient.Credentials = New-Object System.Net.Networkcredential($UserName, $Password)
    $WebClient.DownloadFile($SharePointUrl, $DownloadToPath)

    # Execute File
    If ([Boolean]$ExecuteArgument) {
        Start-Process -FilePath $DownloadToPath -ArgumentList $ExecuteArgument
    }
    Else {
        Start-Process -FilePath $DownloadToPath
    }
}
