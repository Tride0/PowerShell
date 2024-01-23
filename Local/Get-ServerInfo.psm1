Function Get-ServerInfo {
    Param(

        [String[]]$ComputerName = $ENV:computername,
        [Boolean]$PassThru = $True,
        [Boolean]$Export = $False,
        [String]$ExportPath = "$env:USERPROFILE\desktop\ComputerInfo.csv"
    )
    $WMIObjects = @(
        'Win32_OPeratingSystem'
        'Win32_ComputerSystem'
        'Win32_NetworkAdapterConfiguration'
        'Win32_Processor'
        'win32_logicaldisk'
    )

    Foreach ($Computer in $ComputerName) {
        Write-Host $Computer 
        Remove-Variable ($WMIObjects + 'trustedfordelegation') -Force -ErrorAction SilentlyContinue

        :Wmi Foreach ($WMIObject in $WMIObjects) {
            Try {
                New-Variable `
                    -Name $WMIObject `
                    -Value (Get-WmiObject $WMIObject -ComputerName $Computer -ErrorAction Stop)
            }
            Catch {
                Break WMI
            }
        }

        $TrustedForDelegation = Get-ADComputer $Computer -Properties TrustedForDelegation | Select-Object -ExpandProperty TrustedForDelegation
    
        [Array]$Win32_NetworkAdapterConfiguration = ($Win32_NetworkAdapterConfiguration | Where-Object -FilterScript { $_.ipaddress })
    
        $Information = [PSCustomObject]@{
            Domain                    = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain().Name
            Computer                  = $Computer
        
            Manufacturer              = $Win32_ComputerSystem.Manufacturer
            Model                     = $Win32_ComputerSystem.Model
        
            'OS'                      = $Win32_OPeratingSystem.Caption
            'OS Version'              = $Win32_OPeratingSystem.Version
        
            'Usable Memory'           = "$([Math]::Round($Win32_OPeratingSystem.TotalVisibleMemorySize/1MB,2)) GB"
        
            Storage                   = "$([Math]::Round((($Win32_LogicalDisk | Where-Object -FilterScript {$_.DriveType -eq 3}).Size | Measure-Object -Sum).Sum/1GB,2)) GB"
        
            'Number of CPU Sockets'   = $Win32_ComputerSystem.NumberOfProcessors
            'Number of Logical Cores' = $Win32_ComputerSystem.NumberOfLogicalProcessors
            'CPU Max Speed'           = $Win32_Processor.MaxClockSpeed -join ', '
        
            'Trusted for Delegation'  = $TrustedForDelegation
        
            'IP Addresses'            = $Win32_NetworkAdapterConfiguration.IPAddress -join ', '
            'Subnet Mask'             = $Win32_NetworkAdapterConfiguration.IPSubnet -join ', '
        } 
        
        If ($PassThru) {
            $Information
        }
        If ($Export) {
            $Information | Export-Csv $ExportPath -NoTypeInformation -Append -Force
        }

    }
    if ($Export) { & $ExportPath }
}