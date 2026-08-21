function Remove-LocalUserAccount {
    [CmdletBinding(
        SupportsShouldProcess = $true,
        ConfirmImpact = 'High'
    )]
    param (
        [Parameter(
            Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [ValidateNotNullOrEmpty()]
        [string[]]$UserName
    )

    process {
        foreach ($CurrentUser in $UserName) {

            try {
                $Account = Get-LocalUser `
                    -Name $CurrentUser `
                    -ErrorAction Stop

                if (
                    $PSCmdlet.ShouldProcess(
                        $Account.Name,
                        'Remove local user account'
                    )
                ) {
                    Remove-LocalUser `
                        -Name $Account.Name `
                        -ErrorAction Stop

                    $RemainingAccount = Get-LocalUser `
                        -Name $Account.Name `
                        -ErrorAction SilentlyContinue

                    $Succeeded = $null -eq $RemainingAccount

                    [PSCustomObject]@{
                        ComputerName = $env:COMPUTERNAME
                        UserName     = $Account.Name
                        Removed      = $Succeeded
                        Success      = $Succeeded
                    }
                }
            }
            catch {
                Write-Error "Impossible de supprimer le compte local '$CurrentUser' : $($_.Exception.Message)"
            }
        }
    }
}