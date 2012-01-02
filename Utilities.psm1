#**********************************
#**       Output Utilities       **
#**********************************

function Write-ColorText([String[]]$Text, [ConsoleColor[]]$Color, [switch]$NewLine)
{
	for($i = 0; $i -lt $Text.Length; $i++)
	{
		Write-Host $Text[$i] -Foreground $Color[$i] -NoNewLine
	}
	if ($NewLine)
	{ 
		Write-Host
	}
}

function Read-ColorText([String[]]$Text, [ConsoleColor[]]$Color)
{
	for($i = 0; $i -lt $Text.Length; $i++)
	{
		Write-Host $Text[$i] -Foreground $Color[$i] -NoNewLine
	}
	return Read-Host " "
}

#**********************************
#**       Specific Modules       **
#**********************************

function Load-pssnapin([string]$pssnapin) {
	$regSnapin = Get-pssnapin -Registered | where { $_.Name -eq $pssnapin }
	
	if ($regSnapin) {
		Add-pssnapin -Name WebAdministration -ErrorAction SilentlyCOntinue -ErrorVariable err
		if ($err){
			if($err[0].Exception.Message.Contains( 'because it is already added')){
				Write-Host "$($pssnapin) already added!" -ForegroundColor green
			}else{
				Write-Host "an error occurred:$($err[0])." -BackgroundColor white -ForegroundColor red
				exit
			}
		}else{
			Write-Verbose "$($pssnapin) Snapin installed"
		}
	} else {
		Write-Warning "pssnapin $($pssnapin) not registered so it will need to be installed first..."
	}
}

function Get-Arguments([string]$path) {
	$Arguments = @()
	$Arguments += "/i"
	$Arguments += "`"$path`""
	$Arguments += "RebootYesNo=`"No`""
	$Arguments += "REBOOT=`"Suppress`""
	$Arguments += "ALLUSERS=`"1`""
	$Arguments += "/passive"
	
	$Arguments
}

function Import-WebAdministration {
	$webAdminModule = get-module -ListAvailable | ? { $_.Name -eq "webadministration" }
	If ($webAdminModule -ne $null) 
	{
		import-module WebAdministration
	} else 	{
		Write-Warning "WebAdministration Module not available to load."
		Write-Warning "Attempting to check if Snapin is available..."
		
		$regSnapin = Get-pssnapin -Registered | where { $_.Name -eq "WebAdministration" }
		
		if ($regSnapin) {
			Write-ColorText -Text "IIS 7 PSSnapin is registered, loading IIS 7 PSSnapin..." -Color Cyan -NewLine
			Load-pssnapin -pssnapin "WebAdministration"
		} else {
			Write-Warning "Snapin not registered, registering IIS 7 PSSnapin..."
			#IIS 7 Snapin not registered, so we will need to install
			$proc = $Env:Processor_Architecture
						
			switch ($proc.ToLower()) {
				amd64 {
					Write-ColorText -Text "Registering IIS 7 PSSnapin for AMD64 Processor..." -Color Cyan -NewLine
					$path = (Join-Path $PWD "inetmgr_amd64.msi")
					$Arguments = Get-Arguments -path $path
					Start-Process "msiexec.exe" -ArgumentList $Arguments -Wait
				}
				x86 {
					Write-ColorText -Text "Registering IIS 7 PSSnapin for x86 Processor..." -Color Cyan -NewLine
					$path = (Join-Path $PWD "iis7psprov_x86.msi")
					$Arguments = Get-Arguments -path $path
					Start-Process "msiexec.exe" -ArgumentList $Arguments -Wait
				}
			}
			#Attempting to load the snapin assuming it installed correctly
			Load-pssnapin -pssnapin "WebAdministration"
		}
	}
}


#**********************************
#**        IIS Utilities         **
#**********************************

function Approve-App {
	Param(
		[string]$appName,
		[string]$site
	)
	
	if ($appName) 
	{
		$existingApp = Get-ChildItem IIS:\sites\$site | ? { $_.Name -eq $appName }
		if ($existingApp)
		{
			return $true
		}
		return $false
	}
}

function Approve-Site([string]$site = "") {
	if($site) {
		$existingSite = Get-ChildItem IIS:\Sites | ? { $_.Name -eq $site }
		
		if ($existingSite) {
			return $true
		}
		
		return $false
	}
}

function Find-Site {
	$existingSites = Get-ChildItem IIS:\Sites
	Write-ColorText -Text "The Following are the existing sites availabe to add a new application." -Color Yellow -NewLine
	$count = 0
	foreach ($site in $existingSites) 
	{
		$count++
		Write-Host $count") " $site.Name
	}
	
	Write-Host ""
	[int]$choice = Read-ColorText -Text "Please Specify the number of the site [1 - $count] you want to add a new Application to " -Color green -NewLine
	Write-Host ""
	
	while (($choice -lt 1) -Or ($choice -gt $count)) {
		Write-ColorText -Text "Your choice $($choice) is invalid. Please choice a valid number [1 - $count]: " -Color green -NewLine 
		[int]$choice = Read-Host "Please choose [1 - $count] "
		Write-Host
	}
	
	if (($existingSites | Measure-Object).Count -eq 1) {
		return $site = $existingSites.Name
	} else {
		return $site = $existingSites[($choice - 1)].Name	
	}
}

function Get-SiteApps([string]$site) {
	return Get-ChildItem IIS:\Sites\$site | where { $_.Schema.Name -eq "application" }
}

function Find-App([string]$site) {
	$existingApps = Get-SiteApps $site
	
	$count = 0
	if ($existingApps) { 
		for($i = 0; $i -lt $existingApps.Length; $i++) {
			$num = $i 
			$app = "{0}) {1}" -f $($i+1), $existingApps[$i].Name
			Write-host $app
			$count++
		}
		
		Write-Host ""
		$choice = Read-ColorText -Text "Please Specify the number of the application [1 - $count] where you want to add the virtual directory " -Color green -NewLine
		Write-Host ""
		
		while (($choice -lt 1) -Or ($choice -gt $count)) {
			Write-ColorText -Text "Your choice $($choice) is invalid. Please choice a valid number [1 - $count]: " -Color green -NewLine 
			$choice = Read-Host "Please choose [1 - $count] "
			Write-Host
		}
		
		return $existingApps[$choice - 1].Name
	}
	return $null
}

#***************************
#* File/folder utilities
#***************************

function Select-Folder($message='Select a folder', $path = 0) { 
    $object = New-Object -comObject Shell.Application  
     
    $folder = $object.BrowseForFolder(0, $message, 0, $path) 
    if ($folder -ne $null) 
	{ 
        $folder.self.Path 
    } 
}

function Set-LocationTo {
    param(  [parameter(Mandatory = $true)]
         [ValidateNotNullOrEmpty()]
            [string] $targetDir)            

    $dirs = (pwd).Path.Split('\')
    for($i = $dirs.Length - 1; $i -ge 0; $i--) {
        if ($dirs[$i].ToLower().StartsWith($targetDir.ToLower())) {
            $targetIndex = $i
            break
        }
    }
    if($targetIndex -eq 0) {
        Write-Host "Unable to resolve $targetDir"
        return
    }            

    $targetPath = ''
    for($i = 0; $i -le $targetIndex; $i++) {
       $targetPath += $dirs[$i] + '\'
    }            

    Set-Location $targetPath
}            



#this is a change
Export-ModuleMember Write-ColorText, Import-WebAdministration, Approve-App, Approve-Site, Read-ColorText, Select-Folder, Find-Site, Find-App, Get-SiteApps