function Add-ADUserToGroup {
    <#
    .SYNOPSIS
        Ajoute un utilisateur à un groupe Active Directory à distance.
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

        if ($IsMember) {
            return [PSCustomObject]@{
                ComputerName   = $ComputerName
                SamAccountName = $SamAccountName
                GroupName      = $GroupName
                Action         = "AlreadyMember"
                Changed        = $false
            }
        }

        if ($PSCmdlet.ShouldProcess(
            "$SamAccountName -> $GroupName",
            "Ajouter l'utilisateur au groupe Active Directory"
        )) {
            Invoke-Command -ComputerName $ComputerName -Credential $Credential `
                -ScriptBlock {
                    param ($SamAccountName, $GroupName)

                    Import-Module ActiveDirectory -ErrorAction Stop

                    Add-ADGroupMember `
                        -Identity $GroupName `
                        -Members $SamAccountName `
                        -ErrorAction Stop

                } -ArgumentList $SamAccountName, $GroupName -ErrorAction Stop

            [PSCustomObject]@{
                ComputerName   = $ComputerName
                SamAccountName = $SamAccountName
                GroupName      = $GroupName
                Action         = "Added"
                Changed        = $true
            }
        }
    }
    catch {
        Write-Error "Échec de l'ajout de '$SamAccountName' au groupe '$GroupName' : $($_.Exception.Message)"
    }
}