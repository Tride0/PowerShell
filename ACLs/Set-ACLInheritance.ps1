Function Set-ACLInheritance {
    <#
        .NOTES
            Created By: Kyle Hewitt
            Created On: 08-12-2020
            Version: 2020.08.12

        .DESCRIPTION
            This function will modify inheritance on an ACL
    #>

    Param(
        $ACL,    
        [String]$Path,
        [Boolean]$Inherit,
        [Boolean]$PreserveInerhitedACEs = $false,
        [Boolean]$RemoveExplicitACEs = $False
    )

    # If ACL isn't provided
    If (![Boolean]$ACL) {
        # Appends AD:\ if a distinguishedname is provided
        If ($Path -like '*,DC=*,DC=*' -and $Path -notlike 'AD:\*') {
            $Path = "AD:\$Path"
        }
        # Get ACL
        $ACL = Get-Acl -Path $Path
    }

    # If the ACL Inheritance doesn't match desired set it
    If ($ACL.AreAuditRulesProtected -ne !$Inherit) {
        # Set Inheritance
        $ACL.SetAccessRuleProtection(!$Inherit, $PreserveInerhitedACEs)
    }
    Else {
        Return "Inheritance already set to $(!$Inherit)"
    }
    
    # Remove Explicit ACEs if you're going to inherited permissions
    If ($Inherit -and $RemoveExplicitACEs) {
        Foreach ($ACE in $ACL.Access) {
            If (-not $ACE.IsInherited) {
                [Void] $ACL.RemoveAccessRule($ACE)
            }
        }
    }

    # Set ACL
    Set-Acl -Path $Path -AclObject $ACL
}