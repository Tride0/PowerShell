Function Search-GPO {
    #Requires -Modules GroupPolicy
    Param(
        [Parameter(ValueFromPipeline = $true, Position = 1)]
        [String]$String = $(Read-Host -Prompt 'What string do you want to search for?'),
        [String]$Name,
        [String]$Domain = $env:USERDNSDOMAIN
    )
    Begin {
        Import-Module -Name GroupPolicy -ErrorAction Stop

        #region Functions

        Function Get-GPOSettingSummary {
            Param(
                $GPO,
                [Switch]$ToReadableString
            )
            If ([Boolean]$GPO.ExtensionData) { $GPO = $GPO.ExtensionData.Extension }
            ElseIf ([Boolean]$GPO.Extension) { $GPO = $GPO.Extension }

            If (![Boolean]$GPO.ParentNode.Extension) { Return $null }

            $Information = @()
            Foreach ($Parent in $GPO) {
                $CurrentChild = $Parent.FirstChild
                Do {
                    $HashTable = [System.Collections.Specialized.OrderedDictionary]@{}

                    $HashTable.SettingName = $CurrentChild.LocalName + ' - ' + $CurrentChild.Name

                    If ($CurrentChild.Name -like 'Se*' -and ($CurrentChild.Name -like '*Privilege' -or $CurrentChild.Name -like '*Right')) {
                        $HashTable.$($CurrentChild.Name) = $($CurrentChild.Member.Name.'#Text' -join ' ; ')
                    }
                    Else {
                        [String[]]$SkipSettings = 'Supported', 'Explain', 'Category'
                        :SettingNames Foreach ($SettingName in $CurrentChild.ChildNodes.Name) {
                            If ($SettingName -like '*:*') {
                                $SettingName = $SettingName.Split(':')[1].Trim()
                            }
                            # Skip if Setting is in the Skip
                            If ($SkipSettings.Contains($SettingName) -or ![Boolean]$SettingName) { Continue SettingNames }

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
                                    Else { $Value = $($ItemToEval -join ' ; ') }

                                    # Add value to hashtable
                                    If ($value -ne $CurrentChild.Name) {

                                        # Determine which key to put it under
                                        If ($SettingName.LocalName -eq 'Name' -and $SettingName.ParentNode.LocalName -ne 'Name') { $Key = ($SettingName.ParentNode.LocalName) }
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
        } # END FUNCTION Get-GPOSettingSummary

        Function Get-PermissionSummary {
            Param($SDDLString)
            (ConvertFrom-SddlString $SDDLString).DiscretionaryAcl |
                ForEach-Object -Process {
                    $Split = $_.Split(':').Split('(').TrimEnd(')').Trim()
                    $PermSetList = $Split[2].split(',').Trim()

                    If ($PermSetlist.Contains('FullControl')) { $Permission = 'Full Control' }
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
        If ($PSBoundParameters.ContainsKey('Name')) { [Array]$GPOs = Get-GPO -Name $Name -Domain $Domain }
        Else { [Array]$GPOs = Get-GPO -All -Domain $Domain }

        Foreach ($GPO in $GPOs) {
            $Report = Get-GPOReport -Guid $GPO.Id -ReportType Xml -Domain $Domain
            If ($Report -like "*$String*") {
                Write-Host $GPO.DisplayName
                $Report = ([xml]$Report)
                [Array]$GPOSettings = (Get-GPOSettingSummary -GPO $Report.GPO.User) + (Get-GPOSettingSummary -GPO $Report.GPO.Computer)
                Foreach ($Setting in $GPOSettings) {
                    $Setting.GPO = $GPO.DisplayName

                    # Convert to String
                    [String]$StringSetting = :Keys Foreach ($Key in $Setting.Keys) {
                        If (![Boolean]$Key -or ![Boolean]$Setting.$Key) { Continue Keys }
                        $ValueSplit = $Setting.$Key.Split(';').Trim()

                        If ($ValueSplit.Count -gt 1) { "$Key ::`n`t$($ValueSplit -join "`n`t")" }
                        ElseIf ([Boolean]$ValueSplit) { "$Key :: $ValueSplit" }
                        Else { "$Key :: $($Setting.$Key)" }
                    }

                    # If String is present, output.
                    If ($StringSetting -like "*$String*") { Write-Host $StringSetting }
                }
            }
        }
    }
}