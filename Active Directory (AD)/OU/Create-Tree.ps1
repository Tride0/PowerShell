
Function Create-Tree {
    <#
        .NOTES
            Created By: Kyle Hewitt
            Created On: 08-05-2020
            Version: 2020.08.05

        .DESCRIPTION
            This function will create a OU tree based on specified DN
    #>
    Param([String[]]$OUs)
    Begin {
        Import-Module ActiveDirectory -ErrorAction Stop
        Function Split-OU {
            Param($DN)
            $SplitDN = $DN.split(',')
            Return @{
                OU        = $DN
                Parent    = $SplitDN[1..($SplitDN.Count - 1)] -join ','
                ChildName = $SplitDN[0].Split('=')[1]
            }
        }
    }
    Process {
        Foreach ($OU in $OUs) {
            $OUInfo = Split-OU -DN $OU
            
            # If the Parent OU doesn't exist, create it first.
            If (![DirectoryServices.DirectoryEntry]::Exists("LDAP://$($OUInfo.Parent)")) {
                Create-OUs -OUs $OUInfo.Parent
            }

            Try {
                New-ADOrganizationalUnit -Path $OUInfo.Parent -Name $OUInfo.ChildName -ProtectedFromAccidentalDeletion $True -ErrorAction Stop
                Write-Host "Created: '$OU'." -ForegroundColor Green
            }
            Catch {
                Write-Host "Failed to Create '$OU'. Error: $_" -ForegroundColor Red
                Continue
            }
        }
    }
}