Function Delete-RegistryKey {
    <#
        .NOTES
            Created By: Kyle Hewitt
            Created On: 5/22/2020
            Version: 2020.05.22

        .DESCRIPTION
            Remove Registry Keys
    #>
    Param(
        [String[]]$ComputerName = $env:COMPUTERNAME,
        [String]$Key,
        [String]$BaseKey = 'CurrentUser', # ([Microsoft.Win32.Registry].GetFields().Name)
        [String]$SubKey
    )
    Begin {
        If ([Boolean]$Key) {
            $KeySplit = $key.TrimStart('\').TrimStart('/').Split('\').Split('/')
            $BaseKey = $KeySplit[0]
            $SubKey = $KeySplit[1..$($KeySplit.Count - 2)] -join '/'
            $DeleteKey = $KeySplit[-1]
            Remove-Variable KeySplit -ErrorAction SilentlyContinue
        }
        Else {
            $KeySplit = $key.TrimStart('\').TrimStart('/').Split('\').Split('/')
            $SubKey = $KeySplit[0..$($KeySplit.Count - 2)] -join '/'
            $DeleteKey = $KeySplit[-1]
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
                $Key.DeleteSubkeyTree($DeleteKey)
            }
            Catch {
                Write-Error "Failed to Delete '$($Key.Name)\$($DeleteKey)'.`nError: $_ "
            }
            
        }
    }
}