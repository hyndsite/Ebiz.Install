<#
.DESCRIPTION
	This function will create a new IIS application pool OR set the Ebusiness required application parameters to an existing application pool
	
.EXAMPLE
	.\Install-AppPool -appPool MyNewAppPool
	
.NOTES
	IIS Does not allow for any non-alphanumeric characters
	
#>

function Install-AppPool([string]$appPool) {
	if (!$appPool) {
		Write-Warning ">>> No AppPool submitted <<<"
		return $false
	}
	
	$confirmedAppPool = Get-ChildItem IIS:\AppPools | where {$_.Name -eq $appPool}
	
	if ($confirmedAppPool) {
		Write-ColorText -Text "INFO: >>", "Application Pool ", $($appPool), " already exists, will use existing application pool." -Color Gray, Green, white, Green -NewLine
		Write-Host ""
		$appPoolName = Get-ChildItem IIS:\apppools | where { $_.Name -eq $appPool}
		$appPoolName.Stop()
		$appPoolName | Set-ItemProperty -Name "ManagedRunTimeVersion" -Value "v2.0"
		$appPoolName | Set-ItemProperty -Name "ManagedPipelineMode"  -Value "1"
		return $true
	}
		
	Write-ColorText -Text "INFO: >>", " Creating application pool ", $($appPool) -Color Gray, Green, White -NewLine	
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