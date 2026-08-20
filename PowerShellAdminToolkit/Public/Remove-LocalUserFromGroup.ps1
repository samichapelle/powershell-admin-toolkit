function Remove-LocalUserFromGroup {
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

                # Vérifie si l'utilisateur est actuellement membre.
                $ExistingMember = Get-LocalGroupMember `
                    -Group $Group.Name `
                    -ErrorAction Stop |
                    Where-Object {
                        $_.SID -eq $User.SID
                    }

                if (-not $ExistingMember) {
                    [PSCustomObject]@{
                        ComputerName = $env:COMPUTERNAME
                        UserName     = $User.Name
                        GroupName    = $Group.Name
                        WasMember    = $false
                        Changed      = $false
                        Success      = $true
                    }

                    continue
                }

                if (
                    $PSCmdlet.ShouldProcess(
                        "$($User.Name) <- $($Group.Name)",
                        'Remove local user from group'
                    )
                ) {
                    Remove-LocalGroupMember `
                        -Group $Group.Name `
                        -Member $User.Name `
                        -ErrorAction Stop

                    # Vérification après suppression.
                    $VerifiedMember = Get-LocalGroupMember `
                        -Group $Group.Name `
                        -ErrorAction Stop |
                        Where-Object {
                            $_.SID -eq $User.SID
                        }

                    $Succeeded = $null -eq $VerifiedMember

                    [PSCustomObject]@{
                        ComputerName = $env:COMPUTERNAME
                        UserName     = $User.Name
                        GroupName    = $Group.Name
                        WasMember    = $true
                        Changed      = $Succeeded
                        Success      = $Succeeded
                    }
                }
            }
            catch {
                Write-Error "Impossible de retirer '$CurrentUser' du groupe '$GroupName' : $($_.Exception.Message)"
            }
        }
    }
}