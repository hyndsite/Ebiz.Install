$modules = dir -recurse | where {$_.Name -match "^*.psm1"}

for ($i = 0; $i -lt $modules.Length; $i++) {
	$file = "$($modules[$i])"
	$modName = $file.Remove($file.IndexOf('.'), 5)
	$loadedModule = Get-Module | ? { $_.Name -eq $modName }
		
	if ($loadedModule) {
		Write-Host "Reloading Module: $($loadedModule)"
		Remove-Module $modName -Force
		Import-Module .\$modName 
	} else {
		Write-Host "Importing Module: $($modName)"
		Import-Module .\$modName 
	}
}

Import-WebAdministration
