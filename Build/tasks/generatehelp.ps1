
Properties {
    $Log = $null
    $Base = $null
    $Modules = $null
    $Help = $null
    $Debug   = $false
    $Verbose = $false
}

Task default -Depends TestProperties, GenerateHelp, GenerateHelpToc

Task GenerateHelp {
    # generate markdown function help
    if (-not ($env:PSModulePath | Select-String -SimpleMatch "PoshHive\Modules")) {
        $env:PSModulePath += ";$Modules"
    } else {
        Write-Verbose $env:PSModulePath
    }
    Write-Output 'building powershell help'
    Import-Module PoshHive -Force -Verbose:$Verbose
    if (Test-Path $Help) {
        Remove-Item $Help\*.* -Force
    }

    New-MarkdownHelp -Module poshhive -Force -OutputFolder $Help -NoMetadata -AlphabeticParamsOrder
}

Task GenerateHelpToc {
    # generate markdown function help TOC
    # generates markdown function table of contents, syntax and links to generated help
    # Note: at this time you need to manually copy the results from $Log\FunctionToc.md into the readme
    # I did consider generating this in-place however I felt the likeliness of splatting something in the readme
    # by mistake outweighed the value as the readme is largely a manual document process.
    Write-Output 'building powershell help toc for readme'
    $helpTable = $(
        Get-Command -Module PoshHive | 
            %{
                "[$($_.Name)](Help/$($_.Name).md) | ``$($(Get-Command $($_.Name) -Syntax).Replace($_.Name, '').Trim())``"
            }
        )
    $helpTable | Out-File $Log\FunctionToc.md -Encoding UTF8 -Force
}

task TestProperties {
  Assert ($Log -ne $null) "Log should not be null"
  Assert ($Base -ne $null) "Base should not be null"
  Assert ($Modules -ne $null) "Modules should not be null"
  Assert ($Help -ne $null) "Help should not be null"
  Assert ($Debug -ne $null) "Debug should not be null"
  Assert ($Verbose -ne $null) "Verbose should not be null"
}
