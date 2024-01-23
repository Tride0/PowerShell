Function Select-ObjectFast {
    Param([Array]$Property)
    Process {
        $Hash = @{}
        Foreach ($p in $Property) { $Hash.Add($p, $_.$p) }
        [PSCustomObject]$Hash
    }
}
