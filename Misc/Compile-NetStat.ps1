<#
    .NOTES
        Created By: Kyle Hewitt
        Created On: 4/24/20
        Last Edit: 4/24/20
        Version: 1.0.0

    .DESCRIPTION
        Gets all netstat files from folder. Filters them, Formats them and compiles them into a single csv file.
#>

$NetStatFolder = '\\SERVER\SHARE\Folder'
$ExportPath = "$PSScriptRoot\Compiled_Netstat_$(Get-Date -Format yyyyMMdd_hhmmss).csv"

$NetStatFiles = Get-ChildItem -Path $NetStatFolder -File

Foreach ($File in $NetStatFiles) {
    $NetStat = Get-Content -Path $File.FullName

    # Trim dud lines at start and removes all local addresses
    $NetStat = $NetStat[3..$NetStat.Count].trim() -Replace ' {2,}', ';' -notlike '*127.0.0.1*' -notlike '*0.0.0.0*' -notlike '*::*'
    
    # Get Headers
    $Headers = $NetStat[0].trim().split(';')
    # Convert NetStat into something parse-able and exportable to csv
    # For every line in NetStat
    $NetStat = for ($i = 1; $i -lt $NetStat.Count; $i++) { 
        $Entry = $NetStat[$i].Split(';')
        $Info = [System.Collections.Specialized.OrderedDictionary]@{}
        for ($j = 0; $j -lt $Headers.count; $j++) {
            If ($Entry[$j] -like '*:*') {
                $Split = $Entry[$j].split(':')
                $Info.Add($Headers[$j], $Split[0])
                $Info.Add("$($Headers[$j]) Port", $Split[1])
            }
            Else {
                $Info.Add($Headers[$j], $Entry[$j])
            }
        }
        [PSCustomObject]$Info
        Remove-Variable info, Split, entry -ErrorAction SilentlyContinue
    }
    # Exports results to csv file
    $NetStat | Export-Csv -Path $ExportPath -NoTypeInformation -Append -Force
}
# Opens csv file
& $ExportPath