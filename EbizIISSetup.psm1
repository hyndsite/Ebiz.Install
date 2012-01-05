function Get-HandlerAttributes([string]$name) {
	$attributes = New-Object System.Collections.Specialized.OrderedDictionary
	switch ($name) {
		wildcard {
			$attributes.Add("path", "*")
			$attributes.Add("verb", "*")
			$attributes.Add("modules", "StaticFileModule")
			$attributes.Add("scriptProcessor", "%windir%\Microsoft.NET\Framework\v2.0.50727\aspnet_isapi.dll")
			$attributes.Add("resourceType", "Unspecified")
			$attributes.Add("requireAccess", "None")
			$attributes.Add("allowPathInfo", "false")
			$attributes.Add("preCondition", "classicMode,runtimeVersionv2.0,bitness32")
			$attributes.Add("responseBufferLimit", "4194304")
			return $attributes
		}
		image {
			$attributes.Add("path", "*.jpg, *.png, *.gif, *.ico, *.tif, *.tiff")
			$attributes.Add("verb", "GET")
			$attributes.Add("modules", "IsapiModule")
			$attributes.Add("resourceType", "File")
			$attributes.Add("requireAccess", "Read")
			$attributes.Add("responseBufferLimit", "4194304")
			return $attributes
		}
		video {
			$attributes.Add("path", "*.avi, *.mp3, *.mp4, *.mpg, *.wmv")
			$attributes.Add("verb", "GET")
			$attributes.Add("modules", "IsapiModule")
			$attributes.Add("resourceType", "File")
			$attributes.Add("requireAccess", "Read")
			$attributes.Add("responseBufferLimit", "4194304")
			return $attributes
		}
		binary {
			$attributes.Add("path", "*.exe, *.zip, *.dfx")
			$attributes.Add("verb", "GET")
			$attributes.Add("modules", "IsapiModule")
			$attributes.Add("resourceType", "File")
			$attributes.Add("requireAccess", "Read")
			$attributes.Add("responseBufferLimit", "4194304")
			return $attributes
		}
		flash {
			$attributes.Add("path", "*.swf, *.fla, *.flv")
			$attributes.Add("verb", "GET")
			$attributes.Add("modules", "IsapiModule")
			$attributes.Add("resourceType", "File")
			$attributes.Add("requireAccess", "Read")
			$attributes.Add("responseBufferLimit", "4194304")
			return $attributes
		}
	}
}

function Security-DnnFix([string]$sitePath) {
	$path = join-path $sitePath "Providers\HtmlEditorProviders\Fck"
	$config = join-path $sitePath "web.config"

	if(!(Test-Path $path) -or !(test-path $config)) {
		Write-Warning "The path: $($path) or the website config file path: $($config) is not correct or does not exist."
		Return
	}

	$guid = [guid]::NewGuid().ToString("n");

	get-childItem -Path $path -Recurse fcklinkgallery.*  | rename-item -newname { $_.name -replace 'fcklinkgallery', $guid }

	
	# backup the web.config
	cp $config "$config.bak"

	
	# Fix the web.config
	(Get-Content $config) | Foreach-Object {$_ -replace 'fcklinkgallery', $guid} | Set-Content $config
}

<#
 .DESCRIPTION
	This will deploy an IIS site and complete the following tasks
	- Create IIS Site or IIS Site Application
	- Create Application pool with Visual Ebusiness required parameters and bind to specified site or site application
	- Create required Visual Ebusiness virtual directories
	- (IIS 7.0 / 7.5 Only) Create IIS Hanlder Mappings
	
 .EXAMPLE
	.\Setup
	.\Install-Ebiz
 
 .NOTES
	The Setup.ps1 script must be ran first in order to load all necessary modules and necessary PSSnapin's.
	
#>

function Install-Ebiz {
	$ErrorActionPreference = "Stop"
		
	#Ensure we have the WebAdministration module loaded.
	
	
	#Lets find out what the user wants to do
	Write-ColorText -Text "*******************************************" -Color Green -NewLine
	Write-ColorText -Text "*                                         *" -Color Green -NewLine
	Write-ColorText -Text "*  What do you want to do?                *" -Color Green -NewLine
	Write-ColorText -Text "*                                         *" -Color Green -NewLine
	Write-ColorText -Text "*  1) Complete Ebiz Site Deployment       *" -Color Green -NewLine
	Write-ColorText -Text "*  2) Quit                                *" -Color Green -NewLine
	Write-ColorText -Text "*                                         *" -Color Green -NewLine
	Write-ColorText -Text "*******************************************" -Color Green -NewLine
	$option = Read-Host "Your Chose >> "
	
	While ($option -lt 1 -Or $option -gt 2) 
	{
		$option = Read-Host "Please choose a valid option: "
	}
	
	switch ($option) 
	{
		1 { 
			try {
				#Create site and App Pool
				$info = Install-Site -action $null -Internal
				
				
				#find Parent directory where Ebiz.Modules resides
				$dirs = $info["Path"].Split('\')
				$parentDir = $dirs[0]
				for($i=1; $i -lt $dirs.Length; $i++) {
					$parentDir = (Join-Path $parentDir $dirs[$i])
					if ((Test-Path (Join-Path $parentDir "Ebiz.Modules"))) {
						break
					}
				}
				
				#Create VirtualDirectories
				Write-ColorText -Text "INFO>> ", "Creating Virtual Directories" -Color Yellow, White -NewLine
				Write-Host ""
				Install-VirtualDirectory -site $info["Site"] -app $info["App"] -name "Services" -path (Join-Path $parentDir Ebiz.Modules\Services)
				
				Write-ColorText -Text "Input Needed >>", "Select the Image directory...." -Color Yellow, White -NewLine
				$imageDir = Select-Folder -message "Please choose which directory contains Images." -path $info["Path"]
				
				Install-VirtualDirectory -site $info["Site"] -app $info["App"] -name "Images1" -path $imageDir
				Install-VirtualDirectory -site $info["Site"] -app $info["App"] -name "DesktopModules\Ebiz.Modules" -path (Join-Path $parentDir Ebiz.Modules)
				Install-VirtualDirectory -site $info["Site"] -app $info["App"] -name "DesktopModules\ModuleDefinitions" -path (Join-Path $parentDir Ebiz.Modules\ModuleDefinitions)
				
				#Create Handler Mappings
				$configPath = Join-Path $info["Path"] web.config
				
				if (Test-Path $configPath) {
					if ((gp $configPath IsReadOnly).IsReadOnly) {
						sp $configPath IsReadOnly $false
					}
				}
				
				$iisVersion = get-itemproperty HKLM:\Software\Microsoft\Inetstp | select SetupString, *Version*
				if ($iisVersion -And $iisVersion.MajorVersion.ToString().Contains("7")) {
					Write-ColorText -Text "INFO: >> ", " Creating Handler Mappings" -Color Yellow, White -NewLine
					$mappings = "Wildcard", "Image", "Video", "Binary", "Flash"
					for ($i = 0; $i -lt $mappings.Length; $i++) {
					   $attributes = Get-HandlerAttributes -name $($mappings[$i]).ToLower()
					   Install-HandlerMappings -site $info["Site"] -app $info["App"] -name "$($mappings[$i]) Mappings" -Attributes $attributes
				    }
				}
				
				#apply Dnn Security Fix
				Write-Host ""
				Write-ColorText -Text "INFO: >> ", "Applying Dnn Security Fix" -Color Yellow, White -NewLine
				Security-DnnFix -sitePath $info["Path"]
			}
			catch [Exception] {
				$_.Exception.ToString()
			}
		}
		2 { }
	}
}

Export-ModuleMember Install-Ebiz
