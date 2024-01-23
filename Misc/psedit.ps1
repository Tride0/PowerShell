Function psedit {
    param(
        [Parameter(Mandatory)] $File,
        [switch] $Recurse,
        [switch] $ReOpen
    )
    Foreach ($filename in $File) {
        $Items = Get-ChildItem -Path $filename -Recurse:$($Recurse.IsPresent) | Where-Object -FilterScript { !$_.PSIsContainer }
        Foreach ($Item in $Items) {
            
            $OpenFile = $psISE.CurrentPowerShellTab.Files | Where-Object -FilterScript { $_.FullPath -eq $Item.FullName } 
            If ($OpenFile -and $ReOpen.IsPresent) {
                [Void]$psISE.CurrentPowerShellTab.Files.Remove($OpenFile)  
            }
            ElseIf ($OpenFile -and !$ReOpen.IsPresent) {
                Write-Warning "File Already Open: $($Item.FullName)"
            }

            [void]$psISE.CurrentPowerShellTab.Files.Add($Item.FullName)
        }
    }
}