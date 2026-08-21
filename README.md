# PowerShell Admin Toolkit

Toolkit PowerShell conçu pour automatiser des tâches courantes de **diagnostic et d'administration de systèmes Windows**.

L'objectif est double : construire des outils réutilisables pour l'administration d'un parc Windows et mettre en pratique les principaux concepts PowerShell sur des cas d'usage concrets.

---

## Fonctionnalités

### Inventaire système

`Get-SystemInventory` collecte les principales informations d'une machine Windows : OS, uptime, CPU, RAM, IPv4, constructeur, modèle et stockage.

```powershell
Get-SystemInventory
Get-SystemInventory | Select-Object ComputerName, OS, RAM_GB
Get-SystemInventory -ComputerName SRV01
```

`Export-SystemInventory` permet d'exporter les objets obtenus vers CSV.

```powershell
Get-SystemInventory |
    Export-SystemInventory -Path .\inventory.csv
```

### Services Windows

`Get-ServiceHealth` contrôle l'état des services et leur type de démarrage.

```powershell
Get-ServiceHealth -ServiceName WinRM,W32Time,EventLog

Get-ServiceHealth |
    Where-Object Healthy -eq $false
```

`Show-ServiceHealth` fournit une vue interactive destinée à une consultation rapide.

```powershell
Show-ServiceHealth -ServiceName AdobeARMservice,EventLog
```

![Service Health Monitoring](./docs/screenshots/service-health.png)

`Set-ServiceStartup` permet de modifier de manière contrôlée le type de démarrage d'un service.

```powershell
Set-ServiceStartup -ServiceName W32Time -StartupType Automatic
Set-ServiceStartup -ServiceName W32Time -StartupType Automatic -WhatIf
```

La fonction vérifie l'état existant avant modification et retourne notamment `PreviousStartupType`, `NewStartupType`, `Changed` et `Success`.

![Service Startup Management](./docs/screenshots/service-startup.png)

### Diagnostic réseau

`Test-NetworkConnectivity` regroupe plusieurs contrôles : résolution DNS, adresses IP, ICMP et ports TCP.

```powershell
Test-NetworkConnectivity -ComputerName google.com -Port 80,443

Test-NetworkConnectivity -ComputerName SRV01,SRV02 -Port 443,3389 |
    Where-Object TcpOpen -eq $false
```

![Network Connectivity](./docs/screenshots/network-connectivity.png)

### Journaux d'événements Windows

`Get-EventLogSummary` produit une synthèse des événements d'un journal Windows sur une période donnée et retourne notamment les erreurs, avertissements, événements critiques et un niveau de risque.

```powershell
Get-EventLogSummary
Get-EventLogSummary -LogName Application -LastHours 24
```

![Event Log Summary](./docs/screenshots/event-log-summary.png)

---

## Administration des comptes locaux

### Analyse des comptes

`Get-LocalAccountStatus` inventorie les comptes locaux et effectue plusieurs contrôles simples liés à leur état et à leur utilisation.

```powershell
Get-LocalAccountStatus

Get-LocalAccountStatus |
    Where-Object Risk -ne 'OK'
```

Les comptes intégrés Administrator et Guest sont identifiés à partir de leur **SID/RID**, indépendamment de la langue de Windows ou d'un éventuel renommage.

La fonction peut notamment signaler un compte intégré sensible activé, un compte actif n'ayant jamais ouvert de session ou un compte inutilisé depuis un seuil configurable.

```powershell
Get-LocalAccountStatus -InactiveDays 60
```

![Local Account Status](./docs/screenshots/local-account-status.png)

### Cycle de vie des utilisateurs

Le toolkit permet de gérer les principales opérations sur les comptes locaux.

```powershell
# Création
$Password = Read-Host "Mot de passe" -AsSecureString

New-LocalUserAccount `
    -UserName "demouser" `
    -Password $Password `
    -FullName "Utilisateur de démonstration" `
    -Description "Compte de test du toolkit"

# Désactivation / activation
Disable-LocalUserAccount -UserName demouser
Enable-LocalUserAccount -UserName demouser

# Changement de mot de passe
$NewPassword = Read-Host "Nouveau mot de passe" -AsSecureString
Set-LocalUserPassword -UserName demouser -Password $NewPassword

# Suppression
Remove-LocalUserAccount -UserName demouser
```

Les fonctions de modification prennent en charge `ShouldProcess`, permettant notamment l'utilisation de `-WhatIf` et `-Confirm`.

![Local User Lifecycle](./docs/screenshots/local-user-lifecycle.png)

---

## Administration des groupes locaux

Création et suppression de groupes :

```powershell
Add-LocalGroup `
    -GroupName "Toolkit-Operators" `
    -Description "Groupe de test du toolkit"

Remove-LocalGroup -GroupName "Toolkit-Operators"
```

Gestion de l'appartenance d'un utilisateur :

```powershell
Add-LocalUserToGroup `
    -UserName testadmin `
    -GroupName Utilisateurs

Remove-LocalUserFromGroup `
    -UserName testadmin `
    -GroupName Utilisateurs
```

Les fonctions vérifient l'état existant afin d'éviter les modifications inutiles et retournent des objets structurés indiquant le résultat de l'opération.

![Local Group Management](./docs/screenshots/local-group-management.png)

---

## Utilisation

Importer le module depuis la racine du projet :

```powershell
Import-Module .\PowerShellAdminToolkit
```

Afficher les commandes disponibles :

```powershell
Get-Command -Module PowerShellAdminToolkit
```

Commandes actuellement exposées :

```text
Add-LocalGroup
Add-LocalUserToGroup
Disable-LocalUserAccount
Enable-LocalUserAccount
Export-SystemInventory
Get-EventLogSummary
Get-LocalAccountStatus
Get-ServiceHealth
Get-SystemInventory
New-LocalUserAccount
Remove-LocalGroup
Remove-LocalUserAccount
Remove-LocalUserFromGroup
Set-LocalUserPassword
Set-ServiceStartup
Show-ServiceHealth
Test-NetworkConnectivity
```

---

## Sécurité et idempotence

Les fonctions qui modifient le système utilisent les mécanismes standards de PowerShell.

`-WhatIf` permet de visualiser une action sans l'exécuter :

```powershell
Remove-LocalUserAccount -UserName testuser -WhatIf
```

`-Confirm` permet de demander une confirmation avant une opération sensible :

```powershell
Remove-LocalGroup -GroupName "Toolkit-Operators" -Confirm
```

Lorsque cela est pertinent, l'état actuel est vérifié avant modification. Une opération déjà appliquée ne provoque donc pas de changement inutile.

```text
PreviousState : Enabled
NewState      : Enabled
Changed       : False
Success       : True
```

Cette logique rend les fonctions plus prévisibles et facilite leur utilisation dans des scénarios d'automatisation.

---

## Administration distante

Plusieurs fonctions sont conçues pour fonctionner localement ou à distance.

```powershell
Get-SystemInventory -ComputerName SRV01
Get-LocalAccountStatus -ComputerName SRV01,SRV02
```

L'administration distante nécessite une configuration appropriée de **WinRM / PowerShell Remoting**.

---

## Structure du projet

```text
powershell-admin-toolkit/
│
├── README.md
├── config/
├── docs/
│   └── screenshots/
│       ├── event-log-summary.png
│       ├── local-account-status.png
│       ├── local-group-management.png
│       ├── local-group-membership.png
│       ├── local-user-creation.png
│       ├── local-user-disable.png
│       ├── local-user-lifecycle.png
│       ├── network-connectivity.png
│       ├── service-health.png
│       └── service-startup.png
│
├── examples/
│   └── usage-examples.ps1
│
├── PowerShellAdminToolkit/
│   ├── PowerShellAdminToolkit.psd1
│   ├── PowerShellAdminToolkit.psm1
│   ├── Private/
│   │   └── Write-ToolkitLog.ps1
│   └── Public/
│       ├── Add-LocalGroup.ps1
│       ├── Add-LocalUserToGroup.ps1
│       ├── Disable-LocalUserAccount.ps1
│       ├── Enable-LocalUserAccount.ps1
│       ├── Export-SystemInventory.ps1
│       ├── Get-EventLogSummary.ps1
│       ├── Get-LocalAccountStatus.ps1
│       ├── Get-ServiceHealth.ps1
│       ├── Get-SystemInventory.ps1
│       ├── New-LocalUserAccount.ps1
│       ├── Remove-LocalGroup.ps1
│       ├── Remove-LocalUserAccount.ps1
│       ├── Remove-LocalUserFromGroup.ps1
│       ├── Set-LocalUserPassword.ps1
│       ├── Set-ServiceStartup.ps1
│       ├── Show-ServiceHealth.ps1
│       └── Test-NetworkConnectivity.ps1
│
└── tests/
    └── PowerShellAdminToolkit.Tests.ps1
```

Les fonctions du dossier `Public` constituent les commandes exposées par le module. Le dossier `Private` contient les fonctions destinées au fonctionnement interne.

---

## Concepts PowerShell mis en œuvre

Le projet met notamment en pratique :

- fonctions avancées avec `[CmdletBinding()]` ;
- paramètres typés et validation ;
- pipeline et `[PSCustomObject]` ;
- CIM et PowerShell Remoting ;
- gestion des erreurs avec `try`, `catch` et `finally` ;
- modules `.psm1` et manifestes `.psd1` ;
- interrogation système, réseau et journaux Windows ;
- gestion des comptes et groupes locaux ;
- `SecureString` pour les mots de passe ;
- manipulation et analyse des SID Windows ;
- `ShouldProcess`, `-WhatIf` et `-Confirm` ;
- opérations idempotentes avec vérification de l'état existant ;
- export et exploitation de données structurées.

---

## Compatibilité

Le module est actuellement développé pour :

- Windows 10 / Windows 11 ;
- Windows Server ;
- Windows PowerShell 5.1 et versions ultérieures.

Certaines fonctionnalités nécessitent le module `Microsoft.PowerShell.LocalAccounts`, une configuration WinRM appropriée pour l'administration distante ou des privilèges administrateur pour les opérations modifiant le système.

---

## État du projet

Le toolkit couvre désormais deux axes complémentaires.

**Diagnostic et observation :**

- inventaire matériel et système ;
- export CSV ;
- contrôle des services ;
- diagnostic DNS, ICMP et TCP ;
- synthèse des journaux Windows ;
- analyse des comptes locaux.

**Administration contrôlée :**

- création, activation, désactivation et suppression de comptes locaux ;
- changement de mot de passe ;
- création et suppression de groupes locaux ;
- gestion de l'appartenance aux groupes ;
- modification du démarrage des services ;
- opérations protégées par `ShouldProcess` ;
- vérification de l'état existant et comportement idempotent.

L'objectif est de constituer progressivement une **boîte à outils d'administration systèmes Windows réutilisable**, tout en démontrant une utilisation structurée de PowerShell sur des cas d'usage proches de l'administration réelle.

Les prochaines étapes porteront principalement sur les **tests automatisés**, la consolidation de la documentation et, si nécessaire, l'ajout de nouveaux scénarios Windows / Windows Server.
