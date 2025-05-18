Function Search-GPO {
    #Requires -Modules GroupPolicy
    Param(
        [Parameter(ValueFromPipeline = $true, Position = 1)]
        [String]$String = $(Read-Host -Prompt 'What string do you want to search for?'),
        [String]$GPOName,
        [String]$Domain = $env:USERDNSDOMAIN
    )
    Begin {
        Import-Module -Name GroupPolicy -ErrorAction Stop

        #region Functions

        Function Get-GPOSettingSummary {
            Param(
                $GPOReportXML,
                [Switch]$ToReadableString
            )

            $GPO = $GPOReportXML
            If (![Bool]$GPO.GpoStatus) {
                :forloop for ($i = 1; $i -le 3; $i++) {
                    If ([Bool]$GPO.ExtensionNode) {
                        $GPO = $GPO.ExtensionNode
                    }
                    If ([Bool]$GPO.GpoStatus -or [Bool]$GPO.GPO) {
                        Break forloop
                    }
                }
            }

            If ([Boolean]$GPO.GPO) { $GPO = $GPO.GPO }

            $SettingSections = @($GPO.Computer, $GPO.User)

            Foreach ($Section in $SettingSections) {

                $Extensions = $Section.ExtensionData.Extension

                $Information = @()
                Foreach ($Extension in $Extensions) {
                    $CurrentChild = $Extension.FirstChild
                    Do {
                        $HashTable = [System.Collections.Specialized.OrderedDictionary]@{}

                        If ($CurrentChild.Name -like "*$($CurrentChild.LocalName)*") {
                            $HashTable.Type = $CurrentChild.LocalName
                        }
                        Else {
                            $HashTable.Type = $CurrentChild.LocalName + ' - ' + $CurrentChild.Name
                        }

                        If ($CurrentChild.Name -like 'Se*' -and ($CurrentChild.Name -like '*Privilege' -or $CurrentChild.Name -like '*Right')) {
                            $HashTable.$($CurrentChild.Name) = $($CurrentChild.Member.Name.'#Text' -join ' ; ')
                        }
                        Else {

                            [String[]]$SkipSettings = 'Supported', 'Explain'#, 'Category'
                            :SettingNames Foreach ($SettingName in $CurrentChild.ChildNodes.Name) {
                                If ($SettingName -like '*:*') {
                                    $SettingName = $SettingName.Split(':')[1].Trim()
                                }

                                $HashTable.Extension = $($CurrentChild.ParentNode.ParentNode.Name)

                                # Skip if Setting is in the Skip
                                If ($SettingName -eq 'Name') {
                                    If ($HashTable.Type -like "*$($CurrentChild.'Name')*") {
                                        Continue SettingNames
                                    }
                                }
                                ElseIf ($SkipSettings.Contains($SettingName) -or ![Boolean]$SettingName) {
                                    Continue SettingNames
                                }
                                # If Permissions get read-able summary
                                ElseIf ([Boolean]$CurrentChild.$SettingName.SDDL) {
                                    $HashTable.$SettingName = (Get-PermissionSummary -SDDLString $CurrentChild.$SettingName.SDDL.InnerText) -join ' ; '
                                }
                                # Catch All
                                Else {
                                    # Get the item that will be evaluated
                                    If ([Boolean]$CurrentChild.$SettingName) { $ItemToEval = $CurrentChild.$SettingName }
                                    ElseIf ([Boolean]$SettingName) { $ItemToEval = $SettingName }
                                    # If a value exists for this setting add it
                                    If ([Boolean]$ItemToEval) {

                                        #Get the value that will be added to the hashtable
                                        If ([Boolean]$ItemToEval.Value) { $Value = $($ItemToEval.Value) -join ' ; ' }
                                        ElseIf ([Boolean]$ItemToEval.'#text') { $Value = $($ItemToEval.'#text') -join ' ; ' }
                                        ElseIf ($ItemToEval -is [System.Array]) { $Value = $($ItemToEval -join ' ; ') }
                                        ElseIf ([Boolean]$ItemToEval.InnerText) { $Value = $($ItemToEval.InnerText -join ' ; ') }
                                        ElseIf ([Boolean]$ItemToEval.nil) { $Value = $ItemToEval.nil -join ' ; ' }
                                        Else { $Value = $($ItemToEval -join ' ; ') }

                                        # Determine which key to put it under
                                        If ($SettingName.LocalName -eq 'Name' -and $SettingName.ExtensionNode.LocalName -ne 'Name') { $Key = ($SettingName.ExtensionNode.LocalName) }
                                        ElseIf ([Boolean]$CurrentChild.$SettingName) { $Key = $SettingName }
                                        ElseIf ([Boolean]$CurrentChild.LocalName) { $Key = $($CurrentChild.LocalName) }
                                        Else { $Key = 'Note' }



                                        # Add $Value to $HashTable under the selected $Key
                                        If ([Boolean]$HashTable.$Key) { $HashTable.$Key = $HashTable.$Key + ', ' + $Value }
                                        Else { $HashTable.$Key = $Value }
                                    }
                                }
                            }
                        }

                        $Information += $HashTable

                        $CurrentChild = $CurrentChild.NextSibling
                    }
                    While ([Boolean]$CurrentChild)
                }

                If ($ToReadableString.IsPresent) {
                    Return $Information | ForEach-Object -Process {
                        "`n"
                        Foreach ($Key in $_.Keys) {
                            $ValueSplit = $_.$Key.Split(';').Trim()

                            If ($ValueSplit.Count -gt 1) { "$Key ::`n`t$($ValueSplit -join "`n`t")" }
                            ElseIf ([Boolean]$ValueSplit) { "$Key :: $ValueSplit" }
                            Else { "$Key :: $($_.$Key)" }
                        }
                    }
                }
                Else {
                    Return $Information
                }
            }
        } # END FUNCTION Get-GPOSettingSummary

        Function Get-PermissionSummary {
            Param($SDDLString)
            (ConvertFrom-SddlString $SDDLString).DiscretionaryAcl |
                ForEach-Object -Process {
                    $Split = $_.Split(':').Split('(').TrimEnd(')').Trim()
                    $PermSetList = $Split[2].split(',').Trim()

                    If ($PermSetList.Contains('FullControl')) { $Permission = 'Full Control' }
                    ElseIf ($PermSetList.Contains('WriteKey')) { $Permission = 'Modify' }
                    ElseIf ($PermSetList.Contains('WriteAttributes')) { $Permission = 'Apply Group Policy' }
                    ElseIf ($PermSetList.Contains('GenericExecute') -or $PermSetList.Contains('Read') -or $PermSetList.Contains('ReadExtendedAttributes')) { $Permission = 'Read' }
                    Else { $Permission = 'Custom' }

                    "$($Split[1].Trim()): $($SPlit[0].Trim()): $Permission"
                }
        } # END FUNCTION Get-PermissionSummary

        #endregion Functions
    }
    Process {
        If ($PSBoundParameters.ContainsKey('GPOName')) { [Array]$GPOs = Get-GPO -Name $GPOName -Domain $Domain }
        Else { [Array]$GPOs = Get-GPO -All -Domain $Domain }

        Foreach ($GPO in $GPOs) {
            $ReportXML = Get-GPOReport -Guid $GPO.Id -ReportType Xml -Domain $Domain

            If ($ReportXML -like "*$String*") {
                Write-Host GPO: $GPO.DisplayName -ForegroundColor Magenta

                $Report = ([xml]$ReportXML)
                [Array]$GPOSettings = Get-GPOSettingSummary -GPO $Report
                Foreach ($Setting in $GPOSettings) {
                    $Setting.GPO = $GPO.DisplayName

                    # Convert to String
                    [String[]]$StringSetting = :Keys Foreach ($Key in $Setting.Keys) {
                        If (![Boolean]$Key -or ![Boolean]$Setting.$Key) { Continue Keys }
                        $ValueSplit = $Setting.$Key.Split(';').Trim()

                        If ($ValueSplit.Count -gt 1) { "$Key ::`n`t$($ValueSplit -join "`n`t")" }
                        ElseIf ([Boolean]$ValueSplit) { "$Key :: $ValueSplit" }
                        Else { "$Key :: $($Setting.$Key)" }
                    }

                    # If String is present, output.
                    If ("$StringSetting" -like "*$String*") { "`n"; $StringSetting }
                }
            }
        }
    }
}