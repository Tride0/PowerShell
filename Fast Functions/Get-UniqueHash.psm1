Function Get-UniqueHash {
    Begin {
        $StringArr = @()
        $Arr = @()
    }
    Process {
        If ([Boolean]$_.Keys) {
            [String[]]$Keys = $_.Keys
        }
        Else {
            [String[]]$Keys = $_.PSObject.Properties.Name
        }

        $String = ''
        Foreach ($Key in $Keys) {
            $String += "$Key :: $($_.$Key)"
        }

        If ($StringArr -notcontains $String) {
            $Arr += $_
            $StringArr += $String
        }
    }
    End {
        Return $Arr
    }
}