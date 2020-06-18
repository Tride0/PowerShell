Function Check-StringDiff {
    Param(
        [Parameter(Mandatory = $True)][String]$CompareToString,
        [Parameter(Mandatory = $True)][String[]]$Strings,
        [Boolean]$Explain = $True
    )

    Foreach ($String in $Strings) {
        If ($CompareToString.Length -gt $String.Length) { $StringLength = $CompareToString.Length }
        Else { $StringLength = $String.Length }
        
        Write-Host "`n$CompareToString"
        If ($CompareToString[-1] -eq ' ') { Write-Host "$(' ' * ($CompareToString.Length-1))^" }

        $SpaceIndexes = @()
        For ($i = 0; $i -lt $StringLength; $i++) {
            If ($String[$i] -eq ' ' -and $String[$i] -ne $CompareToString[$i]) {
                Write-Host ' ' -NoNewline
                $SpaceIndexes += $i
            }
            ElseIf (![Boolean]$String[$i]) {
                Write-Host $CompareToString[$i] -ForegroundColor Gray -NoNewline
            }
            ElseIf ($CompareToString[$i] -ceq $String[$i]) {
                Write-Host $String[$i] -ForegroundColor Green -NoNewline
            }
            ElseIf ($CompareToString[$i] -cne $String[$i] -and $CompareToString[$i] -ieq $String[$i]) {
                Write-Host $String[$i] -ForegroundColor Yellow -NoNewline
            }
            Else {
                Write-Host $String[$i] -ForegroundColor Red -NoNewline
            }
        }
    
        Write-Host ''
        For ($i = 0; $i -lt $SpaceIndexes.Count; $i++) {
            If ($i -ne 0) { $Spaces = $SpaceIndexes[$i] - $SpaceIndexes[$i - 1] - 1 }
            Else { $Spaces = $SpaceIndexes[$i] }
            Write-Host "$(' ' * $Spaces)^" -NoNewline 
        }
    }
    If ($Explain) {
        Write-Host "`n" NewLine
        Write-Host '^ (Space)'
        Write-Host 'Good' -ForegroundColor Green
        Write-Host 'Case' -ForegroundColor Yellow
        Write-Host 'Missing' -ForegroundColor Gray
        Write-Host 'Different' -ForegroundColor Red
    }
}

