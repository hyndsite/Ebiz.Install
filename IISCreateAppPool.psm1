function Install-AppPool([string]$appPool) {
	if (!$appPool) {
		return $false
	}
	
	$confirmedAppPool = Get-ChildItem IIS:\AppPools | where {$_.Name -eq $appPool}
	
	if ($confirmedAppPool) {
		Write-ColorText -Text "Application Pool $($appPool) already exists, will use existing application pool." -Color Cyan -NewLine
		$appPoolName = Get-ChildItem IIS:\apppools | where { $_.Name -eq $appPool}
		$appPoolName.Stop()
		$appPoolName | Set-ItemProperty -Name "ManagedRunTimeVersion" -Value "v2.0"
		$appPoolName | Set-ItemProperty -Name "ManagedPipelineMode"  -Value "1"
		return $true
	}
	
	Write-ColorText -Text "Creating application pool $($appPool)..." -Color Cyan -NewLine	
	New-Item IIS:\AppPools\$appPool
	
	$appPoolName = Get-ChildItem IIS:\apppools | where { $_.Name -eq $appPool}
	$appPoolName.Stop()
	$appPoolName | Set-ItemProperty -Name "ManagedRunTimeVersion" -Value "v2.0"
	$appPoolName | Set-ItemProperty -Name "ManagedPipelineMode"  -Value "1"
	$appPoolName.Start()
	
	$confirmedAppPool = Get-ChildItem IIS:\AppPools | where {$_.Name -eq $appPool}
	
	if ($confirmedAppPool) {
		return $true
	}
	return $false
}

Export-ModuleMember Install-AppPool