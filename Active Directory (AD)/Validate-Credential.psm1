Function Validate-Credential {
    Param(
        $UserName = $ENV:UserName,
        [Parameter(Mandatory = $True)]$Password,
        $Server = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain().Name
    )

    # Now we need to pickup the AuthKey
    Add-Type -AssemblyName System.DirectoryServices.AccountManagement

    # Create AD and Principal contexts
    $PrincipalContext = New-Object System.DirectoryServices.AccountManagement.PrincipalContext 'Domain', $Server

    # Validate our creds
    $AuthResult = $PrincipalContext.ValidateCredentials(
        $UserName,
        $Password,
        ([System.DirectoryServices.AccountManagement.ContextOptions]::Negotiate)
    )

    Return $AuthResult
}