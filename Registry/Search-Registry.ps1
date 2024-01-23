Function Search-Registry {
    <#
        .NOTES
            Created By: Kyle Hewitt
            Created On: 05-21-2020
            Version: 2020.05.21

        .DESCRIPTION
            Will Search for a String in the registry at the specified location
    #>
    Param(
        [String[]]$ComputerName = $ENV:ComputerName,
        [String]$BaseKey = 'LocalMachine', # ([Microsoft.Win32.Registry].GetFields().Name)
        [String]$Subkey, # System\CurrentControlSet\Control
        [String]$SearchString, 
        [Switch]$SearchValues,
        [Switch]$Recurse
    )
    Foreach ($Computer in $ComputerName) {
        If ($Subkey) {
            $Key = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($BaseKey, $Computer).OpenSubKey($SubKey)
        }
        Else {
            $Key = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($BaseKey, $Computer)
        }

        # Search Value Names
        [String[]]$ValueNames = $Key.GetValueNames()
        If ([Boolean]$ValueNames) {
            Foreach ($Name in $ValueNames) {
                If ($Name -like "*$SearchString*") {
                    Write-Output "$($Key.Name) $Name"
                }

                # Search Values
                If ($SearchValues) {
                    $value = $Key.GetValue($Name)
                    If ($Value -like "*$SearchString*") {
                        Write-Output "$($Key.Name) $Name $Value"
                    }
                }
            }
        }

        [String[]]$SubKeys = $Key.GetSubKeyNames()
        If ([Boolean]$SubKeys) {
            # Search Sub Keys
            Foreach ($SubKey in $Subkeys) {
                If ($SubKey -like "*$SearchString*") {
                    Write-Output "$($Key.Name)\$SubKey"
                }

                # Search Sub-Sub Keys/ValueNames/Values
                If ($Recurse) {
                    Search-Registry -Computer $Computer -BaseKey $BaseKey -Subkey "$Subkey\$Sub" -Recurse:$Recurse -SearchValues:$SearchValues -SearchString $SearchString
                }
            }
        }
    }
}