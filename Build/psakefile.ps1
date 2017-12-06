#
# PoshHive psake entry-point
#
# Run build with additional information
#   Invoke-psake .\build\psakefile.ps1 -properties @{"Verbose"=$true; "Debug"=$true}

Properties {
    $Base    = Split-Path (Resolve-Path $PSScriptRoot) -Parent
    $Log     = Join-Path $Base Log
    $Help    = Join-Path $Base Help
    $Modules = Resolve-Path (Join-Path $Base Modules)
    $ModuleName = 'PoshHive'
    $Debug   = $false
    $Verbose = $false
}

FormatTaskName {
   param($taskName)
   # uaee magenta to distinguish tasks from verbose output
   Write-Host "Executing Task: $taskName" -foregroundcolor Magenta
}

Task default -Depends BuildNugetPackage,
                      DebugEnvironment

Task BuildNugetPackage -Depends UnitTest, GenerateHelp {
    $properties = ($script:DefaultProperties).Clone()
    $properties.Add('ModuleName', $ModuleName)
    $args = @{
        'buildFile'  = 'Tasks\buildnugetpackage.ps1';
        'properties' = $properties;
        'nologo'     = $true
    }
    Invoke-psake @args
}
                      
Task UnitTest -Depends StaticAnalysis {
    $properties = ($script:DefaultProperties).Clone()
    $args = @{
        'buildFile'  = 'Tasks\template.ps1';
        'properties' = $properties;
        'nologo'     = $true
    }
    Invoke-psake @args
}

Task GenerateHelp -Depends StaticAnalysis, InitialiseLog {
    $properties = ($script:DefaultProperties).Clone()
    $properties.Add('Help', $Help)
    $args = @{
        'buildFile'  = 'Tasks\generatehelp.ps1';
        'properties' = $properties;
        'nologo'     = $true
    }
    Invoke-psake @args
}

Task StaticAnalysis -Depends BuildModule {
    $properties = ($script:DefaultProperties).Clone()
    $properties.Add('ModuleName', $ModuleName)
    $args = @{
        'buildFile'  = 'Tasks\staticanalysis.ps1';
        'properties' = $properties;
        'nologo'     = $true
    }
    Invoke-psake @args
}

Task BuildModule -Depends InitialiseRequiredModules {
    $properties = ($script:DefaultProperties).Clone()
    $args = @{
        'buildFile'  = 'Tasks\buildmodule.ps1';
        'properties' = $properties;
        'nologo'     = $true
    }
    Invoke-psake @args
}

Task InitialiseRequiredModules -Depends InitialiseProperties {
    $properties = ($script:DefaultProperties).Clone()
    $args = @{
        'buildFile'  = 'Tasks\initialiserequiredmodules.ps1';
        'properties' = $properties;
        'nologo'     = $true
    }
    Invoke-psake @args
}

Task DebugEnvironment -precondition { return $Debug } {
    Write-Output "Debug environment information"
    Get-Module -ListAvailable | Write-Output
    $PSVersionTable | Write-Output
}

Task InitialiseLog -Depends InitialiseProperties {
    # log directory should not be uploaded to source control
    if (Test-Path $Log) {
        # remove any artefacts from previous Build
        Remove-Item $Log\*.* -Force
    } else {
        New-Item -Type directory -Path $Log 2>$null | Out-Null
    }
    Write-Output "Any file based logs will be located at: $Log"
}

task InitialiseProperties {
    Assert ($Base -ne $null) 	"Base should not be null"
    Assert ($Log -ne $null) 	"Log should not be null"
    Assert ($Modules -ne $null) "Modules should not be null"
    Assert ($Debug -ne $null) 	"Debug should not be null"
    Assert ($Verbose -ne $null) "Verbose should not be null"
    
    # Initialise default working set of properties. These
    # are shared between all Task contexts in this script.
    # DefaultProperties must be cloned before modification
	$Script:DefaultProperties = @{
		"Base"    = $Base;
		"Log"     = $Log;
		"Modules" = $Modules;
		"Debug"   = $Debug;
		"Verbose" = $Verbose
	 }
}