
Properties {
    $Log = $null
    $Base = $null
    $Modules = $null
    $ModuleName = $null
    $Debug   = $false
    $Verbose = $false
}

Task default -Depends TestProperties, RunStaticAnalysisOnModule, RunStaticAnalysisOnManifest

Task RunStaticAnalysisOnModule {
    Write-Output 'executing static code analysis'
    $analysis = Invoke-ScriptAnalyzer -Path $Modules\$ModuleName\$ModuleName.psm1 `
                                      -Verbose:$Verbose
    if (@($analysis | ?{$_.Severity -eq 'Error'}).length -gt 0) {
        Write-Output $analysis
        throw "Build Failed: Script Analyser found errors"
    }
    Write-Output $analysis
}

Task RunStaticAnalysisOnManifest {
    Write-Output 'executing static code analysis'
    $analysis = Invoke-ScriptAnalyzer -Path $Modules\$ModuleName\$ModuleName.psd1 `
                                      -Verbose:$Verbose
    if (@($analysis | ?{$_.Severity -eq 'Error'}).length -gt 0) {
        Write-Output $analysis
        throw "Build Failed: Script Analyser found errors"
    }
    Write-Output $analysis
}

task TestProperties {
  Assert ($Log -ne $null) "Log should not be null"
  Assert ($Base -ne $null) "Base should not be null"
  Assert ($Modules -ne $null) "Modules should not be null"
  Assert ($ModuleName -ne $null) "ModuleName should not be null"
  Assert ($Debug -ne $null) "Debug should not be null"
  Assert ($Verbose -ne $null) "Verbose should not be null"
}
