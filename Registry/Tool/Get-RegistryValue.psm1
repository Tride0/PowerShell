
Function Get-RegistryValue {
    <#
        .NOTES
            Created By: Kyle Hewitt
            Created On: 5/04/20

        .DESCRIPTION
            This tool gets a registry value but will assist in retrieving a value if a full path isn't provided. It has Registry Navigation built into it.
    #>
    Param(
        $Computer = $env:COMPUTERNAME,
        $BaseKey = 'LocalMachine',
        $SubKey,
        $ValueName
    )

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
            $Prompt += "`nSelect Choice"
        }
        Else {
            $Prompt += "`n`nNO OPTIONS AVAILABLE`n"
        }


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
                If ($_ -eq 'All Options') {
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
            $CurrentKeyLocation
        )
        :SubKey While ($Choice -ne 'Stay') {
            $Split = $NewLocation = $PromptPrefix = $SubKeys = $Choice = $null

            # Prompt for Choice
            $SubKeys = $CurrentKeyLocation.GetSubKeyNames() | Sort-Object
            $PromptPrefix = "`n`nCurrent Location: $($CurrentKeyLocation.Name)"
            $PromptPrefix += "`n[..] Previous Location"
            $PromptPrefix += "`n[Stay] Stay at current location"
            $Choice = Select-Choice -Options $SubKeys -PromptPrefix $PromptPrefix -OtherOptions ('..', 'Stay')

            If ($Choice -is [int]) {
                $CurrentKeyLocation = $CurrentKeyLocation.OpenSubKey($SubKeys[($Choice)])
            }

            # To previous location
            If ($Choice -eq '..') {
                $Split = $CurrentKeyLocation.Name.Split('\')
                If ($Split.COunt -gt 2) {
                    $NewLocation = $Split[1..($Split.Count - 2)] -join '\\'
                    $CurrentKeyLocation = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($BaseKey, $Computer).OpenSubKey($NewLocation)
                }
                ElseIf ($Split.Count -eq 2) {
                    $CurrentKeyLocation = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($BaseKey, $Computer)
                }
                ElseIf ($Split.Count -eq 1) {
                    $RegBaseKey = Get-RegBaseKey
                    $CurrentKeyLocation = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($RegBaseKey, $Computer)
                }
            }
        }
        Return $CurrentKeyLocation
    }

    Function Get-RegValue {
        Param(
            $CurrentKeyLocation
        )
        # Prompt for Choice
        $ValueNames = $CurrentKeyLocation.GetValueNames() | Sort-Object

        $PromptPrefix = "`n`n`nCurrent Location: $($CurrentKeyLocation.Name)"
        $PromptPrefix += "`nSelect an option to get it's value"
        $PromptPrefix += "`n[..] Go back to navigation"
        $PromptSuffix = "`n[All] Get all values"
        $Choice = Select-Choice -Options $ValueNames -PromptPrefix $PromptPrefix -PromptSuffix $PromptSuffix -OtherOptions '..', 'All'

        Switch ($Choice) {
            '..' { Get-RegValue (Navigate -CurrentKeyLocation $CurrentKeyLocation) }
            'All' {
                $AllValues = @{ }
                Foreach ($ValueName in $ValueNames) {
                    $AllValues.Add( $ValueName, $CurrentKeyLocation.GetValue($ValueName) )
                }
                Return [PSCustomObject]$AllValues
            }
            Default { Return $CurrentKeyLocation.GetValue($ValueNames[($Choice)]) }
        }
    }

    Function Get-RegBaseKey {
        # Prompt for Choice
        $BaseKeys = ([Microsoft.Win32.Registry].GetFields().Name) | Sort-Object # This is likely a problem because it looks at the local machines' registry's and not the remote machine's.
        $PromptPrefix += "`nSelect an option to go to that Base Key"
        $Choice = Select-Choice -Options $BaseKeys -PromptPrefix $PromptPrefix
        Return $BaseKeys[($Choice)]

    }

    If (![Boolean]$SubKey) {
        $CurrentKeyLocation = Navigate -CurrentKeyLocation ([Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($BaseKey, $Computer))
    }
    Else {
        $CurrentKeyLocation = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($BaseKey, $Computer).OpenSubKey($SubKey)
    }

    If (![Boolean]$ValueName) {
        Get-RegValue -CurrentKeyLocation $CurrentKeyLocation
    }
    Else {
        $CurrentKeyLocation.GetValue($ValueName)
    }
}
