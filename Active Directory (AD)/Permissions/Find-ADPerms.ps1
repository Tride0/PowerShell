Function Find-ADPerms {
    <#
        Created By: Kyle Hewitt
        Created On: 2022-01-11
        Version: 2022.1.12

        Description: This script will search the AD ACLs for any permissions that a SID may have.
    #>
    Param(
        [String[]]$Value,
        [String]$Domain = $env:USERDOMAIN,
        [String[]]$OUs
    )
    Begin {
        Import-Module ActiveDirectory -ErrorAction Stop
        If (!$OUs) {
            $OUs = Get-ADOrganizationalUnit -Filter * -Server $Domain
        }
        $Results = @{}
    }
    Process {
        :Values Foreach ($Val in $Value) {
            Remove-Variable ADUser, UserResults -ErrorAction SilentlyContinue

            Try {
                $ADUser = Get-ADUser $Val -Properties memberof -ErrorAction Stop
                Write-Host AD User Found: $ADUser.SamAccountName -ForegroundColor Cyan
            }
            Catch {
                Write-Host "AD User Not Found. Error: $_" -ForegroundColor Red
                Continue Values
            }

            $UserResults = @{
                DN      = $ADUser.DistinguishedName
                PermOUs = @()
            }

            :OUs Foreach ($OU in $OUs) {
                Remove-Variable OUDN, ACL, DirectACE, GroupACE -ErrorAction SilentlyContinue

                If ($OU.DistinguishedName) {
                    $OUDN = $OU.DistinguishedName
                }
                Else {
                    $OUDN = $OU
                }

                Try {
                    $ACL = Get-Acl "AD:\$($OUDN)" -ErrorAction Stop
                }
                Catch {
                    Write-Host "Failed to Get ACL for $($OUDN). Error: $_" -ForegroundColor Red
                    Continue OUs
                }

                $DirectACE = $ACL.Access | Where-Object -FilterScript { $_.IdentityReference -match $ADUser.SamAccountName }
                If ($DirectACE) {
                    Write-Host Direct Permission Found on: $OUDN -ForegroundColor Cyan
                    $UserResults.PermOUs += "Direct :: $OUDN"
                }

                :Groups Foreach ($Group in $ADUser.MemberOf) {
                    Try {
                        $ADGroup = Get-ADGroup $Group -Server "$Domain`:3268" -ErrorAction Stop
                    }
                    Catch {
                        Write-Host "Failed to get Group: $Group. Error: $_" -ForegroundColor Red
                        Continue Groups
                    }
                    $GroupACE = $ACL.Access | Where-Object -FilterScript { $_.IdentityReference -match $ADGroup.SamAccountName }
                    If ($GroupACE) {
                        Write-Host "Group ($($ADGroup.SamAccountName) Permission Found on: $OUDN" -ForegroundColor Cyan
                        $UserResults.PermOUs += "$Group :: $OUDN"
                    }
                }
            }

            $Results += $UserResults.Clone()
        }
    }
    End {
        Return $Results
    }
}