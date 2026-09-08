function Disable-ADUserAccount {
    <#
    .SYNOPSIS
        Désactive un compte utilisateur Active Directory à distance.
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

        if (-not $User.Enabled) {
            return [PSCustomObject]@{
                ComputerName   = $ComputerName
                SamAccountName = $SamAccountName
                Action         = "AlreadyDisabled"
                Changed        = $false
            }
        }

        if ($PSCmdlet.ShouldProcess($SamAccountName, "Désactiver le compte Active Directory")) {

            Invoke-Command -ComputerName $ComputerName -Credential $Credential `
                -ScriptBlock {
                    param ($SamAccountName)

                    Import-Module ActiveDirectory -ErrorAction Stop
                    Disable-ADAccount -Identity $SamAccountName -ErrorAction Stop

                } -ArgumentList $SamAccountName -ErrorAction Stop

            [PSCustomObject]@{
                ComputerName   = $ComputerName
                SamAccountName = $SamAccountName
                Action         = "Disabled"
                Changed        = $true
            }
        }
    }
    catch {
        Write-Error "Échec de la désactivation du compte '$SamAccountName' : $($_.Exception.Message)"
    }
}