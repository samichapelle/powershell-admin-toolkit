function Export-SystemInventory {
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [PSObject]$InputObject,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$Path = ".\system-inventory.csv"
    )

    begin {
        $Inventory = @()
    }

    process {
        $Inventory += $InputObject
    }

    end {
        try {
            $Inventory |
                Select-Object `
                    ComputerName,
                    Manufacturer,
                    Model,
                    OS,
                    OSVersion,
                    UptimeDays,
                    CPU,
                    RAM_GB,
                    IPv4,
                    @{
                        Name = 'Disks'
                        Expression = {
                            ($_.Disks | ForEach-Object {
                                "$($_.Drive) $($_.FreeGB)/$($_.SizeGB) GB free"
                            }) -join ' | '
                        }
                    } |
                Export-Csv `
                    -Path $Path `
                    -NoTypeInformation `
                    -Encoding UTF8

            Write-Verbose "Inventaire exporté vers $Path"
        }
        catch {
            Write-Error "Impossible d'exporter l'inventaire : $($_.Exception.Message)"
        }
    }
}