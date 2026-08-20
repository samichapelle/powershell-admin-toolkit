function Add-LocalUserToGroup {
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

        [Parameter(
            Mandatory = $true,
            Position = 1
        )]
        [ValidateNotNullOrEmpty()]
        [string]$GroupName
    )

    process {
        foreach ($CurrentUser in $UserName) {

            try {
                # Vérifie que l'utilisateur existe.
                $User = Get-LocalUser `
                    -Name $CurrentUser `
                    -ErrorAction Stop

                # Vérifie que le groupe existe.
                $Group = Get-LocalGroup `
                    -Name $GroupName `
                    -ErrorAction Stop

                # Vérifie si l'utilisateur est déjà membre.
                $ExistingMember = Get-LocalGroupMember `
                    -Group $Group.Name `
                    -ErrorAction Stop |
                    Where-Object {
                        $_.SID -eq $User.SID
                    }

                if ($ExistingMember) {
                    [PSCustomObject]@{
                        ComputerName = $env:COMPUTERNAME
                        UserName     = $User.Name
                        GroupName    = $Group.Name
                        AlreadyMember = $true
                        Changed      = $false
                        Success      = $true
                    }

                    continue
                }

                if (
                    $PSCmdlet.ShouldProcess(
                        "$($User.Name) -> $($Group.Name)",
                        'Add local user to group'
                    )
                ) {
                    Add-LocalGroupMember `
                        -Group $Group.Name `
                        -Member $User.Name `
                        -ErrorAction Stop

                    # Vérification après modification.
                    $VerifiedMember = Get-LocalGroupMember `
                        -Group $Group.Name `
                        -ErrorAction Stop |
                        Where-Object {
                            $_.SID -eq $User.SID
                        }

                    $Succeeded = $null -ne $VerifiedMember

                    [PSCustomObject]@{
                        ComputerName = $env:COMPUTERNAME
                        UserName     = $User.Name
                        GroupName    = $Group.Name
                        AlreadyMember = $false
                        Changed      = $Succeeded
                        Success      = $Succeeded
                    }
                }
            }
            catch {
                Write-Error "Impossible d'ajouter '$CurrentUser' au groupe '$GroupName' : $($_.Exception.Message)"
            }
        }
    }
}