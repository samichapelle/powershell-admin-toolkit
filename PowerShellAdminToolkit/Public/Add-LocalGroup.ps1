function Add-LocalGroup {
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
        [string[]]$GroupName,

        [Parameter()]
        [ValidateLength(0, 48)]
        [string]$Description
    )

    process {
        foreach ($CurrentGroup in $GroupName) {

            try {
                $ExistingGroup = Get-LocalGroup `
                    -Name $CurrentGroup `
                    -ErrorAction SilentlyContinue

                if ($ExistingGroup) {
                    [PSCustomObject]@{
                        ComputerName  = $env:COMPUTERNAME
                        GroupName     = $ExistingGroup.Name
                        Description   = $ExistingGroup.Description
                        AlreadyExists = $true
                        Created       = $false
                        Success       = $true
                    }

                    continue
                }

                if (
                    $PSCmdlet.ShouldProcess(
                        $CurrentGroup,
                        'Create local group'
                    )
                ) {
                    $Parameters = @{
                        Name        = $CurrentGroup
                        ErrorAction = 'Stop'
                    }

                    if ($Description) {
                        $Parameters.Description = $Description
                    }

                    $CreatedGroup = New-LocalGroup @Parameters

                    $VerifiedGroup = Get-LocalGroup `
                        -Name $CreatedGroup.Name `
                        -ErrorAction Stop

                    [PSCustomObject]@{
                        ComputerName  = $env:COMPUTERNAME
                        GroupName     = $VerifiedGroup.Name
                        Description   = $VerifiedGroup.Description
                        AlreadyExists = $false
                        Created       = $true
                        Success       = $true
                    }
                }
            }
            catch {
                Write-Error "Impossible de créer le groupe local '$CurrentGroup' : $($_.Exception.Message)"
            }
        }
    }
}