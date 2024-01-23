Function Get-CustomSchemaAttributes {
    Param(
        $Domain = $env:USERDNSDOMAIN
    )
    Begin {
        Import-Module ActiveDirectory -ErrorAction Stop
    }
    Process {
        Get-ADObject -SearchBase "CN=Schema,CN=Configuration,DC=$($Domain.replace('.',',DC='))" -Filter { ObjectClass -eq 'attributeSchema' } -Properties * -Server $Domain |
            Select-Object -Property Name, lDAPDisplayName, isSingleValued, attributeID, objectGUID, 
            @{Name = 'WhenCreated'; Expression = { ($_.WhenCreated).Date.ToString('yyyy-MM-dd') } }, 
            @{Name = 'WhenChanged'; Expression = { ($_.WhenChanged).Date.ToString('yyyy-MM-dd') } }, 
            @{Name         = 'AttributeType'
                Expression = {
                    $oMSyntax = $_.oMSyntax
                    $OMObjectClass = $_.OMObjectClass -join '.'
                    Switch ($_.attributeSyntax) {
                        '2.5.5.1' { 'Distinguished_Name' }
                        '2.5.5.2' { 'Object_Identifier' }
                        '2.5.5.3' { 'Case_Sensitive_String' }
                        '2.5.5.4' { 'Case_Insensitive_String' }
                        '2.5.5.5' {
                            If ($oMSyntax -eq '22') { 'IA5_string' }
                            ElseIf ($oMSyntax -eq '19') { 'Print_Case_String' }
                        }
                        '2.5.5.6' { 'Numerical_String' }
                        '2.5.5.7' {
                            If ($OMObjectClass -like '*1.1.1.11') { 'DN_Binary' }
                            ElseIf ($OMObjectClass -like '*1.2.5.11.29') { 'OR_Name' }
                        }
                        '2.5.5.8' { 'Boolean' }
                        '2.5.5.9' {
                            If ($oMSyntax -eq '2') { 'Integer' }
                            ElseIf ($oMSyntax -eq '10') { 'Enumeration' }
                        }
                        '2.5.5.10' {
                            If ($oMSyntax -eq '4') { 'Octet_String' }
                            ElseIf ($oMSyntax -eq '127') { 'Replica_Link' }
                        }
                        '2.5.5.11' {
                            If ($oMSyntax -eq '23') { 'UTC_Coded_Time' }
                            ElseIf ($oMSyntax -eq '24') { 'Generalized_Time' }
                        }
                        '2.5.5.12' { 'Unicode_String' } 
                        '2.5.5.13' { 'Presentation_Address' }
                        '2.5.5.14' { 'Distinguished_Name_With_String' }
                        '2.5.5.15' { 'NT_Security_Desccriptor' }
                        '2.5.5.16' { 'Large_Integer/Interval' }
                        '2.5.5.17' { 'SID' }
                    }
                }
            }, AttributeSyntax, oMSyntax
    }
}