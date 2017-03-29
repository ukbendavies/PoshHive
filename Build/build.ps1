<# 
.SYNOPSIS
    Build PoshHive
	Copyright 2017 Ben Davies
	MIT License. Full license: https://github.com/ukbendavies/PoshHive/blob/master/LICENSE
.NOTES
    Requires PSScriptAnalyzer - static code analysis
	Requires platyPS - generate automated powershell help
#>
Set-StrictMode -Version Latest
Set-PsDebug -Strict

$base = Resolve-Path "$PSScriptRoot\.."
$modules = Resolve-Path "$base\Modules"
$helpDir = Join-Path $base Help

Write-Verbose 'execting static code analysis'
Import-Module PSScriptAnalyzer
$analysis = Invoke-ScriptAnalyzer -Path $modules\PoshHive\PoshHive.psm1
if (@($analysis | ?{$_.Severity -eq 'Error'}).length -gt 0) {
	Write-Output $analysis
	throw "Build Failed: ScriptAnalyzer found errors"
} else {
	Write-Output $analysis
}
Write-Verbose 'building powershell help'
Import-Module $modules\PoshHive -Force
if (Test-Path $helpDir) {
	rm $helpDir\*.* -Force
}
New-MarkdownHelp -Module poshhive -Force -OutputFolder $helpDir

Write-Output 'build completed without errors'
