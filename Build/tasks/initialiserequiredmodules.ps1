
Properties {
    $Log = $null
    $Base = $null
    $Modules = $null
    $Debug   = $false
    $Verbose = $false
}

Task default -Depends TestProperties, Template

Task Template {
    # Build environment initialization
    $vendorPath = "$Base\Build\Vendor"
    $packagePath = "$vendorPath\Packages"
    $packageConfigFile = "$vendorPath\packages.config"

    if (-not ($env:PSModulePath | Select-String -SimpleMatch $packagePath)) {
        $env:PSModulePath += ";$packagePath"
    } else {
        Write-Verbose $env:PSModulePath
    }
    
    if (-not (Test-Path $packageConfigFile)) {
        throw "File not found: $packageConfigFile"
    }
    
    if (-not (Test-Path $packagePath)) {
        New-Item -Type directory -Path $packagePath 2>$null | Out-Null
    }

    # parse nuget package format
    $packageConfig = [xml](Get-Content -Raw $packageConfigFile)
    $packageConfig.packages.package | ForEach-Object {
        if (Get-Module -ListAvailable -Name $_.id) {
            Write-Warning "Skipping $($_.id) : Module already installed"
            return
        }
        Write-Output "Getting package: $($_.id)"
        Save-Module -Name $_.id -MinimumVersion $_.version -Path $packagePath -Verbose:$Verbose
    }

    $packageConfig.packages.package | ForEach-Object {	
        Write-Output "Importing Module $($_.id)"
        Import-Module -Name $_.id -Verbose:$Verbose
    }
}

task TestProperties {
  Assert ($Log -ne $null) "Log should not be null"
  Assert ($Base -ne $null) "Base should not be null"
  Assert ($Modules -ne $null) "Modules should not be null"
  Assert ($Debug -ne $null) "Debug should not be null"
  Assert ($Verbose -ne $null) "Verbose should not be null"
}
