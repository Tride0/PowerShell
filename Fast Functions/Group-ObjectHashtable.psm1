Function Group-ObjectHashtable {
    param ( [string[]] $Property )
    begin { $hashtable = @{} }
    process {
        $key = $( foreach ($prop in $Property) { $_.$prop } ) -join ','
        
        if ($hashtable.ContainsKey($key) -eq $false) {
            $hashtable[$key] = [Collections.Arraylist]@()
        }

        $null = $hashtable[$key].Add($_)
    }
    end { $hashtable }
}