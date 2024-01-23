Function Set-FileExtension {
    <#
        .NOTES
            Created By: Kyle Hewitt
            Created On: 08-21-2020
            Version: 2020.08.21

        .DESCRIPTION
            This function will add, replace or remove a file's extension
    #>
    Param(
        [Parameter(Mandatory = $True, 
            ValueFromPipeline = $true)]
        [String[]]$Path,

        [Parameter(Mandatory = $False)]
        [String]$Extension,

        [parameter(Mandatory = $True)]
        [ValidateSet('Add', 'Replace', 'RemoveEnd')]
        [String]$Action,

        [Switch]$Resurce,

        [Switch]$HiddenFiles
    )

    If ($Extension[0] -eq '.') {
        $Extension = $Extension.Remove(0, 1)
    }

    Foreach ($Path in $Path) {
        If ($Resurce.IsPresent -and $HiddenFiles.IsPresent) {
            $Items = Get-ChildItem -File -Path $Path -Recurse -Force
        }
        ElseIf ($Resurce.IsPresent -and !$HiddenFiles.IsPresent) {
            $Items = Get-ChildItem -File -Path $Path -Recurse
        }
        ElseIf (!$Resurce.IsPresent -and $HiddenFiles.IsPresent) {
            $Items = Get-ChildItem -File -Path $Path -Force
        }
        ElseIf (!$Resurce.IsPresent -and !$HiddenFiles.IsPresent) {
            $Items = Get-ChildItem -File -Path $Path
        }

        ForEach ($Item in $Items) {
            Switch ($Action) {
                'Add' {
                    Rename-Item -Path $Item.FullName -NewName "$($Item.Name).$Extension"
                }
                'Replace' {
                    If (!(Test-Path -Path "$(Split-Path $Item.FullName)\$($Item.BaseName).$Extension")) {
                        Rename-Item -Path $Item.FullName -NewName "$($Item.BaseName).$Extension"
                    }
                    Else {
                        Write-Warning -Message "Added $Extension to `"$($Item.FullName)`" because `"$(Split-Path $Item.FullName)\$($Item.BaseName).$Extension`" already exists."
                        Rename-Item -Path $Item.FullName -NewName "$($Item.Name).$Extension"
                    }
                }
                'RemoveEnd' {
                    Rename-Item -Path $Item.FullName -NewName $($Item.Name -Replace $Item.Extension)
                }
                Default {
                    Write-Warning 'Invalid or No Action Specified.'
                    Exit
                }
            }
        }
    }
}