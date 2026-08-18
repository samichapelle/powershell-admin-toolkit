function Show-ServiceHealth {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline = $true)]
        [string[]]$ComputerName = $env:COMPUTERNAME,

        [string[]]$ServiceName = @(
            'WinRM',
            'W32Time',
            'EventLog'
        )
    )

    process {
        $results = Get-ServiceHealth `
            -ComputerName $ComputerName `
            -ServiceName $ServiceName

        foreach ($service in $results) {

            Write-Host "ComputerName : $($service.ComputerName)"
            Write-Host "ServiceName  : $($service.ServiceName)"
            Write-Host "DisplayName  : $($service.DisplayName)"
            Write-Host "Status       : $($service.Status)"
            Write-Host "StartType    : $($service.StartType)"

            Write-Host "Healthy      : " -NoNewline

            if ($service.Healthy) {
                Write-Host "True" -ForegroundColor Green
            }
            else {
                Write-Host "False" -ForegroundColor Red
            }

            Write-Host ""
        }
    }
}