
$path = join-path $pwd "Website\Providers\HtmlEditorProviders\Fck"
$config = join-path $pwd "Website\web.config"

if(!(Test-Path $path) -or !(test-path $config)) {
	Write-Warning "This script needs run from the ebiz installation directory!"
	Exit
}

$guid = [guid]::NewGuid().ToString("n");

get-childItem -Path $path -Recurse fcklinkgallery.*  | rename-item -newname { $_.name -replace 'fcklinkgallery', $guid }

#
# backup the web.config
cp $config "$config.bak"

#
# Fix the web.config
(Get-Content $config) | Foreach-Object {$_ -replace 'fcklinkgallery', $guid} | Set-Content $config
