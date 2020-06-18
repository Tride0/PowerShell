<#
    Edits: 
    Kyle Hewitt - 10/17/2018
        Added LastLogonDate filter to Get-ADComputer(s)
        Moved Where-Object Filter of OperatingSystem into Get-ADComputer(s) Filter - should increase speed
        Moved Log Paths, Filters, DataProperties, & ExportDataProperties to Variables - for manage-ability
        Moved Export outside of Foreach - for increased speed
        Added the creation of the log directories - incase a folder is missing in the path
        Removed Searchbase from Get-ADComputer(s) - they're un-ncessary
        Changed Date Format of Log Files - for better Sorting
#>

# Logs
$LogPath = "$PSScriptRoot\Stale_Computers"
$DisableLogPath = "$LogPath\Disabled\StaleComputers_Disable_Report_$(Get-Date -Format yyyy-MM-dd).csv"
$DeleteLogPath = "$LogPath\Deleted\StaleComputers_Delete_Report_$(Get-Date -Format yyyy-MM-dd).csv"

# Dates
$90Days = [DateTime]::Now.AddDays(-90)
$120Days = [DateTime]::Now.AddDays(-120)

# Filters
$DisableFilter = { (Enabled -eq $true) -and (PasswordLastSet -lt $90Days) -and (LastLogonDate -lt $90Days) -and 
    (WhenCreated -lt $90Days) -and (WhenChanged -lt $90Days) -and
    (OperatingSystem -like 'Windows*') -and (OperatingSystem -notlike '*Server*') -and (OperatingSystem -notlike 'Windows NT*') }

$DeleteFilter = { (Enabled -eq $false) -and (PasswordLastSet -lt $120Days) -and (LastLogonDate -lt $90Days) -and 
    (WhenCreated -lt $120Days) -and (WhenChanged -lt $120Days) -and
    (OperatingSystem -like 'Windows*') -and (OperatingSystem -notlike '*Server*') -and (OperatingSystem -notlike 'Windows NT*') }

# Properties
$DataProperties = 'OperatingSystem', 'LastLogonDate', 'WhenCreated', 'WhenChanged', 'PasswordLastSet'
$ExportDataProperties = 'Name', 'OperatingSystem', 'DistinguishedName', 'PasswordLastSet', 'LastLogonDate', 'WhenCreated', 'WhenChanged'

# Begin Script
ForEach ($Task in 'Disable', 'Delete') {
    # Gets Values for task being performed
    $Filter = "$((Get-Variable -Name $Task`Filter).Value)"
    $LogPath = "$((Get-Variable -Name $Task`LogPath).Value)"
    
    # Gets Computers to perform task on
    $Computers = Get-ADComputer -Filter $Filter -Properties $DataProperties
    
    # Performs Task
    Switch ($Task) {
        'Disable' { Set-ADComputer -Identity $Computer -Enabled $False -Add @{ Description = "Disabled by Clean-StaleComputers script on $(Get-Date)." } -confirm:$False }
        'Delete' { Remove-ADComputer -Identity $Computer -confirm:$False }
    }
    
    # Exports Computers that a task was performed on
    [Void] (New-Item -Path (Split-Path $LogPath -Parent) -ItemType Directory -Force)
    $Computers | Select-Object -Property $ExportDataProperties | Export-Csv -Path $LogPath -NoTypeInformation -Force
}
