Function Check-IfUserIsMember {
    <#
        Created By: Kyle Hewitt
        Created On: 12/04/2018
    #>

    Param(
        [Parameter(ParameterSetName = 'UserID')]$Identifier,
        [Parameter(ParameterSetName = 'UserID')]$DistinguishedName,
        [Parameter(Mandatory = $True)]$Group
    )

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

                $Value = "$(($Value -Split(',[A-Z]{2}='))[0].Replace('CN=',''))"
            
                #Removes Results that are already a part of FinalResults
                If ($Global:FinalResults -notcontains $Value.Trim()) {
                    $Global:FinalResults += $Value.Trim()
                    #Add Line Break or Separator

                    #Cycles through Member and Memberof for any Nested memberships up to the max display limit
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

    If ([Boolean]$Identifier) {
        $ADSearcher = [DirectoryServices.DirectorySearcher]@{
            Filter = "(|(userprincipalname=$Identifier)(samaccountname=$Identifier))"
        }

        $DN = $ADSearcher.FindOne().Properties.distinguishedname
    }
    Else {
        $DN = $DistinguishedName
    }

    $Memberships = Get-NestedMembers -Targets (Get-AllMembers -distinguishedname $DN)

    For ($i = 0; $i -lt $Memberships.Count; $i++) {
        $Memberships[$i] = ($Memberships[$i] -split ',[A-Z]{2}=')[0].TrimStart('CN=')
    }

    Return ($Memberships -contains $Group)
}