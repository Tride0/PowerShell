Function Get-ADUserPassNotReq {
    <#
        .NOTES
            Created By: Kyle Hewitt
            Created On: 4/30/20
            Version: 2020.04.30
            
        .DESCRIPTION
            Get AD User Objects that have their password set to not be required.
    #>
    Begin {
        $ADSearcher = [DirectoryServices.DirectorySearcher]@{
            # Increase this number to increase the amount of results returned. This is useful for large domains/queries.
            PageSize = 3 
            Filter   = '(&(objectCategory=person)(objectClass=user)(userAccountControl:1.2.840.113556.1.4.803:=32))'
        }
    }
    Process {
        $ADSearcher.FindAll().Properties | 
            ForEach-Object -Process {
                [PSCustomObject]@{
                    distinguishedname = $($_.distinguishedname)
                    name              = $($_.name)
                    samaccountname    = $($_.samaccountname)
                    manager           = $($_.manager)
                    whencreated       = $($_.whencreated)
                    whenChanged       = $($_.whenchanged)
                    LastLogonDate     = [DateTime]::FromFileTime("$($_.lastlogontimestamp)")
                    PasswordLastSet   = [DateTime]::FromFileTime("$($_.pwdlastset)")
                    Disabled          = ([Convert]::ToString($_.useraccountcontrol[0], 2)[-2] -eq '1')
                    LockedOut         = $(If ([Boolean]$_.lockouttime -and $_.lockouttime -gt 0 -or (([Convert]::ToString($_.useraccountcontrol[0], 2)[-5]) -eq 1 -and [Boolean]([Convert]::ToString($_.useraccountcontrol[0], 2)[-5]))) { 'True' }
                        Else { 'False' })
                }
            }
    }
}