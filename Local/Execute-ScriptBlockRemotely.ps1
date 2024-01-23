<#
    .NOTES
        Created By: Kyle Hewitt
        Created On: 07-24-2020
        Version: 2020.07.24

    .DESCRIPTION
        This script will modify itself, distribute itself to the system(s) and execute that copy of itself on the remote system. It will then clean it self up. The remote copy of itself will delete itself.
        Something to keep in mind is that the remote copy of the script will use the system account to run.
            For this reason the account will most likely not be able to reach other systems from that one or will recieve access denied.
        Theroretically allowing you to run any command or script remotely as long as:
        1. WinRM is available
        2. The account used to run this script is an administrator on the system(s).
#>

# Use : as the separator between the key and value
<# Inter-Script Info
    Dispersor:

Inter-Script Info #> 

Param(
    [String[]]$Computers = '',
    [String]$LogPath = "$PSSCriptRoot\RemoteLocalScript_Logs\$ENV:ComputerName`_$(Get-Date -Format yyyyMMdd_hhmmss).log",
    $ScriptBlock
)

$CurrentComputer = $env:COMPUTERNAME

$ScriptPath = $MyInvocation.MyCommand.Definition


#region Functions

Function Set-InterScriptInfo {
    Param(
        [String]$ScriptPath = $ScriptPath
    )
    $ScriptContent = Get-Content $ScriptPath
    
    $Dispersor_Content = $ScriptContent -like '*Dispersor*:*' -notlike '*=*'
    $Dispersor_Index = $ScriptContent.IndexOf($Dispersor_Content)
    $ScriptContent[$Dispersor_Index] = "Dispersor: $env:COMPUTERNAME"

    Set-Content -Path $ScriptPath -Value $ScriptContent -Force 
}

Function Get-InterScriptInfo {
    Param(
        [String]$ScriptPath = $ScriptPath,
        [ValidateSet('Index', 'Content')]$OutputType = 'Content'
    )

    $ScriptContent = Get-Content $ScriptPath

    $FirstLineContent = $ScriptContent -like '*<# Inter-Script Info*' -notlike '*ThisLine*'
    $LastLineContent = $ScriptContent -like '*Inter-Script Info #>*' -notlike '*ThisLine*'
    
    $FirstLineIndex = $ScriptContent.IndexOf($FirstLineContent)
    $LastLineIndex = $ScriptContent.IndexOf($LastLineContent)
    
    If ($OutputType -eq 'Index') {
        Return $FirstLineIndex..$LastLineIndex
    }
    ElseIf ($OutputType -eq 'Content') {
        $Hash = [System.Collections.Specialized.OrderedDictionary]@{}
        :BuildHashFor For ($i = $FirstLineIndex; $i -le $LastLineIndex; $i++) { 
            $i_Content = $ScriptContent[$i]
            If ($i_Content -notlike '*:*') { Continue BuildHashFor }
            Else {
                $Split_Content = $i_Content.split(':').Trim()
                $Key = $Split_Content[0]
                $value = $Split_Content[1]
                $Hash.Add($Key, $Value)
            }
        }
        Return $Hash
    }
}

Function Clear-InterScriptInfo {
    Param(
        [String]$ScriptPath = $ScriptPath
    )

    $ScriptContent = Get-Content -Path $ScriptPath

    $Indexes = Get-InterScriptInfo -ScriptPath $ScriptPath -OutputType Index 

    :PurgeFor For ($i = $Indexes[0]; $i -le $Indexes[-1]; $i++) { 
        $i_Content = $ScriptContent[$i]
        If ($i_Content -notlike '*:*') { Continue PurgeFor }
        Else {
            $Split_Content = $i_Content.split(':').Trim()
            $Key = $Split_Content[0]
            $ScriptContent[$i] = "`t$key`:"
        }
    }
    
    Set-Content -Path $ScriptPath -Value $ScriptContent -Force

}

Function ExecuteRemotely {
    Param(
        [String]$Computer,
        [String]$FilePath
    )
    $WMIProcess = ([Management.ManagementClass]"\\$Computer\ROOT\CIMV2:win32_process")

    Return $WMIProcess.InvokeMethod('Create', "Powershell.exe -File `"$FilePath`"")
}

#endregion Functions


$InterScriptInfo = Get-InterScriptInfo

If ($CurrentComputer -eq $InterScriptInfo.Dispersor -or ![Boolean]$InterScriptInfo.Dispersor) {

    Start-Transcript -Path $LogPath  -Force

    Write-Host "Adding Dispersor $($CurrentComputer) to the script."
    Set-InterScriptInfo
    
    If ([Boolean]$ScriptBlock) {
        Write-Host 'Using a scriptblock for this run'
        Write-Host 'Modifying Script Block'
        $ScriptBlock = "`n`r# TEMP SCRIPT BLOCK`n`r`n`r" + $ScriptBlock.ToString() + "`n`r`n`rRemove-Item -Path `$ScriptPath -Force"
        
        Write-Host 'Adding Temporary ScriptBlock to this script.'
        Add-Content -Path $ScriptPath -Value $ScriptBlock -Force 
    }

    :CopyExecuteForeach Foreach ($Computer in $Computers) {
        # Copy
        Try {
            Write-Host "Copying Script to $Computer"
            [Void] (New-Item -Path "\\$Computer\c$\temp" -ItemType Directory -Force -ErrorAction Stop )
            Copy-Item -Path $ScriptPath -Destination "\\$Computer\c$\temp\$($ScriptPath | Split-Path -Leaf)" -Force -ErrorAction Stop 
            Start-Sleep -Seconds 2
        }
        Catch {
            Write-Warning "Failed to Copy script to $Computer. Error: $_.`nSkipping."
            Continue CopyExecuteForeach
        }

        # Execute
        Write-Host "Executing Script on $Computer"
        $Status = ExecuteRemotely -Computer $Computer -FilePath "C:\temp\$($ScriptPath | Split-Path -Leaf)"
        Write-Host "Execution Code: $Status"
    }

    Write-Host 'Clearing InterScript Information from Script'
    Clear-InterScriptInfo

    If ([Boolean]$ScriptBlock) {
        Write-Host 'Clearing Temporary ScriptBlock from Script'
        $ScriptContent = Get-Content -Path $ScriptPath

        $ScriptBlock_Index = $ScriptContent.IndexOf('# TEMP SCRIPT BLOCK')
        If ($ScriptBlock_Index -ne -1) {
            Set-Content -Path $ScriptPath -Value $ScriptContent[0..($ScriptBlock_Index - 2)] -Force
        }
        Else {
            Write-Warning 'Failed to clear scriptblock from script. Please verify script is clear before attempting to run again.'
        }
    }

    Stop-Transcript 

    Break
}

