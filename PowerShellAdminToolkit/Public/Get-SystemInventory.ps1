function Get-SystemInventory {
    [CmdletBinding()]
    param (
        [Parameter(
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [ValidateNotNullOrEmpty()]
        [string[]]$ComputerName = $env:COMPUTERNAME
    )

    process {
        foreach ($Computer in $ComputerName) {

            $CimSession = $null

            try {
                Write-Verbose "Collecte de l'inventaire pour $Computer"

                $IsLocal = $Computer -in @(
                    $env:COMPUTERNAME,
                    'localhost',
                    '.'
                )

                if ($IsLocal) {
                    $CimParams = @{
                        ErrorAction = 'Stop'
                    }
                }
                else {
                    Write-Verbose "Création d'une session CIM vers $Computer"

                    $CimSession = New-CimSession `
                        -ComputerName $Computer `
                        -ErrorAction Stop

                    $CimParams = @{
                        CimSession  = $CimSession
                        ErrorAction = 'Stop'
                    }
                }

                $ComputerSystem = Get-CimInstance `
                    -ClassName Win32_ComputerSystem `
                    @CimParams

                $OperatingSystem = Get-CimInstance `
                    -ClassName Win32_OperatingSystem `
                    @CimParams

                $Processor = Get-CimInstance `
                    -ClassName Win32_Processor `
                    @CimParams |
                    Select-Object -First 1

                $Disks = Get-CimInstance `
                    -ClassName Win32_LogicalDisk `
                    -Filter "DriveType = 3" `
                    @CimParams

                $NetworkAdapters = Get-CimInstance `
                    -ClassName Win32_NetworkAdapterConfiguration `
                    -Filter "IPEnabled = True" `
                    @CimParams

                $IPv4Addresses = foreach ($Adapter in $NetworkAdapters) {
                    foreach ($Address in $Adapter.IPAddress) {
                        if (
                            $Address -match '^\d{1,3}(\.\d{1,3}){3}$' -and
                            $Address -notlike '127.*' -and
                            $Address -notlike '169.254.*'
                        ) {
                            $Address
                        }
                    }
                }

                $Uptime = (Get-Date) - $OperatingSystem.LastBootUpTime

                $DiskSummary = foreach ($Disk in $Disks) {
                    [PSCustomObject]@{
                        Drive            = $Disk.DeviceID
                        SizeGB           = [math]::Round($Disk.Size / 1GB, 2)
                        FreeGB           = [math]::Round($Disk.FreeSpace / 1GB, 2)
                        FreeSpacePercent = [math]::Round(
                            ($Disk.FreeSpace / $Disk.Size) * 100,
                            2
                        )
                    }
                }

                [PSCustomObject]@{
                    ComputerName = $ComputerSystem.Name
                    Manufacturer = $ComputerSystem.Manufacturer
                    Model        = $ComputerSystem.Model
                    OS           = $OperatingSystem.Caption
                    OSVersion    = $OperatingSystem.Version
                    UptimeDays   = [math]::Round($Uptime.TotalDays, 2)
                    CPU          = $Processor.Name
                    RAM_GB       = [math]::Round(
                        $ComputerSystem.TotalPhysicalMemory / 1GB,
                        2
                    )
                    IPv4         = $IPv4Addresses -join ', '
                    Disks        = $DiskSummary
                }
            }
            catch {
                Write-Error "Impossible de récupérer l'inventaire de '$Computer' : $($_.Exception.Message)"
            }
            finally {
                if ($CimSession) {
                    Remove-CimSession $CimSession
                }
            }
        }
    }
}