Function Delete-RegistryValue {
    <#
        .NOTES
            Created By: Kyle Hewitt
            Created On: 5/22/2020
            Version: 2020.05.22

        .DESCRIPTION
            Removes Registry Key Values
    #>
    Param(
        [String[]]$ComputerName = $env:COMPUTERNAME,
        [String]$Key,
        [String]$BaseKey = 'CurrentUser', # ([Microsoft.Win32.Registry].GetFields().Name)
        [String]$SubKey,
        [String]$ValueName
    )
    Begin {
        If ([Boolean]$Key) {
            $KeySplit = $key.TrimStart('\').TrimStart('/').Split('\').Split('/')
            $BaseKey = $KeySplit[0]
            $SubKey = $KeySplit[1..$($KeySplit.Count - 1)] -join '/'
            Remove-Variable KeySplit -ErrorAction SilentlyContinue
        }
        If ($BaseKey -like 'HKEY*') {
            $BaseKeySplit = $BaseKey.Split('_')
            $BaseKey = $BaseKeySplit[1..$($BaseKeySplit.Count - 1)] -join ''
            Remove-Variable BaseKeySplit -ErrorAction SilentlyContinue
        }
    }
    Process {
        :ComputerName Foreach ($Computer in $Computername) {
            Try {
                $Key = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($BaseKey, $Computer).OpenSubKey($SubKey, $True)
            }
            Catch {
                Write-Error "Failed to Open '$($Key.Name)'.`nError: $_ "
            }
            Try {
                $Key.DeleteValue($ValueName)
            }
            Catch {
                Write-Error "Failed to Delete '$($Key.Name)'.`nError: $_ "
            }
            
        }
    }
}