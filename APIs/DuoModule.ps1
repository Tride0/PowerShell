<#
    .NOTES
        Created By: Kyle Hewitt
        Created On: 05-10-2022
        Version: 2022.5.12
        
        Description: This module is simple and can hopefully be built upon easily.
        Functions: When creating a new function for calling the API. Adding the DuoTenant parameter will allow other Duo Tenants to be selected for your command.

#>

$DuoVerbose = $False
$DuoDebug = $false
$PrimaryDuoTenant = 'prod'

$DuoTenants = @{
    prod = @{
        DuoURL = '' # api-XXXXXXXX.duosecurity.com
        iKey   = ''
        sKey   = ''
    }
    prev = @{
        DuoURL = '' # api-XXXXXXXX.duosecurity.com
        iKey   = ''
        sKey   = ''
    }
}

# These are used to help with older https protocols
[Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls -bor [System.Net.SecurityProtocolType]::Tls11 -bor [System.Net.SecurityProtocolType]::Tls12
[System.Reflection.Assembly]::LoadWithPartialName('System.Web') | Out-Null

#region Variables

$Global:SelectedDuoTenant = $DuoTenants.$PrimaryDuoTenant

#endregion Variables


#region Auth and Base Call Functions

function _duoCanonicalizeParams() {
    param(
        [hashtable]$parameters
    )
    
    If ($parameters.Count -ge 1) {
        $ret = New-Object System.Collections.ArrayList

        foreach ($key in $parameters.keys) {
            [string]$param = [System.Web.HttpUtility]::UrlEncode($key) + '=' + [System.Web.HttpUtility]::UrlEncode($parameters[$key])
            # Signatures require upper-case hex digits.
            $param = [regex]::Replace($param, '(%[0-9A-Fa-f][0-9A-Fa-f])', { $args[0].Value.ToUpperInvariant() })
            $param = [regex]::Replace($param, "([!'()*])", { '%' + [System.Convert]::ToByte($args[0].Value[0]).ToString('X') })
            $param = $param.Replace('%7E', '~')
            $param = $param.Replace('+', '%20')
            $ret.Add($param) | Out-Null
        }

        $ret.Sort([System.StringComparer]::Ordinal)
        [string]$canon_params = [string]::Join('&', ($ret.ToArray()))
        
        Write-Debug ("_duoCanonicalizeParams`n" + $canon_params) -Debug:$DuoDebug
    }
    else {
        $canon_params = ''
    }
    return $canon_params
}

function _duoCanonicalizeRequest() {
    param
    (
        [string]$XDuoDate,
        [string]$method,
        [string]$path,
        [string]$canon_params
    )

    [string[]]$lines = @(
        $XDuoDate.Trim(), 
        $method.ToUpperInvariant().Trim(), 
        $Global:SelectedDuoTenant.DuoURL.ToLower().Trim(), 
        $path.Trim(), 
        $canon_params.Trim()
    )
    [string]$canon = [string]::Join("`n", $lines)

    Write-Debug ("_duoCanonicalizeRequest`n" + $canon) -Debug:$DuoDebug
    return $canon
}

function _duoHmacSign() {
    param(
        [string]$data
    )

    If ($Global:SelectedDuoTenant.sKey) {
        [byte[]]$key_bytes = [System.Text.Encoding]::UTF8.GetBytes(
            [Runtime.InteropServices.Marshal]::PtrToStringAuto(
                [Runtime.InteropServices.Marshal]::SecureStringToBSTR(
                    (ConvertTo-SecureString -String ($Global:SelectedDuoTenant.sKey).ToString() -AsPlainText -Force)
                ) 
            )
        )
    }
    else {
        [byte[]]$key_bytes = [System.Text.Encoding]::UTF8.GetBytes($Global:SelectedDuoTenant.sKey)
    }

    [byte[]]$data_bytes = [System.Text.Encoding]::UTF8.GetBytes($data)

    $hmacsha1 = New-Object System.Security.Cryptography.HMACSHA1
    $hmacsha1.Key = $key_bytes
        
    $hmacsha1.ComputeHash($data_bytes) | Out-Null
    $hash_hex = [System.BitConverter]::ToString($hmacsha1.Hash)

    $response = $hash_hex.Replace('-', '').ToLower()
    
    Write-Debug ("_duoHmacSign`n" + $response) -Debug:$DuoDebug
    return $response
}

function _duoEncode64() {
    param($plainText)
    $Return = [System.Convert]::ToBase64String([byte[]][System.Text.Encoding]::ASCII.GetBytes($plainText))
    Write-Debug ("_duoEncode64`n" + $Return) -Debug:$DuoDebug
    return $Return
}

function _duoSign() {
    param
    (
        [string]$XDuoDate,
        [string]$method,
        [string]$path,
        [string]$canon_params
    )

    [string]$canon = _duoCanonicalizeRequest -XDuoDate $XDuoDate -method $method -path $path -canon_params $canon_params
    [string]$sig = _duoHmacSign -data $canon
    [string]$auth = $Global:SelectedDuoTenant.iKey + ':' + $sig
    $basic = _duoEncode64 -plainText $auth
    
    Write-Debug ("_duoSign`n" + $basic) -Debug:$DuoDebug
    return "Basic $basic"
}

Function _MakeDuoCall {
    Param(
        $UriExtension,
        $Method,
        [HashTable]$Params
    )
    
    # Select Dou Tenant
    If ($Params.Keys -Contains 'DuoTenant') {
        $Params.Remove('DuoTenant') | Out-Null
        $Global:SelectedDuoTenant = $DuoTenants.$DuoTenant
    }
    ElseIf ([Boolean]$PrimaryDuoTenant) {
        $Global:SelectedDuoTenant = $DuoTenants.$PrimaryDuoTenant
    }
    Else {
        $Global:SelectedDuoTenant = $DuoTenants.GetEnumerator() | Select-Object -First 1 -ExpandProperty Value
    }

    $InvokeRestmethodSplat = @{
        Method  = $Method
        Headers = @{
            Accept = 'application/json'
        }
    }

    # Parameters
    If ($Params.Count -gt 0) {
        If ($DuoVerbose) {
            Foreach ($Param in $Params.GetEnumerator()) {
                Write-Verbose "Param: $($Param.Key) = $($Param.Value)" -Verbose:$DuoVerbose
            }
        }


        $CanonParams = _duoCanonicalizeParams $Params
        If ('GET', 'DELETE' -contains $Method) {
            $ParamURL = "?$CanonParams"
        }
        Else {
            $InvokeRestmethodSplat.Headers.'ContentType' = 'application/x-www-form-urlencoded'
            
            $bytes = [System.Text.Encoding]::UTF8.GetBytes($CanonParams)
            $InvokeRestmethodSplat.Headers.'ContentLength' = $bytes.Length

            $InvokeRestmethodSplat.Body = $bytes
        }
    }

    If ([Boolean]$InvokeRestmethodSplat.Body) {
        Write-Verbose "Body: $($InvokeRestmethodSplat.Body)" -Verbose:$DuoVerbose
    }

    # Headers
    $XDuoDate = "$((Get-Date).ToUniversalTime().ToString('ddd, dd MMM yyyy HH:mm:ss -0000', ([System.Globalization.CultureInfo]::InvariantCulture)))"
    $InvokeRestmethodSplat.Headers.'X-Duo-Date' = $XDuoDate
    
    $Auth = "$(_duoSign -method $Method -path $UriExtension -canon_params $CanonParams -XDuoDate $XDuoDate)"
    $InvokeRestmethodSplat.Headers.'Authorization' = $Auth
    
    If ($DuoVerbose) {
        Foreach ($Header in $InvokeRestmethodSplat.Headers.GetEnumerator()) {
            Write-Verbose "Header: $($Header.Key) = $($Header.Value)" -Verbose:$DuoVerbose
        }
    }

    # URL
    $InvokeRestmethodSplat.Uri = 'https://' + $($Global:SelectedDuoTenant.DuoURL) + $UriExtension + $ParamURL
    
    Write-Verbose "Method: $Method" -Verbose:$DuoVerbose
    Write-Verbose "URL: $($InvokeRestmethodSplat.Uri)" -Verbose:$DuoVerbose


    # API Call
    Try {
        Invoke-RestMethod @InvokeRestmethodSplat -Verbose:$DuoVerbose -ErrorAction Stop | 
            Select-Object -ExpandProperty response
    }
    Catch {
        Throw $_
    }
    Finally {
        If ($PrimaryDuoTenant -ne $DuoTenant -and [Boolean]$PrimaryDuoTenant) {
            $Global:SelectedDuoTenant = $DuoTenants.$PrimaryDuoTenant
        }
    }
}

#endregion Auth and Base Call Functions


#region API Call Functions

#region User Functions

Function New-DuoUser {
    [CmdletBinding()]
    Param(
        $username,
        $alias1,
        $alias2,
        $alias3,
        $alias4,
        $aliases,
        $realname,
        $email,
        [ValidateSet('active', 'bypass', 'disabled')]$status,
        $notes,
        $firstname,
        $lastname,
        $DuoTenant
    )
    Write-Verbose 'Creating Duo User Account' -Verbose:$DuoVerbose
    _MakeDuoCall -UriExtension '/admin/v1/users' -Method POST -Params $PSBoundParameters
}

Function Remove-DuoUser {
    [CmdletBinding()]
    Param($user_id, $DuoTenant)
    Write-Verbose 'Getting Duo User Account' -Verbose:$DuoVerbose
    _MakeDuoCall -UriExtension "/admin/v1/users/$user_id" -Method DELETE
}

Function Get-DuoUser {
    [CmdletBinding()]
    Param($username, $user_id, $DuoTenant)
    Write-Verbose 'Getting Duo User Account' -Verbose:$DuoVerbose
    If ($username) {
        _MakeDuoCall -UriExtension '/admin/v1/users' -Method GET -Params $PSBoundParameters
    }
    ElseIf ($user_id) {
        _MakeDuoCall -UriExtension "/admin/v1/users/$user_id" -Method GET
    }
}

function Set-DuoUser {
    [CmdletBinding()]
    param (
        [ValidateLength(20, 20)][String]$user_id,
        [String]$alias1,
        [String]$alias2,
        [String]$alias3,
        [String]$alias4,
        [hashtable]$aliases,
        [ValidateLength(1, 100)][String]$realname,
        [ValidateLength(1, 100)][String]$email,
        [validateset('active', 'disabled', 'bypass')][String]$status,
        [String]$notes,
        [ValidateLength(1, 100)][String]$firstname,
        [ValidateLength(1, 100)][String]$lastname,
        [ValidateLength(1, 100)][String]$NewUserName,
        $DuoTenant
    )
    
    $PSBoundParameters.Remove('user_id') | Out-Null


    $aliasArray = @()
    If ([Boolean]$aliases) {
        'alias1', 'alias2', 'alias3', 'alias4' | ForEach-Object -Process { 
            If ($PSBoundParameters.ContainsKey($_)) {
                $PSBoundParameters.Remove($_) | Out-Null 
            }
        }

        Foreach ($alias in $aliases.GetEnumerator()) {
            If ($parameters.keys -notcontains $alias.key) {
                $aliasArray += "$($alias.key)=$($alias.value)"
            }
        }
        If ([Boolean]$aliasArray) { $PSBoundParameters.aliases = "$($aliasArray -join '&')" }
        Else { $PSBoundParameters.Remove('aliases') | Out-Null }
    }

    Write-Verbose 'Setting Duo User Account' -Verbose:$DuoVerbose
    _MakeDuoCall -UriExtension "/admin/v1/users/$user_id" -Method POST -Params $PSBoundParameters
}

#endregion User Functions

#region Phone Functions

Function Get-DuoPhone {
    [CmdletBinding()]
    Param($number, $extension, $phone_id, $DuoTenant)
    Write-Verbose 'Getting Duo Phone' -Verbose:$DuoVerbose
    If ($number) {
        _MakeDuoCall -UriExtension '/admin/v1/phones' -Method GET -Params $PSBoundParameters
    }
    Elseif ($phone_id) {
        _MakeDuoCall -UriExtension "/admin/v1/phones/$phone_id" -Method GET 
    }
}

Function New-DuoPhone {
    [CmdletBinding()]
    Param($number, $name, $extension, $type, $platform, $predelay, $postdelay, $DuoTenant)
    Write-Verbose 'Creating Duo Phone' -Verbose:$DuoVerbose
    _MakeDuoCall -UriExtension '/admin/v1/phones' -Method POST -Params $PSBoundParameters
}

Function Remove-DuoPhone {
    [CmdletBinding()]
    Param($phone_id, $DuoTenant)
    Write-Verbose 'Deleting Duo Phone' -Verbose:$DuoVerbose
    _MakeDuoCall -UriExtension "/admin/v1/phones/$phone_id" -Method DELETE
}

Function New-DuoUserPhoneAssociation {
    [CmdletBinding()]
    Param($user_id, $phone_id, $DuoTenant)
    Write-Verbose "Assocating Duo Phone $phone_id to Duo User $user_id" -Verbose:$DuoVerbose
    _MakeDuoCall -UriExtension "/admin/v1/users/$user_id/phones" -Method POST -Params @{ phone_id = $phone_id }
}

Function Remove-DuoUserPhoneAssociation {
    [CmdletBinding()]
    Param($user_id, $phone_id, $DuoTenant)
    Write-Verbose "Removing Assocation between Duo Phone $phone_id and Duo User $user_id" -Verbose:$DuoVerbose
    _MakeDuoCall -UriExtension "/admin/v1/users/$user_id/phones/$phone_id" -Method DELETE
}

#endregion Phone Functions

#endregion API Call Functions