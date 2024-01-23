Function Get-GPONoSettingsButEnabled {
    <#
        .NOTES
            Created By: Kyle Hewitt
            Created On: 4/30/20
            Version: 2020.04.30
            
        .DESCRIPTION
            Gets GPOs that have sections with no settings but those sections are still enabled.
                Disabling those sections should help improve processing time.
    #>
    Param(
        $Domain = $env:USERDNSDOMAIN
    )
    Begin {
        Import-Module GroupPolicy -ErrorAction Stop
    }
    Process {
        [Microsoft.GroupPolicy.GPDomain]::new("$Domain").GetAllGpos() | 
            ForEach-Object -Process {
                $GPO = $_
                $XML = ($GPO | Get-GPOReport -ReportType Xml).Split("`n")
                    
                $CompStart = $XML.IndexOf($($XML -like '*<Computer>*'))
                $CompEnd = $XML.IndexOf($($XML -like '*</Computer>*'))
                $CompSettings = ($XML[$CompStart..$CompEnd]) -match '<q[0-9]{1,}.{1,}>'
                    
                $UserStart = $XML.IndexOf($($XML -like '*<User>*'))
                $UserEnd = $XML.IndexOf($($XML -like '*</User>*'))
                $UserSettings = $XML[$UserStart..$UserEnd] -match '<q[0-9]{1,}.{1,}>'

                If (( ![Boolean]$CompSettings -and $GPO.Computer.Enabled ) -or
                ( ![Boolean]$UserSettings -and $GPO.User.Enabled )) {
                    $GPO | 
                        Select-Object -Property DisplayName, CreationTime, ModificationTime, Owner, Description,
                        @{n = 'User_Enabled'; e = { $_.User.Enabled } }, @{n = 'User_Settings'; e = { [Boolean]$UserSettings } },
                        @{n = 'Comp_Enabled'; e = { $_.Computer.Enabled } }, @{n = 'Comp_Settings'; e = { [Boolean]$CompSettings } }

                    }
                    Remove-Variable GPO, XML, CompStart, CompEnd, CompSettings, UserStart, UserEnd, UserSettings -ErrorAction SilentlyContinue
                } |
                Sort-Object -Property DisplayName
    }
}