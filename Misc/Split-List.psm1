Function Split-List {
    Param(
        [ValidateScript( { $_ -like "*:\*" -or $_ -like "\\*\*" })][String]$ListPath,
        [array]$List,
        $SplitCount = 2
    )
    If ($ListPath) {
        Try {
            $ListItem = Get-Item -Path $ListPath -ErrorAction Stop
        }
        Catch { Throw $_ }

        Try {
            $List = Get-Content -Path $ListPath -ErrorAction Stop
        }
        Catch { Throw $_ }

        $Folder = $(Split-Path $ListItem.FullName -Parent)
        $BaseName = $($ListItem.BaseName)
        $Extension = $($ListItem.Extension)
    }
    Else {
        $Folder = '.'
        $BaseName = "SplitList_$(Get-Date -Format yyyyMMdd_hhmmss)"
        If ($List[0] -is [hashtable] -or $List[0] -is [pscustomobject]) {
            $Extension = '.csv'
        }
        Else {
            $Extension = '.txt'
        }
    }
    $Step = $List.Count / $SplitCount

    $First = 0
    $Last = $Step - 1
    For ($i = 0; $i -lt $SplitCount; $i++) {
        $NewList = $List[$First..$Last]

        $Path = "$Folder\$BaseName`_$i`_$Extension"

        If ($Extension -eq '.csv') {
            $NewList | Export-csv -Path $Path -NoTypeInformation -Force
        }
        Else {
            Set-Content -Value $NewList -Path $Path -Force
        }

        $First = $First + $Step
        $Last = $Last + $Step
    }
}