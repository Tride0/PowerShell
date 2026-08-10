function Search-GPO {
    #Requires -Modules GroupPolicy
    param(
        [Parameter(ValueFromPipeline = $true, Position = 1)]
        [String]$String = $(Read-Host -Prompt 'What string do you want to search for?'),
        [String]$GPOName,
        [String]$Domain = $env:USERDNSDOMAIN
    )
    begin {
        Import-Module -Name GroupPolicy -ErrorAction Stop

        #region Functions

        
        function Get-GPOSettingSummary {
            param(
                $GPOReportXML,
                [Switch]$ToReadableString
            )

            $GPO = $GPOReportXML
            if (![Bool]$GPO.GpoStatus) {
                :forloop for ($i = 1; $i -le 3; $i++) { 
                    if ([Bool]$GPO.ExtensionNode) {
                        $GPO = $GPO.ExtensionNode
                    }
                    if ([Bool]$GPO.GpoStatus -or [Bool]$GPO.GPO) {
                        break forloop
                    }
                }
            }

            if ([Boolean]$GPO.GPO) { $GPO = $GPO.GPO }

            $SettingSections = @($GPO.Computer, $GPO.User)

            foreach ($Section in $SettingSections) {

                $Extensions = $Section.ExtensionData.Extension

                $Information = @()
                foreach ($Extension in $Extensions) {
                    $CurrentChild = $Extension.FirstChild
                    do {
                        $HashTable = [System.Collections.Specialized.OrderedDictionary]@{}

                        if ($CurrentChild.Name -like "*$($CurrentChild.LocalName)*") {
                            $HashTable.Type = $CurrentChild.LocalName
                        }
                        else {
                            $HashTable.Type = $CurrentChild.LocalName + ' - ' + $CurrentChild.Name
                        }

                        if ($CurrentChild.Name -like 'Se*' -and ($CurrentChild.Name -like '*Privilege' -or $CurrentChild.Name -like '*Right')) {
                            $HashTable.$($CurrentChild.Name) = $($CurrentChild.Member.Name.'#Text' -join ' ; ')
                        }
                        else {
                
                            [String[]]$SkipSettings = 'Supported', 'Explain'#, 'Category'
                            :SettingNames foreach ($SettingName in $CurrentChild.ChildNodes.Name) {
                                if ($SettingName -like '*:*') {
                                    $SettingName = $SettingName.Split(':')[1].Trim()
                                }

                                $HashTable.Extension = $($CurrentChild.ParentNode.ParentNode.Name)

                                # Skip if Setting is in the Skip
                                if ($SettingName -eq 'Name') {
                                    if ($HashTable.Type -like "*$($CurrentChild.'Name')*") {
                                        continue SettingNames
                                    }
                                }
                                elseif ($SkipSettings.Contains($SettingName) -or ![Boolean]$SettingName) { 
                                    continue SettingNames 
                                }
                                # If Permissions get read-able summary
                                elseif ([Boolean]$CurrentChild.$SettingName.SDDL) {
                                    $HashTable.$SettingName = (Get-PermissionSummary -SDDLString $CurrentChild.$SettingName.SDDL.InnerText) -join ' ; '
                                }
                                # Catch All
                                else {
                                    # Get the item that will be evaluated
                                    if ([Boolean]$CurrentChild.$SettingName) { $ItemToEval = $CurrentChild.$SettingName }
                                    elseif ([Boolean]$SettingName) { $ItemToEval = $SettingName }
                                    # If a value exists for this setting add it
                                    if ([Boolean]$ItemToEval) {

                                        #Get the value that will be added to the hashtable
                                        if ([Boolean]$ItemToEval.Value) { $Value = $($ItemToEval.Value) -join ' ; ' }
                                        elseif ([Boolean]$ItemToEval.'#text') { $Value = $($ItemToEval.'#text') -join ' ; ' }
                                        elseif ($ItemToEval -is [System.Array]) { $Value = $($ItemToEval -join ' ; ') }
                                        elseif ([Boolean]$ItemToEval.InnerText) { $Value = $($ItemToEval.InnerText -join ' ; ') }
                                        elseif ([Boolean]$ItemToEval.nil) { $Value = $ItemToEval.nil -join ' ; ' }
                                        else { $Value = $($ItemToEval -join ' ; ') }

                                        # Determine which key to put it under
                                        if ($SettingName.LocalName -eq 'Name' -and $SettingName.ExtensionNode.LocalName -ne 'Name') { $Key = ($SettingName.ExtensionNode.LocalName) }
                                        elseif ([Boolean]$CurrentChild.$SettingName) { $Key = $SettingName }
                                        elseif ([Boolean]$CurrentChild.LocalName) { $Key = $($CurrentChild.LocalName) }
                                        else { $Key = 'Note' }

                            

                                        # Add $Value to $HashTable under the selected $Key
                                        if ([Boolean]$HashTable.$Key) { $HashTable.$Key = $HashTable.$Key + ', ' + $Value }
                                        else { $HashTable.$Key = $Value }
                                    }
                                }
                            }
                        }

                        $Information += $HashTable

                        $CurrentChild = $CurrentChild.NextSibling
                    }
                    while ([Boolean]$CurrentChild)
                }

                if ($ToReadableString.IsPresent) {
                    return $Information | ForEach-Object -Process {
                        "`n"
                        foreach ($Key in $_.Keys) {
                            $ValueSplit = $_.$Key.Split(';').Trim()

                            if ($ValueSplit.Count -gt 1) { "$Key ::`n`t$($ValueSplit -join "`n`t")" }
                            elseif ([Boolean]$ValueSplit) { "$Key :: $ValueSplit" }
                            else { "$Key :: $($_.$Key)" }
                        }
                    }
                }
                else {
                    $Information
                }
            }
        } # END FUNCTION Get-GPOSettingSummary

        function Get-PermissionSummary {
            param($SDDLString)
            (ConvertFrom-SddlString $SDDLString).DiscretionaryAcl |
                ForEach-Object -Process {
                    $Split = $_.Split(':').Split('(').TrimEnd(')').Trim()
                    $PermSetList = $Split[2].split(',').Trim()

                    if ($PermSetList.Contains('FullControl')) { $Permission = 'Full Control' }
                    elseif ($PermSetList.Contains('WriteKey')) { $Permission = 'Modify' }
                    elseif ($PermSetList.Contains('WriteAttributes')) { $Permission = 'Apply Group Policy' }
                    elseif ($PermSetList.Contains('GenericExecute') -or $PermSetList.Contains('Read') -or $PermSetList.Contains('ReadExtendedAttributes')) { $Permission = 'Read' }
                    else { $Permission = 'Custom' }

                    "$($Split[1].Trim()): $($SPlit[0].Trim()): $Permission"
                }
        } # END FUNCTION Get-PermissionSummary

        #endregion Functions
    }
    process {
        if ($PSBoundParameters.ContainsKey('GPOName')) { [Array]$GPOs = Get-GPO -Name $GPOName -Domain $Domain }
        else { [Array]$GPOs = Get-GPO -All -Domain $Domain }

        $LoopStarted = Get-Date
        $i = 0
        $iTotal = $GPOs.count
        foreach ($GPO in $GPOs) {
            $i ++
            Write-Progress -Id 1 -Activity "Checking GPOs for '$String'" -Status "$i/$iTotal" -PercentComplete ($i / $iTotal * 100) -SecondsRemaining (((Get-Date) - $LoopStarted).TotalSeconds / $i * $iTotal) -CurrentOperation "$($GPO.DisplayName)"
            $ReportXML = Get-GPOReport -Guid $GPO.Id -ReportType Xml -Domain $Domain

            if ($ReportXML -like "*$String*") {
                Write-Host GPO: $GPO.DisplayName -ForegroundColor Magenta

                $Report = ([xml]$ReportXML)
                [Array]$GPOSettings = Get-GPOSettingSummary -GPO $Report
                foreach ($Setting in $GPOSettings) {
                    $Setting.GPO = $GPO.DisplayName

                    # Convert to String
                    [String[]]$StringSetting = :Keys foreach ($Key in $Setting.Keys) {
                        if (![Boolean]$Key -or ![Boolean]$Setting.$Key) { continue Keys }
                        $ValueSplit = $Setting.$Key.Split(';').Trim()

                        if ($ValueSplit.Count -gt 1) { "$Key ::`n`t$($ValueSplit -join "`n`t")" }
                        elseif ([Boolean]$ValueSplit) { "$Key :: $ValueSplit" }
                        else { "$Key :: $($Setting.$Key)" }
                    }

                    # If String is present, output.
                    if ("$StringSetting" -like "*$String*") { "`n"; $StringSetting }
                }
            }
        }
        Write-Progress -Id 1 -Activity "Checking GPOs for '$String'" -Completed
    }
}