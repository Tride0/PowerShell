Function Check-Word {
    Param(
        $Word,
        $Language = 'English (US)'
    )
    $Dictionary = New-Object -COM Scripting.Dictionary
    $wordChecker = New-Object -COM Word.Application
    $wordChecker.Languages | ForEach-Object -Process { If ($_.Name -eq $Language) { $Dictionary = $_.ActiveSpellingDictionary } }
    $wordChecker.checkSpelling($Word, [ref]$null, [ref]$null, [ref]$Dictionary)
}