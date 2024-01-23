Function Get-ADRights {
    <#
        .NOTES
            Created By: Kyle Hewitt
            Created On: 4/30/20
            Version: 2020.04.30
            
        .DESCRIPTION
            Get all the AD rights that are assignable in AD.
    #>
    Param(
        $Domain = $env:USERDNSDOMAIN
    )
    Begin {
        Import-Module ActiveDirectory -ErrorAction Stop
        $Root = "DC=$($Domain.Replace('.',',DC='))"
    }
    Process {
        $GUIDs = @()
        Get-ADObject -SearchBase "CN=Configuration,$Root" -LDAPFilter '(&(objectclass=controlAccessRight)(rightsguid=*))' -Properties RightsGuid, DisplayName -Server $Domain | 
            ForEach-Object {
                $Guids += [pscustomobject]@{
                    Name = $_.Name
                    GUID = [GUID]$_.RightsGuid
                }
            }
        Get-ADObject -SearchBase "CN=Schema,CN=Configuration,$Root" -LDAPFilter '(schemaidguid=*)' -Properties LdapDisplayName, SchemaIdGuid -Server $Domain | 
            ForEach-Object {
                $Guids += [pscustomobject]@{
                    Name = $_.LdapDisplayName
                    GUID = [GUID]$_.SchemaIdGuid
                }
            } 
        $GUIDs | 
            Sort-Object -Property Name
    }
}
