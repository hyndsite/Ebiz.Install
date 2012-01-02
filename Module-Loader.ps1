# create a FileSystemWatcher on the currect directory
$filter = '*.psm1'
$folder = $PWD
$watcher = New-object IO.FileSystemWatcher $folder, $filter -Property @{IncludeSubdirectories = $false; EnableRaisingEvents = $true; NotifyFilter = [IO.NotifyFilters]'LastWrite'}
Register-ObjectEvent $watcher Changed -SourceIdentifier FileChanged -Action { 
	$folder = $PWD
	$name = $Event.SourceEventArgs.Name 
   	$filename = ($name -split '\.')[0]
   	$loadedModule = Get-Module | ? { $_.Name -eq $filename }
	write-host $filename		
	if ($loadedModule) {
		write-host "Reloading Module $folder\$($filename)"
		remove-module $filename
		Import-Module .\$filename
		#Reload-Module $filename
	} else {
		write-host "Importing Module $folder\$($filename)"
		Import-Module .\$filename
	}
}
