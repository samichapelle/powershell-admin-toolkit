function New-ADUserAccount {
    <#
    .SYNOPSIS
        Crée un compte utilisateur Active Directory à distance.
    #>

    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory)]
        [string]$ComputerName,

        [Parameter(Mandatory)]
        [PSCredential]$Credential,

        [Parameter(Mandatory)]
        [string]$SamAccountName,

        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [SecureString]$AccountPassword
    )

    try {
        $Exists = Invoke-Command -ComputerName $ComputerName -Credential $Credential `
            -ScriptBlock {
                param ($SamAccountName)

                Import-Module ActiveDirectory
                $null -ne (Get-ADUser -Filter "SamAccountName -eq '$SamAccountName'")
            } -ArgumentList $SamAccountName -ErrorAction Stop

        if ($Exists) {
            return [PSCustomObject]@{
                ComputerName   = $ComputerName
                SamAccountName = $SamAccountName
                Action         = "AlreadyExists"
                Changed        = $false
            }
        }

        if ($PSCmdlet.ShouldProcess($SamAccountName, "Créer le compte Active Directory")) {

            Invoke-Command -ComputerName $ComputerName -Credential $Credential `
                -ScriptBlock {
                    param ($SamAccountName, $Name, $Path, $AccountPassword)

                    Import-Module ActiveDirectory

                    New-ADUser `
                        -SamAccountName $SamAccountName `
                        -Name $Name `
                        -Path $Path `
                        -AccountPassword $AccountPassword `
                        -Enabled $true
                } -ArgumentList $SamAccountName, $Name, $Path, $AccountPassword `
                -ErrorAction Stop

            [PSCustomObject]@{
                ComputerName   = $ComputerName
                SamAccountName = $SamAccountName
                Action         = "Created"
                Changed        = $true
            }
        }
    }
    catch {
        Write-Error "Échec de la création du compte '$SamAccountName' : $($_.Exception.Message)"
    }
}