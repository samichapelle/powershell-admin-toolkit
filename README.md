# PowerShell Admin Toolkit

Toolkit PowerShell conçu pour automatiser des tâches courantes d'**administration systèmes Windows**.

Ce projet a pour objectif de développer des outils réutilisables pour l'administration d'un parc Windows tout en mettant en pratique les principaux concepts de PowerShell : modules, fonctions avancées, pipeline, objets structurés, CIM et gestion des erreurs.

Le toolkit est développé progressivement autour de cas d'usage concrets rencontrés en administration systèmes.

---

## Fonctionnalités

### Inventaire système

La fonction `Get-SystemInventory` permet de collecter les principales informations matérielles et système d'une machine Windows :

- nom de la machine ;
- constructeur et modèle ;
- système d'exploitation et version ;
- uptime ;
- processeur ;
- mémoire RAM ;
- adresses IPv4 ;
- informations sur les disques et l'espace disponible.

La fonction fonctionne sur la machine locale et est conçue pour permettre également l'interrogation de machines distantes via **CIM / WinRM**.

Exemple :

```powershell
Get-SystemInventory
```

Il est également possible d'utiliser le pipeline PowerShell :

```powershell
$env:COMPUTERNAME | Get-SystemInventory
```

Ou de sélectionner uniquement certaines propriétés :

```powershell
Get-SystemInventory |
    Select-Object ComputerName, OS, RAM_GB
```

---

### Export de l'inventaire

La fonction `Export-SystemInventory` permet d'exporter les objets produits par `Get-SystemInventory` dans un fichier CSV exploitable pour du reporting ou un inventaire de parc.

Exemple :

```powershell
Get-SystemInventory |
    Export-SystemInventory -Path .\inventory.csv
```

Le fichier généré contient notamment :

```text
ComputerName
Manufacturer
Model
OS
OSVersion
UptimeDays
CPU
RAM_GB
IPv4
Disks
```

L'utilisation d'objets PowerShell structurés permet de conserver les données exploitables dans le pipeline plutôt que de produire uniquement du texte destiné à l'affichage.

---

### Supervision de l'état des services

La fonction `Get-ServiceHealth` permet de contrôler l'état de services Windows sur une ou plusieurs machines.

Pour chaque service analysé, la fonction retourne notamment :

- le nom de la machine ;
- le nom du service ;
- son nom d'affichage ;
- son état (`Running`, `Stopped`, etc.) ;
- son type de démarrage ;
- un indicateur `Healthy`.

Exemple :

```powershell
Get-ServiceHealth -ServiceName WinRM,W32Time,EventLog
```

La fonction ne considère pas automatiquement un service arrêté comme problématique.

Le type de démarrage est également pris en compte : un service configuré en démarrage automatique mais arrêté est considéré comme non sain.

```text
Status    StartType    Healthy
------    ---------    -------
Running   Auto         True
Stopped   Manual       True
Stopped   Auto         False
```

Les résultats retournés étant des objets PowerShell, ils peuvent être directement filtrés dans le pipeline.

Par exemple, pour afficher uniquement les services présentant une anomalie :

```powershell
Get-ServiceHealth |
    Where-Object Healthy -eq $false
```

---

### Affichage de l'état des services

La fonction `Show-ServiceHealth` fournit une vue destinée à une consultation interactive rapide par l'administrateur.

Elle s'appuie sur les résultats de `Get-ServiceHealth` et ajoute une représentation visuelle de l'indicateur de santé :

- `True` en vert ;
- `False` en rouge.

Exemple :

```powershell
Show-ServiceHealth -ServiceName AdobeARMservice,EventLog
```

Cette séparation permet de conserver `Get-ServiceHealth` comme une fonction produisant des objets exploitables pour l'automatisation, tout en proposant `Show-ServiceHealth` pour une lecture directe dans le terminal.

![Service Health Monitoring](./docs/screenshots/service-health.png)

---

## Utilisation

Importer le module :

```powershell
Import-Module .\PowerShellAdminToolkit
```

Afficher les commandes disponibles :

```powershell
Get-Command -Module PowerShellAdminToolkit
```

Exemple de sortie :

```text
Export-SystemInventory
Get-ServiceHealth
Get-SystemInventory
Show-ServiceHealth
```

Pour obtenir davantage d'informations pendant l'exécution :

```powershell
Get-SystemInventory |
    Export-SystemInventory -Path .\inventory.csv -Verbose
```

---

## Administration distante

`Get-SystemInventory` distingue automatiquement l'inventaire de la machine locale et celui d'une machine distante.

L'inventaire local utilise directement CIM :

```powershell
Get-SystemInventory
```

Pour une machine distante :

```powershell
Get-SystemInventory -ComputerName SRV01
```

L'interrogation distante nécessite que la machine cible soit accessible et correctement configurée pour l'administration distante, notamment via **WinRM**.

La fonction accepte également plusieurs noms de machines et les entrées provenant du pipeline.

---

## Structure du projet

```text
powershell-admin-toolkit/
│
├── README.md
├── config/
├── docs/
│   └── screenshots/
│       └── service-health.png
├── examples/
│   └── usage-examples.ps1
│
├── PowerShellAdminToolkit/
│   ├── PowerShellAdminToolkit.psd1
│   ├── PowerShellAdminToolkit.psm1
│   │
│   ├── Private/
│   │   └── Write-ToolkitLog.ps1
│   │
│   └── Public/
│       ├── Export-SystemInventory.ps1
│       ├── Get-ServiceHealth.ps1
│       ├── Get-SystemInventory.ps1
│       └── Show-ServiceHealth.ps1
│
└── tests/
    └── PowerShellAdminToolkit.Tests.ps1
```

Les fonctions du dossier `Public` constituent les commandes exposées par le module.

Les fonctions du dossier `Private` sont destinées au fonctionnement interne du toolkit et ne sont pas directement exposées à l'utilisateur.

---

## Concepts PowerShell mis en œuvre

Le projet met progressivement en pratique plusieurs mécanismes importants de PowerShell :

- fonctions avancées avec `[CmdletBinding()]` ;
- paramètres typés et validation ;
- utilisation du pipeline ;
- `begin`, `process` et `end` ;
- création d'objets avec `[PSCustomObject]` ;
- interrogation système avec CIM ;
- sessions CIM pour l'administration distante ;
- splatting de paramètres ;
- boucles `foreach` ;
- logique conditionnelle ;
- gestion des erreurs avec `try`, `catch` et `finally` ;
- séparation entre collecte de données et présentation ;
- modules PowerShell (`.psm1`) ;
- manifestes de modules (`.psd1`) ;
- export de données structurées vers CSV.

---

## Compatibilité

Le module est actuellement développé pour :

- Windows 10 / Windows 11 ;
- Windows Server ;
- Windows PowerShell 5.1 et versions ultérieures.

Certaines fonctionnalités d'administration distante nécessitent une configuration appropriée de WinRM sur les machines cibles.

---

## État du projet

Le projet est en cours de développement.

Les fonctionnalités actuellement opérationnelles comprennent :

- l'inventaire matériel et système ;
- l'export des inventaires au format CSV ;
- le contrôle de l'état des services Windows ;
- la détection de services automatiques anormalement arrêtés ;
- l'affichage interactif de l'état des services.

D'autres fonctions d'administration Windows seront progressivement ajoutées au toolkit.