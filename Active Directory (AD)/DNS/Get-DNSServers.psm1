Function Get-DNSServers {
    <#
        .NOTES
            Created By: Kyle Hewitt
            Created On: 4/30/20
            Version: 2020.4.30

        .DESCRIPTION
            Get DNS Servers of a domain
    #>
    Param(
        $Domain = $env:USERDNSDOMAIN
    )
    Process {
        (nslookup -type=ns $Domain) | 
            Where-Object -FilterScript { $_ -like '* = *' } |
            ForEach-Object -Process { 
                If ($_ -like '*nameserver*' -or $_ -like '*primary*') {
                    $ns = $_.Split('=')[1]    
                }
                Elseif ($_ -like '*internet address*') {
                    $ns = $_.Split(' ')[0]
                }
                If ([boolean]$ns) {
                    $ns.split('.')[0].Trim()
                }
                Remove-Variable ns -ErrorAction SilentlyContinue 
            } |
            Sort-Object
    }
}
