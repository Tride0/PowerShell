Function Convert-HashToString {
    <#
        .NOTES
            Created By: Kyle Hewitt
            Created On: 04-12-2021
            Version: 2021.04.12

        .DESCRIPTION
            This function will consolidate every item in a hashtable into a string
    #>
    param(
        $HashTable,
        $KeyDelimiter = "`n",
        $KeyValueSeperator = '=',
        $KeyEncapsulator = "'", 
        $ValueEncapsulator = "'"
    )
    Begin { 
        [System.Collections.ArrayList]$String = @()
        Function Convert-ArrayToString {
            Param (
                [Array]$Array, 
                $ArrayDelimiter = "`n", 
                $ValueDelimiter = "`n"
            )
            Begin {
                [System.Collections.ArrayList]$String = @()
            }
            Process {
                [System.Collections.ArrayList]$ArrayString += Foreach ($Item in $Array) {
                    If ($Item -is [System.Collections.Hashtable] -or $Item -is [System.Management.Automation.PSObject]) {
                        Convert-HashToString -HashTable $Item
                    }
                    ElseIf ($Item -is [Array]) {
                        Convert-ArrayToString -Array $Item
                    }
                    Else {
                        $Item
                    }
                }
                $String += ($ArrayString -join $ValueDelimiter)
            }
            End { Return ($String -join $KeyDelimiter) }
        }
    }
    Process {
        If ([Boolean]$HashTable.Keys) { $Keys = $HashTable.keys }
        Else { $Keys = $HashTable.psobject.Properties.name }
        
        Foreach ($Key in $Keys) {
            If ($HashTable.$Key -is [array]) {
                $String += "$KeyEncapsulator$($Key)$KeyEncapsulator $KeyValueSeperator $ValueEncapsulator$(Convert-ArrayToString -Array $HashTable.$Key -ArrayDelimiter "`n" -ValueDelimiter ',')$ValueEncapsulator" 
            }
            Else {
                $String += "$KeyEncapsulator$($Key)$KeyEncapsulator $KeyValueSeperator $ValueEncapsulator$($HashTable.$Key)$ValueEncapsulator" 
            }
        }
    }
    End { Return ($String -join $KeyDelimiter) }
}