Function Check-FileVersion {
    <#
        .NOTES
            Created By: Kyle Hewitt
            Created On: 07-16-2020
            Version: 2020.07.16

        .DESCRIPTION
            Check if the file version matches the specified version.
    #>
    Param(
        [Parameter(Mandatory)][String]$FilePath,
        [Parameter(Mandatory)]$Version,
        [Switch]$Detailed
    )

    Try {
        $Item = Get-Item -Path $FilePath -ErrorAction Stop
    }
    Catch {
        Throw $_
    }
    $FileVersion = $Item.VersionInfo.FileVersionRaw.ToString()

    $Summary = [PSCustomObject]@{
        Matches         = ($FileVersion -eq $Version)
        FileVersion     = $FileVersion
        ProvidedVersion = $Version
    }

    If ($Detailed.IsPresent) {
        Return $Summary
    }
    Else {
        Return $Summary.Matches
    }
}