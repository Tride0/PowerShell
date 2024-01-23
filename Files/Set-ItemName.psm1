Function Set-ItemName {
    <#
        .NOTES
            Created By: Kyle Hewitt
            Created On: 07-06-2020
            Version: 2020.08.17
            
            I'm open to a new name for this function.

        .DESCRIPTION
            This function can be used to change file names in bulk.
    #>
    Param(
        [String[]]$Path,
        [Switch]$Recurse,
        [String]$Filter,
        [Int]$Depth,
        [Switch]$Force,
        [ValidateSet('Directory', 'File')]$ItemType,
        [String]$Replace,
        [String]$ReplaceWith,
        [String]$Remove,
        [String]$Prefix,
        [String]$Suffix,
        [String]$Extension,
        [Boolean]$AddAnyway = $False
    )
    Process {
        # Build Parameters for Get-ChildItem
        If ([Boolean]$Filter) {
            $GetChildItemParameters.Filter = $Filter
        }
        If ([Boolean]$Recurse) {
            $GetChildItemParameters.Recurse = $Recurse
        }
        If ([Boolean]$Force) {
            $GetChildItemParameters.Force = $Force
        }
        If ([Boolean]$Depth) {
            $GetChildItemParameters.Depth = $Depth
        }
        If ([Boolean]$ItemType) {
            $GetChildItemParameters.ItemType = $ItemType
        }

        :Path Foreach ($iPath in $Path) {
            Try {
                If (!(Test-Path -Path $iPath)) {
                    Write-Host "Failed to find $iPath. Skipping." -ForegroundColor Red
                    Continue Path
                }
            } 
            Catch {
                Write-Host "Failed to find $iPath. Skipping. Error: $_" -ForegroundColor Red
                Continue Path
            }
            
            [Array]$Paths = Get-ChildItem @GetChildItemParameters -Path $iPath

            :Item Foreach ($Item in $Paths) {
                Try {
                    $Item = Get-Item -Path $Item -ErrorAction Stop
                }
                Catch {
                    Write-Host "Failed to retrieve $($Item.FullName). Skipping. Error: $_" -ForegroundColor Red
                    Continue Item
                }

                $NewName = $Item.BaseName

                If ([Boolean]$Replace -and [Boolean]$ReplaceWith) {
                    $NewName = $NewName.Replace($Replace, $ReplaceWith)
                }
                
                If ([Boolean]$Remove) {
                    $NewName = $NewName.Replace($Remove, '')
                }

                If ([Boolean]$Prefix -or [Boolean]$Suffix) {
                    If ($AddAnyway -or $NewName -notlike "$Prefix*") {
                        $NewName = $Prefix + $NewName
                    }
                    If ($AddAnyway -or $NewName -notlike "*$Suffix") {
                        $NewName = $NewName + $Suffix
                    }
                }
                
                If ([Boolean]$Extension) {
                    If ($Extension -notlike '.*') {
                        $Extension = ".$Extension"
                    }
                    $NewName = $NewName + $Exntesion
                }
                ElseIf ([Boolean]$Item.Extension) {
                    $NewName = $NewName + $Item.Extension
                }
                
                If ($NewName -eq $Item.Name) {
                    Write-Warning "Didn't rename '$($Item.Fullname)'. Reason: No change to name."
                }
                Else {
                    Try {
                        Rename-Item -Path $Item.FullName -NewName $NewName -Force -ErrorAction Stop
                    }
                    Catch {
                        Write-Error "Failed to rename '$($Item.FullName)'. Error: $_"
                    }
                }
            }
        }
    }
}
