Function Generate-RandomPassword {
    <#
        .DESCRIPTION
            Generates a random password based on a character set
        .NOTES
            Created By: Kyle Hewitt
            Created On: 05/08/2020
    #>
    Param(
        $Length = 17,
        [Char[]]$Characters = [Char[]](33..126)
    )
    Return (Get-Random -Count $Length -InputObject $Characters) -join ''
}