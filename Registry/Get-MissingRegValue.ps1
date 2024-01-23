<#
    .NOTES
        Created By: Kyle Hewitt
        Created On: 5/04/2020
        Version: 2020.05.14
    
    .DESCRIPTION
        Check the registry key for a specific value and then output the machines that do not have that registry value
#>
[cmdletbinding()]
Param(
    [Parameter(ParameterSetname = 'Direct')]
    [String[]] $Computer = $env:COMPUTERNAME,
    [Parameter(ParameterSetname = 'Direct')]
    [String[]] $BaseKey = 'LocalMachine', # [Microsoft.Win32.Registry].GetFields().Name
    [Parameter(ParameterSetname = 'Direct')]
    [String[]] $SubKey,
    [Parameter(ParameterSetname = 'Direct')]
    [String[]] $ValueName,
    [Parameter(ParameterSetname = 'Direct')]
    [String[]] $ExpectedValue,
    [String] $CSVPath,
    [String] $ExportFolder = "$PSScriptRoot",
    [String] $ExportFileName = "Machines_Without_Reg_Value_$(Get-Date -Format yyyy-MM-dd-mmhhss).txt",
    [Switch] $Passthru
)
Begin {
    If ([Boolean]$CSVPath) {
        If (!(Test-Path -Path $CSVPath)) {
            [PSCustomObject]@{
                BaseKey = ([Microsoft.Win32.Registry].GetFields().Name -join ', ')
            } |
                Select-Object -Property 'Computers', 'BaseKey', 'SubKey', 'Valuename', 'Expectedvalue' |
                Export-Csv -Path $CSVPath -NoTypeInformation -Force
            & $CSVPath
            Return
        }
    }
    ElseIf (![Boolean]$CSVPath -and $BaseKey.count -ne $SubKey.Count -ne $ValueName.Count -ne $ExpectedValue.Count) {
        Write-Host "Missing required parameters. Use Computer ($($Computer.Count)), BaseKey ($($BaseKey.Count)), Subkey ($($SubKey.Count)), ValueName ($($ValueName.Count)) and ExpectedValue ($($ExpectedValue.Count))" -ForegroundColor Red
        Break
    }
    
    Write-Host "Folder: $ExportFolder"
    If (!(Test-Path -Path "$ExportFolder")) {
        Write-Verbose "Creating $ExportFolder"
        [Void] (New-Item -Path $ExportFolder -ItemType Directory -Force)
    }

    $Script:MachinesWithoutValue = @()

    Function Cycle {
        Param(
            [String[]] $Computers,
            [String] $BaseKey,
            [String] $SubKey,
            [String] $ValueName,
            [String] $ExpectedValue    
        )
        :ComputerForEach Foreach ($Machine in $Computers) {
            If ($Passthru) {
                Write-Host "[$(Get-Date)] $Machine" -ForegroundColor Magenta -NoNewline
            }

            $ErrorActionPreference = 'Stop'
            Try {
                $Value = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($BaseKey, $Machine).OpenSubKey($SubKey).GetValue($ValueName)
            }
            Catch {
                If ($Passthru) {
                    Write-Host " - Failed to get Registry Value. Error: $_" -ForegroundColor Red
                }
                $Script:MachinesWithoutValue += "$Machine - Failed to get Registry Value. Error: $_"
                Continue ComputerForEach
            }
            $ErrorActionPreference = 'Continue'

            If ($Value -ne $ExpectedValue -and [Boolean]$Value) {
                $Script:MachinesWithoutValue += "$Machine - $BaseKey\$SubKey\$ValueName - Actual Value: $Value - ExpectedValue: $ExpectedValue"
                If ($Passthru) {
                    Write-Host " - No Match - Value: $value" -ForegroundColor Yellow
                }
            }
            Else {
                If ($Passthru) {
                    Write-Host " - Match - Value: $value" -ForegroundColor Green
                }
            }
            
            Remove-Variable -Name Value -ErrorAction SilentlyContinue
        }
    }

}
Process {
    If ([Boolean]$CSVPath) {
        $CSVInfo = Import-Csv -Path $CSVPath
        $Count = ($CSVInfo.BaseKey -ne '').Count
        for ($i = 0; $i -lt $Count; $i++) {
            Cycle -Computers $CSVInfo.Computers -BaseKey $CSVInfo.BaseKey[$i] -SubKey $CSVInfo.SubKey[$i] -ValueName $CSVInfo.ValueName[$i] -ExpectedValue $CSVInfo.ExpectedValue[$i]
        }
    }
    ElseIf ($BaseKey.Count -gt 1) {
        for ($i = 0; $i -lt $BaseKey.Count; $i++) { 
            Cycle -Computers $Computer -BaseKey $Basekey[$i] -SubKey $SubKey[$i] -ValueName $ValueName[$i] -ExpectedValue $ExpectedValue[$i]
        }
    }
    Else {
        If ($Computer -like '\\*' -or $Computer.Substring(0, 3) -Match '[A-Za-z]{1}:\\') {
            $Computer = Get-Content -Path $Computer
        }
        Cycle -Computers $Computer -BaseKey $Basekey -SubKey $SubKey -ValueName $ValueName -ExpectedValue $ExpectedValue
    }
}
End {
    If ([Boolean]$ExportFolder -and [Boolean]$ExportFilename -and [Boolean]$Script:MachinesWithoutValue) {
        Add-Content -Path "$ExportFolder\$ExportFileName" -Value $Script:MachinesWithoutValue -Force
        & "$ExportFolder\$ExportFilename"
    }
}
