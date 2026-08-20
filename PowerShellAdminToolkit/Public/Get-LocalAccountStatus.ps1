function Get-LocalAccountStatus {
    [CmdletBinding()]
    param (
        [Parameter(
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [ValidateNotNullOrEmpty()]
        [string[]]$ComputerName = $env:COMPUTERNAME,

        [Parameter()]
        [ValidateRange(1, 3650)]
        [int]$InactiveDays = 90
    )

    process {
        foreach ($Computer in $ComputerName) {

            try {
                Write-Verbose "Analyse des comptes locaux sur $Computer"

                $IsLocal = $Computer -in @(
                    $env:COMPUTERNAME,
                    'localhost',
                    '.'
                )

                if ($IsLocal) {
                    $Accounts = Get-LocalUser -ErrorAction Stop
                }
                else {
                    $Accounts = Invoke-Command `
                        -ComputerName $Computer `
                        -ScriptBlock {
                            Get-LocalUser
                        } `
                        -ErrorAction Stop
                }

                foreach ($Account in $Accounts) {

                    $Sid = [string]$Account.SID
                    $RiskReasons = @()

                    # Identification des comptes intégrés par RID.
                    # Cela reste fiable indépendamment de la langue
                    # de Windows ou d'un éventuel renommage du compte.
                    if ($Sid -match '-500$') {
                        $AccountType = 'BuiltInAdministrator'

                        if ($Account.Enabled) {
                            $RiskReasons += 'Built-in Administrator account enabled'
                        }
                    }
                    elseif ($Sid -match '-501$') {
                        $AccountType = 'BuiltInGuest'

                        if ($Account.Enabled) {
                            $RiskReasons += 'Built-in Guest account enabled'
                        }
                    }
                    else {
                        $AccountType = 'LocalAccount'
                    }

                    # Analyse de la dernière connexion.
                    if ($Account.LastLogon) {
                        $DaysSinceLastLogon = [math]::Floor(
                            ((Get-Date) - $Account.LastLogon).TotalDays
                        )

                        if (
                            $Account.Enabled -and
                            $DaysSinceLastLogon -ge $InactiveDays
                        ) {
                            $RiskReasons += "Account inactive for $DaysSinceLastLogon days"
                        }
                    }
                    else {
                        $DaysSinceLastLogon = $null

                        if ($Account.Enabled) {
                            $RiskReasons += 'Enabled account has never logged on'
                        }
                    }

                    # Evaluation globale du compte.
                    if ($RiskReasons.Count -gt 0) {
                        $Risk = 'Warning'
                    }
                    else {
                        $Risk = 'OK'
                    }

                    [PSCustomObject]@{
                        ComputerName       = $Computer
                        UserName           = $Account.Name
                        SID                = $Sid
                        AccountType        = $AccountType
                        Enabled            = $Account.Enabled
                        LastLogon          = $Account.LastLogon
                        DaysSinceLastLogon = $DaysSinceLastLogon
                        PasswordExpires    = $Account.PasswordExpires
                        PasswordRequired   = $Account.PasswordRequired
                        UserMayChangePwd   = $Account.UserMayChangePassword
                        Risk               = $Risk
                        RiskReason         = $RiskReasons -join '; '
                    }
                }
            }
            catch {
                Write-Error "Impossible d'analyser les comptes locaux sur '$Computer' : $($_.Exception.Message)"
            }
        }
    }
}