Function Split-List {
    <#
        .NOTES
            Created By: Kyle Hewitt
            Created On: 08-21-2020
            Version: 2020.08.21

        .DESCRIPTION
            Splits list into multiple equal lists
    #>
    Param(
        [ValidateScript({$_ -like "*:\*" -or $_ -like "\\*\*"})][String]$ListPath,
        $SplitCount = 2
    )

    Try {
        $ListItem = Get-Item -Path $ListPath -ErrorAction Stop
    }
    Catch { Throw $_ }

    Try {
        $List = Get-Content -Path $ListPath -ErrorAction Stop
    }
    Catch { Throw $_ }

    $Step = $List.Count/$SplitCount

    $First = 0
    $Last = $Step - 1
    For ($i = 0; $i -lt $SplitCount; $i++) {
        $NewList = $List[$First..$Last]

        Set-Content -Value $NewList -Path "$(Split-Path $ListItem.FullName -Parent)\$($ListItem.BaseName)_$i`_$($ListItem.Extension)" -Force

        $First = $First + $Step
        $Last = $Last + $Step
    }
}