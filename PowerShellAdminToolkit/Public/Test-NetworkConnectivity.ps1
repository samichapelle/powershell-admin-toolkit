function Test-NetworkConnectivity {
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [ValidateNotNullOrEmpty()]
        [string[]]$ComputerName,

        [Parameter()]
        [ValidateRange(1, 65535)]
        [int[]]$Port = @(53, 80, 443, 3389, 5985)
    )

    process {
        foreach ($Computer in $ComputerName) {

            Write-Verbose "Test de connectivité vers $Computer"

            # Résolution DNS
            try {
                $DnsResult = Resolve-DnsName `
                    -Name $Computer `
                    -ErrorAction Stop |
                    Where-Object { $_.IPAddress } |
                    Select-Object -ExpandProperty IPAddress

                $DnsResolved = $true
                $ResolvedIP = $DnsResult -join ', '
            }
            catch {
                $DnsResolved = $false
                $ResolvedIP = $null
            }

            # Test ICMP
            try {
                $PingResult = Test-Connection `
                    -ComputerName $Computer `
                    -Count 1 `
                    -Quiet `
                    -ErrorAction Stop

                $PingSuccess = [bool]$PingResult
            }
            catch {
                $PingSuccess = $false
            }

            # Tests TCP
            foreach ($CurrentPort in $Port) {
                try {
                    $TcpResult = Test-NetConnection `
                        -ComputerName $Computer `
                        -Port $CurrentPort `
                        -WarningAction SilentlyContinue `
                        -InformationLevel Quiet

                    $TcpOpen = [bool]$TcpResult
                }
                catch {
                    $TcpOpen = $false
                }

                [PSCustomObject]@{
                    ComputerName = $Computer
                    DnsResolved  = $DnsResolved
                    ResolvedIP   = $ResolvedIP
                    PingSuccess  = $PingSuccess
                    Port         = $CurrentPort
                    TcpOpen      = $TcpOpen
                }
            }
        }
    }
}