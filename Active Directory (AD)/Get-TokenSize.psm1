Function Get-TokenSize {
    <#
        Created By: Kyle Hewitt
        Created On: 12/11/2018 12:08:51
        Last Edit: 1/21/2020
        Version: 1.0.0
    #>

    Param(
        [Parameter(Mandatory = $True)][String[]]$User,
        #MaxLimit is 48000 for newer OSs and 12000 for older
        [ValidateSet(12000, 48000)]$AcceptableSizeLimit = 48000,
        [Switch]$OnDC
    )

    Begin {
        #region Functions

        Function FindUser {
            Param($U, $Attribute = 'distinguishedname')

            If (![Bool]$U) { Return }
  
            $Searcher = [ADSISearcher]@{ }

            $U = $U.Trim()

            If ($U -like 'CN=*') {
                $Searcher.Filter = "(distinguishedname=$U)"
            }
            ElseIf ($U -like '*@*.*') {
                $Searcher.Filter = "(mail=$U)"
            }
            ElseIf ($U -like '* - *') {
                $Searcher.Filter = "(|(displayname=$U)(name=$U)(samaccountname=$U))"
            }
            ElseIf ($U -like '* *') {
                $Searcher.Filter = "(|(&(givenname=$($U.split(' ')[0].Trim()))(sn=$(($U.split(' ')[1..$U.length] -join ' ').trim())))(&(givenname=$($U.split(' ')[-1].Trim()))(sn=$(($U.Split(' ')[0..($U.Split(' ').Count-2)] -join ' ').Trim()))))"
            }
            ElseIf ($U -like '*,*') {
                $Searcher.Filter = "(|(&(givenname=$($U.split(',')[0].Trim()))(sn=$($U.split(',')[1].Trim())))(&(givenname=$($U.split(',')[1].Trim()))(sn=$($U.split(',')[0].Trim()))))"
            }
            ElseIf ($U -match '[0-9]{1,}' -and $U -notmatch '[a-zA-Z]{1,}') {
                $Searcher.Filter = "(uidnumber=$U)"
            }
            Else {
                $Searcher.Filter = "(samaccountname=$U)"
            }

            Return $Searcher.FindOne().Properties.$Attribute
        }

        Function Get-AllMembers {
            Param(
                $distinguishedname
            )
            Begin {
                $ADSearcher = [DirectoryServices.DirectorySearcher]@{
                    Filter = "distinguishedname=$($distinguishedname)"
                }
    
                $RetrievedAllItems = $False
                $RangeTop = $RangeBottom = 0
                $AllMembers = @()
            }
            Process {
                While (!$RetrievedAllItems) {
                    $RangeTop = $RangeBottom + 1500             
                    $ADSearcher.PropertiesToLoad.Clear()
                    [Void] $ADSearcher.PropertiesToLoad.Add("memberof;range=$RangeBottom-$RangeTop")
                    $RangeBottom += 1500

                    Try {
                        $TempInfo = $ADSearcher.FindOne().Properties
                        $AllMembers += $TempInfo.Item($TempInfo.PropertyNames -like 'memberof;range=*')
                            
                        If ($TempInfo.Item($TempInfo.PropertyNames -like 'memberof;range=*').Count -eq 0) { $RetrievedAllItems = $True }

                        Remove-Variable -Name TempInfo -ErrorAction SilentlyContinue
                    }
                    Catch { $RetrievedAllItems = $True }
                }
            }
            End {
                Return $AllMembers
            }
        }

        Function Get-NestedMembers {
            Param(
                $Targets,
                $Depth = 0
            )
            Begin {
                If ($Depth -eq 0) {
                    $Global:FinalResults = @()
                    $PrimaryMembers = $Targets
                }
            }
            Process {
                Foreach ($Value in $Targets) {
                    #Prevents Primary Memberships from being Re-displayed as NestedMemberships
                    If ($PrimaryMembers -contains $Value -and $Depth -gt 0) { Continue }
                    $DN = $Value

                    #Removes Results that are already a part of FinalResults
                    If ($Global:FinalResults -notcontains $Value.Trim()) {
                        $Global:FinalResults += $Value.Trim()
                        #Add Line Break or Separator

                        #Cycles through Member and member for any Nested memberships up to the max display limit
                        If (([adsi]"LDAP://$DN").objectclass -contains 'group') {
                            $TempNestedValues = Get-AllMembers -distinguishedname $DN
                            $NestedValues = @()

                            Foreach ($NestedValue in $TempNestedValues) {
                                #Removes Results that are already a part of FinalResults
                                If ($FinalResults -notcontains "$(($NestedValue -Split(',[A-Z]{2}='))[0].Replace('CN=',''))".Trim()) {
                                    $NestedValues += $NestedValue
                                }
                            }
            
                            #Restart the Function with new Values
                            If ([Boolean]$NestedValues) {
                                Get-NestedMembers -Targets $NestedValues -Depth ($Depth + 1)
                            }
                        }
                    }
                }
            }
            End {
                If ($Depth -eq 0) { Return $Global:FinalResults }
            }
        }

        #endregion Functions
    }

    Process {
        Foreach ($U in $User) {
            $MemberDN = FindUser -U $U

            $Member = ([ADSISearcher]"distinguishedname=$MemberDN").FindOne().Properties
    
            $MembershipDNs = Get-NestedMembers -Targets (Get-AllMembers -distinguishedname $MemberDN) -Depth 0
    
            Foreach ($DN in $MembershipDNs) {
                $ADObject = ([ADSISearcher]"distinguishedname=$DN").FindOne().Properties
                $DomainSID = (New-Object System.Security.Principal.SecurityIdentifier($($ADObject.objectsid), 0)).Value

                #SID History
                $SIDHistorySids = @()
                Foreach ($SIDHistorySid in $Results.Properties.sidhistory) {
                    $SIDHistorySids += (New-Object System.Security.Principal.SecurityIdentifier($($SIDHistorySid), 0)).Value
                }

                If (($SIDHistorySids | Measure-Object).Count -gt 0) {
                    $AllGroupSIDHistories += $SIDHistorySids
                }

                Switch -Exact ($ADObject.grouptype) {
                    '-2147483646' { $SecurityGlobalScope ++ }
                    '-2147483644' { $SecurityDomainLocalScope ++ }
                    '-2147483640' {
                        If ($GroupSid -match $DomainSID) { $SecurityUniversalInternalScope ++ }
                        Else { $SecurityUniversalExternalScope ++ }
                    }
                }
                $ADObject.Clear()
                Remove-Variable DomainSid -ErrorAction silentlycontinue
            }

            $GroupSidHistoryCounter = $AllGroupSIDHistories.Count 
        
            $TokenSize = 1200 + (40 * 
                ($SecurityDomainLocalScope + $SecurityUniversalExternalScope + $GroupSidHistoryCounter)) + 
            (8 * ($SecurityGlobalScope + $SecurityUniversalInternalScope))
    
            If ($OnDC.IsPresent) {
                $DelegatedTokenSize = 2 * (1200 + 
                    (40 * ($SecurityDomainLocalScope + $SecurityUniversalExternalScope + $GroupSidHistoryCounter)) + 
                    (8 * ($SecurityGlobalScope + $SecurityUniversalInternalScope)))
            }

            [PSCustomObject]@{
                Member             = $($Member.samaccountname)
                MembershipCount    = $MembershipDNs.Count
                TokenSize          = $TokenSize
                DelegatedTokenSize = $DelegatedTokenSize
            }
        }
    }
}