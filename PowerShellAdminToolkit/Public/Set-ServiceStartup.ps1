function Set-ServiceStartup {
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
        [string]$ServiceName,

        [Parameter(Mandatory = $true)]
        [ValidateSet(
            'Automatic',
            'Manual',
            'Disabled'
        )]
        [string]$StartupType
    )

    try {
        # Etat actuel du service
        $Service = Get-Service `
            -Name $ServiceName `
            -ErrorAction Stop

        $PreviousStartupType = [string]$Service.StartType

        # Rien à modifier si le service est déjà
        # configuré avec le type demandé.
        if ($PreviousStartupType -eq $StartupType) {

            [PSCustomObject]@{
                ComputerName        = $env:COMPUTERNAME
                ServiceName         = $ServiceName
                PreviousStartupType = $PreviousStartupType
                NewStartupType      = $PreviousStartupType
                Changed             = $false
                Success             = $true
            }

            return
        }

        # ShouldProcess fournit automatiquement
        # le support de -WhatIf et -Confirm.
        if (
            $PSCmdlet.ShouldProcess(
                $ServiceName,
                "Change startup type from '$PreviousStartupType' to '$StartupType'"
            )
        ) {

            Set-Service `
                -Name $ServiceName `
                -StartupType $StartupType `
                -ErrorAction Stop

            # Nouvelle interrogation pour vérifier
            # que la modification a réellement été appliquée.
            $UpdatedService = Get-Service `
                -Name $ServiceName `
                -ErrorAction Stop

            $NewStartupType = [string]$UpdatedService.StartType
            $ModificationSucceeded = (
                $NewStartupType -eq $StartupType
            )

            [PSCustomObject]@{
                ComputerName        = $env:COMPUTERNAME
                ServiceName         = $ServiceName
                PreviousStartupType = $PreviousStartupType
                NewStartupType      = $NewStartupType
                Changed             = $ModificationSucceeded
                Success             = $ModificationSucceeded
            }
        }
    }
    catch {
        Write-Error "Impossible de modifier le service '$ServiceName' : $($_.Exception.Message)"
    }
}