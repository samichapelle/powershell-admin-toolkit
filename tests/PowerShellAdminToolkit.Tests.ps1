BeforeAll {
    $ModulePath = Join-Path $PSScriptRoot '..\PowerShellAdminToolkit\PowerShellAdminToolkit.psd1'
    Import-Module $ModulePath -Force
}

Describe 'PowerShellAdminToolkit - Module' {

    It 'importe le module sans erreur' {
        Get-Module PowerShellAdminToolkit | Should -Not -BeNullOrEmpty
    }
    
    It 'exporte les commandes principales attendues' {

    $ExpectedCommands = @(
        'Get-SystemInventory'
        'Get-ServiceHealth'
        'Test-NetworkConnectivity'
        'Get-EventLogSummary'
        'Get-LocalAccountStatus'
        'New-LocalUserAccount'
        'Get-ADAccountStatus'
        'New-ADUserAccount'
    )

    $ExportedCommands = (Get-Command -Module PowerShellAdminToolkit).Name

    foreach ($Command in $ExpectedCommands) {
        $ExportedCommands | Should -Contain $Command
    }
}

Describe 'Get-SystemInventory' {

    It 'retourne un inventaire de la machine locale' {
        $Result = Get-SystemInventory

        $Result | Should -Not -BeNullOrEmpty
    }

    It 'retourne les propriétés attendues' {
        $Result = Get-SystemInventory

        $Result.PSObject.Properties.Name | Should -Contain 'ComputerName'
        $Result.PSObject.Properties.Name | Should -Contain 'OS'
        $Result.PSObject.Properties.Name | Should -Contain 'RAM_GB'
    }
}

Describe 'Disable-LocalUserAccount' {

    It 'désactive un compte actif sans modifier réellement le système' {

        InModuleScope PowerShellAdminToolkit {

            $script:GetLocalUserCall = 0

            Mock Get-LocalUser {
                $script:GetLocalUserCall++

                if ($script:GetLocalUserCall -eq 1) {
                    [PSCustomObject]@{
                        Name    = 'testuser'
                        Enabled = $true
                    }
                }
                else {
                    [PSCustomObject]@{
                        Name    = 'testuser'
                        Enabled = $false
                    }
                }
            }

            Mock Disable-LocalUser {}

            $Result = Disable-LocalUserAccount -UserName 'testuser' -Confirm:$false

            $Result.PreviousState | Should -Be 'Enabled'
            $Result.NewState      | Should -Be 'Disabled'
            $Result.Changed       | Should -BeTrue
            $Result.Success       | Should -BeTrue

            Should -Invoke Disable-LocalUser -Times 1 -Exactly
        }
    }

    It 'ne modifie pas un compte déjà désactivé' {

    InModuleScope PowerShellAdminToolkit {

        Mock Get-LocalUser {
            [PSCustomObject]@{
                Name    = 'testuser'
                Enabled = $false
            }
        }

        Mock Disable-LocalUser {}

        $Result = Disable-LocalUserAccount -UserName 'testuser' -Confirm:$false

        $Result.PreviousState | Should -Be 'Disabled'
        $Result.NewState      | Should -Be 'Disabled'
        $Result.Changed       | Should -BeFalse
        $Result.Success       | Should -BeTrue

        Should -Invoke Disable-LocalUser -Times 0 -Exactly
    }
}
    It 'retourne une erreur si le compte est introuvable' {

    InModuleScope PowerShellAdminToolkit {

        Mock Get-LocalUser {
            throw "Utilisateur introuvable"
        }

        Mock Disable-LocalUser {}

        {
            Disable-LocalUserAccount `
                -UserName 'utilisateur-inexistant' `
                -Confirm:$false `
                -ErrorAction Stop
        } | Should -Throw

        Should -Invoke Disable-LocalUser -Times 0 -Exactly
    }
}

Describe 'Disable-ADUserAccount' {

    It 'désactive un compte AD actif via PowerShell Remoting' {

        InModuleScope PowerShellAdminToolkit {

            $script:InvokeCommandCall = 0

            Mock Invoke-Command {
                $script:InvokeCommandCall++

                if ($script:InvokeCommandCall -eq 1) {
                    [PSCustomObject]@{
                        SamAccountName = 'test.aduser'
                        Enabled        = $true
                    }
                }
            }

            $SecurePassword = ConvertTo-SecureString 'MotDePasseTest' -AsPlainText -Force
            $Credential = [PSCredential]::new('TOOLKIT\TestAdmin', $SecurePassword)

            $Result = Disable-ADUserAccount `
                -ComputerName '192.168.56.10' `
                -Credential $Credential `
                -SamAccountName 'test.aduser' `
                -Confirm:$false

            $Result.ComputerName   | Should -Be '192.168.56.10'
            $Result.SamAccountName | Should -Be 'test.aduser'
            $Result.Action         | Should -Be 'Disabled'
            $Result.Changed        | Should -BeTrue

            Should -Invoke Invoke-Command -Times 2 -Exactly
        }
    }
}
}

}