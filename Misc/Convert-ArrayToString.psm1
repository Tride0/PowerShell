Function Convert-ArrayToString {
    Param([Array[]]$Array)
    $String = @()
    :ArrayForeach Foreach ($Item in $Array) {
        write-host Item: $Item
        If (![Boolean]$Item) { "Skip"; Continue ArrayForeach }
        If ($Item -is [Hashtable]) { 
            'hash'
            $String += Convert-HashTableToString -HashTable $Item 
        }
        ElseIf ($Item -is [Array]) { 
            write-host 'array'
            $String += Convert-ArrayToString -Array $Item 
        }
        Else { 
            'item'
            $String += "$Item" 
        }
    }
    Return ($String -join " ; ")
}