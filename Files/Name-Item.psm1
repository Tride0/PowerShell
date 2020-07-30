Function Name-Item {
    <#
        .NOTES
            Created By: Kyle Hewitt
            Created On: 07-06-2020
            Version: 2020.07.06
            
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
        [ValidateSet('Directory','File')]$ItemType,
        [String]$Replace,
        [String]$ReplaceWith,
        [String]$Remove,
        [String]$Prefix,
        [String]$Suffix
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

                $NewName = $Item.Name

                If ([Boolean]$Replace -and [Boolean]$ReplaceWith) {
                    $NewName = $NewName.Replace($Replace,$ReplaceWith)
                }
                If ([Boolean]$Remove) {
                    $NewName = $NewName.Replace($Remove,'')
                }
                If ([Boolean]$Prefix -or [Boolean]$Suffix) {
                    $NewName = $Prefix + $NewName + $Suffix
                }

                Try {
                    Rename-Item -Path $Item.FullName -NewName $NewName -Force -ErrorAction Stop
                }
                Catch {
                    Write-Host "Failed to rename $($Item.FullName). Error: $_" -ForegroundColor Red
                }
            }
        }
    }
}