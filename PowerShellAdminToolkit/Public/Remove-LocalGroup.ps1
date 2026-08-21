function Remove-LocalGroup {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$GroupName
    )

    try {
        $Group = Get-LocalGroup -Name $GroupName -ErrorAction SilentlyContinue

        if (-not $Group) {
            return [PSCustomObject]@{
                ComputerName = $env:COMPUTERNAME
                GroupName    = $GroupName
                Existed      = $false
                Removed      = $false
                Success      = $true
            }
        }

        if ($PSCmdlet.ShouldProcess(
            $GroupName,
            "Remove local group"
        )) {
            Microsoft.PowerShell.LocalAccounts\Remove-LocalGroup `
                -Name $GroupName `
                -ErrorAction Stop

            return [PSCustomObject]@{
                ComputerName = $env:COMPUTERNAME
                GroupName    = $GroupName
                Existed      = $true
                Removed      = $true
                Success      = $true
            }
        }
    }
    catch {
        Write-Error "Impossible de supprimer le groupe local '$GroupName' : $($_.Exception.Message)"
    }
}