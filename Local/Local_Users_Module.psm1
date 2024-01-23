Function Get-LocalUser {
    [cmdletbinding()]
    [Alias('glu', 'get-localu', 'get-lu')]
    Param(
        [String[]] $ComputerName = $env:COMPUTERNAME,
        [String[]] $User
    )
    Process {
        Foreach ($Computer in $ComputerName) {
            [ADSI]$ADSI = "WinNT://$Computer"

            $Children = $ADSI.Children

            $Children | 
                Where-Object -FilterScript { $_.Class -eq 'User' -and (!$PSBoundParameters.ContainsKey('Group') -or $User -contains $_.Name.Value ) } |
                Select-Object -Property `
                @{Name = 'Computer'; Expression = { $Computer } },
                @{Name = 'Name'; Expression = { $_.Name.Value } }
        }
    }
}


Function Reset-LocalUserPassword {
    [cmdletbinding()]
    [Alias('rlupw', 'reset-localupw', 'reset-lupw')]
    Param(
        [String] $ComputerName = $env:COMPUTERNAME,
        [Parameter(Mandatory)]
        [String] $User,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String] $Password
    )
    Begin {
        $Old_ErrorActionPreference = $ErrorActionPreference
    }
    Process {
        
        $ErrorActionPreference = 'Stop'
        
        # Attempt to retrieve user
        Try {
            [ADSI]$User = "WinNT://$Computer/$User,user"
        }
        Catch {
            Write-Host "Unable to retrieve user: $_" -ForegroundColor Red
            Return (Get-LocalUsers -ComputerName $Computer -User $User)
        }

        # Attempt to set password
        Try {
            $user.SetPassword($Password)
            $user.SetInfo()
        }
        Catch {
            Throw "Unable to set password on user: $_"
        }

    }
    End {
        $ErrorActionPreference = $Old_ErrorActionPreference
    }
}


Function Rename-LocalUser {
    [cmdletbinding()]
    [Alias('rename-lu', 'rename-localu', 'rename-lu')]
    Param(
        [String] $ComputerName = $env:COMPUTERNAME,
        [Parameter(Mandatory)]
        [String] $User,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String] $NewName
    )
    Begin {
        $Old_ErrorActionPreference = $ErrorActionPreference
    }
    Process {
        
        $ErrorActionPreference = 'Stop'
        
        # Attempt to retrieve user
        Try {
            [ADSI]$User = "WinNT://$Computer/$User,user"
        }
        Catch {
            Write-Host "Unable to retrieve user: $_" -ForegroundColor Red
            Return (Get-LocalUsers -ComputerName $Computer -User $User)
        }

        # Attempt to rename user
        Try {
            $User.Rename($Newname)
            $user.SetInfo()
        }
        Catch {
            Throw "Unable to rename user: $_"
        }

    }
    End {
        $ErrorActionPreference = $Old_ErrorActionPreference
    }
}


Function Remove-LocalUser {
    [cmdletbinding()]
    [Alias('dlu', 'delete-localu', 'delete-lu')]
    Param(
        [String] $ComputerName = $env:COMPUTERNAME,
        [Parameter(Mandatory)]
        [String] $User,
        [Boolean]$Confirm = $True
    )
    Begin {
        $Old_ErrorActionPreference = $ErrorActionPreference
    }
    Process {
        
        $ErrorActionPreference = 'Stop'
        
        # Attempt to retrieve user
        Try {
            [ADSI]$User = "WinNT://$Computer/$User,user"
        }
        Catch {
            Throw "Unable to retrieve user: $_"
        }

        # Attempt to delete user
        Try {
            If ($Confirm) {
                $Confirmation = $Host.UI.PromptForChoice(
                    'Deletion Confirmation', 
                    "Are you sure you want to delete $($User.Name.Value) on $Computer`?", 
                    ('Delete', 'Cancel'), 1)
                if ($Confirmation -ne 0) {
                    Return 'Operation Cancelled'
                }
            }
            $User.DeleteTree()
            # SetInfo() may not be needed
            $User.SetInfo()
        }
        Catch {
            Throw "Unable to delete user: $_"
        }

    }
    End {
        $ErrorActionPreference = $Old_ErrorActionPreference
    }
}