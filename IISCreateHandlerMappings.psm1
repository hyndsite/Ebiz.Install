<#
.DESCRIPTION
	This functions will create new Handler Mappings in IIS for the specified Site or specified Site Application.
	
.EXAMPLE
	.\Install-HandlerMappings -site MySiteName -app MyAppName -attributes $attributes
		
.NOTES
	Parameters:
	Required: 
		- site
		- [System.Collections.Specialized.OrderedDictionary]::attributes
		
	$attributes is an ordered dictionary in order to maintain the order they were specified.
#>

function Install-HandlerMappings([string]$site, [string]$app = "", [string]$name, $attributes) {
	
	$fullPath = ""
	if ($app) {
		$fullPath = "$($site)/$($app)"
	} else {
		$fullPath = "$($site)"
	}
	
	$null = .{
		$sb = New-Object System.Text.StringBuilder
		$sb.Append(("{0}=`'{1}`'" -f "name", $name))
		$sb.Append(",")
		foreach ($key in $($attributes.keys)) {
			$sb.Append(("{0}=`'{1}`'" -f $key, $attributes[$key])) 
			$sb.Append(",") 
		}
		$attrStr = $sb.ToString()
		$attrStr = $attrStr.Remove($attrStr.LastIndexOf(','), 1)
			
		$appcmd = "$env:windir\system32\inetsrv\AppCmd"
		
		.$appcmd SET config "$($fullPath)" -section:system.webServer/handlers /+"[$($attrStr)]" | Out-Host
		#.$appcmd SET config "$($fullPath)" -section:system.webServer/handlers /+"[name='$($name)',path='$($path)',verb='$($verb)',type='$($type)',modules='$($modules)',scriptProcessor='$($scriptProcessor)',resourceType='$($resourceType)',requireAccess='$($requireAccess)']"
	}
	
	
	
			
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