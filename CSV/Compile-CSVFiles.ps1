<#
    .NOTES
        Created By: Kyle Hewitt
        Created On: 07-29-2020
        Version: 2020.08.05

    .DESCRIPTION
        This script compiles CSV files into a single CSV and will open it afterward.
#>

$FilePathofCSVs = "$ENV:USERPROFILE\Desktop\csvs"
$ExportPath = "$ENV:USERPROFILE\desktop\Compiled_Csv_$(Get-Date -Format yyyyMMdd_hhmmss).csv"

$CSVs = Get-ChildItem -Path $FilePathofCSVs -Filter *.csv

$CompiledInfo = @()
Foreach ($CSv in $CSVs.FullName) {
    $CSVInfo = Import-Csv -Path $CSV

    $Properties = $CSVInfo | Get-Member -MemberType NoteProperty | Select-Object -Expand Name

    Foreach ($Entry in $CSVInfo) {
        $Hash = [System.Collections.Specialized.OrderedDictionary]@{}
        Foreach ($Property in $Properties) {
            # Add property and value to hash 
            $Hash.$Property = $Entry.$Property -join "`n"
        
            # If the rest of the Hash Tables in the CompiledInfo do not contain this property add it to every single one
            If ([Boolean]$CompiledInfo[0]) {
                If ( !$CompiledInfo[0].Keys.Contains($Property).contains($True) ) {
                    For ($i = 0; $i -lt $CompiledInfo.Count; $i++) {
                        $CompiledInfo[$i].$Property = ''
                    }
                }
            }
        }
    
        # If this hash doesn't have every other property then add them to it
        Foreach ($Property in $CompiledInfo[0].Keys) {
            If ($Hash.Keys -notContains $Property) {
                $Hash.$Property = ''
            }
        }

        # Add this hash to the CompiledInfo
        $CompiledInfo += $Hash
    }
}

# Translate the Hash Tables into PSCustomObject and then export it to a csv file.
$CompiledInfo | ForEach-Object -Process { [PSCustomObject]$_ } | Export-Csv -Path $ExportPath -NoTypeInformation -Force

# Open CSV File
& $ExportPath