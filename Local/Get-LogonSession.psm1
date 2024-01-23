Function Get-LogonSession {
    <#
        .NOTES
            The formatting of the logon sessions doesn't account for SessionName and UserName come up blank. 
                Leaving the Session ID to be placed into the SessionName field of the hashtable.

    #>
    [cmdletbinding()]
    Param(
        [String[]]$UserName,
        [String[]]$ComputerName = $ENV:ComputerName,
        [Switch]$Disconnect,
        [Switch]$Confirm
    )
    Begin {
        If ($Disconnect.IsPresent -and ![Boolean]$UserName) {
            Write-Warning -Message 'To disconnect sessions specify a username.'
            Return
        }
        If (!$Disconnect.IsPresent -and $Confirm.IsPresent) {
            Write-Warning -Message 'Confirm is only applicable when used with the Disconnect parameter.'
        }

    }
    Process {
        Foreach ($Computer in $ComputerName) {
            Write-Verbose -Message $Computer
        
            Write-Verbose -Message 'Getting Logon Sessions'
            [Array]$LogonSessions = quser.exe /SERVER:$ComputerName | 
                ForEach-Object -Process {
                    $Split = ($_ -split ' {2,}').Trim()
                    If (![Boolean]$Headers) {
                        [String[]]$Headers += $Split.Trim()
                    }
                    Else {
                        $info = [System.Collections.Specialized.OrderedDictionary]@{ }
                        $info.Add( 'ComputerName', $Computer )
                        $valueIterator = 0
                        $HeaderIterator = 0
                        For ($HeaderIterator = 0; $HeaderIterator -lt $Headers.Count) {
                            If ($(0..100) -contains $Split[$valueIterator] -and $Headers[$HeaderIterator] -ne 'ID' -and $valueIterator -eq $HeaderIterator) {
                                $info.Add( $Headers[$HeaderIterator], $null )
                                $valueIterator--
                            }
                            Else {
                                $info.Add( $Headers[$HeaderIterator], $Split[$valueIterator] )
                            }
                            $valueIterator ++
                            $HeaderIterator++
                        }
                        [PSCustomObject]$info
                    }
                }

            Write-Verbose -Message "$($LogonSessions.Count) Logon Sessions"

            
            If ([Boolean]$UserName) {
                If ($UserName -ne '*') {
                    $SpecifiedLogonSessions = @()
                    Foreach ($User in $UserName) {
                        $UsersLogonSession = $LogonSessions |
                            Where-Object { $_.USERNAME -eq $User }
                        If ([Boolean]$UsersLogonSession) {
                            $SpecifiedLogonSessions += $UsersLogonSession
                        }
                        Else {
                            Write-Warning -Message "Unable to locate logon session for: $User"
                        }
                    }

                    If ($SpecifiedLogonSessions.count -eq 0 -or ![Boolean]$SpecifiedLogonSessions) {
                        Write-Verbose -Message "No Users found to be logged into $Computer. Showing All Present Logon Sessions."
                        Return [PSCustomObject]$LogonSessions | Format-Table
                    }
                    Else {
                        $LogonSessions = $SpecifiedLogonSessions
                    }
                }

                Write-Verbose -Message 'Showing Specified Logon Sessions'
                [PSCustomObject]$LogonSessions | Format-Table | Write-Output

                If ($Disconnect.IsPresent) {
                    Write-Verbose -Message 'Disconnecting sessions'
                    Foreach ($LogonSession in $LogonSessions) {
                        Write-Verbose -Message "Logging off $($LogonSession.USERNAME) on $ComputerName"
                        If ($Confirm) {
                            Read-Host -Prompt "Logging off $($LogonSession.USERNAME) on $ComputerName. Press Enter to Continue..."
                        }
                        logoff.exe $LogonSession.ID /SERVER:$ComputerName /V
                    }
                }
            }
            Else {
                Write-Verbose -Message 'Showing All Logon Sessions'
                [PSCustomObject]$LogonSessions | Format-Table | Write-Output
            }
        }
        Write-Verbose -Message 'Get-LogonSession Cmdlet Finished Running'
    }
    End {
        #Remove-Variable LogonSessions, SpecifiedLogonSessions, UsersLogonSession, Headers
    }
}