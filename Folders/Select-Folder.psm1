Function Select-Folder {
    <#
        .NOTES
            Created By: Kyle Hewitt
            Created On: 5/20/2020
            Version: 2020.05.20
 
        .DESCRIPTION
            This is a CLI Folder Navigation Tool
    #>

    Param (
        $StartFolder
    )
    
    Try {
        If (!(Test-Path $StartFolder -ErrorAction Stop)) {
            Throw "$StartFolder --- Path not found"
        }
    }
    Catch {
        Throw "$StartFolder --- Error: $_"
    }

    $StartFolder = Get-Item -Path $StartFolder -ErrorAction Stop | Select-Object -ExpandProperty FullName

    Function Select-Choice {
        Param(
            [String[]]$Options,
            [String]$PromptPrefix,
            [String]$PromptSuffix,
            [String[]]$OtherOptions,
            [ValidateSet('Index', 'Value')]$ReturnType = 'Index'
        )
        $Prompt = $PromptPrefix
        If ($Options.Count -ge 1) {
            $Prompt += for ($i = 0; $i -lt $Options.Count; $i++) { "`n[$($i+1)] $($Options[$i])" }
            $Prompt += "$PromptSuffix"
            $Prompt += "`nTo search: Type anything aside from a legit option"
            If ([Boolean]$Script:AllOptions) { $Prompt += "`nTo show All Options type `"All Options`"" }
        }
        Else {
            $Prompt += "`n`nNO OPTIONS AVAILABLE`n"
        }
        $Prompt += "`nSelect Choice"

        Switch (Read-Host -Prompt $Prompt) {
            { $OtherOptions -contains $_ } { 
                Remove-Variable -Name AllOptions -Scope Script -ErrorAction SilentlyContinue
                Return $_
            }

            { ((1..$($Options.Count)) -contains $_ ) } { 
                If ($ReturnType -eq 'Index') { 
                    If ([Boolean]$Script:AllOptions -and $Options -ne $Script:AllOptions) {
                        $ReturnIndex = $Script:AllOptions.IndexOf( $Options[([int]$_ - 1)] )   
                        Remove-Variable -Name AllOptions -Scope Script -ErrorAction SilentlyContinue
                        Return $ReturnIndex
                    }
                    Else { Return [Int]$_ - 1 }
                }
                ElseIf ($ReturnType -eq 'Value') { Return $Options[([int]$_ - 1)] }
            }

            Default { 
                If ($_.Length -ge 3 -and $_ -like '*\*') {
                    If ($_.Substring(0, 3) -match '[a-zA-z]{1,}:\\' -or $_ -like '\\*') {
                        Return $_
                    }
                }
                ElseIf ($_ -eq 'All Options') {
                    $Options = $Script:AllOptions
                    Remove-Variable -Name AllOptions -Scope Script -ErrorAction SilentlyContinue
                }
                Else {
                    [String[]]$PossibleOptions = $Options -like "*$_*"
                    If ($PossibleOptions.Count -eq $Options.Count -or $PossibleOptions.Count -eq 0) {
                        Write-Warning 'Not a validate option. Options could not be narrowed down.'
                    }
                    ElseIf ($PossibleOptions.Count -eq 1) {
                        If ($ReturnType -eq 'Index') {
                            If ([Boolean]$Script:AllOptions) {
                                $ReturnIndex = $Script:AllOptions.IndexOf( "$PossibleOptions" )   
                                Remove-Variable -Name AllOptions -Scope Script -ErrorAction SilentlyContinue
                                Return $ReturnIndex
                            }
                            Else {
                                Remove-Variable -Name AllOptions -Scope Script -ErrorAction SilentlyContinue
                                Return $Options.IndexOf("$PossibleOptions") 
                            }
                        }
                        ElseIf ($ReturnType -eq 'Value') {
                            Remove-Variable -Name AllOptions -Scope Script -ErrorAction SilentlyContinue
                            Return $PossibleOptions 
                        }
                    }
                    ElseIf ($PossibleOptions.Count -gt 1) {
                        $Script:AllOptions = $Options
                        $Options = $PossibleOptions 
                    }
                    
                }
                Select-Choice -Options $Options -PromptPrefix $PromptPrefix -OtherOptions $OtherOptions -ReturnType $ReturnType -PromptSuffix $PromptSuffix
            }
        }
    }

    Function Navigate {
        Param(
            $Folder
        )
        $CurrentLocation = $Folder
        :SubKey While ($Choice -ne 'Stay') {
            $PromptPrefix = $SubFolders = $Choice = $null

            # Prompt for Choice
            Try {
                $SubFolders = Get-ChildItem -Path $CurrentLocation -Directory -Force -ErrorAction Stop | 
                    Select-Object -ExpandProperty BaseName
                Sort-Object
            }
            Catch {
                Write-Warning -Message "$_"
                $CurrentLocation = (Split-Path -Path $CurrentLocation)
                $SubFolders = Get-ChildItem -Path $CurrentLocation -Directory -Force -ErrorAction Stop | 
                    Select-Object -ExpandProperty BaseName
                Sort-Object  
            }

            $PromptPrefix = "`n`nCurrent Location: $($CurrentLocation)"
            $PromptPrefix += "`n[..] Previous Location"
            $PromptPrefix += "`n[Stay] Stay at current location"
            $Choice = Select-Choice -Options $SubFolders -PromptPrefix $PromptPrefix -OtherOptions ('..', 'Stay')
            
            If ($Choice -is [int]) {
                $CurrentLocation = "$CurrentLocation\$($SubFolders[($Choice)])"
            }
            # To previous location
            ElseIf ($Choice -eq '..') {
                $Parent = Split-Path -Path $CurrentLocation -Parent -ErrorAction SilentlyContinue
                If ($Parent -ne $CurrentLocation -and [Boolean]$Parent) {
                    $CurrentLocation = $Parent
                }
                ElseIf (![Boolean]$Parent) {
                    $CurrentLocation = Get-MappedDrives
                }
            }
            ElseIf ($Choice.Substring(0, 3) -match '[a-zA-z]{1}:\\' -or $Choice -like '\\*') {
                $CurrentLocation = $Choice
            }
            
        }
        Return $CurrentLocation
    }

    Function Get-MappedDrives {
        # Prompt for Choice
        $Drives = Get-PSDrive -PSProvider FileSystem | Select-Object -ExpandProperty Root
        $PromptPrefix += "`nSelect an option to go to that Drive"
        $Choice = Select-Choice -Options $Drives -PromptPrefix $PromptPrefix
        Return $Drives[($Choice)]
        
    }
    
    Navigate -Folder $StartFolder
}