Function Get-ADConflictObjects {
    <#
        .NOTES
            Created By: Kyle Hewitt
            Created On: 4/30/20
            Version: 2020.04.30
            
        .DESCRIPTION
            Get Conflict objects and look for a potential original
    #>
    Begin {
        $ADSearcher = [DirectoryServices.DirectorySearcher]@{
            # Increase this number to increase the amount of results returned. This is useful for large domains/queries.
            PageSize = 3 
            Filter   = '(|(cn=*\0ACNF:*)(ou=*CNF:*))'
        }
    }
    Process {
        $ADSearcher.FindAll().Properties | 
            ForEach-Object -Process {
                If ([Bool]$_.useraccountcontrol) {
                    $Enabled = ([Convert]::ToString($_.useraccountcontrol[0], 2)[-2] -eq '0')
                    If ([Boolean]$_.lockouttime -and $_.lockouttime -gt 0 -or (([Convert]::ToString($_.useraccountcontrol[0], 2)[-5]) -eq 1 -and [Boolean]([Convert]::ToString($_.useraccountcontrol[0], 2)[-5]))) { $LockedOut = 'True' }
                    Else { $LockedOut = 'False' }
                    $LastLogon = [DateTime]::FromFileTime("$($_.lastlogon)")
                    $LastLogonDate = [DateTime]::FromFileTime("$($_.lastlogontimestamp)")
                    $PasswordLastSet = [DateTime]::FromFileTime("$($_.pwdLastSet)")
                }
                Else {
                    $LockedOut = $Enabled = $PasswordLastSet = $LastLogonDate = $LastLogon = 'No UAC'
                }

                $CNF = [PSCustomObject]@{
                    distinguishedname = $($_.distinguishedname)
                    samaccountname    = $($_.samaccountname)
                    manager           = $($_.manager)
                    whencreated       = $($_.whencreated)
                    whenChanged       = $($_.whenchanged)
                    LastLogon         = $($LastLogon)
                    LastLogonDate     = $($LastLogonDate)
                    PasswordLastSet   = $($PasswordLastSet)
                    Enabled           = $($Enabled)
                    LockedOut         = $($LockedOut)
                }

                $CNFGuid = ($CNF.distinguishedname -split (',[A-Z]{2}='))[0].split('\')[1]
                $OriginalDN = $CNF.distinguishedname.replace("\$CNFGuid", '')
                $ADSearcher.Filter = "distinguishedname=$OriginalDN"
                $Original = $ADSearcher.FindOne().Properties
                    
                If ([Bool]$Original.useraccountcontrol) {
                    $Enabled = ([Convert]::ToString($Original.useraccountcontrol[0], 2)[-2] -eq '0')
                    If ([Boolean]$Original.lockouttime -and $Original.lockouttime -gt 0 -or (([Convert]::ToString($Original.useraccountcontrol[0], 2)[-5]) -eq 1 -and [Boolean]([Convert]::ToString($Original.useraccountcontrol[0], 2)[-5]))) { $LockedOut = 'True' }
                    Else { $LockedOut = 'False' }
                    $LastLogon = [DateTime]::FromFileTime("$($Original.lastlogon)")
                    $LastLogonDate = [DateTime]::FromFileTime("$($Original.lastlogontimestamp)")
                    $PasswordLastSet = [DateTime]::FromFileTime("$($Original.pwdLastSet)")
                }
                Else {
                    $LockedOut = $Enabled = $PasswordLastSet = $LastLogonDate = $LastLogon = 'No UAC'
                }
                    
                If ([Bool]$Original) {
                    $Original = [PSCustomObject]@{
                        distinguishedname = $($Original.distinguishedname)
                        samaccountname    = $($Original.samaccountname)
                        manager           = $($Original.manager)
                        whencreated       = $($Original.whencreated)
                        whenChanged       = $($Original.whenchanged)
                        LastLogon         = $($LastLogon)
                        LastLogonDate     = $($LastLogonDate)
                        PasswordLastSet   = $($PasswordLastSet)
                        Enabled           = $($Enabled)
                        LockedOut         = $($LockedOut)
                    }
                }
                Else {
                    $Original = [PSCustomObject]@{
                        distinguishedname = ''
                        samaccountname    = ''
                        manager           = ''
                        whencreated       = ''
                        whenChanged       = ''
                        LastLogon         = ''
                        LastLogonDate     = ''
                        PasswordLastSet   = ''
                        Enabled           = ''
                        LockedOut         = ''
                    }
                }

                [PSCustomObject]@{
                    CNF_dn              = $CNF.distinguishedname
                    CNF_san             = $CNF.SamAccountName
                    CNF_Manager         = $CNF.manager
                    CNF_Created         = $CNF.Whencreated
                    CNF_Changed         = $CNF.Whenchanged
                    CNF_LastLogon       = $CNF.LastLogon
                    CNF_LastLogonDate   = $CNF.LastLogonDate
                    CNF_PasswordLastSet = $CNF.PasswordLastSet
                    CNF_Enabled         = $CNF.Enabled
                    CNF_LockedOut       = $CNF.LockedOut
                    O_dn                = $Original.distinguishedname
                    O_san               = $Original.SamAccountName
                    O_Manager           = $Original.manager
                    O_Created           = $Original.WhenCreated
                    O_Changed           = $Original.WhenChanged
                    O_LastLogon         = $Original.LastLogon
                    O_LastLogonDate     = $Original.LastLogonDate
                    O_PasswordLastSet   = $Original.PasswordLastSet
                    O_Enabled           = $Original.Enabled
                    O_LockedOut         = $Original.LockedOut
                }

                Remove-Variable CNF, Original, split -ErrorAction SilentlyContinue
            }
    }
}
