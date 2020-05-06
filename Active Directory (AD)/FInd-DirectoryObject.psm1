Function Find-DirectoryObject
{
    <#
        .NOTES
            Created By: Kyle Hewitt
            Created On: 1/1/2019
            Last Edit: 4/17/2020
            Version: 1.2.5
    #>
    [alias('Find-DO','FindDO','FDO')]
    [cmdletbinding()]
    Param(
        [Parameter(ParameterSetName='ID',
                   Position=0,
                   Mandatory, 
                   ValueFromPipeline,
                   ValueFromPipelineByPropertyName)]
            [String[]]$Identifier,
        
        [Parameter(ParameterSetName='ID',
                   Position=1,
                   Mandatory=$False)]
            [String]$SearchByAttribute,
        
        [Parameter(ParameterSetName='Filter')]
            [String]$Filter,
        
        [Parameter(Position=2)]
            [String[]]$ReturnAttribute = 'distinguishedname',
        
        [int]$ResultCount,
        
        [String]$SearchRoot,
        
        [String]$Server,
        
        [ValidateScript({$_ -like "*.*"})]
            [String]$Domain 
    )

    Begin
    {
        If (![Boolean]$Searcher -or $Searcher -isnot [System.DirectoryServices.DirectorySearcher])
        {
            Write-Verbose -Message 'Creating Searcher'
            $Searcher = New-Object -TypeName System.DirectoryServices.DirectorySearcher
        }

        If ([Boolean]$ResultCount)
        {
            Write-Verbose -Message "Adding Result Limit ($ResultCount) to Searcher"
            $Searcher.SizeLimit = $ResultCount
        }

        If ([Boolean]$Domain)
        {
            $SplitDomain = $Domain.Split('.')
            $SearchRoot = "DC=$($SplitDomain -join '.')"
            Write-Verbose -Message "Created '$SearchRoot' for searchroot"
        }

        If ([Boolean]$SearchRoot)
        {
            $SearchRoot = $SearchRoot.TrimStart('/')
            If ($SearchRoot -like "*//*")
            {
                $SearchRoot = "LDAP:$SearchRoot"
            }
            ElseIf ($SearchRoot -like "*://*")
            {
                $SearchRoot = "LDAP$SearchRoot"
            }
            ElseIf ($SearchRoot -notlike '*://*')
            {
                $SearchRoot = "LDAP://$SearchRoot"
            }
            
            Write-Verbose "Setting SearchRoot on Searcher"
            $Searcher.SearchRoot = $SearchRoot
            Write-Verbose "SearchRoot: $($Searcher.SearchRoot.Path)"
        }
        
        If ([Boolean]$Server -and $Searcher.SearchRoot.Path -notlike "*//*/*")
        {
            $SearchRoot = $Searcher.SearchRoot.Path.Replace('//',"//$Server/")
            Write-Verbose "Adding Server to SearchRoot. $SearchRoot"
            $Searcher.SearchRoot = $SearchRoot
            Write-Verbose "SearchRoot: $($Searcher.SearchRoot.Path)"
        }
        ElseIf ($Searcher.SearchRoot.Path -like "*//*/*" -and [Boolean]$Server)
        {
            Write-Warning "Not using $Server because $($SearchRoot.split('/')[2]) was already specified in SearchRoot." -WarningAction Inquire
        }

        $Searcher.PropertiesToLoad.Clear()
        If ($ReturnAttribute -notlike '*')
        {
            Foreach ($Attr in $ReturnAttribute)
            {
                If (!$Searcher.PropertiesToLoad.Contains($Attr))
                {
                    [Void] ($Searcher.PropertiesToLoad.Add($Attr))
                }
            }
        }
    }
    Process
    {
        Foreach ($ID in $Identifier)
        {
            $ID = $ID.Trim()
            If ([Boolean]$SearchByAttribute)
            {
                $Searcher.Filter = "($($Searcher.$SearchByAttribute)=$ID)"
            }
            If ($ID -like 'CN=*' -or $ID -like 'OU=*' -or $ID -like 'DC=*' -or $ID -like "*,*=*")
            {
                $Searcher.Filter = "(distinguishedname=$ID)"
            }
            ElseIf ($ID -like '*@*.*')
            {
                $Searcher.Filter = "(|(mail=$ID)(userprincipalname=$ID))"
            }
            ElseIf ($ID -like '* - *')
            {
                $Searcher.Filter = "(|(displayname=$ID)(name=$ID)(samaccountname=$ID)(userprincipalname=$ID@*))"
            }
            ElseIf ($ID -like '* *')
            {
                $Searcher.Filter = "(|(&(givenname=$($ID.split(' ')[0].Trim()))(sn=$(($ID.split(' ')[1..$ID.length] -join ' ').trim())))(&(givenname=$($ID.split(' ')[-1].Trim()))(sn=$(($ID.Split(' ')[0..($ID.Split(' ').Count-2)] -join ' ').Trim()))))"
            }
            ElseIf ($ID -like '*,*')
            {
                $Searcher.Filter = "(|(&(givenname=$($ID.split(',')[0].Trim()))(sn=$($ID.split(',')[1].Trim())))(&(givenname=$($ID.split(',')[1].Trim()))(sn=$($ID.split(',')[0].Trim()))))"
            }
            Else
            {
                $Searcher.Filter = "(|(samaccountname=$ID)(userprincipalname=$ID@*.*))"
            }

            If ($ReturnAttribute.Count -eq 1 -and $ReturnAttribute -ne '*')
            {
                $Searcher.FindAll().Properties."$ReturnAttribute"
            }
            Else
            {
                $Searcher.FindAll() | ForEach-Object -Process {
                    $Result = @{}
                    If ($ReturnAttribute -eq '*')
                    {
                        Foreach ($Attr in $_.Properties.Keys)
                        {
                            $Result.Add($Attr,$($_.Properties.$Attr))
                        }
                    }
                    Else
                    {
                        Foreach ($Attr in $ReturnAttribute)
                        {
                            $Result.Add($Attr,$($_.Properties.$Attr))
                        }
                    }
                    Write-Output ([PSCustomObject]$Result)
                }
            }
        }
    }
    End
    {
        $Searcher.Dispose()
    }
}
