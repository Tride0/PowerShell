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