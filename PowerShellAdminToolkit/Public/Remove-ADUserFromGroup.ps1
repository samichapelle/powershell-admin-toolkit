function Remove-ADUserFromGroup {
    <#
    .SYNOPSIS
        Retire un utilisateur d'un groupe Active Directory à distance.
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
        [string]$GroupName
    )

    try {
        $IsMember = Invoke-Command -ComputerName $ComputerName -Credential $Credential `
            -ScriptBlock {
                param ($SamAccountName, $GroupName)

                Import-Module ActiveDirectory -ErrorAction Stop

                $User = Get-ADUser -Identity $SamAccountName -ErrorAction Stop
                $Group = Get-ADGroup -Identity $GroupName -ErrorAction Stop

                $null -ne (Get-ADGroupMember -Identity $Group |
                    Where-Object { $_.DistinguishedName -eq $User.DistinguishedName })

            } -ArgumentList $SamAccountName, $GroupName -ErrorAction Stop

        if (-not $IsMember) {
            return [PSCustomObject]@{
                ComputerName   = $ComputerName
                SamAccountName = $SamAccountName
                GroupName      = $GroupName
                Action         = "NotMember"
                Changed        = $false
            }
        }

        if ($PSCmdlet.ShouldProcess(
            "$SamAccountName -> $GroupName",
            "Retirer l'utilisateur du groupe Active Directory"
        )) {
            Invoke-Command -ComputerName $ComputerName -Credential $Credential `
                -ScriptBlock {
                    param ($SamAccountName, $GroupName)

                    Import-Module ActiveDirectory -ErrorAction Stop

                    Remove-ADGroupMember `
                        -Identity $GroupName `
                        -Members $SamAccountName `
                        -Confirm:$false `
                        -ErrorAction Stop

                } -ArgumentList $SamAccountName, $GroupName -ErrorAction Stop

            [PSCustomObject]@{
                ComputerName   = $ComputerName
                SamAccountName = $SamAccountName
                GroupName      = $GroupName
                Action         = "Removed"
                Changed        = $true
            }
        }
    }
    catch {
        Write-Error "Échec du retrait de '$SamAccountName' du groupe '$GroupName' : $($_.Exception.Message)"
    }
}