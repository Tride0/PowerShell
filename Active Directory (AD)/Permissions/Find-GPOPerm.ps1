Function Find-GPOPerm {
    <#
        .NOTES
            Created By: Kyle Hewitt
            Created On: 4/30/20
            Version: 2020.04.30
            
        .DESCRIPTION
            Gets GPOs that don't have a security principal with the Apply Permission
    #>
    Param(
        $Domain = $env:USERDNSDOMAIN,
        $Principal
    )
    Begin {
        Import-Module GroupPolicy, ActiveDirectory -ErrorAction Stop
        $Results = @()
    }
    Process {
        Try {
            $ADUser = Get-ADUser $Principal -Server $Domain -Properties memberof -ErrorAction Stop
            Write-Host AD User Found: $ADUser.SamAccountName -ForegroundColor Cyan
        }
        Catch {
            Throw $_
        }

        $GPOs = (New-Object Microsoft.GroupPolicy.GPDomain $Domain).GetAllGpos()
        :GPOs Foreach ($GPO in $GPOS) {

            Try {
                $ACL = Get-Acl -Path "AD:\$($GPO.Path)" -ErrorAction Stop
            }
            Catch {
                Write-Host "Failed to Get ACL for $($OUDN). Error: $_" -ForegroundColor Red
                Continue GPOs
            }

            $DirectACE = $ACL.Access | Where-Object -FilterScript { $_.IdentityReference -match $ADUser.SamAccountName }
            If ($DirectACE) {
                Write-Host "Direct Permission Found on: $($GPO.DisplayName)" -ForegroundColor Cyan
                $Results += "Direct :: $($GPO.DisplayName)"
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
                    Write-Host "Group ($Group) Permission Found on: $($GPO.DisplayName)" -ForegroundColor Cyan
                    $Results += "$Group :: $($GPO.DisplayName)"
                }
            }
        }
    }
}