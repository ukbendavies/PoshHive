<#
British Gas HIVE Home PowerShell wrapper that exposes core HIVE platform functionallity.
Copyright 2017 Ben Davies

MIT License. Full license: https://github.com/ukbendavies/PoshHive/blob/master/LICENSE

Disclaimer
- I do not work with, for and am not in any way assiciated with British Gas or any organisation that creates or maintains HIVE. 
- This work is purely my own experiment after I originally asked for a supported HIVE RestAPI on the British Gas requests forum.

Aknowledgements
 - HIVE Rest Api v6 documentation published by alertme
#>

# const
$HiveUri = [uri]'https://api-prod.bgchprod.info:443/omnia'
$HiveHeaders = @{
	'Content-Type' = 'application/vnd.alertme.zoo-6.1+json';
	'Accept' = 'application/vnd.alertme.zoo-6.1+json';
	'X-Omnia-Client' = 'Hive Web Dashboard';
	'X-Omnia-Access-Token' = ''
}

# private functions
function GetNodeDataStructure {
	[CmdletBinding()] param ()
	# base data-structure for node-attribute representation
	$nodes = @{
		'nodes' = @(
			@{
				'attributes' = @{
					# end building block
				}
			}
		)
	}
	return $nodes
}

# public functions
function Connect-HiveSession {
	[CmdletBinding()] param (
    [Parameter(Mandatory = $true, Position = 0)]
        [string] $Username,
    [Parameter(Mandatory = $true, Position = 1)]
        [string] $Password 
    )
	$Uri = [uri]('' + $HiveUri + '/auth/sessions')

	# create hive login data-structure
	$session = @{
		'username' = $UserName;
		'password' = $Password;
		'caller' = 'WEB'
	}

	$sessions = @{
		'sessions' = @($session)
	}

	$body = ConvertTo-Json $sessions 
	$response = Invoke-RestMethod -Method Post -Uri $Uri.AbsoluteUri -Headers $HiveHeaders -Body $body
	#todo better response validation

	$mySession = $response.sessions[0]
	# store the first session for downstream calls
	if ($mySession -eq $null -or $mySession -eq '') {
		throw 'No valid session'
	}

	Write-Verbose "Logged in as $($mySession.username) [id:$($mySession.sessionId), newestApiV:$($mySession.latestSupportedApiVersion)]"
	$HiveHeaders.'X-Omnia-Access-Token' = $mySession.sessionId
}

function Get-HiveNode {
	[CmdletBinding()] param (
		[Parameter(Mandatory=$false, Position = 0)]
			[guid] $Id = [guid]::Empty
	)
	$Uri = [uri]('' + $HiveUri + '/nodes')
	if ($id -ne [guid]::Empty) {
		$Uri = [uri]($Uri.AbsoluteUri + '/' + $Id)
	}
	$response = Invoke-RestMethod -Method Get -Uri $Uri.AbsoluteUri -Headers $HiveHeaders
	return $response.nodes
}

# device specific helper functions
function Get-HiveThermostat {
	[CmdletBinding()] param ()
	$thermostat = Get-HiveNode | Where-Object { $_.name -ilike '*Thermostat*' }
	return $thermostat
}

function Get-HiveReceiver {
	[CmdletBinding()] param ()
	$thermostats = Get-HiveNode | Where-Object { $_.name -ilike '*Receiver*' }
	$activeThermostats = $thermostats | Where-Object {
		$_.attributes.zone.reportedValue -eq 'HEATING'
	}
	return $activeThermostats
}

function Get-HiveTopology {
	[CmdletBinding()] param ()
	$Uri = [uri]('' + $HiveUri + '/topology')
	
	$response = Invoke-RestMethod -Method Get -Uri $Uri.AbsoluteUri -Headers $HiveHeaders
	return $response.topology
}

function Get-HiveUser {
	[CmdletBinding()] param ()
	$Uri = [uri]('' + $HiveUri + '/users')
	
	$response = Invoke-RestMethod -Method Get -Uri $Uri.AbsoluteUri -Headers $HiveHeaders
	return $response.users
}

function Get-HiveHub {
	[CmdletBinding()] param ()
	$response = Get-HiveNode | Where-Object { $_.name -ilike '*Hub*' }
	return $response
}

function Get-HiveLight {
	[CmdletBinding()] param ()
	$response = Get-HiveNode | Where-Object { $_.name -ilike '*Light*' }
	return $response
}

function Set-HiveLight {
	[CmdletBinding()] param (
    [Parameter(Mandatory = $true, Position = 0)]
        [guid] $Id,
    [Parameter(Mandatory = $false, Position = 1)]
		[ValidateSet('ON', 'OFF')]
        [string] $PowerState,
    [Parameter(Mandatory = $false, Position = 2)]
		[ValidateSet('COLOUR', 'TUNABLE')]
        [string] $ColourMode
    )
	$Uri = [uri]('' + $HiveUri + '/nodes')
	if ($id -ne [guid]::Empty) {
		$Uri = [uri]($Uri.AbsoluteUri + '/' + $Id)
	}
	
	# hive temperature base data-structure
	$nodes = GetNodeDataStructure

	if ($PSBoundParameters.ContainsKey('PowerState')) {
		$newState = @{'targetValue' = $PowerState}
		$nodes.nodes[0].attributes.Add('state', $newState)
	}

	if ($PSBoundParameters.ContainsKey('ColourMode')) {
		$newState = @{'targetValue' = $ColourMode}
		$nodes.nodes[0].attributes.Add('colourMode', $newState)

		if ($ColourMode -eq 'COLOUR') {
			$newState = @{'targetValue' = 0}
			$nodes.nodes[0].attributes.Add('hsvHue', $newState)
			Write-Verbose "Adding hsvHue value 0 as setting colour mode alone doesn't work"
		} else {
			$newState = @{'targetValue' = 2700}
			$nodes.nodes[0].attributes.Add('colourTemperature', $newState)
			Write-Verbose "Adding hsvHue value 0 as setting colour mode alone doesn't work"
		}
	} 

	$body = ConvertTo-Json $nodes -Depth 6 -Compress
	$body | out-string | Write-Host

	$response = Invoke-WebRequest -UseBasicParsing -Method Put -Uri $Uri.AbsoluteUri -Headers $HiveHeaders -Body $body -Verbose
	#todo response processing
	return $response
}

function Set-HiveReceiver {
	[CmdletBinding()] param (
    [Parameter(Mandatory = $true, Position = 0)]
        [guid] $Id,
    [Parameter(Mandatory = $true, Position = 1)]
        [uint16] $TargetTemperature 
    )
	$Uri = [uri]('' + $HiveUri + '/nodes')
	if ($id -ne [guid]::Empty) {
		$Uri = [uri]($Uri.AbsoluteUri + '/' + $Id)
	}
	
	# hive temperature base data-structure
	$nodes = GetNodeDataStructure

	if ($PSBoundParameters.ContainsKey('TargetTemperature')) {
		$newState = @{'targetValue' = $TargetTemperature}
		$nodes.nodes[0].attributes.Add('targetHeatTemperature', $newState)
	}

	$body = ConvertTo-Json $nodes -Depth 6 -Compress
	$body | out-string | Write-Host

	$response = Invoke-WebRequest -UseBasicParsing -Method Put -Uri $Uri.AbsoluteUri -Headers $HiveHeaders -Body $body -Verbose
	#todo response processing
	return $response
}

function Get-HiveEvents {
	[CmdletBinding()] param ()
	$Uri = [uri]('' + $HiveUri + '/events')
	$response = Invoke-RestMethod -Method Get -Uri $Uri.AbsoluteUri -Headers $HiveHeaders
	return $response.events
}

# export public functions
Export-ModuleMember -function *-*
