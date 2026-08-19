function Get-EventLogSummary {
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
        [ValidateSet('System', 'Application', 'Security')]
        [string]$LogName = 'System',

        [Parameter()]
        [ValidateRange(1, 720)]
        [int]$LastHours = 24,

        [Parameter()]
        [ValidateRange(1, 10000)]
        [int]$ErrorThreshold = 10,

        [Parameter()]
        [ValidateRange(1, 10000)]
        [int]$WarningThreshold = 50
    )

    process {
        foreach ($Computer in $ComputerName) {

            try {
                Write-Verbose "Analyse du journal $LogName sur $Computer"

                $StartTime = (Get-Date).AddHours(-$LastHours)

                $IsLocal = $Computer -in @(
                    $env:COMPUTERNAME,
                    'localhost',
                    '.'
                )

                $Filter = @{
                    LogName   = $LogName
                    StartTime = $StartTime
                }

                if ($IsLocal) {
                    $Events = Get-WinEvent `
                        -FilterHashtable $Filter `
                        -ErrorAction Stop
                }
                else {
                    $Events = Get-WinEvent `
                        -ComputerName $Computer `
                        -FilterHashtable $Filter `
                        -ErrorAction Stop
                }

                # Les niveaux numériques sont utilisés plutôt que
                # LevelDisplayName afin de rester indépendants
                # de la langue de Windows.
                #
                # 1 = Critical
                # 2 = Error
                # 3 = Warning
                # 4 = Information
                # 5 = Verbose

                $Critical = @(
                    $Events | Where-Object Level -eq 1
                ).Count

                $Errors = @(
                    $Events | Where-Object Level -eq 2
                ).Count

                $Warnings = @(
                    $Events | Where-Object Level -eq 3
                ).Count

                $Information = @(
                    $Events | Where-Object Level -eq 4
                ).Count

                $VerboseEvents = @(
                    $Events | Where-Object Level -eq 5
                ).Count

                $KnownEvents = (
                    $Critical +
                    $Errors +
                    $Warnings +
                    $Information +
                    $VerboseEvents
                )

                $OtherEvents = $Events.Count - $KnownEvents

                # Evaluation du niveau de risque
                if ($Critical -gt 0) {
                    $RiskLevel = 'Critical'
                    $Healthy = $false
                }
                elseif ($Errors -ge $ErrorThreshold) {
                    $RiskLevel = 'High'
                    $Healthy = $false
                }
                elseif (
                    $Errors -gt 0 -or
                    $Warnings -ge $WarningThreshold
                ) {
                    $RiskLevel = 'Medium'
                    $Healthy = $true
                }
                else {
                    $RiskLevel = 'Low'
                    $Healthy = $true
                }

                [PSCustomObject]@{
                    ComputerName = $Computer
                    LogName      = $LogName
                    LastHours    = $LastHours
                    TotalEvents  = $Events.Count
                    Critical     = $Critical
                    Errors       = $Errors
                    Warnings     = $Warnings
                    Information  = $Information
                    Verbose      = $VerboseEvents
                    Other        = $OtherEvents
                    Healthy      = $Healthy
                    RiskLevel    = $RiskLevel
                }
            }
            catch {
                Write-Error "Impossible d'analyser le journal '$LogName' sur '$Computer' : $($_.Exception.Message)"
            }
        }
    }
}