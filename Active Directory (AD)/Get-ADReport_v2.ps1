<#
    Created By: Kyle Hewitt
    Created On: 2023-12-13
    Version: 2023.12.13
    Name: Get-ADReports
    Description: Generates reports about AD
#>
param(
    $Domains = @(

    ),
    $ExportFolder = "$PSScriptRoot\Exports\$(Get-Date -Format yyyy\\MM\\dd)",
    $LogPath = "$PSScriptRoot\Logs\File_$(Get-Date -Format yyyyMMdd_hhmmss).Log",
    $LogOutput = $True,
    $ConsoleOutput = $True,
    $EmailSplat = @{
        SmtpServer  = ''
        Port        = 25
        From        = ''
        To          = ''
        Subject     = ''
        BodyAsHtml  = $True
        Attachments = $LogPath
        ErrorAction = 'Stop'
        Body        = "
            <b>WHAT:</b> This email is an accumulation of reports about the state of AD.<br>
            <b>Server:</b> $ENV:ComputerName<br>
            <b>Report Folder:</b> $ExportFolder<br>
            <b>Start:</b> $(Get-Date)<br>
            <b>End:</b> [END]<br>
            <b>Duration:</b> [DURATION]<br>
        "
    }
)
begin {
    $ScriptStopWatch = [System.Diagnostics.Stopwatch]::StartNew()

    #region Functions

    function Add-ToLog {
        param(
            [Parameter(ValueFromPipeline)] $Value,
            $Path = $LogPath,
            $PrefixLineBreaks = 0,
            $SuffixLineBreaks = 0
        )
        if ($PrefixLineBreaks -gt 0) {
            $LogPrefix = "`n" * $PrefixLineBreaks
        }
        if ($SuffixLineBreaks -gt 0) {
            $LogSuffix = "`n" * $SuffixLineBreaks
        }
        if ($ConsoleOutput) {
            Write-Host "$LogPrefix[$(Get-Date)] $Value$LogSuffix"
        }
        if ($LogOutput) {
            "$LogPrefix[$(Get-Date)] $Value$LogSuffix" | Add-Content -Path $Path -Force
        }
    }

    function Find-ADObject {
        # Add getting all group members member;range=0-1499 attr;range=0-1499
        <#
        .NOTES
            Created By: Kyle Hewitt
            Created On: 1/1/2019
            Version: 2021.04.12
    #>
        [alias('Find-ADO', 'FindADO', 'FADO')]
        [cmdLetBinding()]
        param(
            [Parameter(ParameterSetName = 'ID',
                Position = 0, Mandatory,
                ValueFromPipeline, ValueFromPipelineByPropertyName)]
            [String[]]$Identifier,

            [Parameter(ParameterSetName = 'ID',
                Position = 1, Mandatory = $False)]
            [String]$SearchByAttribute,

            [Parameter(ParameterSetName = 'Filter')]
            [String]$LDAPFilter,

            [Parameter(Position = 2)]
            [String[]]$ReturnAttribute = 'distinguishedname',

            [int]$ResultCount,
            [int]$PageSize,

            [ValidateScript({ $_ -match '\b([LDAPGCSldapgcs]{1,5}:\/\/)?([a-zA-Z0-9.]{1,}\/)?([a-zA-Z]{2}=.{1,},?){2,}\b' })]
            [String]$SearchRootPath,

            [ValidateSet('GC', 'LDAP')]
            [String]$Protocol = 'LDAP',

            [String]$Server,

            [ValidateScript( { $_ -like '*.*' })]
            [String]$Domain,

            [String]$UserName,
            [String]$Password,

            [Switch]$ArrayToString = $False,
            [String[]]$ArrayToStringDelimiters = @(',', ';'),

            [Switch]$ExpandMembers,
            [String[]]$ExpandedAttributes = @('distinguishedname', 'samaccountname', 'enabled')
        )
        begin {
            function FormatInfo {
                param($ReturnAttribute, [Parameter(ValueFromPipeline)]$Object)
                process {
                    $Result = [System.Collections.Specialized.OrderedDictionary]@{}

                    if ($ReturnAttribute -eq '*') { [String[]]$Attributes = $Object.Properties.Keys }
                    else { [String[]]$Attributes = $ReturnAttribute }

                    foreach ($Attr in ($Attributes.ToLower() | Sort-Object)) {
                        if ($Attr -eq 'lastlogondate') { $SearchAttr = 'lastlogontimestamp' }
                        elseif ($Attr -eq 'passwordlastset') { $SearchAttr = 'pwdlastset' }
                        elseif ($Attr -eq 'sid') { $SearchAttr = 'objectsid' }
                        elseif ($Attr -eq 'guid') { $SearchAttr = 'objectguid' }
                        elseif ($Attr -eq 'members') { $SearchAttr = 'member' }
                        elseif ('dn', 'domain', 'domainPreFix' -contains $Attr) { $SearchAttr = 'distinguishedname' }
                        elseif ('usercert', 'cert' -contains $Attr) { $SearchAttr = 'usercertificate' }
                        elseif ('uac', 'Enabled', 'LockedOut', 'Disabled', 'passwordneverexpires', 'passwordexpired', 'passwordnotrequired', 'passwordcantchange', 'smartcardrequired' -contains $Attr) {
                            $SearchAttr = 'useraccountcontrol'
                        }
                        elseif ('parentou', 'parent', 'ou' -contains $Attr) { $SearchAttr = 'distinguishedname' }
                        elseif ('sam', 'san' -contains $Attr) { $SearchAttr = 'samaccountname' }
                        elseif ('upn' -contains $Attr) { $SearchAttr = 'userprincipalname' }
                        else { $SearchAttr = $Attr }

                        $AttrValue = $($Object.Properties.$SearchAttr)

                        if ('lastlogondate', 'lastlogontimestamp', 'lastlogon', 'pwdlastset', 'badpasswordtime', 'passwordlastset' -contains $Attr) {
                            $Value = [DateTime]::FromFileTime($Attrvalue)
                            if ($Value -eq '12/31/1600 5:00:00 PM') { $value = '' }
                            $Result.Add($Attr, $Value)
                        }
                        elseif ('parent', 'parentou', 'ou' -contains $Attr) {
                            $Split = $AttrValue -split ',' -like '*=*'
                            $value = $Split[1..($Split.Count)] -join ','
                            $Result.Add($Attr, $Value)
                        }
                        elseif ( $Attr -eq 'domain') {
                            $Value = $AttrValue -split ',' -like 'DC=*' -replace 'DC=' -join '.'
                            $Result.Add($Attr, $Value)
                        }
                        elseif ( $Attr -eq 'domainPreFix') {
                            $Value = ($AttrValue -split ',' -like 'DC=*' -replace 'DC=')[0]
                            $Result.Add('domainPreFix', $Value)
                        }
                        elseif ('objectsid', 'sid' -contains $Attr) {
                            $value = (New-Object System.Security.Principal.SecurityIdentifier($AttrValue, 0)).Value
                            $Result.Add($Attr, $value)
                        }
                        elseif ('objectguid', 'guid' -contains $Attr) {
                            $Value = ([System.Guid]$AttrValue).guid
                            $Result.Add($Attr, $Value)
                        }
                        elseif ($Attr -eq 'Enabled') {
                            $Value = [convert]::ToString($AttrValue, 2)[-2] -eq '0'
                            $Result.Add($Attr, $Value)
                        }
                        elseif ($Attr -eq 'Disabled') {
                            $Value = [convert]::ToString($AttrValue, 2)[-2] -eq '1'
                            $Result.Add($Attr, $Value)
                        }
                        elseif ($Attr -eq 'LockedOut') {
                            $Value = [convert]::ToString($AttrValue, 2)[-5] -eq '0' -and $_.lockouttime -gt 0
                            $Result.Add($Attr, $Value)
                        }
                        elseif ($Attr -eq 'smartcardrequired') {
                            $Value = [convert]::ToString($AttrValue, 2)[-19] -eq '1'
                            $Result.Add($Attr, $Value)
                        }
                        elseif ($Attr -eq 'passwordcantchange') {
                            $Value = [convert]::ToString($AttrValue, 2)[-6] -eq '1'
                            $Result.Add($Attr, $Value)
                        }
                        elseif ($Attr -eq 'passwordnotrequired') {
                            $Value = [convert]::ToString($AttrValue, 2)[-7] -eq '1'
                            $Result.Add($Attr, $Value)
                        }
                        elseif ($Attr -eq 'passwordexpired') {
                            $Value = [convert]::ToString($AttrValue, 2)[-17] -eq '1'
                            $Result.Add($Attr, $Value)
                        }
                        elseif ($Attr -eq 'passwordneverexpires') {
                            $Value = [convert]::ToString($AttrValue, 2)[-24] -eq '1'
                            $Result.Add($Attr, $Value)
                        }
                        elseif ('useraccountcontrol', 'uac' -contains $Attr) {
                            $Result.Add($Attr, $AttrValue)
                            $Num = "$($AttrValue)"
                            $Power = 26
                            $PowerHash = @{
                                26 = 'Partial Secrets Account'
                                24 = 'Trusted To Authenticate For Delegation'
                                23 = 'Password Expired'
                                22 = 'Dont Require PreAuth'
                                21 = 'Use DES Key Use'
                                20 = 'Not Delegated'
                                19 = 'Trusted For Delegation'
                                18 = 'Smartcard Required'
                                17 = 'MNS Logon Account'
                                16 = 'Dont Expire Password'
                                13 = 'Server Trust Account'
                                12 = 'WorkStation Trust Account'
                                11 = 'InterDomain  Trust Account'
                                9  = 'Normal Account'
                                8  = 'Temp Duplicate Account'
                                7  = 'Encrypted Text Password Allowed'
                                6  = 'Password Cant Change'
                                5  = 'Password Not Required'
                                3  = 'Locked Out'
                                2  = 'HomeDir Required'
                                1  = 'Disabled'
                                0  = 'Script'
                            }
                            do {
                                $Test = [Math]::Pow(2, $Power)
                                if (($Num - $Test) -ge 0) {
                                    $Result.Add($PowerHash.$Power, 'True')
                                    $Num = $Num - $Test
                                }
                                $Power--
                            } while ($Power -ge 0)

                            foreach ($Item in $PowerHash.Values) {
                                if (![Bool]$Result.$Item) {
                                    $Result.Add($Item, 'False')
                                }
                            }

                        }
                        elseif ('usercertificate', 'cert', 'usercert' -contains $Attr) {
                            $Result.Add($Attr, $AttrValue)
                            if ($ReturnAttribute -ne '*') {
                                ($Cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2).Import($AttrValue)
                                $Summary = ('DNSNameList', 'Thumbprint', 'SerialNumber', 'Issuer', 'Subject', 'NotAfter', 'NotBefore').ForEach({ "$_ :: $($Cert.$_)" }) -join "`n"
                                $Result.Add("$Attr translated", $Cert)
                                $Result.Add("$Attr Summary", $Summary)
                            }
                        }
                        elseif ('member', 'members', 'memberof' -contains $Attr) {
                            if (([array]$AttrValue).Count -eq 0 -and $Object.Properties.Item($Object.Properties.PropertyNames -like "$SearchAttr;range=*").Count -gt 0) {
                                $Searcher.Filter = "(distinguishedname=$($Object.Properties.distinguishedname))"
                                $RetrievedAllItems = $False
                                $RangeTop = $RangeBottom = 0
                                $AllMembers = @()
                                while (-not $RetrievedAllItems) {
                                    $RangeTop = $RangeBottom + 1500
                                    $Searcher.PropertiesToLoad.Clear()
                                    [Void] $Searcher.PropertiesToLoad.Add("$SearchAttr;range=$RangeBottom-$RangeTop")
                                    $RangeBottom += 1500

                                    try {
                                        $TempInfo = $Searcher.FindOne().Properties
                                        $AllMembers += $TempInfo.Item($TempInfo.PropertyNames -like "$SearchAttr;range=*")

                                        if ($TempInfo.Item($TempInfo.PropertyNames -like "$SearchAttr;range=*").Count -eq 0) { $RetrievedAllItems = $True }

                                        Remove-Variable -Name TempInfo -ErrorAction SilentlyContinue -Verbose:$False
                                    }
                                    catch { $RetrievedAllItems = $True }
                                }

                                $AttrValue = $AllMembers.Clone()

                                $AllMembers.Clear()
                                Remove-Variable AllMembers -ErrorAction SilentlyContinue -Verbose:$False

                            }

                            if ($ExpandMembers.IsPresent) {
                                $ExpandedMembers = @()
                                foreach ($SubObject in $AttrValue) {
                                    $SubObjectDomain = $SubObject -split ',' -like 'DC=*' -replace 'DC=' -join '.'
                                    $ExpandedMembers += Find-ADObject -Identifier $SubObject -SearchByAttribute distinguishedname -ReturnAttribute $ExpandedAttributes -Domain $SubObjectDomain -UserName $UserName -Password $Password -ExpandMembers -Verbose:$False
                                    Remove-Variable SubObjectDomain, SubObject -ErrorAction SilentlyContinue -Verbose:$False
                                }
                                $AttrValue = $ExpandedMembers.Clone()
                                $ExpandedMembers.Clear()
                                Remove-Variable ExpandedMembers -ErrorAction SilentlyContinue -Verbose:$False

                            }

                            $Result.Add($Attr, $AttrValue)
                        }
                        else {
                            $Result.Add($Attr, $AttrValue)
                        }
                    }

                    [string[]]$keys = $Result.keys
                    # Remove values that don
                    foreach ($Attr in ($Keys -like '*;range=*')) {
                        $Split = $Attr.Split(';')
                        if (($Result.($Split[0])).Count -gt 0) {
                            $Result.Remove($Attr)
                        }
                    }

                    # Convert All Values to String
                    if ($ArrayToString.IsPresent) {
                        foreach ($Attr in $Keys) {
                            $AttrValue = $Result.$Attr
                            if ($AttrValue.count -gt 1) {
                                if ($AttrValue -is [byte[]]) {
                                    $AttrValue = $AttrValue -join ' '
                                }
                                else {
                                    :Join foreach ($Delimiter in $ArrayToStringDelimiters) {
                                        if ("$($AttrValue)" -notlike "*$Delimiter*") {
                                            $AttrValue = $AttrValue -join $Delimiter
                                            break Join
                                        }
                                    }
                                    if ($AttrValue -is [array]) {
                                        $AttrValue = $AttrValue -join "`n"
                                    }
                                }
                                $Result.$Attr = $AttrValue
                            }
                        }
                    }
                    Write-Output ([PSCustomObject]$Result)
                }
            }

            if (![Boolean]$Searcher -or $Searcher -isnot [System.DirectoryServices.DirectorySearcher]) {
                Write-Verbose -Message 'Creating Searcher' -Verbose:$Verbose
                $Searcher = New-Object -TypeName System.DirectoryServices.DirectorySearcher
            }

            if ([Boolean]$ResultCount) {
                Write-Verbose -Message "Adding Result Limit ($ResultCount) to Searcher" -Verbose:$Verbose
                $Searcher.SizeLimit = $ResultCount
            }

            if ([Boolean]$PageSize) {
                Write-Verbose -Message "Adding Page Size ($PageSize) to Searcher" -Verbose:$Verbose
                $Searcher.PageSize = $PageSize
            }

            if ([Boolean]$SearchRootPath) {
                $SearchRootPath = $SearchRootPath.TrimStart('/')
                if ($SearchRootPath -notlike "*$Protocol`://*") {
                    $SearchRootPath = "$Protocol`://$SearchRootPath"
                }
            }
            elseif (![Boolean]$SearchRootPath) {
                if ([Boolean]$Domain) {
                    $Split = $Domain.Split(':')

                    $GC = $Split[1]
                    if ('3268', '3269' -contains $GC) {
                        $Protocol = 'GC'
                    }

                    $SplitDomain = $Split[0].Split('.')

                    $SearchRootPath = "$Protocol`://DC=$($SplitDomain -join ',DC=')"
                }
                else {
                    $SearchRootPath = $Searcher.SearchRoot.Path
                }
            }

            if ([Boolean]$Server) {
                $SearchRootPath = $SearchRootPath.Replace('//', "//$Server/")
            }


            if ([Boolean]$UserName -and [Boolean]$Password) {
                $NewSearchRoot = New-Object -TypeName System.DirectoryServices.DirectoryEntry -ArgumentList $SearchRootPath, $UserName, $Password -ErrorAction Stop
                $Searcher.SearchRoot = $NewSearchRoot
                Write-Verbose "SearchRoot: $($Searcher.SearchRoot.Path)" -Verbose:$Verbose
                Write-Verbose "UserName: $($UserName)" -Verbose:$Verbose
            }
            else {
                $Searcher.SearchRoot.Path = $SearchRootPath
                Write-Verbose "SearchRoot: $($Searcher.SearchRoot.Path)" -Verbose:$Verbose
            }


            $Searcher.PropertiesToLoad.Clear()
            if ($ReturnAttribute -ne '*') {
                foreach ($Attr in $ReturnAttribute) {
                    if (!$Searcher.PropertiesToLoad.Contains($Attr)) {
                        if ($Attr -eq 'lastlogondate') {
                            [Void] $Searcher.PropertiesToLoad.Add('lastlogontimestamp')
                        }
                        elseif ($Attr -eq 'passwordlastset') {
                            [Void] $Searcher.PropertiesToLoad.Add('pwdlastset')
                        }
                        elseif ($Attr -eq 'guid') {
                            [Void] $Searcher.PropertiesToLoad.Add('objectguid')
                        }
                        elseif ($Attr -eq 'sid') {
                            [Void] $Searcher.PropertiesToLoad.Add('objectsid')
                        }
                        elseif ('cert', 'usercert', 'certificate', 'certificate' -contains $Attr) {
                            [Void] $Searcher.PropertiesToLoad.Add('usercertificate')
                        }
                        elseif ('san', 'sam' -contains $Attr) {
                            [Void] $Searcher.PropertiesToLoad.Add('samaccountname')
                        }
                        elseif ($Attr -eq 'upn') {
                            [Void] $Searcher.PropertiesToLoad.Add('userprincipalname')
                        }
                        elseif ($Attr -eq 'members') {
                            [Void] $Searcher.PropertiesToLoad.Add('member')
                        }
                        elseif ('uac', 'Enabled', 'LockedOut', 'Disabled', 'passwordneverexpires', 'passwordexpired', 'passwordnotrequired', 'passwordcantchange', 'smartcardrequired' -contains $Attr) {
                            [Void] $Searcher.PropertiesToLoad.Add('useraccountcontrol')
                        }
                        else {
                            [Void] $Searcher.PropertiesToLoad.Add($Attr)
                        }

                        if (!$Searcher.PropertiesToLoad.Contains('distinguishedname')) {
                            [Void] $Searcher.PropertiesToLoad.Add('distinguishedname')
                        }
                    }
                }
            }
        }
        process {
            if ([Boolean]$LDAPFilter) {
                $Searcher.Filter = $LDAPFilter
            }
            else {
                if ([Boolean]$_) {
                    [Array]$Identifier = $_
                }

                $Filter = @()
                foreach ($ID in $Identifier) {
                    $ID = $ID.Trim()
                    if ([Boolean]$SearchByAttribute) {
                        $Filter += "($SearchByAttribute=$ID)"
                    }
                    elseif ($ID -match '([a-zA-Z]{2,}=,?.{1,}){2,}') {
                        $Filter += "(distinguishedname=$ID)"
                    }
                    elseif ($ID -like '*@*.*') {
                        $Filter += "(|(mail=$ID)(userprincipalname=$ID))"
                    }
                    elseif ($ID -like '*-*') {
                        $Filter += "(|(displayname=$ID)(name=$ID)(samaccountname=$ID)(userprincipalname=$ID@*))"
                    }
                    elseif ($ID -like '*,*') {
                        $Filter += "(|(&(givenname=$($ID.split(',')[0].Trim()))(|(sn=$($ID.split(',')[1].Trim()))(surname=$($ID.split(',')[1].Trim()))))(&(givenname=$($ID.split(',')[1].Trim()))(|(surname=$($ID.split(',')[0].Trim()))(sn=$($ID.split(',')[0].Trim())))))"
                    }
                    elseif ($ID -like '* *') {
                        $Filter += "(|(&(givenname=$($ID.split(' ')[0].Trim()))(|(sn=$(($ID.split(' ')[1..$ID.length] -join ' ').trim()))(surname=$(($ID.split(' ')[1..$ID.length] -join ' ').trim()))))(&(givenname=$($ID.split(' ')[-1].Trim()))(|(surname=$(($ID.Split(' ')[0..($ID.Split(' ').Count-2)] -join ' ').Trim()))(sn=$(($ID.Split(' ')[0..($ID.Split(' ').Count-2)] -join ' ').Trim())))))"
                    }
                    else {
                        $Filter += "(|(samaccountname=$ID)(userprincipalname=$ID@*.*))"
                    }
                }
                $Searcher.Filter = "(|$($Filter -join ''))"
                Write-Verbose "Filter: $($Searcher.Filter)" -Verbose:$Verbose
            }
            $Searcher.FindAll() | FormatInfo -ReturnAttribute $ReturnAttribute
        }
    }

    function ForEach-Parallel {
        param(
            [Parameter(Mandatory = $True, position = 0)]
            [System.Management.Automation.ScriptBlock] $ScriptBlock,

            [Parameter(Mandatory = $False)]
            [int]$MaxThreads = ([wmiSearcher]'SELECT NumberOfLogicalProcessors FROM Win32_ComputerSystem').Get().NumberOfLogicalProcessors + 1,

            [Parameter(Mandatory = $False)]
            $Parameters = @{}
        )
        begin {
            $ISS = [System.Management.Automation.RunSpaces.InitialSessionState]::CreateDefault()
            $pool = [RunSpaceFactory]::CreateRunSpacePool(1, $MaxThreads, $ISS, $host)
            $pool.open()
            $threads = @()
        }
        process {
            $powershell = [powershell]::Create().AddScript($scriptblock).AddParameters($Parameters)
            $powershell.RunSpacePool = $pool
            $threads += @{
                instance = $powershell
                handle   = $powershell.BeginInvoke()
            }
        }
        end {
            $Done = $False
            while (!$Done) {
                $Done = $True
                for ($i = 0; $i -lt $threads.count; $i++) {
                    $thread = $threads[$i]
                    if ($thread) {
                        if ($thread.handle.IsCompleted) {
                            $thread.instance.EndInvoke($thread.handle)
                            $thread.instance.dispose()
                            $threads[$i] = $null
                        }
                        else {
                            $Done = $False
                        }
                    }
                }
            }
        }
    }

    "INFO: Finished Importing Functions: $($ScriptStopWatch.Elapsed.TotalSeconds) Seconds" | Add-ToLog
    #endregion Functions

    #region Prep

    New-Item -ItemType Directory -Path $ExportFolder -Force -ErrorAction Stop | Out-Null
    if ($LogOutput) {
        New-Item -ItemType Directory -Path (Split-Path -Parent $LogPath) -Force -ErrorAction Stop | Out-Null
    }

    Import-Module ActiveDirectory -ErrorAction Stop

    "INFO: Finished WIth Prep: $($ScriptStopWatch.Elapsed.TotalSeconds) Seconds" | Add-ToLog

    #endregion Prep

}
process {
    'START: SCRIPT' | Add-ToLog

    $DomainStopWatch = [System.Diagnostics.Stopwatch]::StartNew()
    :Domains foreach ($Domain in $Domains) {
        $DomainStopWatch.Restart()
        Remove-Variable '' -ErrorAction SilentlyContinue -Force -Verbose:$False

        "START: Domain: $Domain" | Add-ToLog -PrefixLineBreaks 1

        try {
            New-Item -ItemType Directory -Path $ExportFolder -Name $Domain -Force -ErrorAction Stop | Out-Null
            $DomainExportFolder = "$ExportFolder\$Domain"
        }
        catch {
            "ERROR: Failed to Create Domain Export Folder. ERROR: $_" | Add-ToLog
            continue Domains
        }

        $DCs = Get-ADDomainController -Filter * -Server $Domain
        $DomainInfo = Get-ADDomain -Server $Domain
        $ForestInfo = Get-ADForest -Server $DomainInfo.Forest
        $GPOs = Get-GPO -All
        $OUs = Get-adoraganizationunits

        # Remove Admin Count
        New-Report -ReportName 'Remove_AdminCount' -Report {
            Get-ADUser -
        }

        # User Password Not Required

        # Computer Password Dont Expire

        # Groups Empty

        # Object Conflicts

        # SPN Duplicates

        # GPO Conflicts

        # GPO Orphaned

        # GPO Orphaned Folders

        # GPO No Links

        # GPO Disabled Links

        # GPO DA Not Owner

        # GPO No Read AuthUsers

        # GPO No Apply Perm

        # GPO Disabled Settings

        # GPO Enabled No Settings

        # Permissions Check

        # OU Empty

        # OU Need Deletion Protection

        # OU No GPO Links

        # DNS Dead DC SRV Record

        # SS Manual Connections

        # SS Site No Subnet

        # SS Missing Subnets

        # DC No Recent Update

        # DC Pending Reboot

        # DC Low Storage

        # DC Services

        "END: Domain: $Domain. Duration: $($DomainStopWatch.Elapsed.TotalSeconds) Seconds"
    }
}
end {
    'END: SCRIPT' | Add-ToLog
    $ScriptStopWatch.Stop()
    Replace('[END]', (Get-Date))
    $EmailSplat.Replace('[DURATION]', "$($ScriptStopWatch.Elapsed.TotalMinutes) Minutes")

    try {
        Send-MailMessage @EmailSplat
    }
    catch {
        Send-MailMessage -To $EmailSplat.To -Subject 'AD Report Failure: Send Report' -BodyAsHtml -Body (
            '<b>OCCURRENCE:</b> Failed to Send Report. <br>' +
            '<b>ACTION:</b> Check Error and Fix Code.<br>' +
            "<b>ERROR:</b> $_<br>"
        )
    }
}