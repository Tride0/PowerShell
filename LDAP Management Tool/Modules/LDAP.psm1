<#
     Created By: Kyle Hewitt & Gemini
     Created On: 2025-08-10
        Version: 2025.08.10
    Description: This module provides functions to interact with LDAP servers using System.DirectoryServices.Protocols over LDAPS.
#>

function _GetLdapConnection {
    <#
    .SYNOPSIS
    Establishes and returns a bound LdapConnection object over LDAPS.

    .DESCRIPTION
    This is a private helper function used by other functions in this module.
    It handles the secure connection setup, credential conversion, and binding to the LDAP server.
    If Username and Password are not provided, it attempts to use the current logged-in user's
    credentials (Default Network Credentials), which is common for Integrated Windows Authentication
    with Active Directory.

    .PARAMETER LdapServer
    The hostname or IP address of the LDAP server to connect to.

    .PARAMETER Port
    The TCP port for the LDAPS connection.

    .PARAMETER Username
    (Optional) The username for binding to the LDAP server. If not provided,
    Default Network Credentials will be attempted.

    .PARAMETER Password
    (Optional) The password for the binding user as a SecureString. Only required if Username is provided.

    .PARAMETER LdapTimeout
    (Optional) The timeout for LDAP operations in milliseconds. Defaults to 30000 (30 seconds).

    .OUTPUTS
    System.DirectoryServices.Protocols.LdapConnection. A bound LDAP connection object.
    #>
    [CmdletBinding(SupportsShouldProcess = $false)] # No ShouldProcess for private helper
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$LdapServer,

        [Parameter(Mandatory = $true)]
        [int]$Port = 389,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$Username,

        [Parameter(Mandatory = $false)]
        [System.Security.SecureString]$Password,

        [Parameter(Mandatory = $false)]
        [int]$LdapTimeout = 30000, # Default to 30 seconds

        [parameter(Mandatory = $false)]
        [bool]$SecureSocketLayer = $true,

        [parameter(Mandatory = $false)]
        [int]$LdapVersion = 3
    )

    $plainPassword = $null # Initialize to null
    $ldapConnection = $null # Initialize to null

    try {
        $ldapConnection = New-Object System.DirectoryServices.Protocols.LdapConnection(
            $LdapServer, $Port
        )

        $ldapConnection.SessionOptions.SecureSocketLayer = $SecureSocketLayer
        $ldapConnection.SessionOptions.ProtocolVersion = $LdapVersion
        $ldapConnection.Timeout = [System.TimeSpan]::FromMilliseconds($LdapTimeout) # Set timeout

        if (![string]::IsNullOrEmpty($Username)) {
            # Explicit credentials provided
            if (-not $Password) {
                Write-Error 'Password is mandatory when Username is provided.'
                throw 'Password not provided.'
            }
            $plainPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
                [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password)
            )
            $credentials = New-Object System.Net.NetworkCredential($Username, $plainPassword)
            $ldapConnection.Credential = $credentials
            Write-Verbose "Attempting to bind to LDAP server ${LdapServer}:${Port} as ${Username} (explicit credentials)..."
        }
        else {
            # No explicit username/password provided, attempt current Windows user credentials
            $ldapConnection.Credential = [System.Net.CredentialCache]::DefaultNetworkCredentials
            Write-Verbose "Attempting to bind to LDAP server ${LdapServer}:${Port} using default network credentials (current logged-in user)..."
        }

        $ldapConnection.Bind()
        Write-Verbose 'Successfully bound to LDAP server.'

        return $ldapConnection

    }
    catch {
        Write-Error "An unexpected connection error occurred: $($_.Exception.Message)"
        throw $_ # Re-throw to propagate the
    }
    finally {
        # Securely clear the plain text password from memory only if it was ever created
        if ($plainPassword) {
            [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR(
                [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password)
            )
            $plainPassword = $null # Ensure variable is cleared
        }
    }
}

function Send-LdapQuery {
    <#
    .SYNOPSIS
    Sends an LDAP query to a specified LDAP server using System.DirectoryServices.Protocols over LDAPS, with paging support.

    .DESCRIPTION
    This function connects to an LDAP server (typically Active Directory) using the LDAPS protocol (port 636)
    and performs a search operation based on the provided parameters. It now includes **paging** to handle
    large result sets efficiently, avoiding LDAP size limits. It returns all found LDAP entries
    with specified attributes. It's designed for efficiency when dealing with large datasets or
    when the built-in Active Directory module is not available or suitable.

    .PARAMETER LdapServer
    The hostname or IP address of the LDAP server to connect to. This server must be configured for LDAPS.

    .PARAMETER Port
    The TCP port for the LDAPS connection. The default is 636.

    .PARAMETER SearchBase
    The distinguished name (DN) of the starting point for your search. Examples: "DC=yourdomain,DC=com" or "OU=Users,DC=yourdomain,DC=com".

    .PARAMETER SearchFilter
    The LDAP filter string to apply for the search. Examples: "(sAMAccountName=johndoe)", "(&(objectClass=user)(mail=*))".

    .PARAMETER PropertiesToLoad
    An array of strings specifying the attributes to retrieve for each matching entry.
    If not specified, a default set (sAMAccountName, distinguishedName, mail, displayName) will be retrieved.

    .PARAMETER PageSize
    (Optional) The number of entries to retrieve per page during a paged search.
    A value of 0 or $null disables paging (retrieves all results in one go, subject to server limits).
    Defaults to 1000.

    .PARAMETER LdapTimeout
    (Optional) The timeout for LDAP operations in milliseconds. Overrides the default timeout for this specific query.

    .PARAMETER Username
    (Optional) The username for binding to the LDAP server. If not provided,
    the current logged-in user's credentials will be attempted.

    .PARAMETER Password
    (Optional) The password for the binding user. Only required if Username is provided.

    .EXAMPLE
    # Search for all users in an OU with paging, using current logged-in user's credentials
    Send-LdapQuery -LdapServer "dc01.contoso.com" `
                   -Port 636 `
                   -SearchBase "OU=Employees,DC=contoso,DC=com" `
                   -SearchFilter "(objectClass=person)" `
                   -PropertiesToLoad @("givenName", "sn", "telephoneNumber") `
                   -PageSize 500 # Retrieve 500 entries per page

    .EXAMPLE
    # Search for a user using explicit credentials (no paging, single request)
    $SecurePassword = ConvertTo-SecureString "YourPassword123" -AsPlainText -Force
    Send-LdapQuery -LdapServer "dc01.contoso.com" `
                   -Port 636 `
                   -SearchBase "DC=contoso,DC=com" `
                   -SearchFilter "(sAMAccountName=johndoe)" `
                   -Username "serviceaccount@contoso.com" `
                   -Password $SecurePassword `
                   -PageSize 0 # Disable paging

    .OUTPUTS
    An array of custom objects, each representing an LDAP entry with the requested properties.
    Each property is stored as a string or an array of strings.
    #>
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    [OutputType('System.Management.Automation.PSCustomObject[]')] # Explicit OutputType
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$LdapServer,

        [Parameter(Mandatory = $false)]
        [int]$Port = 636,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$SearchBase,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$SearchFilter,

        [Parameter(Mandatory = $false)]
        [string[]]$PropertiesToLoad = @('sAMAccountName', 'distinguishedName', 'mail', 'displayName'),

        [Parameter(Mandatory = $false)]
        [int]$PageSize = 1000, # Default page size for paged results

        [Parameter(Mandatory = $false)]
        [int]$LdapTimeout, # Optional override for connection timeout

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$Username,

        [Parameter(Mandatory = $false)]
        [System.Security.SecureString]$Password
    )

    $ldapConnection = $null
    $allResults = @()
    $cookie = $null

    try {
        $connectParams = @{
            LdapServer = $LdapServer
            Port       = $Port
            Username   = $Username
            Password   = $Password
        }
        if ($PSBoundParameters.ContainsKey('LdapTimeout')) {
            $connectParams.LdapTimeout = $LdapTimeout
        }
        $ldapConnection = _GetLdapConnection @connectParams

        # Create a SearchRequest
        $searchRequest = New-Object System.DirectoryServices.Protocols.SearchRequest(
            $SearchBase,
            $SearchFilter,
            [System.DirectoryServices.Protocols.SearchScope]::Subtree,
            $PropertiesToLoad
        )

        do {
            # Add paging control if PageSize is greater than 0
            if ($PageSize -gt 0) {
                $pageControl = New-Object System.DirectoryServices.Protocols.PageResultRequestControl($PageSize, $cookie)
                $searchRequest.Controls.Add($pageControl)
            }

            Write-Verbose "Sending search request with filter '$SearchFilter' under base '$SearchBase' (PageSize: $PageSize)..."
            $searchResponse = $ldapConnection.SendRequest($searchRequest)

            # Process response controls
            foreach ($control in $searchResponse.Controls) {
                if ($control -is [System.DirectoryServices.Protocols.PageResultResponseControl]) {
                    $cookie = $control.Cookie
                    # Remove the old paging control before next request
                    $searchRequest.Controls.Remove($pageControl)
                }
            }

            if ($searchResponse.Entries.Count -gt 0) {
                Write-Verbose "Found $($searchResponse.Entries.Count) entries on this page."
                foreach ($entry in $searchResponse.Entries) {
                    $obj = [PSCustomObject]@{
                        DistinguishedName = $entry.DistinguishedName
                    }

                    # Dynamically add attributes to the custom object
                    foreach ($attr in $PropertiesToLoad) {
                        if ($entry.Attributes[$attr]) {
                            $values = $entry.Attributes[$attr].GetValues([string])
                            if ($values.Length -eq 1) {
                                $obj | Add-Member -MemberType NoteProperty -Name $attr -Value $values[0] -Force
                            }
                            else {
                                $obj | Add-Member -MemberType NoteProperty -Name $attr -Value $values -Force
                            }
                        }
                        else {
                            # Add a null or empty string if attribute not found for consistency
                            $obj | Add-Member -MemberType NoteProperty -Name $attr -Value $null -Force
                        }
                    }
                    $allResults += $obj
                }
            }
            else {
                Write-Verbose 'No entries found on this page or end of results reached.'
            }

        } while ($PageSize -gt 0 -and $null -ne $cookie -and $cookie.Length -gt 0) # Continue if paging is enabled and there's a cookie

        if ($allResults.Count -gt 0) {
            Write-Host "Total entries found: $($allResults.Count)."
        }
        else {
            Write-Warning "No entries found matching filter '$SearchFilter' in '$SearchBase'."
        }

        return $allResults

    }
    catch {
        # Error is already handled/propagated by _GetLdapConnection or by the specific request
        Write-Error "Error performing LDAP query: $($_.Exception.Message)"
        throw $_
    }
    finally {
        if ($ldapConnection) {
            $ldapConnection.Dispose()
            Write-Verbose 'LDAP connection disposed.'
        }
    }
}

function Get-LdapObject {
    <#
    .SYNOPSIS
    Retrieves a single LDAP object by its Distinguished Name (DN).

    .DESCRIPTION
    This function provides a direct way to fetch an LDAP entry when its full
    Distinguished Name (DN) is known. It performs a base-level search
    to retrieve the specified object and its attributes.

    .PARAMETER LdapServer
    The hostname or IP address of the LDAP server to connect to. This server must be configured for LDAPS.

    .PARAMETER Port
    The TCP port for the LDAPS connection. The default is 636.

    .PARAMETER ObjectDn
    The full Distinguished Name (DN) of the object to retrieve.
    Example: "CN=John Doe,OU=Users,DC=yourdomain,DC=com"

    .PARAMETER PropertiesToLoad
    An array of strings specifying the attributes to retrieve for the object.
    If not specified, all available attributes will be retrieved (using "*").

    .PARAMETER LdapTimeout
    (Optional) The timeout for LDAP operations in milliseconds. Overrides the default timeout for this specific query.

    .PARAMETER Username
    (Optional) The username for binding to the LDAP server. If not provided,
    the current logged-in user's credentials will be attempted.

    .PARAMETER Password
    (Optional) The password for the binding user. Only required if Username is provided.

    .OUTPUTS
    A custom object representing the LDAP entry, or $null if not found.

    .EXAMPLE
    # Get user properties using explicit credentials
    $SecurePassword = ConvertTo-SecureString "YourPassword123" -AsPlainText -Force
    Get-LdapObject -LdapServer "dc01.contoso.com" `
                   -Port 636 `
                   -ObjectDn "CN=John Doe,OU=Users,DC=contoso,DC=com" `
                   -PropertiesToLoad @("givenName", "sn", "mail") `
                   -Username "serviceaccount@contoso.com" `
                   -Password $SecurePassword

    .EXAMPLE
    # Get all properties of an Organizational Unit using current logged-in user's credentials
    Get-LdapObject -LdapServer "dc01.contoso.com" `
                   -ObjectDn "OU=Finance,DC=contoso,DC=com"
    #>
    [CmdletBinding(DefaultParameterSetName = 'Default', SupportsShouldProcess = $false)]
    [OutputType('System.Management.Automation.PSCustomObject')] # Explicit OutputType
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$LdapServer,

        [Parameter(Mandatory = $false)]
        [int]$Port = 636,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ObjectDn,

        [Parameter(Mandatory = $false)]
        [string[]]$PropertiesToLoad = @('*'), # Default to all attributes for a single object

        [Parameter(Mandatory = $false)]
        [int]$LdapTimeout, # Optional override for connection timeout

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$Username,

        [Parameter(Mandatory = $false)]
        [System.Security.SecureString]$Password
    )

    $ldapConnection = $null
    try {
        $connectParams = @{
            LdapServer = $LdapServer
            Port       = $Port
            Username   = $Username
            Password   = $Password
        }
        if ($PSBoundParameters.ContainsKey('LdapTimeout')) {
            $connectParams.LdapTimeout = $LdapTimeout
        }
        $ldapConnection = _GetLdapConnection @connectParams

        # Create a SearchRequest with base scope to retrieve a single object
        $searchRequest = New-Object System.DirectoryServices.Protocols.SearchRequest(
            $ObjectDn, # SearchBase is the specific object's DN
            '(objectClass=*)', # Simple filter to retrieve any object
            [System.DirectoryServices.Protocols.SearchScope]::Base, # Only search the base object
            $PropertiesToLoad
        )

        Write-Verbose "Retrieving object '$ObjectDn'..."
        $searchResponse = $ldapConnection.SendRequest($searchRequest)

        if ($searchResponse.Entries.Count -eq 1) {
            $entry = $searchResponse.Entries[0]
            $obj = [PSCustomObject]@{
                DistinguishedName = $entry.DistinguishedName
            }
            foreach ($attr in $PropertiesToLoad) {
                if ($entry.Attributes[$attr]) {
                    $values = $entry.Attributes[$attr].GetValues([string])
                    if ($values.Length -eq 1) {
                        $obj | Add-Member -MemberType NoteProperty -Name $attr -Value $values[0] -Force
                    }
                    else {
                        $obj | Add-Member -MemberType NoteProperty -Name $attr -Value $values -Force
                    }
                }
                else {
                    $obj | Add-Member -MemberType NoteProperty -Name $attr -Value $null -Force
                }
            }
            Write-Host "Object '$ObjectDn' retrieved successfully."
            return $obj
        }
        elseif ($searchResponse.Entries.Count -gt 1) {
            Write-Warning "Multiple objects found for DN '$ObjectDn' with base search. This should not happen. Returning first one."
            # Still process the first entry as a fallback, though this indicates an issue with the provided DN
            $entry = $searchResponse.Entries[0]
            $obj = [PSCustomObject]@{
                DistinguishedName = $entry.DistinguishedName
            }
            foreach ($attr in $PropertiesToLoad) {
                if ($entry.Attributes[$attr]) {
                    $values = $entry.Attributes[$attr].GetValues([string])
                    if ($values.Length -eq 1) {
                        $obj | Add-Member -MemberType NoteProperty -Name $attr -Value $values[0] -Force
                    }
                    else {
                        $obj | Add-Member -MemberType NoteProperty -Name $attr -Value $values -Force
                    }
                }
                else {
                    $obj | Add-Member -MemberType NoteProperty -Name $attr -Value $null -Force
                }
                $obj | Add-Member -MemberType NoteProperty -Name $attr -Value $null -Force
            }
            return $obj
        }
        else {
            Write-Warning "Object '$ObjectDn' not found."
            return $null
        }

    }
    catch {
        Write-Error "Error retrieving LDAP object '$ObjectDn': $($_.Exception.Message)"
        throw $_
    }
    finally {
        if ($ldapConnection) {
            $ldapConnection.Dispose()
            Write-Verbose 'LDAP connection disposed.'
        }
    }
}

function New-LdapObject {
    <#
    .SYNOPSIS
    Creates a new LDAP object in the specified directory.

    .DESCRIPTION
    This function connects to an LDAP server over LDAPS and adds a new entry with the provided
    Distinguished Name (DN), object classes, and attributes.

    .PARAMETER LdapServer
    The hostname or IP address of the LDAP server to connect to.

    .PARAMETER Port
    The TCP port for the LDAPS connection. The default is 636.

    .PARAMETER NewObjectDn
    The full Distinguished Name (DN) of the new object to create.
    Example: "CN=John Doe,OU=Users,DC=yourdomain,DC=com"

    .PARAMETER ObjectClass
    An array of strings specifying the objectClass(es) for the new entry.
    Common examples: "user", "organizationalPerson", "computer", "organizationalUnit".

    .PARAMETER Attributes
    A hashtable where keys are attribute names (strings) and values are the attribute values.
    Values can be single strings, arrays of strings, or byte arrays for binary data.
    Example: @{sAMAccountName = "johndoe"; givenName = "John"; sn = "Doe"; displayName = "John Doe"}

    .PARAMETER LdapTimeout
    (Optional) The timeout for LDAP operations in milliseconds. Overrides the default timeout for this specific operation.

    .PARAMETER Username
    (Optional) The username for binding to the LDAP server. If not provided,
    the current logged-in user's credentials will be attempted.

    .PARAMETER Password
    (Optional) The password for the binding user. Only required if Username is provided.

    .OUTPUTS
    System.Boolean. Returns $true if the object was created successfully, $false otherwise.

    .EXAMPLE
    # Create a new user account using explicit credentials
    $SecurePassword = ConvertTo-SecureString "P@ssw0rd!123" -AsPlainText -Force
    New-LdapObject -LdapServer "dc01.contoso.com" `
                   -Port 636 `
                   -NewObjectDn "CN=New User,OU=TestOU,DC=contoso,DC=com" `
                   -ObjectClass @("user", "organizationalPerson") `
                   -Attributes @{
                       sAMAccountName = "newuser"
                       givenName = "New"
                       sn = "User"
                       displayName = "New User"
                       userPrincipalName = "newuser@contoso.com"
                       # For Active Directory, password needs to be set with a specific modification
                       # and potentially later enabled via a separate modify operation.
                       # This example does NOT set the userPassword directly here.
                       # For setting password securely in AD, you'd typically use a ModifyRequest
                       # with a specific attribute like 'unicodePwd' and convert the password
                       # to a byte array. This is a more advanced topic.
                   } `
                   -Username "serviceaccount@contoso.com" `
                   -Password $SecurePassword

    .EXAMPLE
    # Create a new Organizational Unit (OU) using current logged-in user's credentials
    New-LdapObject -LdapServer "dc01.contoso.com" `
                   -Port 636 `
                   -NewObjectDn "OU=NewDepartment,DC=contoso,DC=com" `
                   -ObjectClass "organizationalUnit" `
                   -Attributes @{ description = "A new department for testing" }
    #>
    [CmdletBinding(DefaultParameterSetName = 'Default', SupportsShouldProcess = $true)]
    [OutputType('System.Boolean')] # Explicit OutputType
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$LdapServer,

        [Parameter(Mandatory = $false)]
        [int]$Port = 636,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$NewObjectDn,

        [Parameter(Mandatory = $true)]
        [string[]]$ObjectClass,

        [Parameter(Mandatory = $false)]
        [hashtable]$Attributes, # Use hashtable for flexible attributes

        [Parameter(Mandatory = $false)]
        [int]$LdapTimeout, # Optional override for connection timeout

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$Username,

        [Parameter(Mandatory = $false)]
        [System.Security.SecureString]$Password
    )

    if ($PSCmdlet.ShouldProcess($NewObjectDn, 'Create LDAP Object')) {
        $ldapConnection = $null
        try {
            $connectParams = @{
                LdapServer = $LdapServer
                Port       = $Port
                Username   = $Username
                Password   = $Password
            }
            if ($PSBoundParameters.ContainsKey('LdapTimeout')) {
                $connectParams.LdapTimeout = $LdapTimeout
            }
            $ldapConnection = _GetLdapConnection @connectParams

            # Create an AddRequest
            $addRequest = New-Object System.DirectoryServices.Protocols.AddRequest($NewObjectDn)

            # Add ObjectClass attributes
            foreach ($oc in $ObjectClass) {
                $addRequest.Attributes.Add((New-Object System.DirectoryServices.Protocols.DirectoryAttribute('objectClass', $oc)))
            }

            # Add other specified attributes
            if ($Attributes) {
                foreach ($key in $Attributes.Keys) {
                    $value = $Attributes[$key]
                    if ($value -is [byte[]]) {
                        # For binary attributes
                        $addRequest.Attributes.Add((New-Object System.DirectoryServices.Protocols.DirectoryAttribute($key, $value)))
                    }
                    elseif ($value -is [System.Collections.IEnumerable] -and $value -isnot [string] -and $value -isnot [byte[]]) {
                        # For multi-valued attributes (ensure not to treat strings or byte arrays as enumerable collections of chars/bytes)
                        $addRequest.Attributes.Add((New-Object System.DirectoryServices.Protocols.DirectoryAttribute($key, $value)))
                    }
                    else {
                        # For single-valued string attributes
                        $addRequest.Attributes.Add((New-Object System.DirectoryServices.Protocols.DirectoryAttribute($key, "$value")))
                    }
                }
            }

            Write-Verbose "Sending AddRequest for '$NewObjectDn'..."
            $addResponse = $ldapConnection.SendRequest($addRequest)

            if ($addResponse.ResultCode -eq [System.DirectoryServices.Protocols.ResultCode]::Success) {
                Write-Host "LDAP object '$NewObjectDn' created successfully."
                return $true
            }
            else {
                Write-Error "Failed to create LDAP object '$NewObjectDn'. Result Code: $($addResponse.ResultCode) - Error Message: $($addResponse.ErrorMessage)"
                return $false
            }

        }
        catch {
            Write-Error "Error creating LDAP object '$NewObjectDn': $($_.Exception.Message)"
            throw $_
        }
        finally {
            if ($ldapConnection) {
                $ldapConnection.Dispose()
                Write-Verbose 'LDAP connection disposed.'
            }
        }
    }
    return $false # If ShouldProcess didn't confirm or an error occurred
}

function Remove-LdapObject {
    <#
    .SYNOPSIS
    Deletes an LDAP object from the directory.

    .DESCRIPTION
    This function connects to an LDAP server over LDAPS and removes an entry
    specified by its Distinguished Name (DN).

    .PARAMETER LdapServer
    The hostname or IP address of the LDAP server to connect to.

    .PARAMETER Port
    The TCP port for the LDAPS connection. The default is 636.

    .PARAMETER ObjectDn
    The full Distinguished Name (DN) of the object to delete.
    Example: "CN=Old User,OU=Users,DC=yourdomain,DC=com"

    .PARAMETER LdapTimeout
    (Optional) The timeout for LDAP operations in milliseconds. Overrides the default timeout for this specific operation.

    .PARAMETER Username
    (Optional) The username for binding to the LDAP server. If not provided,
    the current logged-in user's credentials will be attempted.

    .PARAMETER Password
    (Optional) The password for the binding user. Only required if Username is provided.

    .OUTPUTS
    System.Boolean. Returns $true if the object was deleted successfully, $false otherwise.

    .EXAMPLE
    # Delete a user account using explicit credentials
    $SecurePassword = ConvertTo-SecureString "P@ssw0rd!123" -AsPlainText -Force
    Remove-LdapObject -LdapServer "dc01.contoso.com" `
                      -Port 636 `
                      -ObjectDn "CN=Old User,OU=TestOU,DC=contoso,DC=com" `
                      -Username "serviceaccount@contoso.com" `
                      -Password $SecurePassword

    .EXAMPLE
    # Delete an object using current logged-in user's credentials
    Remove-LdapObject -LdapServer "dc01.contoso.com" `
                      -Port 636 `
                      -ObjectDn "CN=Temporary Object,OU=TestOU,DC=contoso,DC=com"
    #>
    [CmdletBinding(DefaultParameterSetName = 'Default', SupportsShouldProcess = $true)]
    [OutputType('System.Boolean')] # Explicit OutputType
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$LdapServer,

        [Parameter(Mandatory = $false)]
        [int]$Port = 636,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ObjectDn,

        [Parameter(Mandatory = $false)]
        [int]$LdapTimeout, # Optional override for connection timeout

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$Username,

        [Parameter(Mandatory = $false)]
        [System.Security.SecureString]$Password
    )

    if ($PSCmdlet.ShouldProcess($ObjectDn, 'Delete LDAP Object')) {
        $ldapConnection = $null
        try {
            $connectParams = @{
                LdapServer = $LdapServer
                Port       = $Port
                Username   = $Username
                Password   = $Password
            }
            if ($PSBoundParameters.ContainsKey('LdapTimeout')) {
                $connectParams.LdapTimeout = $LdapTimeout
            }
            $ldapConnection = _GetLdapConnection @connectParams

            # Create a DeleteRequest
            $deleteRequest = New-Object System.DirectoryServices.Protocols.DeleteRequest($ObjectDn)

            Write-Verbose "Sending DeleteRequest for '$ObjectDn'..."
            $deleteResponse = $ldapConnection.SendRequest($deleteRequest)

            if ($deleteResponse.ResultCode -eq [System.DirectoryServices.Protocols.ResultCode]::Success) {
                Write-Host "LDAP object '$ObjectDn' deleted successfully."
                return $true
            }
            else {
                Write-Error "Failed to delete LDAP object '$ObjectDn'. Result Code: $($deleteResponse.ResultCode) - Error Message: $($deleteResponse.ErrorMessage)"
                return $false
            }

        }
        catch {
            Write-Error "Error deleting LDAP object '$ObjectDn': $($_.Exception.Message)"
            throw $_
        }
        finally {
            if ($ldapConnection) {
                $ldapConnection.Dispose()
                Write-Verbose 'LDAP connection disposed.'
            }
        }
    }
    return $false
}

function Set-LdapObject {
    <#
    .SYNOPSIS
    Modifies an existing LDAP object's attributes with explicit add, replace, remove, or clear operations.

    .DESCRIPTION
    This function connects to an LDAP server over LDAPS and modifies attributes
    of an existing LDAP entry specified by its Distinguished Name (DN).
    It supports adding new attribute values, replacing existing values, removing specific values,
    or completely clearing (deleting) attributes.

    .PARAMETER LdapServer
    The hostname or IP address of the LDAP server to connect to.

    .PARAMETER Port
    The TCP port for the LDAPS connection. The default is 636.

    .PARAMETER ObjectDn
    The full Distinguished Name (DN) of the object to modify.

    .PARAMETER Add
    A hashtable where keys are attribute names (strings) and values are the attribute values
    to add. Values can be single strings, arrays of strings, or byte arrays for binary data.
    If the attribute already exists, the values are appended. If not, the attribute is created.

    .PARAMETER Replace
    A hashtable where keys are attribute names (strings) and values are the attribute values
    to replace existing ones. Values can be single strings, arrays of strings, or byte arrays.
    All existing values for the specified attributes will be removed and replaced with these new values.

    .PARAMETER Remove
    A hashtable where keys are attribute names (strings) and values are the specific attribute values
    to remove. Values can be single strings, arrays of strings, or byte arrays.
    Only the specified values will be removed; other values for the attribute will remain.

    .PARAMETER ClearAttribute
    An array of strings specifying the names of attributes to completely remove (clear all values)
    from the LDAP object.

    .PARAMETER LdapTimeout
    (Optional) The timeout for LDAP operations in milliseconds. Overrides the default timeout for this specific operation.

    .PARAMETER Username
    (Optional) The username for binding to the LDAP server. If not provided,
    the current logged-in user's credentials will be attempted.

    .PARAMETER Password
    (Optional) The password for the binding user. Only required if Username is provided.

    .OUTPUTS
    System.Boolean. Returns $true if the object was modified successfully, $false otherwise.

    .EXAMPLE
    # Add a new phone number to a user using explicit credentials
    $SecurePassword = ConvertTo-SecureString "P@ssw0rd!123" -AsPlainText -Force
    Set-LdapObject -LdapServer "dc01.contoso.com" `
                   -Port 636 `
                   -ObjectDn "CN=John Doe,OU=Users,DC=contoso,DC=com" `
                   -Add @{ telephoneNumber = "555-999-1111" } `
                   -Username "serviceaccount@contoso.com" `
                   -Password $SecurePassword

    .EXAMPLE
    # Replace a user's description and add another email address using current logged-in user's credentials
    Set-LdapObject -LdapServer "dc01.contoso.com" `
                   -Port 636 `
                   -ObjectDn "CN=John Doe,OU=Users,DC=contoso,DC=com" `
                   -Replace @{ description = "Manager of West Coast Sales" } `
                   -Add @{ proxyAddresses = "SMTP:john.doe@contoso.com" }
    #>
    [CmdletBinding(DefaultParameterSetName = 'Default', SupportsShouldProcess = $true)]
    [OutputType('System.Boolean')] # Explicit OutputType
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$LdapServer,

        [Parameter(Mandatory = $false)]
        [int]$Port = 636,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ObjectDn,

        [Parameter(Mandatory = $false)]
        [hashtable]$Add,

        [Parameter(Mandatory = $false)]
        [hashtable]$Replace,

        [Parameter(Mandatory = $false)]
        [hashtable]$Remove,

        [Parameter(Mandatory = $false)]
        [string[]]$ClearAttribute,

        [Parameter(Mandatory = $false)]
        [int]$LdapTimeout, # Optional override for connection timeout

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$Username,

        [Parameter(Mandatory = $false)]
        [System.Security.SecureString]$Password
    )

    if ($PSCmdlet.ShouldProcess($ObjectDn, 'Modify LDAP Object Attributes')) {
        $ldapConnection = $null
        try {
            $connectParams = @{
                LdapServer = $LdapServer
                Port       = $Port
                Username   = $Username
                Password   = $Password
            }
            if ($PSBoundParameters.ContainsKey('LdapTimeout')) {
                $connectParams.LdapTimeout = $LdapTimeout
            }
            $ldapConnection = _GetLdapConnection @connectParams

            # Create a ModifyRequest
            $modifyRequest = New-Object System.DirectoryServices.Protocols.ModifyRequest($ObjectDn)


            if ($Add) {
                foreach ($attrName in $Add.Keys) {
                    $valuesToAdd = $Add[$attrName]
                    $directoryAttributeModification = New-Object System.DirectoryServices.Protocols.DirectoryAttributeModification
                    $directoryAttributeModification.Name = $attrName
                    $directoryAttributeModification.Operation = [System.DirectoryServices.Protocols.DirectoryAttributeOperation]::Add

                    if ($valuesToAdd -is [System.Collections.IEnumerable] -and $valuesToAdd -isnot [string] -and $valuesToAdd -isnot [byte[]]) {
                        foreach ($val in $valuesToAdd) {
                            if ($val -is [byte[]]) { $directoryAttributeModification.Add($val) }
                            else { $directoryAttributeModification.Add("$val") }
                        }
                    }
                    elseif ($valuesToAdd -is [byte[]]) {
                        $directoryAttributeModification.Add($valuesToAdd)
                    }
                    else {
                        $directoryAttributeModification.Add("$valuesToAdd")
                    }
                    $modifyRequest.Modifications.Add($directoryAttributeModification)
                }
            }


            if ($Replace) {
                foreach ($attrName in $Replace.Keys) {
                    $valuesToReplace = $Replace[$attrName]
                    $directoryAttributeModification = New-Object System.DirectoryServices.Protocols.DirectoryAttributeModification
                    $directoryAttributeModification.Name = $attrName
                    $directoryAttributeModification.Operation = [System.DirectoryServices.Protocols.DirectoryAttributeOperation]::Replace

                    if ($valuesToReplace -is [System.Collections.IEnumerable] -and $valuesToReplace -isnot [string] -and $valuesToReplace -isnot [byte[]]) {
                        foreach ($val in $valuesToReplace) {
                            if ($val -is [byte[]]) { $directoryAttributeModification.Add($val) }
                            else { $directoryAttributeModification.Add("$val") }
                        }
                    }
                    elseif ($valuesToReplace -is [byte[]]) {
                        $directoryAttributeModification.Add($valuesToReplace)
                    }
                    else {
                        $directoryAttributeModification.Add("$valuesToReplace")
                    }
                    $modifyRequest.Modifications.Add($directoryAttributeModification)
                }
            }


            if ($Remove) {
                foreach ($attrName in $Remove.Keys) {
                    $valuesToRemove = $Remove[$attrName]
                    if ($null -ne $valuesToRemove) {
                        # Only remove specific values if not null
                        $directoryAttributeModification = New-Object System.DirectoryServices.Protocols.DirectoryAttributeModification
                        $directoryAttributeModification.Name = $attrName
                        $directoryAttributeModification.Operation = [System.DirectoryServices.Protocols.DirectoryAttributeOperation]::Delete # Correct for removing specific values

                        if ($valuesToRemove -is [System.Collections.IEnumerable] -and $valuesToRemove -isnot [string] -and $valuesToRemove -isnot [byte[]]) {
                            foreach ($val in $valuesToRemove) {
                                if ($val -is [byte[]]) { $directoryAttributeModification.Add($val) }
                                else { $directoryAttributeModification.Add("$val") }
                            }
                        }
                        elseif ($valuesToRemove -is [byte[]]) {
                            $directoryAttributeModification.Add($valuesToRemove)
                        }
                        else {
                            $directoryAttributeModification.Add("$valuesToRemove")
                        }
                        $modifyRequest.Modifications.Add($directoryAttributeModification)
                    }
                }
            }


            if ($ClearAttribute) {
                foreach ($attrName in $ClearAttribute) {
                    # To clear an entire attribute, the DirectoryAttributeModification should have
                    # the Delete operation and no values added to it.
                    $directoryAttributeModification = New-Object System.DirectoryServices.Protocols.DirectoryAttributeModification
                    $directoryAttributeModification.Name = $attrName
                    $directoryAttributeModification.Operation = [System.DirectoryServices.Protocols.DirectoryAttributeOperation]::Delete
                    # No values are added to directoryAttributeModification when clearing the entire attribute
                    $modifyRequest.Modifications.Add($directoryAttributeModification)
                }
            }

            # Only send request if there are modifications to apply
            if ($modifyRequest.Modifications.Count -gt 0) {
                Write-Verbose "Sending ModifyRequest for '$ObjectDn'..."
                $modifyResponse = $ldapConnection.SendRequest($modifyRequest)

                if ($modifyResponse.ResultCode -eq [System.DirectoryServices.Protocols.ResultCode]::Success) {
                    Write-Host "LDAP object '$ObjectDn' modified successfully."
                    return $true
                }
                else {
                    Write-Error "Failed to modify LDAP object '$ObjectDn'. Result Code: $($modifyResponse.ResultCode) - Error Message: $($modifyResponse.ErrorMessage)"
                    return $false
                }
            }
            else {
                Write-Warning "No modifications specified for object '$ObjectDn'. No action taken."
                return $true # Considered successful as no action was needed.
            }

        }
        catch {
            Write-Error "Error modifying LDAP object '$ObjectDn': $($_.Exception.Message)"
            throw $_
        }
        finally {
            if ($ldapConnection) {
                $ldapConnection.Dispose()
                Write-Verbose 'LDAP connection disposed.'
            }
        }
    }
    return $false
}

function Get-LdapSchemaAttribute {
    <#
    .SYNOPSIS
    Queries an LDAP server's schema for attribute definitions, optionally filtered by object class.

    .DESCRIPTION
    This function connects to an LDAP server over LDAPS, retrieves the schema naming context,
    and then queries for attribute schema definitions. If an ObjectClass is specified,
    it further filters the attributes to show only those explicitly defined as 'mustContain'
    or 'mayContain' for that object class.

    .PARAMETER LdapServer
    The hostname or IP address of the LDAP server to connect to.

    .PARAMETER Port
    The TCP port for the LDAPS connection. The default is 636.

    .PARAMETER ObjectClass
    (Optional) The ldapDisplayName of a specific objectClass (e.g., "user", "group", "organizationalUnit")
    to filter the returned attributes. Only attributes associated with this object class
    (via 'mustContain' or 'mayContain') will be returned.

    .PARAMETER LdapTimeout
    (Optional) The timeout for LDAP operations in milliseconds. Overrides the default timeout for this specific query.

    .PARAMETER Username
    (Optional) The username for binding to the LDAP server. If not provided,
    the current logged-in user's credentials will be attempted.

    .PARAMETER Password
    (Optional) The password for the binding user. Only required if Username is provided.

    .OUTPUTS
    An array of custom objects, each representing an LDAP attribute definition with properties like
    ldapDisplayName, attributeID, isSingleValued, attributeSyntax.
    #>
    [CmdletBinding(DefaultParameterSetName = 'Default', SupportsShouldProcess = $false)]
    [OutputType('System.Management.Automation.PSCustomObject[]')] # Explicit OutputType
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$LdapServer,

        [Parameter(Mandatory = $false)]
        [int]$Port = 636,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$ObjectClass, # Optional parameter for filtering

        [Parameter(Mandatory = $false)]
        [int]$LdapTimeout, # Optional override for connection timeout

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$Username,

        [Parameter(Mandatory = $false)]
        [System.Security.SecureString]$Password
    )

    $ldapConnection = $null
    try {
        $connectParams = @{
            LdapServer = $LdapServer
            Port       = $Port
            Username   = $Username
            Password   = $Password
        }
        if ($PSBoundParameters.ContainsKey('LdapTimeout')) {
            $connectParams.LdapTimeout = $LdapTimeout
        }
        $ldapConnection = _GetLdapConnection @connectParams

        # 1. Query the RootDSE to get the schemaNamingContext
        Write-Verbose 'Querying RootDSE for schemaNamingContext...'
        $rootDSESearchRequest = New-Object System.DirectoryServices.Protocols.SearchRequest(
            '', # Base DN for RootDSE
            '(objectClass=*)',
            [System.DirectoryServices.Protocols.SearchScope]::Base,
            @('schemaNamingContext')
        )
        $rootDSESearchResponse = $ldapConnection.SendRequest($rootDSESearchRequest)

        $schemaDN = $null
        if ($rootDSESearchResponse.Entries.Count -gt 0) {
            $schemaEntry = $rootDSESearchResponse.Entries[0]
            if ($schemaEntry.Attributes['schemaNamingContext']) {
                $schemaDN = $schemaEntry.Attributes['schemaNamingContext'].GetValues([string])[0]
                Write-Verbose "Schema Naming Context: $schemaDN"
            }
        }

        if (-not $schemaDN) {
            Write-Error 'Could not determine the schemaNamingContext. Cannot query schema attributes.'
            return $null
        }

        # 2. Query the schema for all attribute definitions
        Write-Verbose 'Querying schema for all attributeSchema objects...'
        $attributeSchemaSearchRequest = New-Object System.DirectoryServices.Protocols.SearchRequest(
            $schemaDN,
            '(objectClass=attributeSchema)',
            [System.DirectoryServices.Protocols.SearchScope]::OneLevel, # OneLevel for direct children of schemaNamingContext
            @('ldapDisplayName', 'attributeID', 'isSingleValued', 'attributeSyntax', 'omSyntax', 'rangeLower', 'rangeUpper', 'description')
        )
        $allAttributeSchemasResponse = $ldapConnection.SendRequest($attributeSchemaSearchRequest)

        $allAttributes = @()
        if ($allAttributeSchemasResponse.Entries.Count -gt 0) {
            Write-Verbose "Found $($allAttributeSchemasResponse.Entries.Count) raw attribute schema definitions."
            foreach ($entry in $allAttributeSchemasResponse.Entries) {
                $obj = [PSCustomObject]@{
                    ldapDisplayName = if ($entry.Attributes['ldapDisplayName']) { $entry.Attributes['ldapDisplayName'].GetValues([string])[0] } else { $null }
                    attributeID     = if ($entry.Attributes['attributeID']) { $entry.Attributes['attributeID'].GetValues([string])[0] } else { $null }
                    isSingleValued  = if ($entry.Attributes['isSingleValued']) { [bool]::Parse($entry.Attributes['isSingleValued'].GetValues([string])[0]) } else { $null } # Convert string "TRUE"/"FALSE" to boolean
                    attributeSyntax = if ($entry.Attributes['attributeSyntax']) { $entry.Attributes['attributeSyntax'].GetValues([string])[0] } else { $null }
                    omSyntax        = if ($entry.Attributes['omSyntax']) { [int]::Parse($entry.Attributes['omSyntax'].GetValues([string])[0]) } else { $null }
                    rangeLower      = if ($entry.Attributes['rangeLower']) { $entry.Attributes['rangeLower'].GetValues([string])[0] } else { $null }
                    rangeUpper      = if ($entry.Attributes['rangeUpper']) { $entry.Attributes['rangeUpper'].GetValues([string])[0] } else { $null }
                    description     = if ($entry.Attributes['description']) { $entry.Attributes['description'].GetValues([string])[0] } else { $null }
                    # Add other schema-related attributes as needed
                }
                $allAttributes += $obj
            }
        }

        # 3. Filter by ObjectClass if specified
        if (![string]::IsNullOrEmpty($ObjectClass)) {
            Write-Verbose "Filtering attributes for object class '$ObjectClass'..."

            # Query the objectClassSchema for the specified object class
            $objectClassSchemaSearchRequest = New-Object System.DirectoryServices.Protocols.SearchRequest(
                $schemaDN,
                "(&(objectClass=objectClassSchema)(ldapDisplayName=$ObjectClass))",
                [System.DirectoryServices.Protocols.SearchScope]::OneLevel,
                @('mustContain', 'mayContain')
            )
            $objectClassSchemaResponse = $ldapConnection.SendRequest($objectClassSchemaSearchRequest)

            if ($objectClassSchemaResponse.Entries.Count -gt 0) {
                $objectClassEntry = $objectClassSchemaResponse.Entries[0]
                $mustContain = @()
                if ($objectClassEntry.Attributes['mustContain']) {
                    $mustClassValues = $objectClassEntry.Attributes['mustContain'].GetValues([string])
                    $mustContain = $mustClassValues | ForEach-Object { ($_ -split '(?<=\d),(?=[a-zA-Z])')[-1] } # Extract attribute name if it's an OID.name format
                }
                $mayContain = @()
                if ($objectClassEntry.Attributes['mayContain']) {
                    $mayClassValues = $objectClassEntry.Attributes['mayContain'].GetValues([string])
                    $mayContain = $mayClassValues | ForEach-Object { ($_ -split '(?<=\d),(?=[a-zA-Z])')[-1] } # Extract attribute name if it's an OID.name format
                }

                $allowedAttributeNames = New-Object System.Collections.Generic.HashSet[string]
                $mustContain | ForEach-Object { [void]$allowedAttributeNames.Add($_) }
                $mayContain | ForEach-Object { [void]$allowedAttributeNames.Add($_) }

                $filteredAttributes = $allAttributes | Where-Object { $allowedAttributeNames.Contains($_.ldapDisplayName) }
                Write-Verbose "Found $($filteredAttributes.Count) attributes associated with '$ObjectClass'."
                return $filteredAttributes
            }
            else {
                Write-Warning "Object class '$ObjectClass' not found in schema. Returning all attributes."
                return $allAttributes # Return all if specified object class not found
            }
        }
        else {
            # If no ObjectClass specified, return all attributes
            return $allAttributes
        }

    }
    catch {
        Write-Error "Error querying LDAP schema: $($_.Exception.Message)"
        throw $_
    }
    finally {
        if ($ldapConnection) {
            $ldapConnection.Dispose()
            Write-Verbose 'LDAP connection disposed.'
        }
    }
}

function Get-LdapServersFromDns {
    <#
    .SYNOPSIS
    Discovers LDAP servers for a specified domain by querying DNS SRV records.

    .DESCRIPTION
    This function leverages the Resolve-DnsName cmdlet to find LDAP (or LDAPS)
    servers registered in DNS for a given domain. It looks for _ldap._tcp or _ldaps._tcp
    SRV records, which are commonly used for LDAP service discovery.

    .PARAMETER DomainName
    The domain for which to find LDAP servers (e.g., "contoso.com").

    .PARAMETER UseSsl
    Specify $true to search for LDAPS servers (_ldaps._tcp) on port 636.
    By default, it searches for standard LDAP servers (_ldap._tcp) on port 389.

    .OUTPUTS
    An array of custom objects, each representing an LDAP server discovered via DNS,
    including its Hostname, Port, Priority, and Weight.

    .EXAMPLE
    # Discover standard LDAP servers for 'contoso.com'
    Get-LdapServersFromDns -DomainName "contoso.com"

    .EXAMPLE
    # Discover LDAPS servers for 'example.org'
    Get-LdapServersFromDns -DomainName "example.org" -UseSsl $true
    #>
    [CmdletBinding()]
    [OutputType('System.Management.Automation.PSCustomObject[]')] # Explicit OutputType
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$DomainName,

        [Parameter(Mandatory = $false)]
        [bool]$UseSsl = $false
    )

    $serviceProtocol = if ($UseSsl) { '_ldaps._tcp' } else { '_ldap._tcp' }
    $queryName = "$serviceProtocol.$DomainName"
    # $defaultPort is not strictly needed here as Resolve-DnsName provides the port

    Write-Verbose "Attempting to resolve DNS SRV records for '$queryName'..."

    try {
        # Use Resolve-DnsName to query for SRV records
        # Adding -ErrorAction Stop to make error handling consistent
        $srvRecords = Resolve-DnsName -Name $queryName -Type SRV -ErrorAction Stop

        $ldapServers = @()
        foreach ($record in $srvRecords) {
            # Each SRV record points to an LDAP server
            $ldapServers += [PSCustomObject]@{
                Hostname = $record.NameTarget
                Port     = $record.Port
                Priority = $record.Priority
                Weight   = $record.Weight
                Service  = $record.Name # The full SRV record name (e.g., _ldap._tcp.contoso.com)
            }
        }
        # Sort by priority (lower is better), then by weight (higher is better for load balancing)
        return $ldapServers | Sort-Object Priority, @{Expression = 'Weight'; Descending = $true }

    }
    catch {
        Write-Warning "Could not find SRV records for '$queryName'. $($_.Exception.Message)"
        return $null
    }
}

function Move-LdapObject {
    <#
    .SYNOPSIS
    Moves an LDAP object to a new parent container in the directory.

    .DESCRIPTION
    This function connects to an LDAP server over LDAPS and performs a ModifyDNRequest
    to move an existing LDAP entry from its current location to a new parent container.
    It can optionally rename the object's RDN at the same time.

    .PARAMETER LdapServer
    The hostname or IP address of the LDAP server to connect to.

    .PARAMETER Port
    The TCP port for the LDAPS connection. The default is 636.

    .PARAMETER ObjectDn
    The full Distinguished Name (DN) of the object to move.
    Example: "CN=John Doe,OU=OldOU,DC=yourdomain,DC=com"

    .PARAMETER NewParentDn
    The full Distinguished Name (DN) of the new parent container for the object.
    Example: "OU=NewOU,DC=yourdomain,DC=com"

    .PARAMETER NewRdn
    (Optional) The new Relative Distinguished Name (RDN) for the object at its new location.
    If not specified, the original RDN will be kept.
    Example: "CN=Jonathan Doe" (to rename the object while moving)

    .PARAMETER DeleteOldRdn
    Specifies whether the old RDN should be deleted. This should almost always be $true.
    Default is $true.

    .PARAMETER LdapTimeout
    (Optional) The timeout for LDAP operations in milliseconds. Overrides the default timeout for this specific operation.

    .PARAMETER Username
    (Optional) The username for binding to the LDAP server. If not provided,
    the current logged-in user's credentials will be attempted.

    .PARAMETER Password
    (Optional) The password for the binding user. Only required if Username is provided.

    .OUTPUTS
    System.Boolean. Returns $true if the object was moved successfully, $false otherwise.

    .EXAMPLE
    # Move a user from one OU to another using explicit credentials
    $SecurePassword = ConvertTo-SecureString "P@ssw0rd!123" -AsPlainText -Force
    Move-LdapObject -LdapServer "dc01.contoso.com" `
                    -Port 636 `
                    -ObjectDn "CN=Test User,OU=OldOU,DC=contoso,DC=com" `
                    -NewParentDn "OU=NewOU,DC=contoso,DC=com" `
                    -Username "serviceaccount@contoso.com" `
                    -Password $SecurePassword

    .EXAMPLE
    # Move and rename a user using current logged-in user's credentials
    Move-LdapObject -LdapServer "dc01.contoso.com" `
                    -Port 636 `
                    -ObjectDn "CN=Old Name,OU=Users,DC=contoso,DC=com" `
                    -NewParentDn "OU=NewOU,DC=contoso,DC=com" `
                    -NewRdn "CN=New Name" `
                    -DeleteOldRdn $true
    #>
    [CmdletBinding(DefaultParameterSetName = 'Default', SupportsShouldProcess = $true)]
    [OutputType('System.Boolean')] # Explicit OutputType
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$LdapServer,

        [Parameter(Mandatory = $false)]
        [int]$Port = 636,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ObjectDn,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$NewParentDn,

        [Parameter(Mandatory = $false)]
        [string]$NewRdn, # Optional new RDN, if renaming during move

        [Parameter(Mandatory = $false)]
        [bool]$DeleteOldRdn = $true, # Usually $true when moving

        [Parameter(Mandatory = $false)]
        [int]$LdapTimeout, # Optional override for connection timeout

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$Username,

        [Parameter(Mandatory = $false)]
        [System.Security.SecureString]$Password
    )

    if ($PSCmdlet.ShouldProcess($ObjectDn, "Move LDAP Object to '$NewParentDn'")) {
        $ldapConnection = $null
        try {
            $connectParams = @{
                LdapServer = $LdapServer
                Port       = $Port
                Username   = $Username
                Password   = $Password
            }
            if ($PSBoundParameters.ContainsKey('LdapTimeout')) {
                $connectParams.LdapTimeout = $LdapTimeout
            }
            $ldapConnection = _GetLdapConnection @connectParams

            # If NewRdn is not specified, extract the current RDN from ObjectDn
            if ([string]::IsNullOrEmpty($NewRdn)) {
                $parts = $ObjectDn.Split(',')
                $NewRdn = $parts[0] # The first part is the RDN
            }

            # Create a ModifyDNRequest (Move/Rename)
            $modifyDnRequest = New-Object System.DirectoryServices.Protocols.ModifyDNRequest(
                $ObjectDn,
                $NewRdn,
                $NewParentDn,
                $DeleteOldRdn
            )

            Write-Verbose "Sending Move/Rename request for '$ObjectDn' to '$NewParentDn' with new RDN '$NewRdn'..."
            $modifyDnResponse = $ldapConnection.SendRequest($modifyDnRequest)

            if ($modifyDnResponse.ResultCode -eq [System.DirectoryServices.Protocols.ResultCode]::Success) {
                Write-Host "LDAP object '$ObjectDn' moved successfully to '$NewParentDn' (New RDN: '$NewRdn')."
                return $true
            }
            else {
                Write-Error "Failed to move LDAP object '$ObjectDn'. Result Code: $($modifyDnResponse.ResultCode) - Error Message: $($modifyDnResponse.ErrorMessage)"
                return $false
            }

        }
        catch {
            Write-Error "Error moving LDAP object '$ObjectDn': $($_.Exception.Message)"
            throw $_
        }
        finally {
            if ($ldapConnection) {
                $ldapConnection.Dispose()
                Write-Verbose 'LDAP connection disposed.'
            }
        }
    }
    return $false
}

function Rename-LdapObject {
    <#
    .SYNOPSIS
    Renames the Relative Distinguished Name (RDN) of an LDAP object.

    .DESCRIPTION
    This function connects to an LDAP server over LDAPS and performs a ModifyDNRequest
    to change the RDN of an existing LDAP entry. This operation only changes the
    leftmost component of the object's Distinguished Name, keeping it in the same parent container.

    .PARAMETER LdapServer
    The hostname or IP address of the LDAP server to connect to.

    .PARAMETER Port
    The TCP port for the LDAPS connection. The default is 636.

    .PARAMETER ObjectDn
    The full Distinguished Name (DN) of the object to rename.
    Example: "CN=Old Name,OU=Users,DC=yourdomain,DC=com"

    .PARAMETER NewRdn
    The new Relative Distinguished Name (RDN) for the object.
    Example: "CN=New Name"

    .PARAMETER DeleteOldRdn
    Specifies whether the old RDN should be deleted. This should almost always be $true.
    Default is $true.

    .PARAMETER LdapTimeout
    (Optional) The timeout for LDAP operations in milliseconds. Overrides the default timeout for this specific operation.

    .PARAMETER Username
    (Optional) The username for binding to the LDAP server. If not provided,
    the current logged-in user's credentials will be attempted.

    .PARAMETER Password
    (Optional) The password for the binding user. Only required if Username is provided.

    .OUTPUTS
    System.Boolean. Returns $true if the object was renamed successfully, $false otherwise.

    .EXAMPLE
    # Rename a user's CN using explicit credentials
    $SecurePassword = ConvertTo-SecureString "P@ssw0rd!123" -AsPlainText -Force
    Rename-LdapObject -LdapServer "dc01.contoso.com" `
                      -Port 636 `
                      -ObjectDn "CN=John Doe,OU=Users,DC=contoso,DC=com" `
                      -NewRdn "CN=Johnny Doe" `
                      -Username "serviceaccount@contoso.com" `
                      -Password $SecurePassword

    .EXAMPLE
    # Rename an Organizational Unit using current logged-in user's credentials
    Rename-LdapObject -LdapServer "dc01.contoso.com" `
                      -Port 636 `
                      -ObjectDn "OU=Sales,DC=contoso,DC=com" `
                      -NewRdn "OU=Global Sales"
    #>
    [CmdletBinding(DefaultParameterSetName = 'Default', SupportsShouldProcess = $true)]
    [OutputType('System.Boolean')] # Explicit OutputType
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$LdapServer,

        [Parameter(Mandatory = $false)]
        [int]$Port = 636,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ObjectDn,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$NewRdn,

        [Parameter(Mandatory = $false)]
        [bool]$DeleteOldRdn = $true, # Always $true for a simple rename

        [Parameter(Mandatory = $false)]
        [int]$LdapTimeout, # Optional override for connection timeout

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$Username,

        [Parameter(Mandatory = $false)]
        [System.Security.SecureString]$Password
    )

    if ($PSCmdlet.ShouldProcess($ObjectDn, "Rename LDAP Object RDN to '$NewRdn'")) {
        $ldapConnection = $null
        try {
            $connectParams = @{
                LdapServer = $LdapServer
                Port       = $Port
                Username   = $Username
                Password   = $Password
            }
            if ($PSBoundParameters.ContainsKey('LdapTimeout')) {
                $connectParams.LdapTimeout = $LdapTimeout
            }
            $ldapConnection = _GetLdapConnection @connectParams

            # The NewParentDn parameter for ModifyDNRequest should be null for a simple RDN rename
            # (keeping it in the same parent container).
            $modifyDnRequest = New-Object System.DirectoryServices.Protocols.ModifyDNRequest(
                $ObjectDn,
                $NewRdn,
                $null, # NewParentDn is null for rename within same container
                $DeleteOldRdn
            )

            Write-Verbose "Sending Rename request for '$ObjectDn' to new RDN '$NewRdn'..."
            $modifyDnResponse = $ldapConnection.SendRequest($modifyDnRequest)

            if ($modifyDnResponse.ResultCode -eq [System.DirectoryServices.Protocols.ResultCode]::Success) {
                Write-Host "LDAP object '$ObjectDn' renamed successfully to '$NewRdn'."
                return $true
            }
            else {
                Write-Error "Failed to rename LDAP object '$ObjectDn'. Result Code: $($modifyDnResponse.ResultCode) - Error Message: $($modifyDnResponse.ErrorMessage)"
                return $false
            }

        }
        catch {
            Write-Error "Error renaming LDAP object '$ObjectDn': $($_.Exception.Message)"
            throw $_
        }
        finally {
            if ($ldapConnection) {
                $ldapConnection.Dispose()
                Write-Verbose 'LDAP connection disposed.'
            }
        }
    }
    return $false
}

function Test-LdapConnection {
    <#
    .SYNOPSIS
    Tests connectivity and authentication to an LDAP server.

    .DESCRIPTION
    This function attempts to establish a secure (LDAPS) connection and bind
    to the specified LDAP server using the provided or current user's credentials.
    It returns $true on successful connection and bind, and $false otherwise.
    This is useful for quickly verifying server reachability and authentication validity.

    .PARAMETER LdapServer
    The hostname or IP address of the LDAP server to connect to.

    .PARAMETER Port
    The TCP port for the LDAPS connection. The default is 636.

    .PARAMETER LdapTimeout
    (Optional) The timeout for LDAP operations in milliseconds. Overrides the default timeout for this specific test.

    .PARAMETER Username
    (Optional) The username for binding to the LDAP server. If not provided,
    the current logged-in user's credentials will be attempted.

    .PARAMETER Password
    (Optional) The password for the binding user. Only required if Username is provided.

    .OUTPUTS
    System.Boolean. Returns $true if the connection and bind are successful, $false otherwise.

    .EXAMPLE
    # Test connection using explicit credentials
    $SecurePassword = ConvertTo-SecureString "P@ssw0rd!123" -AsPlainText -Force
    Test-LdapConnection -LdapServer "dc01.contoso.com" `
                        -Port 636 `
                        -Username "serviceaccount@contoso.com" `
                        -Password $SecurePassword

    .EXAMPLE
    # Test connection using current logged-in user's credentials
    Test-LdapConnection -LdapServer "dc01.contoso.com" `
                        -Port 636

    .EXAMPLE
    # Use in a conditional statement
    if (Test-LdapConnection -LdapServer "ldap.example.org" -Username "user" -Password $secPwd) {
        Write-Host "Successfully connected to LDAP!"
    } else {
        Write-Warning "Failed to connect to LDAP server."
    }
    #>
    [CmdletBinding(DefaultParameterSetName = 'Default', SupportsShouldProcess = $false)]
    [OutputType('System.Boolean')] # Explicit OutputType
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$LdapServer,

        [Parameter(Mandatory = $false)]
        [int]$Port = 636,

        [Parameter(Mandatory = $false)]
        [int]$LdapTimeout, # Optional override for connection timeout

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$Username,

        [Parameter(Mandatory = $false)]
        [System.Security.SecureString]$Password
    )

    $isConnected = $false
    $ldapConnection = $null
    try {
        Write-Verbose "Testing connection to $LdapServer`:$Port..."
        $connectParams = @{
            LdapServer = $LdapServer
            Port       = $Port
        }
        if ([Bool]$UserName) {
            $connectParams.Username = $Username
        }
        if ([Bool]$Password) {
            $connectParams.Password = $Password
        }
        if ($PSBoundParameters.ContainsKey('LdapTimeout')) {
            $connectParams.LdapTimeout = $LdapTimeout
        }
        $ldapConnection = _GetLdapConnection @connectParams
        $isConnected = $true
    }
    catch {
        Write-Warning "Connection test failed: $($_.Exception.Message)"
        $isConnected = $false
    }
    finally {
        if ($ldapConnection) {
            $ldapConnection.Dispose()
            Write-Verbose 'LDAP connection disposed after test.'
        }
    }
    return $isConnected
}

function Add-LdapGroupMember {
    <#
    .SYNOPSIS
    Adds a member to an LDAP group.

    .DESCRIPTION
    This function adds a specified LDAP object (user, group, computer) to an LDAP group
    by modifying the group's 'member' attribute.

    .PARAMETER LdapServer
    The hostname or IP address of the LDAP server to connect to.

    .PARAMETER Port
    The TCP port for the LDAPS connection. The default is 636.

    .PARAMETER GroupDn
    The Distinguished Name (DN) of the group to which the member will be added.
    Example: "CN=MyGroup,OU=Groups,DC=contoso,DC=com"

    .PARAMETER MemberDn
    The Distinguished Name (DN) of the object to add as a member.
    Example: "CN=John Doe,OU=Users,DC=contoso,DC=com"

    .PARAMETER LdapTimeout
    (Optional) The timeout for LDAP operations in milliseconds. Overrides the default timeout for this specific operation.

    .PARAMETER Username
    (Optional) The username for binding to the LDAP server. If not provided,
    the current logged-in user's credentials will be attempted.

    .PARAMETER Password
    (Optional) The password for the binding user. Only required if Username is provided.

    .OUTPUTS
    System.Boolean. Returns $true if the member was added successfully, $false otherwise.

    .EXAMPLE
    # Add a user to a group using current credentials
    Add-LdapGroupMember -LdapServer "dc01.contoso.com" `
                        -GroupDn "CN=IT Admins,OU=Groups,DC=contoso,DC=com" `
                        -MemberDn "CN=Jane Smith,OU=Users,DC=contoso,DC=com"

    .EXAMPLE
    # Add a computer to a group using explicit credentials
    $SecurePassword = ConvertTo-SecureString "AdminPass" -AsPlainText -Force
    Add-LdapGroupMember -LdapServer "dc01.contoso.com" `
                        -Port 636 `
                        -GroupDn "CN=Workstations,OU=Groups,DC=contoso,DC=com" `
                        -MemberDn "CN=Laptop123,OU=Computers,DC=contoso,DC=com" `
                        -Username "svc_ldap@contoso.com" `
                        -Password $SecurePassword
    #>
    [CmdletBinding(DefaultParameterSetName = 'Default', SupportsShouldProcess = $true)]
    [OutputType('System.Boolean')] # Explicit OutputType
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$LdapServer,

        [Parameter(Mandatory = $false)]
        [int]$Port = 636,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$GroupDn,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$MemberDn,

        [Parameter(Mandatory = $false)]
        [int]$LdapTimeout, # Optional override for connection timeout

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$Username,

        [Parameter(Mandatory = $false)]
        [System.Security.SecureString]$Password
    )

    if ($PSCmdlet.ShouldProcess("Member '$MemberDn' to Group '$GroupDn'", 'Add LDAP Group Member')) {
        $ldapConnection = $null
        try {
            $connectParams = @{
                LdapServer = $LdapServer
                Port       = $Port
                Username   = $Username
                Password   = $Password
            }
            if ($PSBoundParameters.ContainsKey('LdapTimeout')) {
                $connectParams.LdapTimeout = $LdapTimeout
            }
            $ldapConnection = _GetLdapConnection @connectParams

            $modifyRequest = New-Object System.DirectoryServices.Protocols.ModifyRequest($GroupDn)
            $memberModification = New-Object System.DirectoryServices.Protocols.DirectoryAttributeModification
            $memberModification.Name = 'member' # Common attribute for group members
            $memberModification.Operation = [System.DirectoryServices.Protocols.DirectoryAttributeOperation]::Add
            $memberModification.Add($MemberDn)
            $modifyRequest.Modifications.Add($memberModification)

            Write-Verbose "Adding member '$MemberDn' to group '$GroupDn'..."
            $modifyResponse = $ldapConnection.SendRequest($modifyRequest)

            if ($modifyResponse.ResultCode -eq [System.DirectoryServices.Protocols.ResultCode]::Success) {
                Write-Host "Member '$MemberDn' added successfully to group '$GroupDn'."
                return $true
            }
            else {
                Write-Error "Failed to add member '$MemberDn' to group '$GroupDn'. Result Code: $($modifyResponse.ResultCode) - Error Message: $($modifyResponse.ErrorMessage)"
                return $false
            }
        }
        catch {
            Write-Error "Error adding group member: $($_.Exception.Message)"
            throw $_
        }
        finally {
            if ($ldapConnection) { $ldapConnection.Dispose() }
        }
    }
    return $false
}

function Remove-LdapGroupMember {
    <#
    .SYNOPSIS
    Removes a member from an LDAP group.

    .DESCRIPTION
    This function removes a specified LDAP object (user, group, computer) from an LDAP group
    by modifying the group's 'member' attribute.

    .PARAMETER LdapServer
    The hostname or IP address of the LDAP server to connect to.

    .PARAMETER Port
    The TCP port for the LDAPS connection. The default is 636.

    .PARAMETER GroupDn
    The Distinguished Name (DN) of the group from which the member will be removed.
    Example: "CN=MyGroup,OU=Groups,DC=contoso,DC=com"

    .PARAMETER MemberDn
    The Distinguished Name (DN) of the object to remove as a member.
    Example: "CN=John Doe,OU=Users,DC=contoso,DC=com"

    .PARAMETER LdapTimeout
    (Optional) The timeout for LDAP operations in milliseconds. Overrides the default timeout for this specific operation.

    .PARAMETER Username
    (Optional) The username for binding to the LDAP server. If not provided,
    the current logged-in user's credentials will be attempted.

    .PARAMETER Password
    (Optional) The password for the binding user. Only required if Username is provided.

    .OUTPUTS
    System.Boolean. Returns $true if the member was removed successfully, $false otherwise.

    .EXAMPLE
    # Remove a user from a group using current credentials
    Remove-LdapGroupMember -LdapServer "dc01.contoso.com" `
                           -GroupDn "CN=IT Admins,OU=Groups,DC=contoso,DC=com" `
                           -MemberDn "CN=Jane Smith,OU=Users,DC=contoso,DC=com"

    .EXAMPLE
    # Remove a computer from a group using explicit credentials
    $SecurePassword = ConvertTo-SecureString "AdminPass" -AsPlainText -Force
    Remove-LdapGroupMember -LdapServer "dc01.contoso.com" `
                           -Port 636 `
                           -GroupDn "CN=Workstations,OU=Groups,DC=contoso,DC=com" `
                           -MemberDn "CN=Laptop123,OU=Computers,DC=contoso,DC=com" `
                           -Username "svc_ldap@contoso.com" `
                           -Password $SecurePassword
    #>
    [CmdletBinding(DefaultParameterSetName = 'Default', SupportsShouldProcess = $true)]
    [OutputType('System.Boolean')] # Explicit OutputType
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$LdapServer,

        [Parameter(Mandatory = $false)]
        [int]$Port = 636,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$GroupDn,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$MemberDn,

        [Parameter(Mandatory = $false)]
        [int]$LdapTimeout, # Optional override for connection timeout

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$Username,

        [Parameter(Mandatory = $false)]
        [System.Security.SecureString]$Password
    )

    if ($PSCmdlet.ShouldProcess("Member '$MemberDn' from Group '$GroupDn'", 'Remove LDAP Group Member')) {
        $ldapConnection = $null
        try {
            $connectParams = @{
                LdapServer = $LdapServer
                Port       = $Port
                Username   = $Username
                Password   = $Password
            }
            if ($PSBoundParameters.ContainsKey('LdapTimeout')) {
                $connectParams.LdapTimeout = $LdapTimeout
            }
            $ldapConnection = _GetLdapConnection @connectParams

            $modifyRequest = New-Object System.DirectoryServices.Protocols.ModifyRequest($GroupDn)
            $memberModification = New-Object System.DirectoryServices.Protocols.DirectoryAttributeModification
            $memberModification.Name = 'member' # Common attribute for group members
            $memberModification.Operation = [System.DirectoryServices.Protocols.DirectoryAttributeOperation]::Delete
            $memberModification.Add($MemberDn)
            $modifyRequest.Modifications.Add($memberModification)

            Write-Verbose "Removing member '$MemberDn' from group '$GroupDn'..."
            $modifyResponse = $ldapConnection.SendRequest($modifyRequest)

            if ($modifyResponse.ResultCode -eq [System.DirectoryServices.Protocols.ResultCode]::Success) {
                Write-Host "Member '$MemberDn' removed successfully from group '$GroupDn'."
                return $true
            }
            else {
                Write-Error "Failed to remove member '$MemberDn' from group '$GroupDn'. Result Code: $($modifyResponse.ResultCode) - Error Message: $($modifyResponse.ErrorMessage)"
                return $false
            }
        }
        catch {
            Write-Error "Error removing group member: $($_.Exception.Message)"
            throw $_
        }
        finally {
            if ($ldapConnection) { $ldapConnection.Dispose() }
        }
    }
    return $false
}

function Get-LdapGroupMember {
    <#
    .SYNOPSIS
    Retrieves all members of an LDAP group.

    .DESCRIPTION
    This function queries an LDAP group and returns the Distinguished Names (DNs)
    of all its members.

    .PARAMETER LdapServer
    The hostname or IP address of the LDAP server to connect to.

    .PARAMETER Port
    The TCP port for the LDAPS connection. The default is 636.

    .PARAMETER GroupDn
    The Distinguished Name (DN) of the group whose members will be retrieved.
    Example: "CN=MyGroup,OU=Groups,DC=contoso,DC=com"

    .PARAMETER LdapTimeout
    (Optional) The timeout for LDAP operations in milliseconds. Overrides the default timeout for this specific query.

    .PARAMETER Username
    (Optional) The username for binding to the LDAP server. If not provided,
    the current logged-in user's credentials will be attempted.

    .PARAMETER Password
    (Optional) The password for the binding user. Only required if Username is provided.

    .OUTPUTS
    System.String[]. An array of strings, where each string is the Distinguished Name (DN)
    of a group member. Returns an empty array if the group is found but has no members, or $null if the group is not found.

    .EXAMPLE
    # Get members of a group using current credentials
    Get-LdapGroupMember -LdapServer "dc01.contoso.com" `
                        -GroupDn "CN=IT Admins,OU=Groups,DC=contoso,DC=com"

    .EXAMPLE
    # Get members of a group and display them
    $SecurePassword = ConvertTo-SecureString "AdminPass" -AsPlainText -Force
    Get-LdapGroupMember -LdapServer "dc01.contoso.com" `
                        -Port 636 `
                        -GroupDn "CN=Developers,OU=Groups,DC=contoso,DC=com" `
                        -Username "svc_ldap@contoso.com" `
                        -Password $SecurePassword | Format-Table
    #>
    [CmdletBinding(DefaultParameterSetName = 'Default', SupportsShouldProcess = $false)]
    [OutputType('System.String[]')] # Explicit OutputType
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$LdapServer,

        [Parameter(Mandatory = $false)]
        [int]$Port = 636,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$GroupDn,

        [Parameter(Mandatory = $false)]
        [int]$LdapTimeout, # Optional override for connection timeout

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$Username,

        [Parameter(Mandatory = $false)]
        [System.Security.SecureString]$Password
    )

    $ldapConnection = $null
    try {
        $connectParams = @{
            LdapServer = $LdapServer
            Port       = $Port
            Username   = $Username
            Password   = $Password
        }
        if ($PSBoundParameters.ContainsKey('LdapTimeout')) {
            $connectParams.LdapTimeout = $LdapTimeout
        }
        $ldapConnection = _GetLdapConnection @connectParams

        # Search for the group object and retrieve its 'member' attribute
        $searchRequest = New-Object System.DirectoryServices.Protocols.SearchRequest(
            $GroupDn,
            '(&(objectClass=group))', # Filter specifically for group objects
            [System.DirectoryServices.Protocols.SearchScope]::Base,
            @('member') # Request the 'member' attribute
        )

        Write-Verbose "Retrieving members for group '$GroupDn'..."
        $searchResponse = $ldapConnection.SendRequest($searchRequest)

        if ($searchResponse.Entries.Count -eq 1) {
            $groupEntry = $searchResponse.Entries[0]
            if ($groupEntry.Attributes['member']) {
                $members = $groupEntry.Attributes['member'].GetValues([string])
                Write-Host "Found $($members.Count) members for group '$GroupDn'."
                return $members
            }
            else {
                Write-Warning "Group '$GroupDn' found, but it has no members or the 'member' attribute is empty."
                return @() # Return empty array if no members
            }
        }
        else {
            Write-Warning "Group '$GroupDn' not found or multiple groups matched (unexpected)."
            return $null
        }

    }
    catch {
        Write-Error "Error getting group members for '$GroupDn': $($_.Exception.Message)"
        throw $_
    }
    finally {
        if ($ldapConnection) { $ldapConnection.Dispose() }
    }
}

function Set-LdapUserPassword {
    <#
    .SYNOPSIS
    Sets or resets a user's password in Active Directory.

    .DESCRIPTION
    This function changes the password for a specified user account in Active Directory.
    This operation MUST be performed over LDAPS (port 636) for security.
    It directly modifies the 'unicodePwd' attribute.

    .PARAMETER LdapServer
    The hostname or IP address of the LDAP server (Domain Controller) to connect to.

    .PARAMETER Port
    The TCP port for the LDAPS connection. MUST be 636.

    .PARAMETER UserDn
    The Distinguished Name (DN) of the user account whose password will be set.
    Example: "CN=John Doe,OU=Users,DC=contoso,DC=com"

    .PARAMETER NewPassword
    The new password for the user, provided as a SecureString.

    .PARAMETER LdapTimeout
    (Optional) The timeout for LDAP operations in milliseconds. Overrides the default timeout for this specific operation.

    .PARAMETER Username
    (Optional) The username for binding to the LDAP server. If not provided,
    the current logged-in user's credentials will be attempted. This user must
    have permissions to modify user passwords.

    .PARAMETER Password
    (Optional) The password for the binding user. Only required if Username is provided.

    .OUTPUTS
    System.Boolean. Returns $true if the password was set successfully, $false otherwise.

    .NOTES
    This function is primarily designed for Active Directory. Other LDAP servers
    might use different mechanisms for password changes (e.g., Password Modify extended operation).
    The connection MUST be LDAPS (port 636).
    #>
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    [OutputType('System.Boolean')] # Explicit OutputType
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$LdapServer,

        [Parameter(Mandatory = $false)]
        [int]$Port = 636,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$UserDn,

        [Parameter(Mandatory = $true)]
        [System.Security.SecureString]$NewPassword,

        [Parameter(Mandatory = $false)]
        [int]$LdapTimeout, # Optional override for connection timeout

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$Username,

        [Parameter(Mandatory = $false)]
        [System.Security.SecureString]$Password
    )

    if ($Port -ne 636) {
        Write-Error 'Password modification requires an LDAPS connection on port 636.'
        return $false
    }

    $plainNewPassword = $null # Initialize to null
    $ldapConnection = $null
    try {
        $connectParams = @{
            LdapServer = $LdapServer
            Port       = $Port
            Username   = $Username
            Password   = $Password
        }
        if ($PSBoundParameters.ContainsKey('LdapTimeout')) {
            $connectParams.LdapTimeout = $LdapTimeout
        }
        $ldapConnection = _GetLdapConnection @connectParams

        # Convert SecureString password to byte array for unicodePwd attribute
        $plainNewPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
            [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($NewPassword)
        )
        $unicodePasswordBytes = [System.Text.Encoding]::Unicode.GetBytes("""$plainNewPassword""")

        $modifyRequest = New-Object System.DirectoryServices.Protocols.ModifyRequest($UserDn)
        $passwordModification = New-Object System.DirectoryServices.Protocols.DirectoryAttributeModification
        $passwordModification.Name = 'unicodePwd'
        $passwordModification.Operation = [System.DirectoryServices.Protocols.DirectoryAttributeOperation]::Replace
        $passwordModification.Add($unicodePasswordBytes)
        $modifyRequest.Modifications.Add($passwordModification)

        Write-Verbose "Setting password for user '$UserDn'..."
        $modifyResponse = $ldapConnection.SendRequest($modifyRequest)

        if ($modifyResponse.ResultCode -eq [System.DirectoryServices.Protocols.ResultCode]::Success) {
            Write-Host "Password for user '$UserDn' set successfully."
            return $true
        }
        else {
            Write-Error "Failed to set password for user '$UserDn'. Result Code: $($modifyResponse.ResultCode) - Error Message: $($modifyResponse.ErrorMessage)"
            return $false
        }
    }
    catch {
        Write-Error "Error setting user password: $($_.Exception.Message)"
        throw $_
    }
    finally {
        # Securely clear the plain new password from memory
        if ($plainNewPassword) {
            [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR(
                [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($NewPassword)
            )
            $plainNewPassword = $null # Ensure variable is cleared
        }
        if ($ldapConnection) { $ldapConnection.Dispose() }
    }
    return $false
}

function _GetUserAccountControlValue {
    <#
    .SYNOPSIS
    Calculates the UserAccountControl value for enabling/disabling/unlocking accounts.

    .DESCRIPTION
    This is a private helper function to determine the correct UserAccountControl
    value based on desired account state (enabled, disabled, unlocked).
    Used primarily by Enable-LdapAccount, Disable-LdapAccount, Unlock-LdapAccount.

    .PARAMETER CurrentUserAccountControl
    The current integer value of the userAccountControl attribute.

    .PARAMETER Enable
    If $true, ensures ACCOUNTDISABLE flag is removed.
    .PARAMETER Disable
    If $true, ensures ACCOUNTDISABLE flag is set.
    .PARAMETER Unlock
    If $true, ensures LOCKOUT flag is removed.

    .OUTPUTS
    System.Int32. The calculated new userAccountControl integer value.
    #>
    param(
        [int]$CurrentUserAccountControl,
        [switch]$Enable,
        [switch]$Disable,
        [switch]$Unlock
    )

    $UAC_ACCOUNTDISABLE = 0x0002 # 2
    $UAC_LOCKOUT = 0x0010 # 16

    $newValue = $CurrentUserAccountControl

    if ($Enable) {
        $newValue = $newValue -band ( -bnot $UAC_ACCOUNTDISABLE ) # Remove ACCOUNTDISABLE
    }
    if ($Disable) {
        $newValue = $newValue -bor $UAC_ACCOUNTDISABLE # Add ACCOUNTDISABLE
    }
    if ($Unlock) {
        $newValue = $newValue -band ( -bnot $UAC_LOCKOUT ) # Remove LOCKOUT
    }
    return $newValue
}

function Enable-LdapAccount {
    <#
    .SYNOPSIS
    Enables a user or computer account in Active Directory.

    .DESCRIPTION
    This function modifies the 'userAccountControl' attribute to enable a specified
    user or computer account in Active Directory.

    .PARAMETER LdapServer
    The hostname or IP address of the LDAP server (Domain Controller) to connect to.

    .PARAMETER Port
    The TCP port for the LDAPS connection. The default is 636.

    .PARAMETER ObjectDn
    The Distinguished Name (DN) of the user or computer account to enable.
    Example: "CN=John Doe,OU=Users,DC=contoso,DC=com" or "CN=MyComputer,OU=Computers,DC=contoso,DC=com"

    .PARAMETER LdapTimeout
    (Optional) The timeout for LDAP operations in milliseconds. Overrides the default timeout for this specific operation.

    .PARAMETER Username
    (Optional) The username for binding to the LDAP server. If not provided,
    the current logged-in user's credentials will be attempted.

    .PARAMETER Password
    (Optional) The password for the binding user. Only required if Username is provided.

    .OUTPUTS
    System.Boolean. Returns $true if the account was enabled successfully, $false otherwise.

    .NOTES
    This function is primarily designed for Active Directory, as 'userAccountControl' is AD-specific.
    #>
    [CmdletBinding(DefaultParameterSetName = 'Default', SupportsShouldProcess = $true)]
    [OutputType('System.Boolean')] # Explicit OutputType
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$LdapServer,

        [Parameter(Mandatory = $false)]
        [int]$Port = 636,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ObjectDn,

        [Parameter(Mandatory = $false)]
        [int]$LdapTimeout, # Optional override for connection timeout

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$Username,

        [Parameter(Mandatory = $false)]
        [System.Security.SecureString]$Password
    )

    if ($PSCmdlet.ShouldProcess("Account '$ObjectDn'", 'Enable LDAP Account')) {
        $ldapConnection = $null
        try {
            $connectParams = @{
                LdapServer = $LdapServer
                Port       = $Port
                Username   = $Username
                Password   = $Password
            }
            if ($PSBoundParameters.ContainsKey('LdapTimeout')) {
                $connectParams.LdapTimeout = $LdapTimeout
            }
            $ldapConnection = _GetLdapConnection @connectParams

            # Get current userAccountControl value
            $currentObject = Get-LdapObject -LdapServer $LdapServer `
                -Port $Port `
                -ObjectDn $ObjectDn `
                -PropertiesToLoad @('userAccountControl') `
                -Username $Username `
                -Password $Password `
                -LdapTimeout $LdapTimeout # Pass timeout to sub-function
            if (-not $currentObject) {
                Write-Error "Object '$ObjectDn' not found to enable."
                return $false
            }

            $currentUAC = 0
            if ($currentObject.userAccountControl -is [int]) {
                $currentUAC = $currentObject.userAccountControl
            }
            elseif ($currentObject.userAccountControl -is [string]) {
                [int]::TryParse($currentObject.userAccountControl, [ref]$currentUAC) | Out-Null
            }

            $newUAC = _GetUserAccountControlValue -CurrentUserAccountControl $currentUAC -Enable

            # Apply modification if UAC actually changed
            if ($newUAC -ne $currentUAC) {
                $modifyRequest = New-Object System.DirectoryServices.Protocols.ModifyRequest($ObjectDn)
                $uacModification = New-Object System.DirectoryServices.Protocols.DirectoryAttributeModification
                $uacModification.Name = 'userAccountControl'
                $uacModification.Operation = [System.DirectoryServices.Protocols.DirectoryAttributeOperation]::Replace
                $uacModification.Add("$newUAC") # Add as string
                $modifyRequest.Modifications.Add($uacModification)

                Write-Verbose "Enabling account '$ObjectDn' (userAccountControl: $currentUAC -> $newUAC)..."
                $modifyResponse = $ldapConnection.SendRequest($modifyRequest)

                if ($modifyResponse.ResultCode -eq [System.DirectoryServices.Protocols.ResultCode]::Success) {
                    Write-Host "Account '$ObjectDn' enabled successfully."
                    return $true
                }
                else {
                    Write-Error "Failed to enable account '$ObjectDn'. Result Code: $($modifyResponse.ResultCode) - Error Message: $($modifyResponse.ErrorMessage)"
                    return $false
                }
            }
            else {
                Write-Warning "Account '$ObjectDn' is already enabled. No changes made."
                return $true # Already in desired state
            }
        }
        catch {
            Write-Error "Error enabling LDAP account: $($_.Exception.Message)"
            throw $_
        }
        finally {
            if ($ldapConnection) { $ldapConnection.Dispose() }
        }
    }
    return $false
}

function Disable-LdapAccount {
    <#
    .SYNOPSIS
    Disables a user or computer account in Active Directory.

    .DESCRIPTION
    This function modifies the 'userAccountControl' attribute to disable a specified
    user or computer account in Active Directory.

    .PARAMETER LdapServer
    The hostname or IP address of the LDAP server (Domain Controller) to connect to.

    .PARAMETER Port
    The TCP port for the LDAPS connection. The default is 636.

    .PARAMETER ObjectDn
    The Distinguished Name (DN) of the user or computer account to disable.
    Example: "CN=John Doe,OU=Users,DC=contoso,DC=com" or "CN=MyComputer,OU=Computers,DC=contoso,DC=com"

    .PARAMETER LdapTimeout
    (Optional) The timeout for LDAP operations in milliseconds. Overrides the default timeout for this specific operation.

    .PARAMETER Username
    (Optional) The username for binding to the LDAP server. If not provided,
    the current logged-in user's credentials will be attempted.

    .PARAMETER Password
    (Optional) The password for the binding user. Only required if Username is provided.

    .OUTPUTS
    System.Boolean. Returns $true if the account was disabled successfully, $false otherwise.

    .NOTES
    This function is primarily designed for Active Directory, as 'userAccountControl' is AD-specific.
    #>
    [CmdletBinding(DefaultParameterSetName = 'Default', SupportsShouldProcess = $true)]
    [OutputType('System.Boolean')] # Explicit OutputType
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$LdapServer,

        [Parameter(Mandatory = $false)]
        [int]$Port = 636,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ObjectDn,

        [Parameter(Mandatory = $false)]
        [int]$LdapTimeout, # Optional override for connection timeout

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$Username,

        [Parameter(Mandatory = $false)]
        [System.Security.SecureString]$Password
    )

    if ($PSCmdlet.ShouldProcess("Account '$ObjectDn'", 'Disable LDAP Account')) {
        $ldapConnection = $null
        try {
            $connectParams = @{
                LdapServer = $LdapServer
                Port       = $Port
                Username   = $Username
                Password   = $Password
            }
            if ($PSBoundParameters.ContainsKey('LdapTimeout')) {
                $connectParams.LdapTimeout = $LdapTimeout
            }
            $ldapConnection = _GetLdapConnection @connectParams

            # Get current userAccountControl value
            $currentObject = Get-LdapObject -LdapServer $LdapServer `
                -Port $Port `
                -ObjectDn $ObjectDn `
                -PropertiesToLoad @('userAccountControl') `
                -Username $Username `
                -Password $Password `
                -LdapTimeout $LdapTimeout # Pass timeout to sub-function
            if (-not $currentObject) {
                Write-Error "Object '$ObjectDn' not found to disable."
                return $false
            }

            $currentUAC = 0
            if ($currentObject.userAccountControl -is [int]) {
                $currentUAC = $currentObject.userAccountControl
            }
            elseif ($currentObject.userAccountControl -is [string]) {
                [int]::TryParse($currentObject.userAccountControl, [ref]$currentUAC) | Out-Null
            }

            $newUAC = _GetUserAccountControlValue -CurrentUserAccountControl $currentUAC -Disable

            # Apply modification if UAC actually changed
            if ($newUAC -ne $currentUAC) {
                $modifyRequest = New-Object System.DirectoryServices.Protocols.ModifyRequest($ObjectDn)
                $uacModification = New-Object System.DirectoryServices.Protocols.DirectoryAttributeModification
                $uacModification.Name = 'userAccountControl'
                $uacModification.Operation = [System.DirectoryServices.Protocols.DirectoryAttributeOperation]::Replace
                $uacModification.Add("$newUAC") # Add as string
                $modifyRequest.Modifications.Add($uacModification)

                Write-Verbose "Disabling account '$ObjectDn' (userAccountControl: $currentUAC -> $newUAC)..."
                $modifyResponse = $ldapConnection.SendRequest($modifyRequest)

                if ($modifyResponse.ResultCode -eq [System.DirectoryServices.Protocols.ResultCode]::Success) {
                    Write-Host "Account '$ObjectDn' disabled successfully."
                    return $true
                }
                else {
                    Write-Error "Failed to disable account '$ObjectDn'. Result Code: $($modifyResponse.ResultCode) - Error Message: $($modifyResponse.ErrorMessage)"
                    return $false
                }
            }
            else {
                Write-Warning "Account '$ObjectDn' is already disabled. No changes made."
                return $true # Already in desired state
            }
        }
        catch {
            Write-Error "Error disabling LDAP account: $($_.Exception.Message)"
            throw $_
        }
        finally {
            if ($ldapConnection) { $ldapConnection.Dispose() }
        }
    }
    return $false
}

function Unlock-LdapAccount {
    <#
    .SYNOPSIS
    Unlocks a locked user account in Active Directory.

    .DESCRIPTION
    This function clears the 'lockoutTime' attribute and modifies 'userAccountControl'
    to unlock a specified user account in Active Directory.

    .PARAMETER LdapServer
    The hostname or IP address of the LDAP server (Domain Controller) to connect to.

    .PARAMETER Port
    The TCP port for the LDAPS connection. The default is 636.

    .PARAMETER UserDn
    The Distinguished Name (DN) of the user account to unlock.
    Example: "CN=John Doe,OU=Users,DC=contoso,DC=com"

    .PARAMETER LdapTimeout
    (Optional) The timeout for LDAP operations in milliseconds. Overrides the default timeout for this specific operation.

    .PARAMETER Username
    (Optional) The username for binding to the LDAP server. If not provided,
    the current logged-in user's credentials will be attempted.

    .PARAMETER Password
    (Optional) The password for the binding user. Only required if Username is provided.

    .OUTPUTS
    System.Boolean. Returns $true if the account was unlocked successfully, $false otherwise.

    .NOTES
    This function is primarily designed for Active Directory, as 'lockoutTime' and
    'userAccountControl' flags related to lockout are AD-specific.
    #>
    [CmdletBinding(DefaultParameterSetName = 'Default', SupportsShouldProcess = $true)]
    [OutputType('System.Boolean')] # Explicit OutputType
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$LdapServer,

        [Parameter(Mandatory = $false)]
        [int]$Port = 636,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$UserDn,

        [Parameter(Mandatory = $false)]
        [int]$LdapTimeout, # Optional override for connection timeout

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$Username,

        [Parameter(Mandatory = $false)]
        [System.Security.SecureString]$Password
    )

    if ($PSCmdlet.ShouldProcess("Account '$UserDn'", 'Unlock LDAP Account')) {
        $ldapConnection = $null
        try {
            $connectParams = @{
                LdapServer = $LdapServer
                Port       = $Port
                Username   = $Username
                Password   = $Password
            }
            if ($PSBoundParameters.ContainsKey('LdapTimeout')) {
                $connectParams.LdapTimeout = $LdapTimeout
            }
            $ldapConnection = _GetLdapConnection @connectParams

            # Get current userAccountControl and lockoutTime values
            $currentObject = Get-LdapObject -LdapServer $LdapServer `
                -Port $Port `
                -ObjectDn $UserDn `
                -PropertiesToLoad @('userAccountControl', 'lockoutTime') `
                -Username $Username `
                -Password $Password `
                -LdapTimeout $LdapTimeout # Pass timeout to sub-function
            if (-not $currentObject) {
                Write-Error "User account '$UserDn' not found to unlock."
                return $false
            }

            $currentUAC = 0
            if ($currentObject.userAccountControl -is [int]) {
                $currentUAC = $currentObject.userAccountControl
            }
            elseif ($currentObject.userAccountControl -is [string]) {
                [int]::TryParse($currentObject.userAccountControl, [ref]$currentUAC) | Out-Null
            }
            $isLockedOut = $false
            if ($currentObject.lockoutTime -and ($currentObject.lockoutTime -ne '0')) {
                $isLockedOut = $true
            }

            if (-not $isLockedOut) {
                Write-Warning "Account '$UserDn' is not locked out. No changes made."
                return $true # Already unlocked
            }

            $newUAC = _GetUserAccountControlValue -CurrentUserAccountControl $currentUAC -Unlock

            $modifyRequest = New-Object System.DirectoryServices.Protocols.ModifyRequest($UserDn)

            # 1. Clear lockoutTime attribute
            $lockoutTimeModification = New-Object System.DirectoryServices.Protocols.DirectoryAttributeModification
            $lockoutTimeModification.Name = 'lockoutTime'
            $lockoutTimeModification.Operation = [System.DirectoryServices.Protocols.DirectoryAttributeOperation]::Replace # Replace with 0
            $lockoutTimeModification.Add('0')
            $modifyRequest.Modifications.Add($lockoutTimeModification)

            # 2. Update userAccountControl to remove LOCKOUT flag
            if ($newUAC -ne $currentUAC) {
                $uacModification = New-Object System.DirectoryServices.Protocols.DirectoryAttributeModification
                $uacModification.Name = 'userAccountControl'
                $uacModification.Operation = [System.DirectoryServices.Protocols.DirectoryAttributeOperation]::Replace
                $uacModification.Add("$newUAC")
                $modifyRequest.Modifications.Add($uacModification)
            }

            Write-Verbose "Unlocking account '$UserDn' (userAccountControl: $currentUAC -> $newUAC, lockoutTime: cleared)..."
            $modifyResponse = $ldapConnection.SendRequest($modifyRequest)

            if ($modifyResponse.ResultCode -eq [System.DirectoryServices.Protocols.ResultCode]::Success) {
                Write-Host "Account '$UserDn' unlocked successfully."
                return $true
            }
            else {
                Write-Error "Failed to unlock account '$UserDn'. Result Code: $($modifyResponse.ResultCode) - Error Message: $($modifyResponse.ErrorMessage)"
                return $false
            }
        }
        catch {
            Write-Error "Error unlocking LDAP account: $($_.Exception.Message)"
            throw $_
        }
        finally {
            if ($ldapConnection) { $ldapConnection.Dispose() }
        }
    }
    return $false
}

function Get-LdapSchemaObjectClass {
    <#
    .SYNOPSIS
    Queries an LDAP server's schema for object class definitions.

    .DESCRIPTION
    This function connects to an LDAP server over LDAPS, retrieves the schema naming context,
    and then queries for objectClassSchema definitions. It can optionally filter for a
    specific object class or include all definitions.

    .PARAMETER LdapServer
    The hostname or IP address of the LDAP server to connect to.

    .PARAMETER Port
    The TCP port for the LDAPS connection. The default is 636.

    .PARAMETER ObjectClass
    (Optional) The ldapDisplayName of a specific objectClass (e.g., "user", "group", "organizationalUnit")
    to retrieve. If not specified, all object classes will be returned.

    .PARAMETER LdapTimeout
    (Optional) The timeout for LDAP operations in milliseconds. Overrides the default timeout for this specific query.

    .PARAMETER Username
    (Optional) The username for binding to the LDAP server. If not provided,
    the current logged-in user's credentials will be attempted.

    .PARAMETER Password
    (Optional) The password for the binding user. Only required if Username is provided.

    .OUTPUTS
    An array of custom objects, each representing an LDAP object class definition with properties like
    ldapDisplayName, objectClassCategory, superiorClasses, mustContain, mayContain.

    .EXAMPLE
    # Get all object classes in the schema
    Get-LdapSchemaObjectClass -LdapServer "dc01.contoso.com"

    .EXAMPLE
    # Get details for the 'user' object class
    Get-LdapSchemaObjectClass -LdapServer "dc01.contoso.com" -ObjectClass "user"

    .EXAMPLE
    # Get 'group' object class details using explicit credentials
    $SecurePassword = ConvertTo-SecureString "Pass123" -AsPlainText -Force
    Get-LdapSchemaObjectClass -LdapServer "dc01.contoso.com" `
                              -ObjectClass "group" `
                              -Username "svc_ldap@contoso.com" `
                              -Password $SecurePassword
    #>
    [CmdletBinding(DefaultParameterSetName = 'Default', SupportsShouldProcess = $false)]
    [OutputType('System.Management.Automation.PSCustomObject[]')] # Explicit OutputType
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$LdapServer,

        [Parameter(Mandatory = $false)]
        [int]$Port = 636,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$ObjectClass, # Optional parameter for filtering

        [Parameter(Mandatory = $false)]
        [int]$LdapTimeout, # Optional override for connection timeout

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$Username,

        [Parameter(Mandatory = $false)]
        [System.Security.SecureString]$Password
    )

    $ldapConnection = $null
    try {
        $connectParams = @{
            LdapServer = $LdapServer
            Port       = $Port
            Username   = $Username
            Password   = $Password
        }
        if ($PSBoundParameters.ContainsKey('LdapTimeout')) {
            $connectParams.LdapTimeout = $LdapTimeout
        }
        $ldapConnection = _GetLdapConnection @connectParams

        # 1. Query the RootDSE to get the schemaNamingContext
        Write-Verbose 'Querying RootDSE for schemaNamingContext...'
        $rootDSESearchRequest = New-Object System.DirectoryServices.Protocols.SearchRequest(
            '', # Base DN for RootDSE
            '(objectClass=*)',
            [System.DirectoryServices.Protocols.SearchScope]::Base,
            @('schemaNamingContext')
        )
        $rootDSESearchResponse = $ldapConnection.SendRequest($rootDSESearchRequest)

        $schemaDN = $null
        if ($rootDSESearchResponse.Entries.Count -gt 0) {
            $schemaEntry = $rootDSESearchResponse.Entries[0]
            if ($schemaEntry.Attributes['schemaNamingContext']) {
                $schemaDN = $schemaEntry.Attributes['schemaNamingContext'].GetValues([string])[0]
                Write-Verbose "Schema Naming Context: $schemaDN"
            }
        }

        if (-not $schemaDN) {
            Write-Error 'Could not determine the schemaNamingContext. Cannot query schema object classes.'
            return $null
        }

        # Construct filter based on ObjectClass parameter
        $searchFilter = '(objectClass=objectClassSchema)'
        if (![string]::IsNullOrEmpty($ObjectClass)) {
            $searchFilter = "(&(objectClass=objectClassSchema)(ldapDisplayName=$ObjectClass))"
        }

        # 2. Query the schema for object class definitions
        Write-Verbose "Querying schema for objectClassSchema objects with filter: $searchFilter..."
        $objectClassSchemaSearchRequest = New-Object System.DirectoryServices.Protocols.SearchRequest(
            $schemaDN,
            $searchFilter,
            [System.DirectoryServices.Protocols.SearchScope]::OneLevel, # OneLevel for direct children of schemaNamingContext
            @('ldapDisplayName', 'objectClassCategory', 'governsID', 'superiorClasses', 'auxiliaryClasses', 'mustContain', 'mayContain', 'description')
        )
        $objectClassSchemasResponse = $ldapConnection.SendRequest($objectClassSchemaSearchRequest)

        $objectClasses = @()
        if ($objectClassSchemasResponse.Entries.Count -gt 0) {
            Write-Verbose "Found $($objectClassSchemasResponse.Entries.Count) object class definitions."
            foreach ($entry in $objectClassSchemasResponse.Entries) {
                $obj = [PSCustomObject]@{
                    ldapDisplayName     = if ($entry.Attributes['ldapDisplayName']) { $entry.Attributes['ldapDisplayName'].GetValues([string])[0] } else { $null }
                    objectClassCategory = if ($entry.Attributes['objectClassCategory']) { [int]::Parse($entry.Attributes['objectClassCategory'].GetValues([string])[0]) } else { $null }
                    governsID           = if ($entry.Attributes['governsID']) { $entry.Attributes['governsID'].GetValues([string])[0] } else { $null }
                    superiorClasses     = if ($entry.Attributes['superiorClasses']) { $entry.Attributes['superiorClasses'].GetValues([string]) } else { @() }
                    auxiliaryClasses    = if ($entry.Attributes['auxiliaryClasses']) { $entry.Attributes['auxiliaryClasses'].GetValues([string]) } else { @() }
                    mustContain         = if ($entry.Attributes['mustContain']) { $entry.Attributes['mustContain'].GetValues([string]) | ForEach-Object { ($_ -split '(?<=\d),(?=[a-zA-Z])')[-1] } } else { @() } # Extract name
                    mayContain          = if ($entry.Attributes['mayContain']) { $entry.Attributes['mayContain'].GetValues([string]) | ForEach-Object { ($_ -split '(?<=\d),(?=[a-zA-Z])')[-1] } } else { @() } # Extract name
                    description         = if ($entry.Attributes['description']) { $entry.Attributes['description'].GetValues([string])[0] } else { $null }
                }
                $objectClasses += $obj
            }
        }
        else {
            if (![string]::IsNullOrEmpty($ObjectClass)) {
                Write-Warning "Object class '$ObjectClass' not found in schema."
            }
            else {
                Write-Warning 'No object class definitions found in the schema.'
            }
        }
        return $objectClasses

    }
    catch {
        Write-Error "Error querying LDAP schema object classes: $($_.Exception.Message)"
        throw $_
    }
    finally {
        if ($ldapConnection) { $ldapConnection.Dispose() }
    }
}

function Get-LdapSchemaSyntax {
    <#
    .SYNOPSIS
    Queries an LDAP server's schema for attribute syntax definitions.

    .DESCRIPTION
    This function connects to an LDAP server over LDAPS and retrieves the definitions
    of attribute syntaxes supported by the directory. This helps understand the data types
    used for various attributes.

    .PARAMETER LdapServer
    The hostname or IP address of the LDAP server to connect to.

    .PARAMETER Port
    The TCP port for the LDAPS connection. The default is 636.

    .PARAMETER SyntaxOid
    (Optional) The OID of a specific attribute syntax to retrieve (e.g., "1.3.6.1.4.1.1466.115.121.1.15" for Directory String).
    If not specified, all syntax definitions will be returned.

    .PARAMETER LdapTimeout
    (Optional) The timeout for LDAP operations in milliseconds. Overrides the default timeout for this specific query.

    .PARAMETER Username
    (Optional) The username for binding to the LDAP server. If not provided,
    the current logged-in user's credentials will be attempted.

    .PARAMETER Password
    (Optional) The password for the binding user. Only required if Username is provided.

    .OUTPUTS
    An array of custom objects, each representing an LDAP attribute syntax definition with properties like
    name, oid, and description.

    .EXAMPLE
    # Get all attribute syntaxes in the schema
    Get-LdapSchemaSyntax -LdapServer "dc01.contoso.com"

    .EXAMPLE
    # Get details for the 'Directory String' syntax (OID 1.3.6.1.4.1.1466.115.121.1.15)
    Get-LdapSchemaSyntax -LdapServer "dc01.contoso.com" -SyntaxOid "1.3.6.1.4.1.1466.115.121.1.15"

    .EXAMPLE
    # Get syntaxes using current credentials
    Get-LdapSchemaSyntax -LdapServer "ldap.example.org"
    #>
    [CmdletBinding(DefaultParameterSetName = 'Default', SupportsShouldProcess = $false)]
    [OutputType('System.Management.Automation.PSCustomObject[]')] # Explicit OutputType
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$LdapServer,

        [Parameter(Mandatory = $false)]
        [int]$Port = 636,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$SyntaxOid, # Optional parameter for filtering by OID

        [Parameter(Mandatory = $false)]
        [int]$LdapTimeout, # Optional override for connection timeout

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$Username,

        [Parameter(Mandatory = $false)]
        [System.Security.SecureString]$Password
    )

    $ldapConnection = $null
    try {
        $connectParams = @{
            LdapServer = $LdapServer
            Port       = $Port
            Username   = $Username
            Password   = $Password
        }
        if ($PSBoundParameters.ContainsKey('LdapTimeout')) {
            $connectParams.LdapTimeout = $LdapTimeout
        }
        $ldapConnection = _GetLdapConnection @connectParams

        # 1. Query the RootDSE to get the schemaNamingContext
        Write-Verbose 'Querying RootDSE for schemaNamingContext...'
        $rootDSESearchRequest = New-Object System.DirectoryServices.Protocols.SearchRequest(
            '', # Base DN for RootDSE
            '(objectClass=*)',
            [System.DirectoryServices.Protocols.SearchScope]::Base,
            @('schemaNamingContext')
        )
        $rootDSESearchResponse = $ldapConnection.SendRequest($rootDSESearchRequest)

        $schemaDN = $null
        if ($rootDSESearchResponse.Entries.Count -gt 0) {
            $schemaEntry = $rootDSESearchResponse.Entries[0]
            if ($schemaEntry.Attributes['schemaNamingContext']) {
                $schemaDN = $schemaEntry.Attributes['schemaNamingContext'].GetValues([string])[0]
                Write-Verbose "Schema Naming Context: $schemaDN"
            }
        }

        if (-not $schemaDN) {
            Write-Error 'Could not determine the schemaNamingContext. Cannot query schema syntaxes.'
            return $null
        }

        # Construct filter based on SyntaxOid parameter
        $searchFilter = '(objectClass=dDS-Syntax)' # Common for syntaxes in AD; adjust for other LDAP servers
        if (![string]::IsNullOrEmpty($SyntaxOid)) {
            $searchFilter = "(&(objectClass=dDS-Syntax)(attributeID=$SyntaxOid))" # attributeID usually holds the OID
        }

        # 2. Query the schema for attribute syntax definitions
        Write-Verbose "Querying schema for attribute syntax objects with filter: $searchFilter..."
        $syntaxSchemaSearchRequest = New-Object System.DirectoryServices.Protocols.SearchRequest(
            $schemaDN,
            $searchFilter,
            [System.DirectoryServices.Protocols.SearchScope]::OneLevel, # OneLevel for direct children
            @('name', 'attributeID', 'description') # Common attributes for syntaxes
        )
        $syntaxSchemasResponse = $ldapConnection.SendRequest($syntaxSchemaSearchRequest)

        $syntaxes = @()
        if ($syntaxSchemasResponse.Entries.Count -gt 0) {
            Write-Verbose "Found $($syntaxSchemasResponse.Entries.Count) attribute syntax definitions."
            foreach ($entry in $syntaxSchemasResponse.Entries) {
                $obj = [PSCustomObject]@{
                    Name        = if ($entry.Attributes['name']) { $entry.Attributes['name'].GetValues([string])[0] } else { $null }
                    OID         = if ($entry.Attributes['attributeID']) { $entry.Attributes['attributeID'].GetValues([string])[0] } else { $null }
                    Description = if ($entry.Attributes['description']) { $entry.Attributes['description'].GetValues([string])[0] } else { $null }
                }
                $syntaxes += $obj
            }
        }
        else {
            if (![string]::IsNullOrEmpty($SyntaxOid)) {
                Write-Warning "Syntax with OID '$SyntaxOid' not found in schema."
            }
            else {
                Write-Warning 'No attribute syntax definitions found in the schema.'
            }
        }
        return $syntaxes

    }
    catch {
        Write-Error "Error querying LDAP schema syntaxes: $($_.Exception.Message)"
        throw $_
    }
    finally {
        if ($ldapConnection) { $ldapConnection.Dispose() }
    }
}

function Get-LdapDefaultNamingContext {
    <#
    .SYNOPSIS
    Retrieves the default naming context (search base) of an LDAP server.

    .DESCRIPTION
    This function connects to an LDAP server over LDAPS and queries its RootDSE
    (Directory Server Entry) to obtain the 'defaultNamingContext' attribute.
    This attribute represents the Distinguished Name (DN) of the domain partition
    and is commonly used as the search base for LDAP queries within that domain.

    .PARAMETER LdapServer
    The hostname or IP address of the LDAP server to connect to.

    .PARAMETER Port
    The TCP port for the LDAPS connection. The default is 636.

    .PARAMETER LdapTimeout
    (Optional) The timeout for LDAP operations in milliseconds. Overrides the default timeout for this specific query.

    .PARAMETER Username
    (Optional) The username for binding to the LDAP server. If not provided,
    the current logged-in user's credentials will be attempted.

    .PARAMETER Password
    (Optional) The password for the binding user. Only required if Username is provided.

    .OUTPUTS
    System.String. The Distinguished Name (DN) of the default naming context (e.g., "DC=yourdomain,DC=com").
    Returns $null if the default naming context cannot be retrieved.

    .EXAMPLE
    # Get the default naming context using current logged-in user's credentials
    Get-LdapDefaultNamingContext -LdapServer "dc01.contoso.com"

    .EXAMPLE
    # Get the default naming context using explicit credentials
    $SecurePassword = ConvertTo-SecureString "YourPassword123" -AsPlainText -Force
    Get-LdapDefaultNamingContext -LdapServer "ldap.example.org" `
                                 -Port 636 `
                                 -Username "serviceaccount@example.org" `
                                 -Password $SecurePassword

    .EXAMPLE
    # Store the default naming context in a variable for later use
    $DomainBaseDN = Get-LdapDefaultNamingContext -LdapServer "dc01.contoso.com"
    if ($DomainBaseDN) {
        Write-Host "Discovered domain base DN: $DomainBaseDN"
    } else {
        Write-Warning "Failed to discover domain base DN."
    }
    #>
    [CmdletBinding(DefaultParameterSetName = 'Default', SupportsShouldProcess = $false)]
    [OutputType('System.String')] # Explicit OutputType
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$LdapServer,

        [Parameter(Mandatory = $false)]
        [int]$Port = 636,

        [Parameter(Mandatory = $false)]
        [int]$LdapTimeout, # Optional override for connection timeout

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$Username,

        [Parameter(Mandatory = $false)]
        [System.Security.SecureString]$Password
    )

    $ldapConnection = $null
    try {
        $connectParams = @{
            LdapServer = $LdapServer
            Port       = $Port
            Username   = $Username
            Password   = $Password
        }
        if ($PSBoundParameters.ContainsKey('LdapTimeout')) {
            $connectParams.LdapTimeout = $LdapTimeout
        }
        $ldapConnection = _GetLdapConnection @connectParams

        Write-Verbose 'Querying RootDSE for defaultNamingContext...'
        $searchRequest = New-Object System.DirectoryServices.Protocols.SearchRequest(
            '', # Base DN for RootDSE is an empty string
            '(objectClass=*)', # Generic filter for any object
            [System.DirectoryServices.Protocols.SearchScope]::Base, # Scope is limited to the base entry
            @('defaultNamingContext') # Request only the defaultNamingContext attribute
        )

        $searchResponse = $ldapConnection.SendRequest($searchRequest)

        if ($searchResponse.Entries.Count -gt 0) {
            $rootDseEntry = $searchResponse.Entries[0]
            if ($rootDseEntry.Attributes['defaultNamingContext']) {
                $defaultNamingContext = $rootDseEntry.Attributes['defaultNamingContext'].GetValues([string])[0]
                Write-Host "Successfully retrieved defaultNamingContext: $defaultNamingContext"
                return $defaultNamingContext
            }
            else {
                Write-Warning 'defaultNamingContext attribute not found in RootDSE.'
                return $null
            }
        }
        else {
            Write-Warning 'No entries returned from RootDSE query. Cannot determine defaultNamingContext.'
            return $null
        }
    }
    catch {
        Write-Error "Error retrieving default naming context: $($_.Exception.Message)"
        throw $_
    }
    finally {
        if ($ldapConnection) {
            $ldapConnection.Dispose()
            Write-Verbose 'LDAP connection disposed.'
        }
    }
}

function Confirm-Credential {
    param(
        $UserName = $ENV:UserName,
        [Parameter(Mandatory = $True)] $Password,
        $Server = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain().Name
    )

    # Now we need to pickup the AuthKey
    Add-Type -AssemblyName System.DirectoryServices.AccountManagement

    # Create AD and Principal contexts
    $PrincipalContext = New-Object System.DirectoryServices.AccountManagement.PrincipalContext 'Domain', $Server

    # Validate Credentials
    $AuthResult = $PrincipalContext.ValidateCredentials(
        $UserName,
        $Password,
        ([System.DirectoryServices.AccountManagement.ContextOptions]::Negotiate)
    )

    return $AuthResult
}

function Write-WinEventLog {
    <#
    .SYNOPSIS
    Writes a standardized log entry to a specified Windows Event Log.

    .DESCRIPTION
    This function wraps the native Write-EventLog cmdlet to provide a consistent
    way to log messages from your PowerShell scripts or applications.
    It automatically manages the Event Log source registration and allows
    for flexible message types and event IDs.

    .PARAMETER LogName
    The name of the event log to write to (e.g., 'Application', 'System', 'Security',
    or a custom log name). Defaults to 'Application'.

    .PARAMETER Source
    The name of the application or script that is writing the event. This source
    will be automatically registered if it does not exist for the specified LogName.
    Defaults to 'MyPowerShellApp'.

    .PARAMETER EventID
    A numeric identifier for the event. This helps categorize events and is useful for filtering.
    Defaults to 1.

    .PARAMETER EntryType
    The severity level of the event. Accepted values: 'Information', 'Warning', 'Error',
    'SuccessAudit', 'FailureAudit'. Defaults to 'Information'.

    .PARAMETER Message
    The actual text content of the log entry. This is what will appear in Event Viewer.

    .OUTPUTS
    System.Void. This function does not return any objects directly, but writes to the Event Log.
    It will write host messages or errors during its operation.

    .EXAMPLE
    # Write an informational message to the Application log
    Write-WinEventLog -Message "Application started successfully." -EntryType Information -EventID 100

    .EXAMPLE
    # Write a warning message with a custom source and log name
    Write-WinEventLog -LogName "CustomLogs" -Source "DataProcessor" `
                      -Message "Input file not found, processing skipped for today." -EntryType Warning -EventID 201

    .EXAMPLE
    # Write an error message with detailed exception information
    try {
        # Simulate an error
        throw "Failed to connect to external service."
    } catch {
        Write-WinEventLog -LogName "Application" -Source "WebServerMonitor" `
                          -Message "Fatal error: $($_.Exception.Message)`nStack Trace: $($_.Exception.StackTrace)" `
                          -EntryType Error -EventID 500
    }

    .EXAMPLE
    # Write a success audit event to the Security log (requires elevated permissions)
    # Note: Writing to the Security log usually requires specific local security policy permissions.
    # Write-WinEventLog -LogName "Security" -Source "AuditLogger" `
    #                   -Message "User 'AdminUser' performed an administrative task." `
    #                   -EntryType SuccessAudit -EventID 9001
    #>
    [CmdletBinding(DefaultParameterSetName = 'Default', SupportsShouldProcess = $false)]
    [OutputType('System.Void')] # Explicit OutputType
    param(
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$LogName = 'Application',

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$Source = 'MyPowerShellApp',

        [Parameter(Mandatory = $false)]
        [int]$EventID = 1,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Information', 'Warning', 'Error', 'SuccessAudit', 'FailureAudit')]
        [string]$EntryType = 'Information',

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Message
    )

    # Check if the Event Log itself exists using System.Diagnostics.EventLog.Exists()
    if (-not ([System.Diagnostics.EventLog]::Exists($LogName))) {
        Write-Warning "Event Log '$LogName' does not exist. Attempting to create it and register source '$Source'."
        try {
            # New-EventLog will create the log and register the source.
            New-EventLog -LogName $LogName -Source $Source -ErrorAction Stop
            Write-Verbose "Event Log '$LogName' created successfully and source '$Source' registered."
        }
        catch {
            Write-Error "Failed to create Event Log '$LogName' and register source '$Source': $($_.Exception.Message)"
            Write-Warning 'Cannot write event. Please ensure sufficient permissions.'
            return # Exit the function if creation/registration fails
        }
    }
    else {
        # If the log exists, verify if the source is registered within that log using .NET
        if (-not ([System.Diagnostics.EventLog]::SourceExists($Source, $LogName))) {
            Write-Warning "Event Log source '$Source' is not registered for log '$LogName'. Attempting to register it."
            try {
                # New-EventLog will register the source for the existing log.
                New-EventLog -LogName $LogName -Source $Source -ErrorAction Stop
                Write-Verbose "Event Log source '$Source' registered successfully for log '$LogName'."
            }
            catch {
                Write-Warning "Failed to register Event Log source '$Source' for '$LogName': $($_.Exception.Message)"
                Write-Warning 'Attempting to write event anyway, but it might fail if source is not properly registered.'
            }
        }
        else {
            Write-Verbose "Event Log '$LogName' exists and source '$Source' is registered."
        }
    }

    # Write the event log entry using the native cmdlet
    try {
        Write-EventLog -LogName $LogName `
            -Source $Source `
            -EventId $EventID `
            -EntryType $EntryType `
            -Message $Message `
            -ErrorAction Stop # Ensure any error here is caught

        Write-Verbose "Successfully logged event (Type: $EntryType, ID: $EventID) to '$LogName' from source '$Source'."
    }
    catch {
        Write-Error "Failed to write Event Log entry: $($_.Exception.Message)"
    }
}

# Export all public functions from this module
Export-ModuleMember -Function `
    Send-LdapQuery, `
    Get-LdapObject, `
    New-LdapObject, `
    Remove-LdapObject, `
    Set-LdapObject, `
    Get-LdapSchemaAttribute, `
    Get-LdapServersFromDns, `
    Move-LdapObject, `
    Rename-LdapObject, `
    Test-LdapConnection, `
    Add-LdapGroupMember, `
    Remove-LdapGroupMember, `
    Get-LdapGroupMember, `
    Set-LdapUserPassword, `
    Enable-LdapAccount, `
    Disable-LdapAccount, `
    Unlock-LdapAccount, `
    Get-LdapDefaultNamingContext, `
    Write-WinEventLog
