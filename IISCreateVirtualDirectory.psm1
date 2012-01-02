function Create-VirtualDirectory ($sitePath, $name, $path) {
	$fullPath = "{0}\{1}" -f $sitePath, $name
	New-Item $fullpath -Type VirtualDirectory -physicalPath $path
}

function Install-VirtualDirectory([string]$site, [string]$app, [string]$name = "", [string]$path = "") {
	if (!$site) {
		$site = Find-Site
	}
		
	$siteApps = Get-SiteApps $site
	if ($siteApps) {
		if (!$app) {
			Write-ColorText -Text "Applications exist for this site, do you want to create the virtual directory for an existing application under site $($site)? " -Color Green
			Write-ColorText -Text "[", "Y", "]", "Yes or ", "[", "N", "]", "No: " -Color DarkYellow, Yellow, DarkYellow, Green, DarkYellow, Yellow, DarkYellow, Green 
			$isAnApp = Read-Host
			
			if ($isAnApp.ToLower() -eq "y") {
				$app = Find-App $site			
			}
		}
	}
	
		
	while (!$name -Or !$path) {
		if (!$name) {
			#Get users prefered virtual directory name
			$name = Read-ColorText -Text "Please specify the name of the virtual directory" -Color Green
			Write-Host ""
		}
		
		if (!$path) {
			#Get virtual directory's physical path
			Write-ColorText -Text "Select virtual directory's physical directory...." -Color Cyan -NewLine
			$path = Select-Folder -message "Please specify the physical location for the virtual directory"
			
			if ($path) {
				While (!(Test-Path $path)) {
					#Get virtual directory's physical path
					Write-ColorText -Text "The physical location specified does not exists. Please choose a valid physical location for the virtual directory" -Color Yellow -NewLine
					$path = Select-Folder -message "Please specify the physical location for the virtual directory"
				}
			}
		}
	}
	if ($site -And $app) {
		$type = "app"
	} else {
		$type = "site"
	}
	
	switch ($type) {
		site {
			Write-ColorText -Text "----------------------------------------------------------" -Color Yellow -NewLine
			Write-ColorText -Text ">>> Creating virtual directory ", $($name), " for site ", $($site), " <<<" -Color Green, White, Green, White, Green -NewLine
			Write-Host ""
			Create-VirtualDirectory "IIS:\Sites\$($site)" $name $path
			Write-Host ""
		}
		
		app {
			Write-ColorText -Text "----------------------------------------------------------" -Color Yellow -NewLine
			Write-ColorText -Text ">>> Creating virtual directory ", $($name), " for site ", $($site), "\", $($app)" <<<" -Color Green, White, Green, White, Green, White, Green -NewLine
			Write-Host ""
			Create-VirtualDirectory "IIS:\Sites\$($site)\$($app)" $name $path
			Write-Host ""
		}
	}
}

Export-ModuleMember Install-VirtualDirectory