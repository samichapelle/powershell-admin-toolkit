function Set-LocalUserPassword {
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
        [string[]]$UserName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [SecureString]$Password
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
                        'Change local user password'
                    )
                ) {
                    Set-LocalUser `
                        -Name $Account.Name `
                        -Password $Password `
                        -ErrorAction Stop

                    # Vérification que le compte existe toujours
                    # et reste accessible après la modification.
                    $UpdatedAccount = Get-LocalUser `
                        -Name $Account.Name `
                        -ErrorAction Stop

                    [PSCustomObject]@{
                        ComputerName = $env:COMPUTERNAME
                        UserName     = $UpdatedAccount.Name
                        PasswordSet  = $true
                        Success      = $true
                    }
                }
            }
            catch {
                Write-Error "Impossible de modifier le mot de passe du compte local '$CurrentUser' : $($_.Exception.Message)"
            }
        }
    }
}