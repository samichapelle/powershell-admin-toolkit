
function Get-ADAccountStatus {
    <#
    .SYNOPSIS
        Audite l'état des comptes utilisateurs Active Directory.

    .DESCRIPTION
        Interroge Active Directory à distance via PowerShell Remoting
        et identifie notamment les comptes inactifs, jamais utilisés,
        dont le mot de passe est expiré ou configuré pour ne jamais expirer.

    .PARAMETER ComputerName
        Nom ou adresse IP du serveur disposant du module ActiveDirectory.

    .PARAMETER Credential
        Identifiants utilisés pour établir la session PowerShell distante.

    .PARAMETER SearchBase
        Distinguished Name de l'OU à auditer.

    .PARAMETER InactiveDays
        Nombre de jours sans connexion à partir duquel un compte actif
        est considéré comme inactif.

    .EXAMPLE
        Get-ADAccountStatus `
            -ComputerName "192.168.56.10" `
            -Credential $cred `
            -SearchBase "OU=Utilisateurs,DC=toolkit,DC=local"

    .EXAMPLE
        Get-ADAccountStatus `
            -ComputerName "192.168.56.10" `
            -Credential $cred `
            -SearchBase "OU=Utilisateurs,DC=toolkit,DC=local" `
            -InactiveDays 60
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$ComputerName,

        [Parameter(Mandatory)]
        [PSCredential]$Credential,

        [Parameter(Mandatory)]
        [string]$SearchBase,

        [ValidateRange(1, 3650)]
        [int]$InactiveDays = 90
    )

    try {
        $Users = Invoke-Command `
            -ComputerName $ComputerName `
            -Credential $Credential `
            -ErrorAction Stop `
            -ScriptBlock {

                param ($SearchBase)

                Import-Module ActiveDirectory -ErrorAction Stop

                Get-ADUser `
                    -Filter * `
                    -SearchBase $SearchBase `
                    -Properties Enabled,
                                LastLogonDate,
                                PasswordExpired,
                                PasswordNeverExpires,
                                PasswordLastSet

            } -ArgumentList $SearchBase

        foreach ($User in $Users) {

            $RiskReasons = [System.Collections.Generic.List[string]]::new()
            $DaysSinceLastLogon = $null

            if ($User.LastLogonDate) {
                $DaysSinceLastLogon = [math]::Floor(
                    ((Get-Date) - $User.LastLogonDate).TotalDays
                )
            }

            if ($User.Enabled -and -not $User.LastLogonDate) {
                $RiskReasons.Add("Compte actif jamais utilisé")
            }

            if (
                $User.Enabled -and
                $null -ne $DaysSinceLastLogon -and
                $DaysSinceLastLogon -ge $InactiveDays
            ) {
                $RiskReasons.Add(
                    "Compte actif inactif depuis au moins $InactiveDays jours"
                )
            }

            if ($User.Enabled -and $User.PasswordExpired) {
                $RiskReasons.Add("Mot de passe expiré")
            }

            if ($User.Enabled -and $User.PasswordNeverExpires) {
                $RiskReasons.Add("Mot de passe configuré pour ne jamais expirer")
            }

            [PSCustomObject]@{
                ComputerName       = $ComputerName
                UserName           = $User.Name
                SamAccountName     = $User.SamAccountName
                Enabled            = $User.Enabled
                LastLogon          = $User.LastLogonDate
                DaysSinceLastLogon = $DaysSinceLastLogon
                PasswordLastSet    = $User.PasswordLastSet
                PasswordExpired    = $User.PasswordExpired
                PasswordNeverExpires = $User.PasswordNeverExpires
                Risk               = ($RiskReasons.Count -gt 0)
                RiskReason         = $RiskReasons -join "; "
            }
        }
    }
    catch {
        Write-Error "Échec de l'audit Active Directory sur '$ComputerName' : $($_.Exception.Message)"
    }
}