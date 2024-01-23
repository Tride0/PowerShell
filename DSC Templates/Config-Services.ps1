[String[]]$Computers = @'

'@.Split("`n", [System.StringSplitOptions]::RemoveEmptyEntries).Trim() -ne ''

[String[]]$FullGoServices = @'

'@.Split("`n", [System.StringSplitOptions]::RemoveEmptyEntries).Trim() -ne ''

[String[]]$FullStopServices = @'

'@.Split("`n", [System.StringSplitOptions]::RemoveEmptyEntries).Trim() -ne ''

configuration Config-Services {
    Param(
        [String[]]$ComputerName,
        [String[]]$FullStopServices,
        [String[]]$FullGoServices
    )
    node $ComputerName
    {
        Foreach ($Service in $FullStopServices) {
            Service "$Service`_FullStop" {
                Name        = $Service
                State       = 'Stopped'
                StartupType = 'Disabled'
                
            }
        }

        Foreach ($Service in $FullGoServices) {
            Service "$Service`_FullGo" {
                Name        = $Service
                State       = 'Running'
                StartupType = 'Automatic'
            }
        }
    }
}

Config-Services -ComputerName $Computers -FullStopServices $FullStopServices -FullGoServices $FullGoServices

Start-DscConfiguration -Path .\Config-Services -ComputerName $Computers -Verbose -Wait -Force
