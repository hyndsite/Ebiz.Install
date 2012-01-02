Param
(
	[Parameter(Mandatory = $False)]
	[string]$action="help",
	[string]$commit
)

$date = Get-Date -format yyyy-MM-dd.HH.mm.ss

function help {
	if($action -ne "help") {
		Write-Host "Invalid argument: $action" -foregroundcolor Yellow
	}
	Write-Host "Usage: $(Get-ScriptName) command" -foregroundcolor Yellow
	Write-Host "Available commands are " -foregroundcolor Yellow -nonewline
	Write-Host $(Get-Functions) -Separator ", " -foregroundcolor Yellow 
	Exit
}

function backup {
	git add -A . | Out-Null
	index
}

function index {
	git commit -q -m "snapshot $date" | Out-Null
	
	Write-Host "Snapshot complete $date"
	Write-Host "The following files where updated in this snapshot:"
	git --no-pager show --pretty="format:" --name-only
}

function pretend {
	Write-Host "The following files would be handled:"
	git status -s
}

function tag {
	git tag -m "Stable Mark $date" stable-$date
}

function list {
	$pager = "--no-pager"
	$count = "-20"
	if($commit -eq "all") {
		$pager = ""
		$count = ""
	}
	git $pager log $count --date=relative --pretty=tformat:'%C(yellow)%h%Creset - %C(yellow)%d%Creset %C(green)%s was saved%Creset %C(yellow)%ar%Creset %Cgreen%an%Creset'
}

function show {
	git --no-pager show --pretty="format:" --name-only $commit
}

function revert {
	git checkout -b "Revert-$date"
	git checkout master
	git reset --hard $commit
}

function init {
	if(Is-GitRepository) {
		Write-Error "Already in a Git Repository!"
		Exit
	}

	if(Test-Path gitignore.txt) {
		mv gitignore.txt .gitignore
	}

	git init
	
# Create a gitignore file to keep TFS version control files, 
# user files and cache files from being added to the new repo
@"
snapshot.ps1
"@ | Out-File .gitignore -encoding ascii
	
	git commit -q -m "setup $date" | Out-Null
}

function Is-GitRepository([string]$dir = $pwd) {
		$git_dir = Join-Path $dir ".git"
		
    if ((Test-Path $git_dir) -eq $TRUE) {
        return $TRUE
    }
    
    # Test within parent dirs
    $checkIn = (Get-Item $dir).parent
    while ($checkIn -ne $NULL) {
        $pathToTest = $checkIn.fullname + '/.git'
        if ((Test-Path $pathToTest) -eq $TRUE) {
            return $TRUE
        } else {
            $checkIn = $checkIn.parent
        }
    }
    
    return $FALSE
}

function Get-Functions {
	[System.Management.Automation.PsParser]::Tokenize((Get-Content $MyInvocation.ScriptName), [ref] $null) | ForEach {
		$PSToken = $_
		if($PSToken.Type -eq  'Keyword' -and $PSToken.Content -eq 'Function' ) {     
			$functionKeyWordFound = $true
		}

		if($functionKeyWordFound -and $PSToken.Type -eq  'CommandArgument') {
			$functionKeyWordFound = $false
			$PSToken.Content
		}
	}
}

function Get-ScriptName {
	$name = $MyInvocation.ScriptName
	$index = $name.LastIndexOf('\') + 1
	if($index -gt 0) {
		$name = $name.Substring($index, $name.Length - $index)
	}
	
	return $name -replace ".ps1", ""
}

function Check-Action {
	if(Get-Functions -notcontain $action) { help }
}
#Check-Action
Invoke-Expression $action

