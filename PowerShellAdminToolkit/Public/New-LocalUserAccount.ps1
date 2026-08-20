function New-LocalUserAccount {
    [CmdletBinding(
        SupportsShouldProcess = $true,
        ConfirmImpact = 'Medium'
    )]
    param (
        [Parameter(
            Mandatory = $true,
            Position = 0
        )]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern('^[a-zA-Z0-9._-]+$')]
        [string]$UserName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [SecureString]$Password,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$FullName,

        [Parameter()]
	[ValidateLength(0, 48)]
	[string]$Description,

        [Parameter()]
        [string[]]$Group
    )

    try {
        # Vérifie si le compte existe déjà.
        $ExistingUser = Get-LocalUser `
            -Name $UserName `
            -ErrorAction SilentlyContinue

        if ($ExistingUser) {
            Write-Error "Le compte local '$UserName' existe déjà."
            return
        }

        # Vérifie que les groupes demandés existent avant
        # de commencer la création du compte.
        if ($Group) {
            foreach ($GroupName in $Group) {
                $ExistingGroup = Get-LocalGroup `
                    -Name $GroupName `
                    -ErrorAction SilentlyContinue

                if (-not $ExistingGroup) {
                    Write-Error "Le groupe local '$GroupName' n'existe pas."
                    return
                }
            }
        }

        if (
            $PSCmdlet.ShouldProcess(
                $UserName,
                'Create local user account'
            )
        ) {
            $UserParams = @{
                Name        = $UserName
                Password    = $Password
                ErrorAction = 'Stop'
            }

            if ($FullName) {
                $UserParams.FullName = $FullName
            }

            if ($Description) {
                $UserParams.Description = $Description
            }

            $CreatedUser = New-LocalUser @UserParams

            $AddedGroups = @()

            if ($Group) {
                foreach ($GroupName in $Group) {
                    Add-LocalGroupMember `
                        -Group $GroupName `
                        -Member $UserName `
                        -ErrorAction Stop

                    $AddedGroups += $GroupName
                }
            }

            # Vérification finale
            $VerifiedUser = Get-LocalUser `
                -Name $UserName `
                -ErrorAction Stop

            [PSCustomObject]@{
                ComputerName = $env:COMPUTERNAME
                UserName     = $VerifiedUser.Name
                FullName     = $VerifiedUser.FullName
                Enabled      = $VerifiedUser.Enabled
                Groups       = $AddedGroups -join ', '
                Created      = $true
                Success      = $true
            }
        }
    }
    catch {
        Write-Error "Impossible de créer le compte local '$UserName' : $($_.Exception.Message)"
    }
}