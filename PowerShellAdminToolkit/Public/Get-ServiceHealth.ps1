function Get-ServiceHealth {
    [CmdletBinding()]
    param (
        [Parameter(
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [ValidateNotNullOrEmpty()]
        [string[]]$ComputerName = $env:COMPUTERNAME,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string[]]$ServiceName = @(
            'WinRM',
            'W32Time',
            'EventLog'
        )
    )

    process {
        foreach ($Computer in $ComputerName) {
            foreach ($Service in $ServiceName) {

                try {
                    Write-Verbose "Vérification du service $Service sur $Computer"

                    $IsLocal = $Computer -in @(
                        $env:COMPUTERNAME,
                        'localhost',
                        '.'
                    )

                    if ($IsLocal) {
                        $ServiceInfo = Get-Service `
                            -Name $Service `
                            -ErrorAction Stop
			$ServiceConfig = Get-CimInstance -ClassName Win32_Service `
    		            -Filter "Name='$Service'" `
    			    -ErrorAction Stop
                    }
                    else {
                        $ServiceInfo = Get-Service `
                            -ComputerName $Computer `
                            -Name $Service `
                            -ErrorAction Stop
                    }
		
                    if ($ServiceConfig.StartMode -eq 'Auto' -and $ServiceInfo.Status -ne 'Running') {
                        $Healthy = $false
                    }
                    else {
                        $Healthy = $true
                    }

                    [PSCustomObject]@{
                        ComputerName = $Computer
                        ServiceName  = $ServiceInfo.Name
                        DisplayName  = $ServiceInfo.DisplayName
                        Status       = $ServiceInfo.Status
                        StartType    = $ServiceConfig.StartMode
			Healthy      = $Healthy
                    }
                }
                catch {
                    [PSCustomObject]@{
                        ComputerName = $Computer
                        ServiceName  = $Service
                        DisplayName  = $null
                        Status       = 'Unavailable'
                    }
                }
            }
        }
    }
}