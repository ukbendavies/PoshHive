<#
British Gas HIVE Home PowerShell wrapper that exposes core HIVE platform functionality.
Copyright 2017 Ben Davies

MIT License. Full license: https://github.com/ukbendavies/PoshHive/blob/master/LICENSE

Disclaimer
- I do not work with, for and am not in any way associated with British Gas or any organisation that creates or maintains HIVE. 
- This work is purely my own experiment after I originally asked for a supported HIVE RestAPI on the British Gas requests forum.

Acknowledgements
- HIVE Rest Api documentation published by alertme
  https://api.prod.bgchprod.info:8443/api/docs
- HIVE REST API V6.1, great investigation by James Saunders
  http://www.smartofthehome.com/2016/05/hive-rest-api-v6/
#>
Set-StrictMode -Version Latest
Set-PsDebug -Strict

# constants
Set-Variable HiveUri $([uri]'https://api-prod.bgchprod.info/omnia') -Option constant
Set-Variable HiveWeatherUri $([uri]'https://weather-prod.bgchprod.info') -Option constant

<# todo figure out what these nodes do. there are also potentially as yet unknown classes?
http://alertme.com/schema/json/node.class.synthetic.binary.control.device.uniform.scheduler.json#
http://alertme.com/schema/json/node.class.synthetic.motion.duration.json#
http://alertme.com/schema/json/node.class.synthetic.control.device.uniform.scheduler.json#
#>
Set-Variable AlertMeSchemaUri $([uri]'http://alertme.com/schema/json') -Option constant
Set-Variable HiveNodeTypes @{
    'hub'                = [String]::Empty + $AlertMeSchemaUri.AbsoluteUri + '/node.class.hub.json#';
    'thermostat'         = [String]::Empty + $AlertMeSchemaUri.AbsoluteUri + '/node.class.thermostat.json#';
    'smartplug'          = [String]::Empty + $AlertMeSchemaUri.AbsoluteUri + '/node.class.smartplug.json#';
    'thermostatui'       = [String]::Empty + $AlertMeSchemaUri.AbsoluteUri + '/node.class.thermostatui.json#';
    'colourtunablelight' = [String]::Empty + $AlertMeSchemaUri.AbsoluteUri + '/node.class.colour.tunable.light.json#'
} -Option constant

Set-Variable ClientIdentifier 'Hive Web Dashboard' -Option constant
Set-Variable ContentType 'application/vnd.alertme.zoo-6.5+json' -Option constant
$HiveHeaders = @{
    'Content-Type'   = $ContentType;
    'Accept'         = $ContentType;
    'X-Omnia-Client' = $ClientIdentifier;
    'X-Omnia-Access-Token' = [String]::Empty
}

# private functions
function GetNodesDataStructure {
	[CmdletBinding()] [OutputType([System.Collections.Hashtable])] param ()
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
function Disconnect-HiveSession {
	[CmdletBinding()] param ()

	# logoff session
	$sessionId = $HiveHeaders.'X-Omnia-Access-Token'
	if ($sessionId -ne [String]::Empty) {
		$Uri = [uri]([String]::Empty + $HiveUri + '/auth/sessions' + '/' + $sessionId)
		Invoke-RestMethod -Method Delete -Uri $Uri.AbsoluteUri -Headers $HiveHeaders
	}
	# remove existing access token
	$HiveHeaders.'X-Omnia-Access-Token' = [String]::Empty
	Write-Verbose "Removed access token, further calls will fail until new access token is available."
}

function Connect-HiveSession {
	[CmdletBinding()] param (
	[Parameter(Mandatory = $true, Position = 0)]
		[PSCredential] [System.Management.Automation.Credential()] $Credential
	)
	$Uri = [uri]([String]::Empty + $HiveUri + '/auth/sessions')

	# create hive login data-structure
	$session = @{
		'username' = $credential.UserName;
		'password' = $credential.GetNetworkCredential().Password;
		'caller' = 'WEB'
	}

	$sessions = @{
		'sessions' = @($session)
	}

	$body = ConvertTo-Json $sessions
	
	Disconnect-HiveSession
	
	# create new session and get the access token
	$response = Invoke-RestMethod -Method Post -Uri $Uri.AbsoluteUri -Headers $HiveHeaders -Body $body

	# store the first session access token for downstream calls
	$mySession = $response.sessions[0]
	if ($null -eq $mySession -or $mySession -eq [String]::Empty) {
		throw 'No valid session'
	}

	$sessionInfo = @(
		"LatestApiVersion : $($mySession.latestSupportedApiVersion)",
		"SessionId : $($mySession.sessionId)",
		"LoggedInAs : $($mySession.username)"
	)
	$HiveHeaders.'X-Omnia-Access-Token' = $mySession.sessionId
	Write-Output $sessionInfo
}

function Get-HiveSession {
	[CmdletBinding()] param ()
	$thisSessionId = $HiveHeaders.'X-Omnia-Access-Token' 
	$Uri = [uri]([String]::Empty + $HiveUri + '/auth/sessions' + '/' + $thisSessionId)

	$response = Invoke-RestMethod -Method Get -Uri $Uri.AbsoluteUri -Headers $HiveHeaders

	return $response.sessions
}

function Get-HiveNodeByType {
	[CmdletBinding()] param (
	[Parameter(Mandatory=$true, Position = 0)]
		[ValidateSet('hub', 'thermostat', 'smartplug', 'thermostatui', 'colourtunablelight')]
		[string] $NodeType,
	[Parameter(Mandatory = $false, Position = 1)]
		[switch] $Minimal
	)
	# resolve resource type schema identifier
	$nodeResourceId = $HiveNodeTypes[$NodeType.TolowerInvariant()]
	Write-Verbose "NodeType schema: $nodeResourceId"
	
	$response = Get-HiveNode -Minimal:$Minimal
	$filteredNodes = $response |
		Where-Object {
			$_.nodeType -ilike "*$nodeResourceId*"
		}
	
	return $filteredNodes
}

function Get-HiveNode {
	<#
	.SYNOPSIS
		Get nodes that make up the Hive system.
	.DESCRIPTION
		Get all Hive nodes or a specific node. Filters can be applied to minimise data and
		improve overall response times.
	.EXAMPLE
		Get-HiveNode
		Get all nodes
	.EXAMPLE
		Get-HiveNode -Minimal -Filter name
		Get all nodes and restrict the response data to mandatory fields and name.
	.INPUTS
		Does not take pipeline input.
	.OUTPUTS
		Array of Hive Nodes.
	#>
	[CmdletBinding()] param (
	[Parameter(Mandatory=$false, Position = 0)]
		# Hive node identifier
		[guid] $Id = [guid]::Empty,
	[Parameter(Mandatory=$false, Position = 1)]
		[ValidateNotNullOrEmpty()]
		# Apply custom filters that reduce the requested data fields to the requested set
		# and any mandatory fields like id.
		[array] $Filter,
	[Parameter(Mandatory = $false, Position = 2)]
		# Reduce requested data to minimal working set that consists of id and nodeType 
		# that are required for resolving most objects.
		[switch] $Minimal
	)
	$Uri = [uri]([String]::Empty + $HiveUri + '/nodes')
	# optional resource selection
	if ($id -ne [guid]::Empty) {
		$Uri = [uri]($Uri.AbsoluteUri + '/' + $Id)
	}
	# Minimal
	$fields = $null
	if ($Minimal) {
		$fields = @('nodeType')
	} 
	# include any other filters
	if ($PSBoundParameters.ContainsKey('Filter')) {
		$fields = $fields + $Filter | Select-Object -Unique
	}
	# apply filters to resource selection
	if ($null -ne $fields) {
		$Uri = [uri]($Uri.AbsoluteUri + '?fields=' + ($fields -join ','))
	}
	$response = Invoke-RestMethod -Method Get -Uri $Uri.AbsoluteUri -Headers $HiveHeaders
	return $response.nodes
}

# node specific helper functions
function Get-HiveThermostat {
	[CmdletBinding()] param (
	[Parameter(Mandatory = $false, Position = 0)]
		[switch] $Minimal
	)
	return Get-HiveNodeByType -NodeType 'thermostatui' -Minimal:$Minimal
}

function Get-HiveReceiver {
	[CmdletBinding()] param (
	[Parameter(Mandatory = $false, Position = 0)]
		[switch] $Minimal
	)
	$receiers = Get-HiveThermostat | ForEach-Object {
		$_.relationships.zigBeeBindingTable 
	}
	# only recievers that are actually comunicating with the thermostat
	return $receiers | ForEach-Object{
		Get-HiveNode -Id $_.Id
	}
}

function Get-HiveHub {
	[CmdletBinding()] param (
	[Parameter(Mandatory = $false, Position = 0)]
		[switch] $Minimal
	)
	return Get-HiveNodeByType -NodeType 'hub' -Minimal:$Minimal
}

function Get-HivePlug {
	[CmdletBinding()] param (
	[Parameter(Mandatory = $false, Position = 0)]
		[switch] $Minimal
	)
	return Get-HiveNodeByType -NodeType 'smartplug' -Minimal:$Minimal
}

function Get-HiveLight {
	[CmdletBinding()] param (
	[Parameter(Mandatory = $false, Position = 0)]
		[switch] $Minimal
	)
	return Get-HiveNodeByType -NodeType 'colourtunablelight' -Minimal:$Minimal
}

function Set-HiveLight {
	<#
	.SYNOPSIS
		Set properties on a specific Hive light.
	.DESCRIPTION
		Update specified Hive light with new desired state that can include a combination of: 
		Brightness, Hue, PowerState, ColourMode and ColourTemperature 
	.INPUTS
		Accepts pipeline input from Get-HiveLight.
	.OUTPUTS
		WebResponse, TODO: this will change to updated Hive Node which is more restful.
	.EXAMPLE 
		# Simple script that increases the Brightness in increments of 5 until the maximum is reached and then reverses the direction and decreases the Brightness until minimum is reached and loops.

		$light = Get-HiveLight | Select -First 1
		$dir = $true
		$lux=5
		while(1) {
			if ($lux -le 5){ $dir=$true }; if ($lux -ge 100){ $dir=$false }
			if ($dir){ $lux=$lux+5 } else { $lux=$lux-5 }
			Set-HiveLight -Id $light.id -Brightness $lux
			# 300ms updates, be kind to Hive API, should probably avoid lower than this!
			Sleep -m 300
		}
	#>
	[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Low')] param (
	[Parameter(Mandatory = $true, Position = 0,
		ValueFromPipelineByPropertyName = $true)]
		# Hive light node identifier.
		[guid] $Id,
	[Parameter(Mandatory = $false, Position = 1)]
		[ValidateSet('ON', 'OFF')]
		# Desired PowerState for the device.
		[string] $PowerState,
	[Parameter(Mandatory = $false, Position = 2)]
		[ValidateSet('COLOUR', 'TUNABLE')]
		# Desired mode of operation (Only for Hive ColourLight).
		[string] $ColourMode,
	[Parameter(Mandatory = $false, Position = 3)]
		[ValidateRange(0, 355)]
		# Desired Hue (only for Hive ColourLight).
		[uint16] $Hue = 0,
	[Parameter(Mandatory = $false, Position = 4)]
		[ValidateRange(5, 100)]
		# Desired Brightness.
		[uint16] $Brightness = 5,
	[Parameter(Mandatory = $false, Position = 5)]
		[ValidateRange(2700, 6533)]
		# Desired Colour Temperature.
		[uint16] $ColourTemperature = 2700
	)
	$Uri = [uri]([String]::Empty + $HiveUri + '/nodes')
	if ($id -ne [guid]::Empty) {
		$Uri = [uri]($Uri.AbsoluteUri + '/' + $Id)
	}
	
	# hive nodes base data-structure
	$nodes = GetNodesDataStructure

	if ($PSBoundParameters.ContainsKey('PowerState')) {
		if ($pscmdlet.ShouldProcess($PowerState)) {
			$newState = @{'targetValue' = $PowerState.ToUpperInvariant()}
			$nodes.nodes[0].attributes.Add('state', $newState)
		} else {
			Write-Verbose "User aborted confirm action."
			return
		}
	}

	if ($PSBoundParameters.ContainsKey('ColourMode')) {
		$newState = @{'targetValue' = $ColourMode.ToUpperInvariant()}
		$nodes.nodes[0].attributes.Add('colourMode', $newState)

		switch ($ColourMode) {
			'COLOUR' {
				$newState = @{'targetValue' = $Hue}
				$nodes.nodes[0].attributes.Add('hsvHue', $newState)
				Write-Verbose "Setting colour temperature to new value: $Hue"
			};
			'TUNABLE'{
				$newState = @{'targetValue' = $ColourTemperature}
				$nodes.nodes[0].attributes.Add('colourTemperature', $newState)
				Write-Verbose "Setting colour temperature to new value: $ColourTemperature"
			}
		}
	} 

	if ($PSBoundParameters.ContainsKey('Brightness')) {
		$newState = @{'targetValue' = $Brightness}
		$nodes.nodes[0].attributes.Add('brightness', $newState)
		Write-Verbose "Setting brightness to new value: $Brightness"
	}

	$body = ConvertTo-Json $nodes -Depth 6 -Compress
	$body | Out-String | Write-Verbose

	$response = Invoke-WebRequest -UseBasicParsing -Method Put -Uri $Uri.AbsoluteUri -Headers $HiveHeaders -Body $body
	#todo response processing
	return $response
}

function Set-HiveReceiver {
	[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Low')] param (
	[Parameter(Mandatory = $true, Position = 0,
		ValueFromPipelineByPropertyName = $true)]
		[guid] $Id,
	[Parameter(Mandatory = $true, Position = 1)]
		[uint16] $TargetTemperature 
	)
	$Uri = [uri]([String]::Empty + $HiveUri + '/nodes')
	if ($id -ne [guid]::Empty) {
		$Uri = [uri]($Uri.AbsoluteUri + '/' + $Id)
	}
	
	# hive nodes base data-structure
	$nodes = GetNodesDataStructure

	if ($PSBoundParameters.ContainsKey('TargetTemperature')) {
		if ($pscmdlet.ShouldProcess($TargetTemperature)) {
			$newState = @{'targetValue' = $TargetTemperature}
			$nodes.nodes[0].attributes.Add('targetHeatTemperature', $newState)
		} else {
			Write-Verbose "User aborted confirm action."
			return
		}
	}

	$body = ConvertTo-Json $nodes -Depth 6 -Compress
	$body | Out-String | Write-Verbose

	$response = Invoke-WebRequest -UseBasicParsing -Method Put -Uri $Uri.AbsoluteUri -Headers $HiveHeaders -Body $body
	#todo response processing
	return $response
}

function Set-HivePlug {
	[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Low')] param (
	[Parameter(Mandatory = $true, Position = 0,
		ValueFromPipelineByPropertyName = $true)]
		[guid] $Id,
	[Parameter(Mandatory = $true, Position = 1)]
		[ValidateSet('ON', 'OFF')]
		[string] $PowerState
	)
	$Uri = [uri]([String]::Empty + $HiveUri + '/nodes')
	if ($id -ne [guid]::Empty) {
		$Uri = [uri]($Uri.AbsoluteUri + '/' + $Id)
	}
	
	# hive nodes data-structure
	$nodes = GetNodesDataStructure
	
	if ($PSBoundParameters.ContainsKey('PowerState')) {
		if ($pscmdlet.ShouldProcess($PowerState)) {
			$newState = @{'targetValue' = $PowerState.ToUpperInvariant()}
			$nodes.nodes[0].attributes.Add('state', $newState)
		} else {
			Write-Verbose "User aborted confirm action."
			return
		}
	}

	$body = ConvertTo-Json $nodes -Depth 6 -Compress
	$body | Out-String | Write-Verbose

	$response = Invoke-WebRequest -UseBasicParsing -Method Put -Uri $Uri.AbsoluteUri -Headers $HiveHeaders -Body $body
	#todo response processing
	return $response
}

# general platform functions
function Get-HiveEvent {
	<#
	.SYNOPSIS
		Retrieves the latest set of events that have occurred on the Hive Api surface.
	.DESCRIPTION
		Uses the Hive Events Api to get the latest set of events that have occurred in your Hive system.
	.INPUTS
		Does not take input.
	.OUTPUTS
		Events that have occurred in your Hive Home.
	#>
	[CmdletBinding()] param ()
	$Uri = [uri]([String]::Empty + $HiveUri + '/events')
	$response = Invoke-RestMethod -Method Get -Uri $Uri.AbsoluteUri -Headers $HiveHeaders
	return $response.events
}

function Get-HiveTopology {
	<#
	.SYNOPSIS
		Retrieves current representation of your Hive Topology.
	.DESCRIPTION
		Uses the Hive Topology Api to get a logical representation of the zigbee network.
	.INPUTS
		Does not take input.
	.OUTPUTS
		Topological representation of your Hive Home.
	#>
	[CmdletBinding()] param ()
	$Uri = [uri]([String]::Empty + $HiveUri + '/topology')
	
	$response = Invoke-RestMethod -Method Get -Uri $Uri.AbsoluteUri -Headers $HiveHeaders
	return $response.topology
}

function Get-HiveUser {
	<#
	.SYNOPSIS
		Retrieves information about the logged in Hive user.
	.DESCRIPTION
		Uses the login session to retrieve information about the current user.
	.INPUTS
		Does not take input.
	.OUTPUTS
		Current logged in user data.
	#>
	[CmdletBinding()] param ()
	$Uri = [uri]([String]::Empty + $HiveUri + '/users')
	
	$response = Invoke-RestMethod -Method Get -Uri $Uri.AbsoluteUri -Headers $HiveHeaders
	return $response.users
}

function Get-HiveDeviceToken {
	<#
	.SYNOPSIS
		Get information about linked Hive Devices e.g. Android applications. 
	.DESCRIPTION
		When you install a phone or tablet app, Hive stores the linkage in
		Hive Devices Api. This function gets the list of devices that are
		active in your account.
	.INPUTS
		Does not take input.
	.OUTPUTS
		One or more Hive Devices.
	#>
	[CmdletBinding()] param ()
	$Uri = [uri]([String]::Empty + $HiveUri + '/deviceTokens')
	$response = Invoke-RestMethod -Method Get -Uri $Uri.AbsoluteUri -Headers $HiveHeaders
	return $response.deviceTokens
}

function Get-HiveWeather {
	<#
	.SYNOPSIS
		Provides basic temperature reading from the Hive Weather API
	.DESCRIPTION
		Uses a PostCode to retrieve current outside temperature. 
		By default the users postcode is used in the query, this can 
		be overridden using the PostCode parameter.
	.INPUTS
		Does not take pipeline input.
	.OUTPUTS
		Current weather data retrieved from Hive.
	#>
	[CmdletBinding()] param (
	[Parameter(Mandatory=$false, Position = 0)]
		[ValidateNotNullOrEmpty()]
		# PostCode used in Weather query.
		# By default the current user postcode is used.
		[string] $PostCode
	)
	$Uri = [uri]([String]::Empty + $HiveWeatherUri + '/weather')
	
	if ($PSBoundParameters.ContainsKey('PostCode')) {
		$query = '?postcode=' + $PostCode
	} else {
		$user = Get-HiveUser
		$query = '?postcode=' + $user.postcode
		$query += '&country=' + $user.country
	}
	$Uri = [uri]($Uri.AbsoluteUri + $query)
	$response = Invoke-RestMethod -Method Get -Uri $Uri.AbsoluteUri -Headers $HiveHeaders
	return $response.weather
}

# export public functions
Export-ModuleMember -function *-*
