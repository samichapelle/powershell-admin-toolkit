# PowerShell Admin Toolkit

Toolkit PowerShell conçu pour automatiser des tâches courantes d'**administration systèmes Windows**.

Ce projet a pour objectif de développer des outils réutilisables pour l'administration d'un parc Windows tout en mettant en pratique les principaux concepts de PowerShell : modules, fonctions avancées, pipeline, objets structurés, CIM, diagnostic réseau, analyse des journaux Windows et gestion des erreurs.

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

### Diagnostic de connectivité réseau

La fonction `Test-NetworkConnectivity` permet d'effectuer plusieurs contrôles de connectivité vers une ou plusieurs machines :

- résolution DNS ;
- récupération des adresses IP associées ;
- test de connectivité ICMP ;
- test de ports TCP ;
- interrogation de plusieurs machines et plusieurs ports.

Exemple :

```powershell
Test-NetworkConnectivity -ComputerName google.com -Port 80,443
```

La fonction retourne des objets PowerShell structurés contenant notamment :

```text
ComputerName
DnsResolved
ResolvedIP
PingSuccess
Port
TcpOpen
```

Plusieurs machines peuvent être testées simultanément :

```powershell
Test-NetworkConnectivity -ComputerName SRV01,SRV02 -Port 443,3389
```

Les résultats peuvent ensuite être exploités directement dans le pipeline. Par exemple, pour afficher uniquement les ports dont la connexion TCP a échoué :

```powershell
Test-NetworkConnectivity -ComputerName SRV01,SRV02 -Port 443,3389 |
    Where-Object TcpOpen -eq $false
```

Cette approche permet d'utiliser la fonction aussi bien pour un diagnostic ponctuel que comme composant d'un processus d'automatisation plus large.

![Test de connectivité réseau](./docs/screenshots/network-connectivity.png)

---

### Analyse des journaux Windows

La fonction `Get-EventLogSummary` permet d'obtenir une synthèse des événements Windows enregistrés sur une période donnée.

Elle permet notamment de :

- sélectionner le journal à analyser (`System`, `Application` ou `Security`) ;
- définir une période d'analyse en heures ;
- compter les événements selon leur niveau de sévérité ;
- identifier automatiquement le niveau de risque global ;
- déterminer un indicateur de santé de la machine ;
- analyser une machine locale ou distante.

Exemple :

```powershell
Get-EventLogSummary
```

Par défaut, la fonction analyse le journal `System` sur les dernières 24 heures.

Il est possible de sélectionner un autre journal et une autre période :

```powershell
Get-EventLogSummary -LogName Application -LastHours 48
```

La fonction retourne un objet structuré contenant notamment :

```text
ComputerName
LogName
LastHours
TotalEvents
Critical
Errors
Warnings
Information
Verbose
Other
Healthy
RiskLevel
```

Les niveaux d'événements sont identifiés à partir de leur valeur numérique Windows plutôt qu'à partir de `LevelDisplayName`.

Cette approche évite de dépendre de la langue du système d'exploitation :

```text
1 = Critical
2 = Error
3 = Warning
4 = Information
5 = Verbose
```

Le niveau de risque est évalué selon les événements observés et des seuils configurables.

Avec les valeurs par défaut :

```text
Critical > 0          -> Critical
Errors >= 10          -> High
Errors > 0            -> Medium
Warnings >= 50        -> Medium
Sinon                 -> Low
```

Les seuils peuvent être adaptés lors de l'appel de la fonction :

```powershell
Get-EventLogSummary -ErrorThreshold 5 -WarningThreshold 20
```

Comme les autres fonctions de collecte du toolkit, `Get-EventLogSummary` retourne des objets PowerShell pouvant être filtrés ou intégrés dans d'autres traitements.

Par exemple :

```powershell
Get-EventLogSummary |
    Where-Object Healthy -eq $false
```

![Event Log Summary](./docs/screenshots/event-log-summary.png)

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
Get-EventLogSummary
Get-ServiceHealth
Get-SystemInventory
Show-ServiceHealth
Test-NetworkConnectivity
```

Pour obtenir davantage d'informations pendant l'exécution :

```powershell
Get-SystemInventory |
    Export-SystemInventory -Path .\inventory.csv -Verbose
```

---

## Administration distante

Plusieurs fonctions du toolkit sont conçues pour fonctionner aussi bien sur la machine locale que sur des machines distantes.

Par exemple :

```powershell
Get-SystemInventory -ComputerName SRV01
```

ou :

```powershell
Get-EventLogSummary -ComputerName SRV01 -LogName System
```

L'interrogation distante nécessite que la machine cible soit accessible et correctement configurée pour l'administration distante.

Selon la fonction utilisée, cela peut notamment nécessiter une configuration appropriée de **WinRM**, des droits suffisants et l'ouverture des flux réseau nécessaires.

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
│       ├── network-connectivity.png
│       └── service-health.png
│
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
│       ├── Get-EventLogSummary.ps1
│       ├── Get-ServiceHealth.ps1
│       ├── Get-SystemInventory.ps1
│       ├── Show-ServiceHealth.ps1
│       └── Test-NetworkConnectivity.ps1
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
- export de données structurées vers CSV ;
- résolution DNS avec `Resolve-DnsName` ;
- diagnostic réseau avec `Test-Connection` et `Test-NetConnection` ;
- analyse des journaux Windows avec `Get-WinEvent` ;
- filtrage des événements avec `FilterHashtable` ;
- agrégation et classification de données ;
- filtrage et exploitation des résultats via le pipeline.

---

## Compatibilité

Le module est actuellement développé pour :

- Windows 10 / Windows 11 ;
- Windows Server ;
- Windows PowerShell 5.1 et versions ultérieures.

Certaines fonctionnalités d'administration distante nécessitent une configuration appropriée de WinRM et des droits suffisants sur les machines cibles.

---

## État du projet

Le projet est en cours de développement.

Les fonctionnalités actuellement opérationnelles comprennent :

- l'inventaire matériel et système ;
- l'export des inventaires au format CSV ;
- le contrôle de l'état des services Windows ;
- la détection de services automatiques anormalement arrêtés ;
- l'affichage interactif de l'état des services ;
- la résolution DNS d'une ou plusieurs cibles ;
- le test de connectivité ICMP ;
- le diagnostic de connectivité TCP sur un ou plusieurs ports ;
- l'analyse des journaux Windows ;
- le comptage des événements par niveau de sévérité ;
- l'évaluation d'un niveau de risque à partir des événements observés ;
- l'analyse locale ou distante de plusieurs composants Windows ;
- le filtrage et l'exploitation des résultats via le pipeline PowerShell.

D'autres fonctions d'administration, de diagnostic et d'automatisation Windows seront progressivement ajoutées au toolkit.