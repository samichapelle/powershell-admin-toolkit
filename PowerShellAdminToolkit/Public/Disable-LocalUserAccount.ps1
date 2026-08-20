function Disable-LocalUserAccount {
    [CmdletBinding(
        SupportsShouldProcess = $true,
        ConfirmImpact = 'Medium'
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

                # Aucun changement à effectuer si le compte
                # est déjà désactivé.
                if (-not $Account.Enabled) {

                    [PSCustomObject]@{
                        ComputerName = $env:COMPUTERNAME
                        UserName     = $Account.Name
                        PreviousState = 'Disabled'
                        NewState      = 'Disabled'
                        Changed       = $false
                        Success       = $true
                    }

                    continue
                }

                if (
                    $PSCmdlet.ShouldProcess(
                        $Account.Name,
                        'Disable local user account'
                    )
                ) {
                    Disable-LocalUser `
                        -Name $Account.Name `
                        -ErrorAction Stop

                    # Vérification après modification.
                    $UpdatedAccount = Get-LocalUser `
                        -Name $Account.Name `
                        -ErrorAction Stop

                    $Succeeded = -not $UpdatedAccount.Enabled

                    [PSCustomObject]@{
                        ComputerName  = $env:COMPUTERNAME
                        UserName      = $UpdatedAccount.Name
                        PreviousState = 'Enabled'
                        NewState      = if ($UpdatedAccount.Enabled) {
                            'Enabled'
                        }
                        else {
                            'Disabled'
                        }
                        Changed       = $Succeeded
                        Success       = $Succeeded
                    }
                }
            }
            catch {
                Write-Error "Impossible de désactiver le compte local '$CurrentUser' : $($_.Exception.Message)"
            }
        }
    }
}