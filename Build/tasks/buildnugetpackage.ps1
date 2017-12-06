
# todo
#  - metadata variable, e.g. for licence url ...
#  - pack process
#  - tests

Properties {
    $Log = $null
    $Base = $null
    $Modules = $null
    $ModuleName = $null
    $Debug   = $false
    $Verbose = $false
}

Task default -Depends TestProperties, CreateDefaultNuspec, UpdateNuspecData

Task CreateDefaultNuspec {
    Write-Output "building nuget package spec in: $Log"
	pushd $Log
	& $Base\Build\Vendor\tools\NuGet.exe spec
	# creates a default filename in the working directory
	$script:NuspecFile = 'Package.nuspec'
	if (-not (Test-Path $script:NuspecFile)) {
		throw "Expected $($script:NuspecFile) file not found in $Log."
	}
	popd
}

Task UpdateNuspecData {
    Write-Output "updatng nuspec '$($script:NuspecFile)' with '$ModuleName' module data"
	
	# import manifest data. # TOFIX there has to be a safer way to do this
	$manifest = Invoke-Expression (Get-Content -Raw (Resolve-Path "$Modules\$ModuleName\$ModuleName.psd1"))
	
	pushd $Log
	$spec = [xml](Get-Content -RAW $script:NuspecFile)
	
	# update template with module data
	$spec.package.metadata.id = $ModuleName
	$spec.package.metadata.copyright = $manifest.Copyright
	$spec.package.metadata.description = $manifest.Description
	$spec.package.metadata.authors = $manifest.Author
	$spec.package.metadata.owners = $manifest.Author
	$spec.package.metadata.version = $manifest.ModuleVersion
	$spec.package.metadata.projectUrl = 'foo'
	$spec.package.metadata.projectUrl = 'foo'
	$spec.package.metadata.releaseNotes = 'releaseNotes here todo'
	$spec.package.metadata.tags = "$ModuleName" + ' todo tags tags'
	
	# remove unused elements
	$spec.package.metadata.RemoveChild($spec.package.metadata['iconUrl']) | Out-Null
	$spec.package.metadata.RemoveChild($spec.package.metadata['dependencies'])  | Out-Null
	
	# create the file elements
	$filesElement = $spec.CreateElement('files')
	$manifest.FileList | ForEach-Object {	
		# create and set the attributes
		$fileElement = $filesElement.OwnerDocument.CreateElement('file')
		$fileElement.SetAttribute('src', $_)
		$fileElement.SetAttribute('target', 'figure this bit out')
		
		# associate with the parents
		$filesElement.AppendChild($fileElement)  | Out-Null
		$spec.DocumentElement.AppendChild($filesElement) | Out-Null
	}
	# emit the modified document over the original
	$spec.Save($(Resolve-Path $script:NuspecFile))
	popd
    Write-Output "updated '$($script:NuspecFile)'"
}

Task TestProperties {
  Assert ($Log -ne $null) 		 "Log should not be null"
  Assert ($Base -ne $null) 		 "Base should not be null"
  Assert ($Modules -ne $null) 	 "Modules should not be null"
  Assert ($ModuleName -ne $null) "ModuleName should not be null"
  Assert ($Debug -ne $null) 	 "Debug should not be null"
  Assert ($Verbose -ne $null) 	 "Verbose should not be null"
}
