Function Get-AllADDomains {
    Param(
        $Domain = [DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain().Name,
        $DomainStorePath = "$PSScriptRoot\Domains.txt",
        $Depth = 0,
        [Switch]$Renew
    )
    Begin {
        If ((Test-Path $DomainStorePath) -and $Depth -eq 0 -and $Renew.IsPresent) {
            Remove-Item $DomainStorePath -Force
        }
    }
    Process {
        # Returns the domains already found
        If ((Test-Path $DomainStorePath) -and $Depth -eq 0) {
            If ((Get-Item $DomainStorePath).LastWriteTime -gt (Get-Date).AddDays(-30)) {
                $Domains = Get-Content $DomainStorePath
                If ($Domains.Count -gt 0) {
                    Write-Output $Domains
                }
            }
        }
        Else {
            Try {
                $DirectoryContext = New-Object System.DirectoryServices.ActiveDirectory.DirectoryContext -ArgumentList 'Domain', $Domain
                $Domain = [System.DirectoryServices.ActiveDirectory.Domain]::GetDomain($DirectoryContext)
                [String[]]$TrustedDomains = [Array]$Domain.Name + [Array]$Domain.Children.Name + [Array]$Domain.GetAllTrustRelationships().TargetName + [Array]$Domain.GetAllTrustRelationships().SourceName +
                [Array]$Domain.Forest.Name + [Array]$Domain.Forest.Domains.Name + [Array]$Domain.Forest.Domains.GetAllTrustRelationships().TargetName + [Array]$Domain.Forest.Domains.GetAllTrustRelationships().SourceName | 
                    Sort-Object -Unique
            }
            Catch {
                Write-Warning "Unable to get domain '$Domain'. Error: $_"
            }

            $TrustedDomains = $TrustedDomains | Select-Object -Unique

            Foreach ($TrustedDomain in $TrustedDomains) {
                If (!(Test-Path $DomainStorePath)) {
                    Write-Output $TrustedDomain.Trim()
                    $TrustedDomain.Trim() | Add-Content -Path $DomainStorePath -Force
                    Get-AllADDomains -Domain $TrustedDomain -Depth $($Depth++)
                }
                ElseIf (!((Get-Content $DomainStorePath).Contains($TrustedDomain.Trim()))) {
                    Write-Output $TrustedDomain.Trim()
                    $TrustedDomain.Trim() | Add-Content -Path $DomainStorePath -Force
                    Get-AllADDomains -Domain $TrustedDomain -Depth $($Depth++)
                }
            }
        }
    }
}