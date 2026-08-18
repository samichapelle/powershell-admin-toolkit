\# PowerShell Admin Toolkit



Toolkit PowerShell conçu pour automatiser des tâches courantes d'\*\*administration systèmes Windows\*\*.



Ce projet a pour objectif de développer des outils réutilisables pour l'administration d'un parc Windows tout en mettant en pratique les principaux concepts de PowerShell : modules, fonctions avancées, pipeline, objets structurés, CIM et gestion des erreurs.



Le toolkit est développé progressivement autour de cas d'usage concrets rencontrés en administration systèmes.



\---



\## Fonctionnalités



\### Inventaire système



La fonction `Get-SystemInventory` permet de collecter les principales informations matérielles et système d'une machine Windows :



\- nom de la machine ;

\- constructeur et modèle ;

\- système d'exploitation et version ;

\- uptime ;

\- processeur ;

\- mémoire RAM ;

\- adresses IPv4 ;

\- informations sur les disques et l'espace disponible.



La fonction fonctionne sur la machine locale et est conçue pour permettre également l'interrogation de machines distantes via \*\*CIM / WinRM\*\*.



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

&#x20;   Select-Object ComputerName, OS, RAM\_GB

```



\---



\### Export de l'inventaire



La fonction `Export-SystemInventory` permet d'exporter les objets produits par `Get-SystemInventory` dans un fichier CSV exploitable pour du reporting ou un inventaire de parc.



Exemple :



```powershell

Get-SystemInventory |

&#x20;   Export-SystemInventory -Path .\\inventory.csv

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

RAM\_GB

IPv4

Disks

```



L'utilisation d'objets PowerShell structurés permet de conserver les données exploitables dans le pipeline plutôt que de produire uniquement du texte destiné à l'affichage.



\---



\## Utilisation



Importer le module :



```powershell

Import-Module .\\PowerShellAdminToolkit

```



Afficher les commandes disponibles :



```powershell

Get-Command -Module PowerShellAdminToolkit

```



Exemple de sortie :



```text

Export-SystemInventory

Get-SystemInventory

```



Pour obtenir davantage d'informations pendant l'exécution :



```powershell

Get-SystemInventory |

&#x20;   Export-SystemInventory -Path .\\inventory.csv -Verbose

```



\---



\## Administration distante



`Get-SystemInventory` distingue automatiquement l'inventaire de la machine locale et celui d'une machine distante.



L'inventaire local utilise directement CIM :



```powershell

Get-SystemInventory

```



Pour une machine distante :



```powershell

Get-SystemInventory -ComputerName SRV01

```



L'interrogation distante nécessite que la machine cible soit accessible et correctement configurée pour l'administration distante, notamment via \*\*WinRM\*\*.



La fonction accepte également plusieurs noms de machines et les entrées provenant du pipeline.



\---



\## Structure du projet



```text

powershell-admin-toolkit/

│

├── README.md

├── config/

├── docs/

│   └── screenshots/

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

│       ├── Get-SystemInventory.ps1

│       └── Export-SystemInventory.ps1

│

└── tests/

&#x20;   └── PowerShellAdminToolkit.Tests.ps1

```



Les fonctions du dossier `Public` constituent les commandes exposées par le module.



Les fonctions du dossier `Private` sont destinées au fonctionnement interne du toolkit et ne sont pas directement exposées à l'utilisateur.



\---



\## Concepts PowerShell mis en œuvre



Le projet met progressivement en pratique plusieurs mécanismes importants de PowerShell :



\- fonctions avancées avec `\[CmdletBinding()]` ;

\- paramètres typés et validation ;

\- utilisation du pipeline ;

\- `begin`, `process` et `end` ;

\- création d'objets avec `\[PSCustomObject]` ;

\- interrogation système avec CIM ;

\- sessions CIM pour l'administration distante ;

\- splatting de paramètres ;

\- gestion des erreurs avec `try`, `catch` et `finally` ;

\- modules PowerShell (`.psm1`) ;

\- manifestes de modules (`.psd1`) ;

\- export de données structurées vers CSV.



\---



\## Compatibilité



Le module est actuellement développé pour :



\- Windows 10 / Windows 11 ;

\- Windows Server ;

\- Windows PowerShell 5.1 et versions ultérieures.



Certaines fonctionnalités d'administration distante nécessitent une configuration appropriée de WinRM sur les machines cibles.



\---



\## État du projet



Le projet est en cours de développement.



Les premières fonctionnalités d'inventaire système et d'export CSV sont opérationnelles. D'autres fonctions d'administration Windows seront progressivement ajoutées au toolkit.

