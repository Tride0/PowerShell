
<#
    .NOTES
        Created By: Kyle Hewitt
        Created On: 3/18/2020
        Last Edit: 3/18/2020
        Version: 1.0.0

    .DESCRIPTION
        Script to tell me if a DHCP scope is set to have different settings than the server settings.
#>

Import-Module -Name dhcpserver -ErrorAction Stop

$ProperDNS_IPs = @'

'@.Split("`n", [System.StringSplitOptions]::RemoveEmptyEntries).Trim()

$ExportPath = "$PSScriptRoot\BAd_DNS_Settings_$(Get-Date -Format yyyyMMdd).csv"

$DHCPServers = Get-DhcpServerInDC

$ExportData = @()
:DHCPServers Foreach ($DHCPServer in $DHCPServers.DnsName) {
    Write-Host $DHCPServer -fore Cyan 

    # Select IP Addresses to Compare the Scopes to
    If ([Boolean]$ProperDNS_IPs) {
        $ProperIPs = $ProperDNS_IPs
    }
    Else {
        $ServerDNS = Get-DhcpServerv4OptionValue –ComputerName $DHCPServer -OptionId 6 -ErrorAction SilentlyContinue
        $ProperIPs = $ServerDNS.Value
    }
    If (![Boolean]$ProperIPs) {
        Write-Host 'No IPs to Compare Scopes Settings to. Provide IPs or Check DHCP Server has DNS Settings configured.' -ForegroundColor Red
        Continue DHCPServers
    }


    # Get Scopes
    Try {
        Write-Host Getting Scopes -fore Cyan
        $Scopes = Get-DhcpServerv4Scope –ComputerName $DHCPServer -ErrorAction Stop
    }
    Catch {
        Write-Host "Failed to get Scopes from $DHCPServer. Error: $_" -ForegroundColor Red
        Continue DHCPServers
    }


    :Scopes Foreach ($Scope in $Scopes) {
        Write-Host $Scope.ScopeId.IPAddressToString -fore Cyan
        $ScopeDNS = Get-DhcpServerv4OptionValue –ComputerName $DHCPServer -ScopeId $Scope.ScopeId.IPAddressToString -OptionId 6 -ErrorAction SilentlyContinue

        If (![Boolean]$ScopeDNS) { Continue Scopes }

        [Array]$ScopeDNS.Value | ForEach-Object -Process {
            If ($ProperIPs -notcontains $_) {
                $Data = [PSCustomObject]@{
                    DHCPServer    = $DHCPServer
                    ScopeName     = $Scope.name
                    ScopeIP       = $Scope.ScopeId.IPAddressToString
                    WrongDNS_IP   = $_
                    WrongDNS_Name = "$([System.Net.Dns]::Resolve($_).HostName)"
                }
                $Data | Format-Table -AutoSize
                $ExportData += $Data
            }
        }
        Remove-Variable ScopeDNS -ErrorAction SilentlyContinue
    }
}
$ExportData | Export-Csv $ExportPath -NoTypeInformation -Force