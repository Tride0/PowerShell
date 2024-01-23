<#
    .NOTES
        Created By: Kyle Hewitt
        Created On: 04-25-2022
        Version: 2022.7.19

        Description: This module is simple and can hopefully be built upon easily.
#>

$OktaVerbose = $False

$Global:OktaTenant = @{
    OktaURL  = ''
    APIToken = ''
}

# These are used to help with older https protocols
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12


#region General Okta Functions

Function _GetOktaHeaders {
    $Headers = @{
        Accept          = 'application/json'
        'Content-Type'  = 'application/json'
        'Authorization' = "SSWS $($Global:OktaTenant.APIToken)"
    }
    Write-Verbose "Headers $($Headers | ConvertTo-Json)" -Verbose:$OktaVerbose
    Return $Headers
}

Function _MakeOktaCall {
    [CmdletBinding()]
    Param(
        $UriExtension,
        $Method,
        $Body
    )

    $Uri = "$($Global:OktaTenant.OktaURL)$UriExtension"
    Write-Verbose "$Method $Uri" -Verbose:$OktaVerbose
    
    $InvokeRestmethodSplat = @{
        Uri     = $Uri
        Method  = $Method
        Headers = $(_GetOktaHeaders)
    }

    If ([Boolean]$Body) {
        Write-Verbose "Body $Body" -Verbose:$OktaVerbose
        $InvokeRestmethodSplat.Body = $Body
    }

    Invoke-RestMethod @InvokeRestmethodSplat -Verbose:$OktaVerbose
    #Invoke-WebRequest @InvokeRestmethodSplat
}

#endregion General Okta Functions


#region Users

Function Get-OktaUser {
    [CmdletBinding()]
    Param($UserName)
    Write-Verbose 'Getting Okta User Account' -Verbose:$OktaVerbose
    _MakeOktaCall -UriExtension "/api/v1/users/$UserName" -Method GET
}

Function Get-OktaUserApplications {
    [CmdletBinding()]
    Param($UserName)
    Write-Verbose 'Getting Okta User Applications' -Verbose:$OktaVerbose
    $OktaUser = Get-OktaUser -UserName $UserName
    _MakeOktaCall -UriExtension "/api/v1/apps?filter=user.id+eq+%22$($OktaUser.id)%22&expand=user/$($OktaUser.id)" -Method GET
}

Function Get-OktaUserAppLinks {
    [CmdletBinding()]
    Param($UserName)
    Write-Verbose 'Getting Okta User Account' -Verbose:$OktaVerbose
    _MakeOktaCall -UriExtension "/api/v1/users/$UserName/appLinks" -Method GET
}

#endregion Users


#region Groups

Function Get-OktaGroup {
    [CmdletBinding()]
    Param($GroupID)
    Write-Verbose 'Getting Okta Group' -Verbose:$OktaVerbose
    _MakeOktaCall -UriExtension "/api/v1/groups/$GroupID" -Method GET
}


Function Find-OktaGroup {
    [CmdletBinding()]
    Param($Query, [int]$Limit = 1)
    Write-Verbose 'Finding Okta Group' -Verbose:$OktaVerbose
    _MakeOktaCall -UriExtension "/api/v1/groups?q=$Query&limit=$Limit" -Method GET
}


Function Add-OktaGroupMember {
    [CmdletBinding()]
    Param($GroupID, $UserID)
    Write-Verbose 'Adding Okta Group Member' -Verbose:$OktaVerbose
    _MakeOktaCall -UriExtension "/api/v1/groups/$GroupID/users/$UserID" -Method PUT
}


Function Remove-OktaGroupMember {
    [CmdletBinding()]
    Param($GroupID, $UserID)
    Write-Verbose 'Adding Okta Group Member' -Verbose:$OktaVerbose
    _MakeOktaCall -UriExtension "/api/v1/groups/$GroupID/users/$UserID" -Method DELETE
}

Function Get-OktaGroupMembers {
    [CmdletBinding()]
    Param($GroupID, $limit = 200)
    Write-Verbose 'Getting Okta Group Members' -Verbose:$OktaVerbose
    _MakeOktaCall -UriExtension "/api/v1/groups/$GroupID/users?limit=$limit" -Method GET
}

#endregion Groups


#region Factors

Function Get-OktaUserFactorsToEnroll {
    [CmdletBinding()]
    Param($UserName)
    $OktaUser = Get-OktaUser -UserName $UserName
    Write-Verbose "Getting Okta User's Factors" -Verbose:$OktaVerbose
    _MakeOktaCall -UriExtension "/api/v1/users/$($OktaUser.id)/factors/catalog" -Method GET
}

Function Get-OktaUserFactor {
    [CmdletBinding()]
    Param($UserName, $FactorID)
    $OktaUser = Get-OktaUser -UserName $UserName
    Write-Verbose "Getting Okta User's Factors" -Verbose:$OktaVerbose
    If ($FactorID) {
        $FactorIDURL = "/$FactorID"
    }
    _MakeOktaCall -UriExtension "/api/v1/users/$($OktaUser.id)/factors$FactorIDURL" -Method GET
}

Function Reset-OktaUserFactor {
    [CmdletBinding()]
    Param($UserName, $FactorID)
    $OktaUser = Get-OktaUser -UserName $UserName
    Write-Verbose "Resetting Okta User's Factor" -Verbose:$OktaVerbose
    _MakeOktaCall -UriExtension "/api/v1/users/$($OktaUser.id)/factors/$FactorID" -Method DELETE
}

Function Enroll-OktaUserCallFactor {
    [CmdletBinding()]
    Param($UserName, $PhoneNumber, [Switch]$Activate)
    $OktaUser = Get-OktaUser -UserName $UserName

    [String]$Body = [ordered]@{
        factorType = 'call'
        provider   = 'OKTA'
        profile    = [ordered]@{
            phoneNumber = $PhoneNumber
        }
    } | ConvertTo-Json
    
    If ($Activate.IsPresent) {
        $ActivatationURL = '?activate=true'
    }

    #$Body = "{`n  `"factorType`": `"call`",`n  `"provider`": `"OKTA`",`n  `"profile`": {`n    `"phoneNumber`": `"$PhoneNumber`"`n  }`n}"

    Write-Verbose 'Enrolling User into Okta Call Factor' -Verbose:$OktaVerbose
    _MakeOktaCall -UriExtension "/api/v1/users/$($OktaUser.id)/factors$ActivatationURL" -Method POST -Body $Body
}

#endregion Factors