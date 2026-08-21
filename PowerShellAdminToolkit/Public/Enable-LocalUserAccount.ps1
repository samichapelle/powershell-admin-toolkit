function Enable-LocalUserAccount {
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

                if ($Account.Enabled) {
                    [PSCustomObject]@{
                        ComputerName  = $env:COMPUTERNAME
                        UserName      = $Account.Name
                        PreviousState = 'Enabled'
                        NewState      = 'Enabled'
                        Changed       = $false
                        Success       = $true
                    }

                    continue
                }

                if (
                    $PSCmdlet.ShouldProcess(
                        $Account.Name,
                        'Enable local user account'
                    )
                ) {
                    Enable-LocalUser `
                        -Name $Account.Name `
                        -ErrorAction Stop

                    $UpdatedAccount = Get-LocalUser `
                        -Name $Account.Name `
                        -ErrorAction Stop

                    $Succeeded = $UpdatedAccount.Enabled

                    [PSCustomObject]@{
                        ComputerName  = $env:COMPUTERNAME
                        UserName      = $UpdatedAccount.Name
                        PreviousState = 'Disabled'
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
                Write-Error "Impossible d'activer le compte local '$CurrentUser' : $($_.Exception.Message)"
            }
        }
    }
}