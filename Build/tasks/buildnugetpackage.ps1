
Properties {
    $Log = $null
    $Base = $null
    $Modules = $null
    $Debug   = $false
    $Verbose = $false
}

Task default -Depends TestProperties, Template

Task Template{
    Write-Host 'building nuget package'
}

task TestProperties {
  Assert ($Log -ne $null) "Log should not be null"
  Assert ($Base -ne $null) "Base should not be null"
  Assert ($Modules -ne $null) "Modules should not be null"
  Assert ($Debug -ne $null) "Debug should not be null"
  Assert ($Verbose -ne $null) "Verbose should not be null"
}
