Function Get-RegValue {
    <#
        .NOTES
            Created By: Kyle Hewitt
            Created On: 5/04/20

        .DESCRIPTION
            Simple function to get a registry value
    #>
    Param(
        $Computer = $env:COMPUTERNAME,
        $BaseKey = 'LocalMachine',
        $SubKey,
        $ValueName
    )
    Return [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($BaseKey, $Computer).OpenSubKey($SubKey).GetValue($ValueName)
}