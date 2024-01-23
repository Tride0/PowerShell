Function Split-List {
    Param (
        [Array]$List,
        [Parameter(Mandatory, ParameterSetName = 'MinSize')]
        [Int]$MinSize, 
        [Parameter(Mandatory, ParameterSetName = 'MaxSize')]
        [Int]$MaxSize,
        [Parameter(Mandatory, ParameterSetName = 'Groups')]
        [Int]$Groups
    )
    If ($MinSize -gt 0) {
        $Groups = [Math]::Floor($List.Count / $MinSize)
    }
    ElseIf ($MaxSize -gt 0) {
        $Groups = [Math]::Ceiling($List.Count / $MaxSize)
    }

    If ($Groups -gt 0) {
        $Return = [Ordered]@{}
        For ($i = 0; $i -lt $Groups; $i++) {
            $Return.$i = [PSCustomObject]@{
                Name  = $i
                Count = 0
                Group = [System.Collections.ArrayList]@()
            }
        }
        $i = 0
        Foreach ($Object in $List) {
            $Return[$i].Group += $Object
            $Return[$i].Count ++
            If ($i -eq $Groups - 1) { $i = 0 }
            Else { $i ++ }
        }
        Return $Return.Values
    }
}