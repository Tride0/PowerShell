Function Convert-HashTableToString {
    <#
        .NOTES
            Created By: Kyle Hewitt
            Created On: 08-28-2020
            Version: 2020.08.28

        .DESCRIPTION
    #>
    Param (
        [Hashtable[]]$HashTable,
        $Depth = 1
    )
    Begin {
        #region Functions
            Function Convert-ArrayToString {
                Param([Array]$Array)
                $String = @()
                :ArrayForeach Foreach ($Item in $Array) {
                    If (![Boolean]$Item) { Continue ArrayForeach }
                    If ($Item -is [Hashtable]) { $String += Convert-HashTableToString -HashTable $Item }
                    ElseIf ($Item -is [Array]) { $String += Convert-ArrayToString -Array $Item }
                    Else { $String += "$Item" }
                }
                Return ($String -join " ; ")
            }
        #endregion Functions
    }
    Process {
        $String = @()
        :Keys Foreach ($Key in $HashTable.Keys) {
            If (![Boolean]$Key -or ![Boolean]$HashTable.$Key) { Continue KeysForeach }
            If ($HashTable.$Key -is [HashTable]) { 
                $String += "$("`t"*($Depth-1))$Key :: $("`t"*$Depth)$(Convert-HashTableToString -HashTable $HashTable.$Key -Depth ($Depth+1))"
            }
            ElseIf ($HashTable.$Key -is [Array]) { 
                $String += "$("`t"*($Depth-1))$Key :: $(Convert-ArrayToString -Array $HashTable.$Key)"
            }
            Else {
                $Value = "$("`t"*($Depth-1))$Key :: $($HashTable.$key)"
                If ($Depth -gt 1 -and $Key -eq $HashTable.Keys[0]) { $Value = "`n$Value" }
                $String += $Value 
            } 
        }
        Return $($String -join "`n")
    }
}