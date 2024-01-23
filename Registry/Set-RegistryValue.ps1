Function Set-RegistryValue {
    <#
        .NOTES
            Created By: Kyle Hewitt
            Created On: 5/22/2020
            Version: 2020.05.22

        .DESCRIPTION
            Modifies the value of a Key's ValueName
    #>
    Param(
        [String[]]$ComputerName = $env:COMPUTERNAME,
        [String]$Key,
        [String]$BaseKey = 'CurrentUser', # ([Microsoft.Win32.Registry].GetFields().Name)
        [String]$SubKey,
        [String]$ValueName,
        $Value
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
            $Key = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($BaseKey, $Computer)

            # Create/Open Subkey Path
            If ([Boolean]$Subkey) {
                $SubKeySplit = $SubKey.TrimStart('\').TrimStart('/').Split('\').Split('/')
                for ($i = 0; $i -lt $SubKeySplit.Count; $i++) {
                    If ($Key.GetSubKeyNames() -notcontains $SubKeySplit[$i]) {
                        Try {
                            $key.CreateSubKey($SubKeySplit[$i])
                        }
                        Catch {
                            Write-Error "Failed to Create '$($Key.Name)\$($SubKeySplit[$i])'.`nError: $_ `nSkipping $Computer..."
                            Continue ComputerName
                        }
                        
                    }
                    $Key = $Key.OpenSubKey($SubKeySplit[$i], $True)
                }
                Remove-Variable SubKeySplit -ErrorAction SilentlyContinue
            }

            Try {
                $Key.SetValue($ValueName, $Value)
            }
            Catch {
                Write-Error "Failed to Create '$($Key.Name)\$($SubKeySplit[$i])'.`nError: $_ "
            }
            
        }
    }
}