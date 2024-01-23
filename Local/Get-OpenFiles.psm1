Function Get-Openfiles {
    <#
        .NOTES
            Created By: Kyle Hewitt
            Created On: 2019
            Last Edit 1/6/2020
    #>
    Param(
        [Parameter(Mandatory = $True, ValueFromPipeline = $true, Position = 0)][String[]]$Paths = '.\',
        [ValidateScript( { 
                $Paths | ForEach-Object { If ($_ -notlike '*\\*' -and $Server -notlike '*') { Return $False } }
                Return $True
            })][String]$Server = '',
        [Parameter(Mandatory = $False)][String[]]$ExcludeUser,
        [Parameter(Mandatory = $False)][String[]]$IncludeUser,
        [Parameter(Mandatory = $False)][Boolean]$PassThru = $True,
        [Parameter(Mandatory = $False)][Switch]$Export = $False,
        [Parameter(Mandatory = $False)][Switch]$Disconnect = $False,
        [Parameter(Mandatory = $False)][String]$ExportPath = "$ENV:USERPROFILE\desktop\$Server`_OpenFiles_$(Get-Date -Format yyyyMMddhhmmss).csv"
    )

    If ([Boolean]$Server) {
        $PerPath = $False
        $OpenFiles = ConvertFrom-Csv (openfiles /query /S $Server /FO csv) #1
    }
    Else {
        $Paths | ForEach-Object -Process {
            If ($Server.Trim() -eq $_.Split('\', [System.StringSplitOptions]::RemoveEmptyEntries)[0].Trim() -or ![Boolean]$Server) {
                $Server = $_.Split('\', [System.StringSplitOptions]::RemoveEmptyEntries)[0].Trim()
                $PerPath = $False
            }
            ElseIf ($Server.Trim() -ne $_.Split('\', [System.StringSplitOptions]::RemoveEmptyEntries)[0].Trim()) {
                $PerPath = $True
            }
        }
        If (!$PerPath) {
            $Server = $Paths[0].Split('\', [System.StringSplitOptions]::RemoveEmptyEntries)[0]
            $Paths = $Paths | ForEach-Object -Process {
                $Split = $_.Split('\', [System.StringSplitOptions]::RemoveEmptyEntries)
                $Split[ - ($Split.Count - 1)..-1] -join '\'
            }
            $OpenFiles = ConvertFrom-Csv (openfiles /query /S $Server /FO csv) #2
        }
    }

    Foreach ($Path in $Paths) {
        If ($PerPath) {
            $Split = $Path.Split('\', [System.StringSplitOptions]::RemoveEmptyEntries)
            $Server = $Split[0]
            $Path = $Split[ - ($Split.Count - 1)..-1] -join '\'
            $OpenFiles = ConvertFrom-Csv (openfiles /query /S $Server /FO csv) #3
        }
        $Information = $OpenFiles | 
            Where-Object -FilterScript { $_.'Open File (Path\executable)' -like "*$Path*" -and 
            (( $PSBoundParameters.ContainsKey('ExcludeUser') -and $ExcludeUser -notcontains $_.'Accessed By' ) -or !$PSBoundParameters.ContainsKey('ExcludeUser') ) -and
            (( $PSBoundParameters.ContainsKey('IncludeUser') -and $IncludeUser -contains $_.'Accessed By') -or !$PSBoundParameters.ContainsKey('IncludeUser') ) } | 
            ForEach-Object -Process {
                Write-Output $_
                If ($Disconnect.IsPresent) {
                    Write-Host Closing... -NoNewline
                    Try {
                        openfiles /disconnect /s $Server /ID * /OP $_.'Open File (Path\executable)'
                        Write-Host " ($($_.'Accessed By')) $($_.'Open File (Path\executable)')"
                    }
                    Catch {
                        Write-Host Failure -ForegroundColor Red
                    }
                }
            } 

        If ($PassThru) {
            $Information
        }
        If ($Export.IsPresent) {
            $Information | Export-Csv $ExportPath -NoTypeInformation -Append -Force
            & $ExportPath
        }
    }
}