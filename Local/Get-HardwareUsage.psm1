Function Get-HardwareUsage {
    Param(
        [String[]]$ComputerName = $env:COMPUTERNAME
    )

    Foreach ($Computer in $ComputerName) {
        [PSCustomObject]@{
            Computer         = $Computer
            'CPU_Usage_%'    = (Get-WmiObject -ComputerName $Computer -Class Cim_Processor | 
                    Measure-Object -Property LoadPercentage -Average | 
                    Select-Object -ExpandProperty Average)
            'Memory_Usage_%' = (Get-WmiObject -ComputerName $Computer -Class CIM_OperatingSystem | 
                    Select-Object -Property @{Name = 'Percentage'; Expression = { [math]::Round(($_.FreePhysicalMemory / $_.TotalVisibleMemorySize) * 100, 2) } } | 
                    Select-Object -ExpandProperty Percentage)
            'Disk_Usage_%'   = ((Get-WmiObject -ComputerName $Computer -Class CIM_LogicalDisk | 
                        Where-Object -FilterScript { $_.DriveType -eq 3 } | 
                        ForEach-Object -Process {
                            "$($_.DeviceID)$([math]::Round((($_.Size-$_.FreeSpace)/$_.Size)*100,2))"
                        }) -join ' ; ')
        }
    }
}