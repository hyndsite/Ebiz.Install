#****************************************************
#***  Create and add new Application to Existing Site
#****************************************************

function Add-SiteApp 
{
	#Let's find out what site the user wants to add the application too.
	$site = Find-Site
	
	#User specifies name of application to create
	$app = Read-ColorText -Text "Please enter name of new application: " -Color green 
	
	#verify they aren't specifying an existing appplication name
	while (Approve-App -appname $app -site $site) {
		Write-ColorText -Text "Specified Application name $app already exists." -Color Red -NewLine 
		$app = Read-Host "Please enter a valid application name: " -foreground yellow
		Write-Host
	}
	Write-Host ""
		
	Write-ColorText -Text "Input Needed >>", "Please Select the Location of the Website Content" -Color Yellow, White -NewLine 
	$path = Select-Folder -message "Please Select the Location of the Website Content"
	Write-ColorText -Text "INFO: >>", " Adding new application ", $app, " for site ", $($site) -Color Gray, Green, White, Green, White  -NewLine 
	
	#Create App
	New-Item "IIS:\Sites\$($site)\$($app)" -Type Application -PhysicalPath $path
	
	#Set Application Pool
	$appPool = "$($app)Pool"
	if (Install-AppPool($appPool)) {
		Write-ColorText -Text "INFO: >>", " Binding application ", $($app), " to application pool ", $($appPool) -Color Gray, Green, White, Green, White -NewLine
		Set-ItemProperty "IIS:\Sites\$($site)\$($app)" ApplicationPool $appPool
	}
	
	$script:app = $app
	$script:site = $site
	$script:dirPath = $path
	
	return  Get-ChildItem IIS:\sites\$site | ? { $_.Name -eq $app } 
}

#****************************************************
#***   Create new Site
#****************************************************

function Acquire-NewSiteName {
	Write-Host ""
	$site = Read-ColorText -Text "Please enter the name of the new site " -Color Green
	Write-Host ""
	
	while (!($site)) {
		$site = Read-ColorText -Text "Please specify a valid site" -Color Yellow
	}
	
	while (Approve-Site($site)) {
		$site = Read-ColorText -Text "INFO: >>", "Site ", $site, " already exists, please specify a new site" -Color Yellow, Green, White, Green
	}
	
	return $site
}

function Create-NewSite
{
	$site = Acquire-NewSiteName
	
	Write-ColorText -Text "Input Needed >>", "Please Select the Location of the Website Content" -Color Yellow, White -NewLine 
	$path = Select-Folder -message "Please Select the Location of the Website Content"
	
	#Create New Site
	New-Item IIS:\Sites\$site -bindings @{protocol = "http"; bindingInformation = "*:80:"} -PhysicalPath $path
					
	$appPool = "$($site)Pool"
	if (Install-AppPool($appPool)) {
		Write-ColorText -Text "INFO: >>", " Binding site ", $($site), " to application pool ", $($appPool) -Color Gray, Green, White, Green, White -NewLine
		 Set-ItemProperty "IIS:\Sites\$($site)" -Name ApplicationPool -Value $appPool
	}
	
	$script:site = $site
	$script:dirPath = $path
	
	return Get-ChildItem IIS:\sites | ? { $_.Name -eq $site } 
}

function Install-Site([string]$action = "", [switch]$Internal) {
	switch ($action) 
	{
		#They chose to add a new application to an existing site
		add { 
			try {
				$newApp = Add-SiteApp
			}
			catch [Exception] {
				$_.Exception.ToString()
				Throw [Exception]
			}
								
			if ($newApp)
			{
				Write-Host ""
				Write-ColorText -Text "SUCCESS: >>", "  New Application ", $($app), " created  ", "<<<" -Color Yellow, Green, White, Green, Yellow -NewLine 
				Write-Host ""										
				if ($script:Internal) {
					return @{"Site" = $($site); "App" = $($app); "Path" = $($dirPath)}
				}
			} else 
			{
				Write-Host ""
				Write-ColorText -Text "FAILED: >>", " There was a problem creating the new application  ", $($app), " <<<" -Color Red, Red, White, Red -NewLine 
				Write-Host ""
			}	
		} 
		#They chose to create a new site - we could expand this to allow either a new site or a new site with an application
		new { 
		
			try {
				$newSite = Create-NewSite
			}
			catch [Exception] {
				$_.Exception.ToString()
				Throw $_.Exception
			}

			if ($newSite)
			{
				Write-Host ""
				Write-ColorText -Text "SUCCESS: >>", "  New Site ", $($site), " created  ", "<<<" -Color Yellow, Green, White, Green, Yellow -NewLine 
				Write-Host ""			
				
				if ($script:Internal) {
					return @{"Site" = $($site); "Path" = $($dirPath)}
				}
			} else 
			{
				Write-Host ""
				Write-ColorText -Text "FAILED: >>", "  There was a problem creating the new site  ", $($site), " <<<" -Color Red, Red, White, Red -NewLine 
				Write-Host ""
			}		
		}
		default {
			$script:Internal = $Internal
			Write-Host  
			Write-ColorText -Text "What Do you want to do?" -Color green -NewLine 
			Write-ColorText -Text "Add an application to an existing site or create a New site? " -Color green -NewLine 
			Write-Host 
			Write-ColorText -Text "[A]", "Add or ", "[N]", "New: " -Color Yellow, Green, Yellow, Green
			$option = Read-Host
			Write-Host
						
			switch ($option.ToLower()) 
			{
				a { Install-Site -action add }
				n { Install-Site -action new }
			}
		}
	}
}

Export-ModuleMember Install-Site 
	