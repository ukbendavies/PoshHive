<# 
.SYNOPSIS
	Build PoshHive, runs unit tests, generates the docs and creates a PoshHive nuget package.
	This process uses the psake build task engine for powershell.
	
	MIT License. Full license: https://github.com/ukbendavies/PoshHive/blob/master/LICENSE

	Copyright 2017 Ben Davies
.NOTES
	Requires PSScriptAnalyzer - Static code analysis
	Requires platyPS - Generate automated PowerShell help
	Requires psake  - PowerShell build engine
#>
#Requires -Version 3.0
[CmdletBinding()] param (
	# generate build dependency documentation
	[switch]$Docs
)
$ErrorActionPreference = "STOP"
Set-StrictMode -Version Latest
Set-PsDebug -Strict

$properties = @{}
if ($PSBoundParameters.ContainsKey('Debug')) {
	$properties.Add('Debug', $true)
}

if ($PSBoundParameters.ContainsKey('Verbose')) {
	$properties.Add('Verbose', $true)
}

$args = @{
	'buildFile'  = "$PSScriptRoot\psakefile.ps1";
	'properties' = $properties;
	'nologo'     = $true
}

if ($Docs) {
	$args.Add('docs', $true)
}

# tofix : 
# - bootstrapping of psake
# - for now psake is included in vendor\tools along side nuget
Import-Module $PSScriptRoot\Vendor\Tools\psake

Invoke-psake @args
