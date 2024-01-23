Function Get-LocalGroupMember {
    <#
        .NOTES
            Created By: Kyle Hewitt
            Created On: 12/23/19
            Last Edit: 12/23/19
            Version: 1.0.0

        .DESCRIPTION
    #>
    [cmdletbinding()]
    [Alias('glgm', 'get-localgm', 'get-lgm')]
    Param(
        [String[]] $ComputerName = $env:COMPUTERNAME,
        [Parameter(ParameterSetname = 'Groups')]
        [String[]] $Group,
        [Parameter(ParameterSetname = 'Groups')]
        [String[]] $Member
    )

    Process {
        Foreach ($Computer in $ComputerName) {
            [ADSI]$ADSI = "WinNT://$Computer"

            $Children = $ADSI.Children

            $Children | 
                Where-Object -FilterScript { $_.Class -eq 'Group' -and (!$PSBoundParameters.ContainsKey('Group') -or $Group -contains $_.Name.Value ) } |
                Select-Object -Property `
                @{Name = 'Computer'; Expression = { $Computer } },
                @{Name = 'Name'; Expression = { $_.Name.Value } },
                @{Name = 'Members'; Expression = {
                        [ADSI]$Group = "$($_.Parent)/$($_.Name),group"
                        $Members = $Group.PSBase.Invoke('Members')
                        $Members | ForEach-Object -Process {
                            $Name = $_.GetType().InvokeMember('Name', 'GetProperty', $null, $_, $null)
                            If (!$PSBoundParameters.ContainsKey('Member') -or $Member -contains $name) {
                                $Name
                            }
                        }
                    }
                }
        }
    }   
}

Function Add-LocalGroupMember {
    <#
        .NOTES
            Created By: Kyle Hewitt
            Created On: 12/23/19
            Last Edit: 12/23/19
            Version: 1.0.0

        .DESCRIPTION
    #>
    [cmdletbinding()]
    [Alias('algm', 'add-localgm', 'add-lgm')]
    Param(
        [String[]]$ComputerName = $env:COMPUTERNAME,
        $Group,
        $Member
    )

    Process {
        Foreach ($Computer in $ComputerName) {
            $ADSI = [ADSI]"WinNT://$Computer/$Group,group" 
            $ADSI.PSBase.Invoke('Add', ([ADSI]"WinNT://$Member").Path)
        }
    }   
}

Function Remove-LocalGroupMember {
    <#
        .NOTES
            Created By: Kyle Hewitt
            Created On: 12/23/19
            Last Edit: 12/23/19
            Version: 1.0.0

        .DESCRIPTION
    #>
    [cmdletbinding()]
    [Alias('rlgm', 'remove-localgm', 'remove-lgm')]
    Param(
        [String[]]$Computername = $env:COMPUTERNAME,
        $Group,
        $Member
    )

    Process {
        Foreach ($Computer in $ComputerName) {
            $ADSI = [ADSI]"WinNT://$Computer/$Group,group" 
            $ADSI.PSBase.Invoke('Remove', ([ADSI]"WinNT://$Member").Path)
        }
    }   
}