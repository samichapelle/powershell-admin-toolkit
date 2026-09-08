function Enable-ADUserAccount {
    <#
    .SYNOPSIS
        Active un compte utilisateur Active Directory à distance.
    #>

    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory)]
        [string]$ComputerName,

        [Parameter(Mandatory)]
        [PSCredential]$Credential,

        [Parameter(Mandatory)]
        [string]$SamAccountName
    )

    try {
        $User = Invoke-Command -ComputerName $ComputerName -Credential $Credential `
            -ScriptBlock {
                param ($SamAccountName)

                Import-Module ActiveDirectory -ErrorAction Stop

                Get-ADUser -Identity $SamAccountName `
                    -Properties Enabled `
                    -ErrorAction Stop
            } -ArgumentList $SamAccountName -ErrorAction Stop

        if ($User.Enabled) {
            return [PSCustomObject]@{
                ComputerName   = $ComputerName
                SamAccountName = $SamAccountName
                Action         = "AlreadyEnabled"
                Changed        = $false
            }
        }

        if ($PSCmdlet.ShouldProcess($SamAccountName, "Activer le compte Active Directory")) {

            Invoke-Command -ComputerName $ComputerName -Credential $Credential `
                -ScriptBlock {
                    param ($SamAccountName)

                    Import-Module ActiveDirectory -ErrorAction Stop
                    Enable-ADAccount -Identity $SamAccountName -ErrorAction Stop

                } -ArgumentList $SamAccountName -ErrorAction Stop

            [PSCustomObject]@{
                ComputerName   = $ComputerName
                SamAccountName = $SamAccountName
                Action         = "Enabled"
                Changed        = $true
            }
        }
    }
    catch {
        Write-Error "Échec de l'activation du compte '$SamAccountName' : $($_.Exception.Message)"
    }
}