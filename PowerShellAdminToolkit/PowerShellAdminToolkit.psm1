# Charge les fonctions privées
$PrivateFunctions = Get-ChildItem -Path "$PSScriptRoot\Private\*.ps1" -ErrorAction SilentlyContinue

foreach ($Function in $PrivateFunctions) {
    . $Function.FullName
}

# Charge les fonctions publiques
$PublicFunctions = Get-ChildItem -Path "$PSScriptRoot\Public\*.ps1" -ErrorAction SilentlyContinue

foreach ($Function in $PublicFunctions) {
    . $Function.FullName
}

# Exporte uniquement les fonctions publiques
Export-ModuleMember -Function $PublicFunctions.BaseName