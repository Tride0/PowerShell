Function Test-PendingReboot {
    [cmdletbinding()]
    Param($Computer)
    Try {
        $WMI_Reg = [WMIClass] "\\$Computer\root\default:StdRegProv"
        if ($WMI_Reg) {
            # Windows Updates
            If (($WMI_Reg.EnumKey('2147483650', 'SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update')).sNames -contains 'RebootRequired') { Return $true }
            If (($WMI_Reg.EnumKey('2147483650', 'SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update')).sNames -contains 'PostRebootReporting') { Return $true }
            #
            If (($WMI_Reg.EnumKey('2147483650', 'SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing')).sNames -contains 'RebootPending') { Return $true }
            If (($WMI_Reg.EnumKey('2147483650', 'Software\Microsoft\Windows\CurrentVersion\Component Based Servicing')).sNames -contains 'RebootInProgress') { Return $true }
            #
            If (($WMI_Reg.EnumKey('2147483650', 'SYSTEM\CurrentControlSet\Control\Session Manager\')).sNames -contains 'PendingFileRenameOperations') { Return $true }
            #
            If (($WMI_Reg.EnumKey('2147483650', 'SYSTEM\CurrentControlSet\Services\Netlogon\')).sNames -contains 'AvoidSpnSet') { Return $true }
            # Joining Domain
            If (($WMI_Reg.EnumKey('2147483650', 'SYSTEM\CurrentControlSet\Services\Netlogon\')).sNames -contains 'JoinDomain') { Return $true }
            #
            If (($WMI_Reg.EnumKey('2147483650', 'SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce')).sNames -contains 'DVDRebootSignal') { Return $true }
            # 
            If (($WMI_Reg.EnumKey('2147483650', 'SOFTWARE\Microsoft\ServerManager')).sNames -contains 'CurrentRebootAttempts') { Return $true }

            #
            $Check = $WMI_Reg.GetDWORDValue('2147483650', 'SOFTWARE\Microsoft\Updates', 'UpdateExeVolatile')
            If ($Check.ReturnValue -eq 0 -and [Bool]$Check.uValue -and $Check.uValue -ne 0) { Return $True }
            
            # 
            $WMI_Reg.EnumKey('2147483650', 'SYSTEM\CurrentControlSet\Control\Session Manager\PendingFileRenameOperations2').sNames | 
                ForEach-Object -Process {
                    If ($WMI_Reg.GetDWORDValue('2147483650', 'SYSTEM\CurrentControlSet\Control\Session Manager\PendingFileRenameOperations2', $_).uValue -like '*Pending*') { Return $True }
                }

            #
            ($WMI_Reg.EnumKey('2147483650', 'SYSTEM').snames -like 'ControlSet*') | 
                ForEach-Object -Process {
                    $MainKey = "SYSTEM\$_\Control\Session Manager\"
                    If ($WMI_Reg.EnumKey('2147483650', $MainKey).snames -contains 'PendingFileRenameOperations') { Return $True }
                    
                    $WMI_Reg.EnumKey('2147483650', "$MainKey\PendingFileRenameOperations2").sNames | 
                        ForEach-Object -Process {
                            If ($WMI_Reg.GetDWORDValue('2147483650', "$MainKey\PendingFileRenameOperations2", $_).uValue -like '*Pending*') { Return $True }
                        }
                    }

            # Check SCCM
            Try {
                If (([WmiClass]"\\$Computer\ROOT\CCM\ClientSDK:CCM_ClientUtilities").DetermineIfRebootPending().RebootPending -eq 'True') { Return $true }   
            }
            Catch { }
 
            Return $False
        }
        Else { Return 'Cant Get to WMI.' }
    }
    Catch { Return "$_" }
}