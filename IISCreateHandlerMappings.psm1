function Install-HandlerMappings([string]$site, [string]$app = "", [string]$name, [string]$path = "", 
								 [string]$verb = "", [string]$type = "", [string]$modules = "", [string]$scriptProcessor = "", 
								 [string]$resourceType = "", [string]$requireAccess = "", [string]$allowPathInfo = "") {
	
	$fullPath = ""
	if ($app) {
		$fullPath = "$($site)/$($app)"
	} else {
		$fullPath = "$($site)"
	}
	
	$appcmd = "$env:windir\system32\inetsrv\AppCmd"
	.$appcmd SET config "$($fullPath)" -section:system.webServer/handlers /+"[name='$($name)',path='$($path)',verb='$($verb)',type='$($type)',modules='$($modules)',resourceType='$($resourceType)',requireAccess='$($requireAccess)']"
	
	#[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.Web.Administration") | Out-Null
	#$iis = new-object Microsoft.Web.Administration.ServerManager
	#$config =$iis.GetApplicationHostConfiguration()
	#$handlersSection = $config.GetSection("system.webServer/handlers" , $($fullPath))
	#$col = $handlersSection.GetCollection()
	#$addElement = $col.CreateElement("add")
	#$addElement["name"] = "$($name)";
	#$addElement["path"] = "$($path)";
	#$addElement["verb"] = "$($verb)";
	#$addElement["modules"] = "$($modules)";
	#$addElement["scriptProcessor"] = "$($scriptProcessor)";
	#$addElement["resourceType"] = "$($resourceType)";
	#$col.Add($addElement)
	#$iis.CommitChanges() 
	
}	
	
Export-ModuleMember Install-HandlerMappings