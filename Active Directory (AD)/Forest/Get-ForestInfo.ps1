<#
    Created By: Kyle Hewitt
    Created On: 06/25/2019
    Version: 2019.06.26

    Purpose: This script is to retrieve information about a forest and all of it's domains.
#>

$Date = Get-Date -Format yyyyMMdd

$ExportRoot = "$ENV:userprofile\Desktop\DomainCheck_$Date".Replace(':', '$')

#region Setup

$Global:MailBody = $()

$Forest = [DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest()

If ($ExportRoot -notlike '\\*') {
    $ExportRoot = "\\$ENV:ComputerName\$($ExportRoot.Replace(':','$'))"
}
[Void] (New-Item -Path $ExportRoot -ItemType Directory -Force)

(Get-Item $ExportRoot).Attributes = 'Hidden'

#endregion Setup



#region Functions

Function SendOut {
    Param(
        $Info,
        $Title, 
        $FileType = 'csv'
    )
    $Path = "$ExportRoot\$Domain`_$Title`_$Date.$FileType"
    If ($FileType -eq 'csv') {
        $Info | Export-Csv -Path $Path -NoTypeInformation -Force
    }
    Else {
        Set-Content -Value $Info -Path $Path -Force
    }
}

Function Get-RegValue ($Computer, $BaseKey = 'LocalMachine', $Key, $Value) {
    Return (([Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($BaseKey, $Computer)).OpenSubKey($Key)).GetValue($Value)
}

#endregion Functions


:Domains Foreach ($Domain in $Forest.Domains) {
    Write-Host Domain: $Domain

    #Dit Location and Size
    $DitLocation = Get-RegValue -Computer $Domain.PdcRoleOwner.IPAddress -Key 'SYSTEM\\CurrentControlSet\\Services\\NTDS\\Parameters' -Value 'DSA Database file'
    #$WorkingDir = Get-RegValue -Computer $Domain.PdcRoleOwner.IPAddress -Key 'SYSTEM\\CurrentControlSet\\Services\\NTDS\\Parameters' -Value 'DSA Working Directory'
    $DitSize = "$((Get-Item -Path "\\$($Domain.PdcRoleOwner.IPAddress)\$($DitLocation.Replace(':','$'))").Length/1GB) GB"

    $ADSearcher = New-Object -TypeName DirectoryServices.DirectorySearcher
    $ADSearcher.SearchRoot.Path = "LDAP://CN=Configuration,DC=$("$($Domain.Name)".Split('.') -join ',DC=')"
    $ADSearcher.Filter = "(distinguishedname=CN=Directory Service,CN=Windows NT,CN=Services,CN=Configuration,DC=$("$($Domain.Name)".Split('.') -join ',DC='))"
    $DSCN = $ADSearcher.FindOne().Properties
    
    Write-Host [$(Get-Date)] Getting Domain Info

    SendOut -Title DomainInfo -Info $(
        New-Object -TypeName PSObject -Property @{
            Forest                       = $Forest.Name
            Domain                       = $Domain.Name
            DomainMode                   = $Domain.DomainMode
            DomainControllerCount        = $Domain.DomainControllers.Count
            DitSize                      = $DitSize
            tombstonelifetime            = $($DSCN.tombstonelifetime)
            'msds-deletedobjectlifetime' = $($DSCN.'msds-deletedobjectlifetime')
            dsheuristics                 = $($DSCN.dsheuristics)
        } | Select-Object -Property Forest, Domain, DomainMode, DomainControllerCount, DitSize, tombstonelifetime, msds-deletedobjectlifetime, dsheuristics
    )

    Write-Host [$(Get-Date)] Getting Info on Trusts

    SendOut -Title Trusts -Info @(
        $Domain.GetAllTrustRelationships()
    )

    Write-Host [$(Get-Date)] Getting Info on SiteLinks

    SendOut -Title SiteLinks -Info @(
        $Forest.Sites | Select-Object -ExpandProperty SiteLinks | 
            Select-Object -Property Name, @{name = 'Sites'; Expression = { $_.Sites -join ', ' } }, Cost, ReplicationInterval, NotificationEnabled, DataCompressionEnabled
    )

    Write-Host [$(Get-Date)] Getting Info on Sites

    SendOut -Title Sites -FileType txt -Info @(
        $Forest.Sites | Select-Object -ExpandProperty Name
    )
    
    Write-Host [$(Get-Date)] Getting Domain Controller Info

    $WMISearcher = New-Object -TypeName System.Management.ManagementObjectSearcher
    SendOut -Title DomainControllers -Info $(
        Foreach ($DC in $Domain.DomainControllers) {
            $WMISearcher.Scope = "\\$($DC.Name)\root\cimv2"

            $WMISearcher.Query = 'SELECT * FROM WIN32_ComputerSystem'
            $ComputerSystem = $WMISearcher.Get()
            
            $WMISearcher.Query = 'SELECT * FROM WIN32_PROCESSOR'
            $PROCESSOR = $WMISearcher.Get()

            $WMISearcher.Query = 'SELECT * FROM Win32_LogicalDisk'
            $LogicalDisk = $WMISearcher.Get()

            $RAM = [Math]::Round(($ComputerSystem | Select-Object -ExpandProperty TotalPhysicalMemory) / 1gb, 0)
            $LogicalProcessors = $ComputerSystem | Select-Object -ExpandProperty NumberOfLogicalProcessors
            $CPUSpeed = ($PROCESSOR | Select-Object -ExpandProperty CurrentClockSpeed) -join ', '
            $Storage = ($LogicalDisk | ForEach-Object -Process { 
                    If ($_.DriveType -eq 3) { 
                        "$($_.DeviceID) $([Math]::Round($_.FreeSpace/1gb,2)) GB / $([Math]::Round($_.Size/1gb,2)) GB" 
                    }
                }) -join ', '

            New-Object -TypeName PSObject -Property @{
                Name              = $DC.name
                OS                = $DC.OSVersion
                RAM               = $RAM
                LogicalProcessors = $LogicalProcessors
                CPUSpeed          = $CPUSpeed
                Storage           = $Storage
                DitSize           = "$((Get-Item -Path "\\$($DC.Name)\$($(Get-RegValue -Computer $($DC.Name) -Key 'SYSTEM\\CurrentControlSet\\Services\\NTDS\\Parameters' -Value 'DSA Database file').Replace(':','$'))").Length/1GB) GB"
            } | Select-Object -Property Name, OS, RAM, LogicalProcessors, CPUSpeed, Storage, DitSize

            Remove-Variable LogicalDisk, ComputerSystem, PROCESSOR, RAM, NumberOfCPUCores, CPUSpeed, Storage -ErrorAction SilentlyContinue
        }
    )

    $ADSearcher = New-Object DirectoryServices.DirectorySearcher
    $ADSearcher.SearchRoot = "LDAP://DC=$("$($Domain.Name)".Split('.') -join ',DC=')"
    $ADSearcher.Tombstone = $True
    $ADSearcher.PageSize = 300
    [Void] $ADSearcher.PropertiesToLoad.Add('name')
    [Void] $ADSearcher.PropertiesToLoad.Add('useraccountcontrol')
    [Void] $ADSearcher.PropertiesToLoad.Add('objectclass')
    [Void] $ADSearcher.PropertiesToLoad.Add('isdeleted')
    [Void] $ADSearcher.PropertiesToLoad.Add('isrecycled')
    
    Write-Host [$(Get-Date)] Counting Objects

    SendOut -Title ObjectCounts -Info $(
        $($ADSearcher.FindAll() | ForEach-Object -Process { $_.Properties } | 
                Select-Object -Property @{ n = 'name'; e = { $_.name } }, 
                @{ n = 'objectclass'; e = { $_.objectclass -join ',' } },
                @{ n = 'Disabled'; e = { ([Convert]::ToString($_.useraccountcontrol[0], 2)[-2] -eq '1') } },
                @{ n = 'deleted'; e = { $_.isdeleted } },
                @{ n = 'recycled'; e = { $_.isrecycled } } |
                Group-Object -Property objectclass | 
                ForEach-Object -Process {
                    New-Object -TypeName PSObject -Property @{
                        Class    = $_.Name
                        Count    = $_.Count
                        Disabled = ($_.Group | Group-Object -Property Disabled | Where-Object -FilterScript { $_.Name -eq 'True' }).Count
                        Deleted  = ($_.Group | Group-Object -Property deleted | Where-Object -FilterScript { $_.Name -eq 'True' }).Count
                        Recycled = ($_.Group | Group-Object -Property recycled | Where-Object -FilterScript { $_.Name -eq 'True' }).Count
                    }
                } | 
                Select-Object -Property Class, Count, Disabled, Deleted, Recycled)
    )
}

New-Item -Path "$ExportRoot.zip" -ItemType File -Force
$ZipFile = (New-Object -ComObject shell.application).NameSpace("$ExportRoot.zip") 
Get-ChildItem -Path $ExportRoot -Force | ForEach-Object { $ZipFile.CopyHere($_.fullname); Start-Sleep -Seconds 2 }

Remove-Item -Path $ExportRoot -Force -Recurse
