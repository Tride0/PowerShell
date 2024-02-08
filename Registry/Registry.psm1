Function Get-RegKeys {
    [CmdletBinding()]
    Param(
        [parameter(Mandatory = $true)]
        [ValidateSet('HKCR', 'HKCU', 'HKLM', 'HKUS', 'HKCC')]
        [string]$Hive,

        [parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Key,

        [parameter(ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true)]
        [string]$ComputerName = "$env:ComputerName",

        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]$Credential = [System.Management.Automation.PSCredential]::Empty
    )
    Begin {
        $reg = Get-WmiObject -List 'StdRegProv' -ComputerName $ComputerName -Credential $Credential
    }
    Process {
        $reg_hive = switch ($hive) {
            'HKCR' { 2147483648 }
            'HKCU' { 2147483649 }
            'HKLM' { 2147483650 }
            'HKUS' { 2147483651 }
            'HKCC' { 2147483653 }
        }

        $data = $reg.EnumKey($reg_hive, $key)
        if ($data.ReturnValue -eq 0) {
            $KeyNum = ($data.sNames).Length
            if ($KeyNum -gt 0) {
                foreach ($KeyName in $data.sNames) {
                    [PSObject]@{
                        Key      = $KeyName
                        FullPath = "$hive\$key\$KeyName"
                    }
                }
            }
            else {
                Write-Verbose "Key $key does not have any keys to enumerate"
            }
        }
        elseif ($data.ReturnValue -eq 2) {
            Write-Error "Key $key does not exist"
        }
        else {
            Write-Error "Error when enumerating keys: $($data.ReturnValue)"
        }
    }
}

Function New-RegKey {
    [CmdletBinding()]
    Param(
        [parameter(Mandatory = $true)]
        [ValidateSet('HKCR', 'HKCU', 'HKLM', 'HKUS', 'HKCC')]
        [string]$Hive,

        [parameter(Mandatory = $true)]
        [string]$Key,

        [parameter(ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true)]
        [string]$ComputerName = "$env:ComputerName",

        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]$Credential = [System.Management.Automation.PSCredential]::Empty
    )
    Begin {
        $reg = Get-WmiObject -List 'StdRegProv' -ComputerName $ComputerName -Credential $Credential
    }
    Process {
        $reg_hive = switch ($hive) {
            'HKCR' { 2147483648 }
            'HKCU' { 2147483649 }
            'HKLM' { 2147483650 }
            'HKUS' { 2147483651 }
            'HKCC' { 2147483653 }
        }

        $data = $reg.CreateKey($reg_hive, $key)
        Switch ($data.ReturnValue) {
            0 { Write-Verbose "Key $hive\$key was created." }
            2 { Write-Error "Key $key does not exist" }
            Default { Write-Error "Error when creating key: $($data.ReturnValue)" }
        }
    }
}

Function Remove-RegKey {
    [CmdletBinding()]
    Param(
        [parameter(Mandatory = $true)]
        [ValidateSet('HKCR', 'HKCU', 'HKLM', 'HKUS', 'HKCC')]
        [string]$Hive,

        [parameter(Mandatory = $true)]
        [string]$Key,

        [parameter(ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true)]
        [string]$ComputerName = "$env:ComputerName",

        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]$Credential = [System.Management.Automation.PSCredential]::Empty
    )
    Begin {
        $reg = Get-WmiObject -List 'StdRegProv' -ComputerName $ComputerName -Credential $Credential
    }
    Process {
        $reg_hive = switch ($hive) {
            'HKCR' { 2147483648 }
            'HKCU' { 2147483649 }
            'HKLM' { 2147483650 }
            'HKUS' { 2147483651 }
            'HKCC' { 2147483653 }
        }

        $data = $reg.DeleteKey($reg_hive, $key)

        Switch ($Data.ReturnValue) {
            o { Write-Verbose "Key $hive\$key was removed." }
            2 { Write-Error "Key $key does not exist" }
            Default { Write-Error "Error when removing key: $($data.ReturnValue)" }
        }
    }
}

Function Get-RegValues {
    [CmdletBinding()]
    Param(
        [parameter(Mandatory = $true)]
        [ValidateSet('HKCR', 'HKCU', 'HKLM', 'HKUS', 'HKCC')]
        [string]$Hive,

        [parameter(Mandatory = $true)]
        [string]$Key,

        [parameter(ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true)]
        [string]$ComputerName = "$env:ComputerName",

        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]$Credential = [System.Management.Automation.PSCredential]::Empty
    )
    Begin {
        $reg = Get-WmiObject -List 'StdRegProv' -ComputerName $ComputerName -Credential $Credential
    }
    Process {
        $reg_hive = switch ($hive) {
            'HKCR' { 2147483648 }
            'HKCU' { 2147483649 }
            'HKLM' { 2147483650 }
            'HKUS' { 2147483651 }
            'HKCC' { 2147483653 }
        }

        $reg_types = @{
            '1'  = 'REG_SZ'
            '2'  = 'REG_EXPAND_SZ'
            '3'  = 'REG_BINARY'
            '4'  = 'REG_DWORD'
            '7'  = 'REG_MULTI_SZ'
            '11' = 'REG_QWORD'
        }

        $data = $reg.EnumValues($reg_hive, $key)
        if ($data.ReturnValue -eq 0) {
            $KeyNum = ($data.sNames).Length
            if ($KeyNum -gt 0) {
                for ($i = 0; $i -le $KeyNum; $i++) {
                    [PSObject]@{
                        ValueName = "$($data.sNames[$i])"
                        Type      = $reg_types["$($data.types[$i])"]
                    }
                }
            }
            else {
                Write-Verbose "Key $key does not have any values to enumerate"
            }
        }
        elseif ($data.ReturnValue -eq 2) {
            Write-Error "Key $key does not exist"
        }
        else {
            Write-Error "Error when enumerating values: $($data.ReturnValue)"
        }
    }
}

Function Test-RegKeyAccess {
    [CmdletBinding()]
    Param(
        [parameter(Mandatory = $true)]
        [ValidateSet('HKCR', 'HKCU', 'HKLM', 'HKUS', 'HKCC')]
        [string]$Hive,

        [parameter(Mandatory = $true)]
        [string]
        [ValidateSet('KEY_QUERY_VALUE', 'KEY_CREATE_SUB_KEY', 'KEY_ENUMERATE_SUB_KEYS',
            'KEY_NOTIFY', 'KEY_CREATE', 'DELETE', 'READ_CONTROL', 'WRITE_DAC', 'WRITE_OWNER')]
        $AccessType,

        [parameter(Mandatory = $true)]
        [string]$Key,

        [parameter(ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true)]
        [string]$ComputerName = "$env:ComputerName",

        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]$Credential = [System.Management.Automation.PSCredential]::Empty
    )
    Begin {
        $reg = Get-WmiObject -List 'StdRegProv' -ComputerName $ComputerName -Credential $Credential
    }
    Process {
        $reg_hive = switch ($hive) {
            'HKCR' { 2147483648 }
            'HKCU' { 2147483649 }
            'HKLM' { 2147483650 }
            'HKUS' { 2147483651 }
            'HKCC' { 2147483653 }
        }

        $type2check = switch ($AccessType) {
            'KEY_QUERY_VALUE' { 1 }
            'KEY_SET_VALUE' { 2 }
            'KEY_CREATE_SUB_KEY' { 4 }
            'KEY_ENUMERATE_SUB_KEYS' { 8 }
            'KEY_NOTIFY' { 16 }
            'KEY_CREATE' { 32 }
            'DELETE' { 65536 }
            'READ_CONTROL' { 131072 }
            'WRITE_DAC' { 262144 }
            'WRITE_OWNER' { 524288 }
        }

        $data = $reg.CheckAccess($reg_hive, $key, $type2check)

        Switch ($data.ReturnValue) {
            0 { $data.bGranted }
            2 { Write-Error "Key $key does not exist" }
            Default { Write-Error "Error when Checking Access Type on key: $($data.ReturnValue)" }
        }
    }
}

Function Set-RegValue {
    [CmdletBinding()]
    Param
    (
        [parameter(Mandatory = $true)]
        [ValidateSet('HKCR', 'HKCU', 'HKLM', 'HKUS', 'HKCC')]
        [string]$Hive,

        [parameter(Mandatory = $true)]
        [ValidateSet('DWORD', 'EXPANDSZ', 'MULTISZ', 'QWORD', 'SZ', 'BINARY')]
        [string]$Type,

        [parameter(Mandatory = $true)]
        [string]$Key,

        [parameter(Mandatory = $true)]
        [string]$Name,

        [parameter(Mandatory = $true)]
        $Data,

        [parameter(ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true)]
        [string]$ComputerName = "$env:ComputerName",

        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]$Credential = [System.Management.Automation.PSCredential]::Empty
    )
    Begin {
        $reg = Get-WmiObject -List 'StdRegProv' -ComputerName $ComputerName -Credential $Credential

    }
    Process {
        $reg_hive = switch ($hive) {
            'HKCR' { 2147483648 }
            'HKCU' { 2147483649 }
            'HKLM' { 2147483650 }
            'HKUS' { 2147483651 }
            'HKCC' { 2147483653 }
        }

        # Set according to type
        $data = switch ($type) {
            'DWORD' { ($reg.SetDwordValue($reg_hive, $key, $Name, $Data)) }
            'EXPANDSZ' { ($reg.SetExpandedStringValue($reg_hive, $key, $Name, $Data)) }
            'MULTISZ' { ($reg.SetMultiStringValue($reg_hive, $key, $Name, $Data)) }
            'QWORD' { ($reg.SetQwordValue($reg_hive, $key, $Name, $Data)) }
            'SZ' { ($reg.SetStringValue($reg_hive, $key, $Name, $Data)) }
            'BINARY' { ($reg.SetBinaryValue($reg_hive, $key, $Name, $Data)) }
        }

        Switch ($data.ReturnValue) {
            0 { Write-Verbose "Value set on $hive\$key\$name of type $type" }
            2 { Write-Error "Key $key does not exist" }
            Default { Write-Error "Error when setting value on key: $($data.ReturnValue)" }
        }
    }
}

Function Get-RegValue {
    [CmdletBinding()]
    [OutputType([int])]
    Param(
        [parameter(Mandatory = $true)]
        [ValidateSet('HKCR', 'HKCU', 'HKLM', 'HKUS', 'HKCC')]
        [string]$Hive,

        [parameter(Mandatory = $true)]
        [string]$Key,

        [parameter(Mandatory = $true)]
        [string]$Name,

        [parameter(ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true)]
        [string]$ComputerName = "$env:ComputerName",

        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]$Credential = [System.Management.Automation.PSCredential]::Empty
    )

    Begin {
        $reg = Get-WmiObject -List 'StdRegProv' -ComputerName $ComputerName -Credential $Credential
    }
    Process {
        $reg_hive = switch ($hive) {
            'HKCR' { 2147483648 }
            'HKCU' { 2147483649 }
            'HKLM' { 2147483650 }
            'HKUS' { 2147483651 }
            'HKCC' { 2147483653 }
        }

        $ValData = $reg.EnumValues($reg_hive, $key)
        if ($ValData.ReturnValue -eq 0) {
            # check that the value actually exists
            if ($ValData.sNames -contains $Name) {
                # Get value index in the array
                $index = (0..($ValData.sNames.Count - 1) | Where-Object { $ValData.sNames[$_] -eq $Name })
                $type = $ValData.types[$index]
                # Get according to type
                $data = switch ($type) {
                    '4' { ($reg.GetDwordValue($reg_hive, $key, $Name)).uValue }
                    '2' { ($reg.GetExpandedStringValue($reg_hive, $key, $Name)).sValue }
                    '7' { ($reg.GetMultiStringValue($reg_hive, $key, $Name)).sValue }
                    '11' { ($reg.GetQwordValue($reg_hive, $key, $Name)).uValue }
                    '1' { ($reg.GetStringValue($reg_hive, $key, $Name)).sValue }
                    '3' { ($reg.GetBinaryValue($reg_hive, $key, $Name)).uValue }
                }
                $data
            }
            else {
                Write-Error "Value $name does not exist in key specified."
            }
        }
        elseif ($ValData.ReturnValue -eq 2) {
            Write-Error "Key $key does not exist"
        }
        else {
            Write-Error "Error when retrieving value on key: $($data.ReturnValue)"
        }
    }
}

Function Remove-RegValue {
    [CmdletBinding()]
    [OutputType([int])]
    Param(
        [parameter(Mandatory = $true)]
        [ValidateSet('HKCR', 'HKCU', 'HKLM', 'HKUS', 'HKCC')]
        [string]$Hive,

        [parameter(Mandatory = $true)]
        [string]$Key,

        [parameter(Mandatory = $true)]
        [string]$Name,

        [parameter(ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true)]
        [string]$ComputerName = "$env:ComputerName",

        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]$Credential = [System.Management.Automation.PSCredential]::Empty
    )
    Begin {
        $reg = Get-WmiObject -List 'StdRegProv' -ComputerName $ComputerName -Credential $Credential
    }
    Process {
        $reg_hive = switch ($hive) {
            'HKCR' { 2147483648 }
            'HKCU' { 2147483649 }
            'HKLM' { 2147483650 }
            'HKUS' { 2147483651 }
            'HKCC' { 2147483653 }
        }

        $ValData = $reg.EnumValues($reg_hive, $key)
        if ($ValData.ReturnValue -eq 0) {
            if ($ValData.sNames -contains $Name) {
                $data = $reg.DeleteValue($reg_hive, $Key, $Name)
                switch ($data.ReturnValue) {
                    '0' { Write-Verbose "Value $name has been removed." }
                    default { Write-Error "Error while removing value $name $($data.ReturnValue)" }
                }
            }
            else {
                Write-Error "Value $name does not exist in key specified."
            }
        }
        elseif ($ValData.ReturnValue -eq 2) {
            Write-Error "Key $key does not exist"
        }
        else {
            Write-Error "Error when removing value on key: $($data.ReturnValue)"
        }
    }
}

Function Get-RegKeySecurityDescriptor {
    [CmdletBinding()]
    Param(
        [parameter(Mandatory = $true)]
        [ValidateSet('HKCR', 'HKCU', 'HKLM', 'HKUS', 'HKCC')]
        [string]$Hive,

        [parameter(Mandatory = $true)]
        [string]$Key,

        [parameter(ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true)]
        [string]$ComputerName = "$env:ComputerName",

        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]$Credential = [System.Management.Automation.PSCredential]::Empty
    )
    Begin {
        $reg = Get-WmiObject -List 'StdRegProv' -ComputerName $ComputerName -Credential $Credential
        $AccessMask = @{
            '1'      = 'Query Value'
            '2'      = 'Set Value.'
            '4'      = 'Create SubKey'
            '8'      = 'Enumerate SubKeys'
            '16'     = 'Notify'
            '32'     = 'Create Key'
            '65536'  = 'Delete Key'
            '131072' = 'Read Control'
            '262144' = 'Write DAC'
            '524288' = 'Write Owner'
            '983103' = 'All Access'
            '131097' = 'Read Access'
        }
    }
    Process {
        $reg_hive = switch ($hive) {
            'HKCR' { 2147483648 }
            'HKCU' { 2147483649 }
            'HKLM' { 2147483650 }
            'HKUS' { 2147483651 }
            'HKCC' { 2147483653 }
        }

        $data = $reg.GetSecurityDescriptor($reg_hive, $key)
        if ($data.ReturnValue -eq 0) {
            [PSObject]@{
                Trustee    = "$($Data.Descriptor.Owner.Domain)\$($Data.Descriptor.Owner.Name)"
                Permission = 'Owner'
            }
            $data.Descriptor.dACL | ForEach-Object {
                Write-Verbose "Access mask for $($_.Trustee.Domain)\$($_.Trustee.Name) is $($_.AccessMask)"
                [PSObject]@{
                    Trustee    = "$($_.Trustee.Domain)\$($_.Trustee.Name)"
                    Permission = "$($AccessMask[[string]$_.AccessMask])"
                }
            }
        }
        elseif ($data.ReturnValue -eq 2) {
            Write-Error "Key $key does not exist"
        }
        else {
            Write-Error "Error when creating key: $($data.ReturnValue)"
        }
    }
}