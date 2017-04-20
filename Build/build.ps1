<# 
.SYNOPSIS
	Build PoshHive
	Copyright 2017 Ben Davies
	MIT License. Full license: https://github.com/ukbendavies/PoshHive/blob/master/LICENSE
.NOTES
	Requires PSScriptAnalyzer - static code analysis
	Requires platyPS - generate automated PowerShell help
#>
#Requires -Version 3.0
[CmdletBinding()] param ()
$ErrorActionPreference = "STOP"
Set-StrictMode -Version Latest
Set-PsDebug -Strict

# establish build environment information
if ($PSBoundParameters.ContainsKey('Debug')) {
	Write-Output "Debug information"
	$PSVersionTable | Write-Output
	Get-Module -ListAvailable | Write-Output
}
$base = Resolve-Path "$PSScriptRoot\.."
$modules = Resolve-Path "$base\Modules"
$helpDir = Join-Path $base Help

# log directory should not be uploaded to source control
$logDir = Join-Path $base Log
if (Test-Path $logDir) {
	# remove any artefacts from previous build
	rmdir $logDir\*.* -Force
} else {
	mkdir $logDir
}

# build environment initialization
if (-not (Get-Module PSScriptAnalyzer)) {
	Write-Output 'configuring build packages'
	Find-Package PSScriptAnalyzer | Install-Package
	Find-Package platyPS | Install-Package
}

Write-Output 'executing static code analysis'
Import-Module PSScriptAnalyzer -Verbose
$analysis = Invoke-ScriptAnalyzer -Path $modules\PoshHive\PoshHive.psm1
if (@($analysis | ?{$_.Severity -eq 'Error'}).length -gt 0) {
	Write-Output $analysis
	throw "Build Failed: Script Analyser found errors"
} else {
	Write-Output $analysis
}

# generate markdown function help
Write-Output 'building powershell help'
Import-Module $modules\PoshHive -Force -Verbose
if (Test-Path $helpDir) {
	rm $helpDir\*.* -Force
}
Import-Module platyPS -Verbose
New-MarkdownHelp -Module poshhive -Force -OutputFolder $helpDir -NoMetadata -AlphabeticParamsOrder

# generate markdown function table of contents, syntax and links to generated help
# Note: at this time you need to manually copy the results from $logDir\FunctionToc.md into the readme
# I did consider generating this in-place however I felt the likeliness of splatting something in the readme
# by mistake outweighed the value as the readme is largely a manual document process.
Write-Output 'building powershell help toc for readme'
$helpTable = $(
	Get-Command -Module PoshHive | 
		%{
			"[$($_.Name)](Help/$($_.Name).md) | ``$($(Get-Command $($_.Name) -Syntax).Replace($_.Name, '').Trim())``"
		}
	)
$helpTable | Out-File $logDir\FunctionToc.md -Encoding UTF8 -Force

Write-Output 'build completed without errors'
