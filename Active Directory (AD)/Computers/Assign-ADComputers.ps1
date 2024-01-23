<#
    .NOTES
        Created By: Kyle Hewitt
        Created On: 07-27-2020
        Version: 2020.07.27

    .DESCRIPTION
        This script is used to move AD computers to OUs using filters of any kind.
        This script can be used on an automated scheduled using Task Scheduler.
#>

[String]$SuccessLogPath = "$PSScriptRoot\Move_Computer_Success_Log.log"
[String]$FailureLogPath = "$PSScriptRoot\Move_Computer_Failure_Log.log"

[String[]]$Include = @(
    @{
        # Leave ADAttribute or MatchString blank to include all computers from this OU
        ADAttribute   = 'name'
        MatchString   = 'phx*'
        # This is array-able
        IncludeFromOU = $('OU=Computers,DC=chw,DC=edu')
    }
)

$Exclude = @(
    @{
        ADAttribute   = 'OperatingSystem'
        MatchString   = '*Server*'
        # Leave ExcludeFromOU blank or put * if you want this filter to apply to every computer retrieved from the OU(s). This is array-able.
        ExcludeFromOU = @('OU=Computers,DC=chw,DC=edu')
    }
)

$Match = @(
    @{
        ADAttribute = 'name'
        # This is array-able
        MatchString = @('phx*')
        MoveToOU    = 'OU=Computers,OU=phx,DC=Domain,DC=com'
    }
)

If ([Boolean]$Match.ADAttribute -or [Boolean]$Exclude.ADAttribute) {
    $GetADComputerParameters = @{
        Properties = [String[]]$Match.ADAttribute + [String[]]$Exclude.ADAttribute
    }
}

$Computers = @()
Foreach ($Inclusion in $Include) {
    If ([Boolean]$Inclusion.ADAttribute -and [Boolean]$Inclusion.MatchString) {
        $GetADComputerParameters.Filter = { $Inclusion.ADAttribute -like "$MatchString" }
    } 
    Else {
        $GetADComputerParameters.Filter = '*'
    }
    Foreach ($OU in $Inclusion.IncludeFromOU) {
        $GetADComputerParameters.SearchBase = $OU
        $Computers += Get-ADComputer @GetADComputerParameters
    }
}

$Excluded = @()
Foreach ($Exclusion in $Exclude) {
    $CurrentIterationList = $Computers |
        Where-Object -FilterScript { $_.($Exclusion.ADAttribute) -notlike $Exclusion.MatchString }
    
    Foreach ($OU in $Exclusion.ExcludeFromOU) {
        If ([Boolean]$OU -or $OU -notlike '*') {
            $CurrentIterationList = $CurrentIterationList |
                Where-Object -FilterScript { $_.DistinguishedName -notmatch "CN=[^=]{1,},$OU" }
        }
    }
    $Excluded += $CurrentIterationList
}
$Computers = $Computers | 
    Where-Object -FilterScript { $Excluded.DistinguishedName -notcontains $_.DistinguishedName }


# Foreach Computer
:Computers Foreach ($Computer in $Computers) {
    # Match it to
    :Matching Foreach ($Matching in $Match) {
        # One of possibly many match strings associated 
        :MatchString Foreach ($MatchString in $Matchin.MatchString) {
            If ($Computer.$($Matching.ADAttribute) -like "$MatchString") {
                Try {
                    $Computer | Move-ADObject -TargetPath $Matching.MoveToOU -ErrorAction Stop
                    Write-Host "Moved $($Computer.distinguishedname) to $($Matching.MoveToOU)" -ForegroundColor Green
                    "Moved $($Computer.distinguishedname) to $($Matching.MoveToOU)" >> $SuccessLogPath
                }
                Catch {
                    Write-Warning "Failed to move $($Computer.distinguishedname) to $($Matching.MoveToOU). Error: $_"
                    "Failed to move $($Computer.distinguishedname) to $($Matching.MoveToOU). Error: $_" >>$FailureLogPath
                }
                Continue Computers
            }
        }
    }
}

