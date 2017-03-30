<#
British Gas HIVE Home PowerShell wrapper that exposes core HIVE platform functionality.
Copyright 2017 Ben Davies

MIT License. Full license: https://github.com/ukbendavies/PoshHive/blob/master/LICENSE

Disclaimer
- I do not work with, for and am not in any way associated with British Gas or any organisation that creates or maintains HIVE. 
- This work is purely my own experiment after I originally asked for a supported HIVE RestAPI on the British Gas requests forum.

Acknowledgements
- HIVE Rest Api v6 documentation published by alertme
  http://www.smartofthehome.com/wp-content/uploads/2016/03/AlertMe-API-v6.1-Documentation.pdf
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
    'hub'                = '' + $AlertMeSchemaUri.AbsoluteUri + '/node.class.hub.json#';
    'thermostat'         = '' + $AlertMeSchemaUri.AbsoluteUri + '/node.class.thermostat.json#';
    'smartplug'          = '' + $AlertMeSchemaUri.AbsoluteUri + '/node.class.smartplug.json#';
    'thermostatui'       = '' + $AlertMeSchemaUri.AbsoluteUri + '/node.class.thermostatui.json#';
    'colourtunablelight' = '' + $AlertMeSchemaUri.AbsoluteUri + '/node.class.colour.tunable.light.json#'
} -Option constant

Set-Variable ClientIdentifier 'Hive Web Dashboard' -Option constant
Set-Variable ContentType 'application/vnd.alertme.zoo-6.1+json' -Option constant
$HiveHeaders = @{
    'Content-Type'   = $ContentType;
    'Accept'         = $ContentType;
    'X-Omnia-Client' = $ClientIdentifier;
    'X-Omnia-Access-Token' = ''
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
	# todo - workout if there is an actual logoff process
	# remove existing access token
	$HiveHeaders.'X-Omnia-Access-Token' = ''
	Write-Verbose "Removed access token, further calls will fail until new access token is available."
}

function Connect-HiveSession {
	[CmdletBinding()] param (
	[Parameter(Mandatory = $true, Position = 0)]
		[PSCredential] [System.Management.Automation.Credential()] $Credential
	)
	$Uri = [uri]('' + $HiveUri + '/auth/sessions')

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
	if ($null -eq $mySession -or $mySession -eq '') {
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
		Hashtable of Hive Nodes.
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
	$Uri = [uri]('' + $HiveUri + '/nodes')
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
	[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Low')] param (
	[Parameter(Mandatory = $true, Position = 0,
		ValueFromPipelineByPropertyName = $true)]
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
	
	# hive nodes base data-structure
	$nodes = GetNodesDataStructure

	if ($PSBoundParameters.ContainsKey('PowerState')) {
		if ($pscmdlet.ShouldProcess($PowerState)) {
			$newState = @{'targetValue' = $PowerState.ToUpperInvariant()}
			$nodes.nodes[0].attributes.Add('state', $newState)
		} else {
			Write-Verbose "User abprted confirm action."
			return
		}
	}

	if ($PSBoundParameters.ContainsKey('ColourMode')) {
		$newState = @{'targetValue' = $ColourMode.ToUpperInvariant()}
		$nodes.nodes[0].attributes.Add('colourMode', $newState)

		switch ($ColourMode) {
			'COLOUR' {
				$newState = @{'targetValue' = 0}
				$nodes.nodes[0].attributes.Add('hsvHue', $newState)
				Write-Verbose "Add hsvHue value 0 as setting colour mode alone doesn't work"
			};
			'TUNABLE'{
				$newState = @{'targetValue' = 2700}
				$nodes.nodes[0].attributes.Add('colourTemperature', $newState)
				Write-Verbose "Add colourTemperature value 2700 as setting colour mode alone doesn't work"
			}
		}
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
	$Uri = [uri]('' + $HiveUri + '/nodes')
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
			Write-Verbose "User abprted confirm action."
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
	$Uri = [uri]('' + $HiveUri + '/nodes')
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
			Write-Verbose "User abprted confirm action."
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
	.OUTPUTS
		Events that have occurred in your Hive Home.
	#>
	[CmdletBinding()] param ()
	$Uri = [uri]('' + $HiveUri + '/events')
	$response = Invoke-RestMethod -Method Get -Uri $Uri.AbsoluteUri -Headers $HiveHeaders
	return $response.events
}

function Get-HiveTopology {
	<#
	.SYNOPSIS
		Retrieves current representation of your Hive Topology.
	.DESCRIPTION
		Uses the Hive Topology Api to get a logical representation of the zigbee network.
	.OUTPUTS
		Topological representation of your Hive Home.
	#>
	[CmdletBinding()] param ()
	$Uri = [uri]('' + $HiveUri + '/topology')
	
	$response = Invoke-RestMethod -Method Get -Uri $Uri.AbsoluteUri -Headers $HiveHeaders
	return $response.topology
}

function Get-HiveUser {
	<#
	.SYNOPSIS
		Retrieves information about the logged in Hive user.
	.DESCRIPTION
		Uses the login session to retrieve information about the current user.
	.OUTPUTS
		Current logged in user data.
	#>
	[CmdletBinding()] param ()
	$Uri = [uri]('' + $HiveUri + '/users')
	
	$response = Invoke-RestMethod -Method Get -Uri $Uri.AbsoluteUri -Headers $HiveHeaders
	return $response.users
}

function Get-HiveWeather {
	<#
	.SYNOPSIS
		Provides basic temperature reading from the Hive Weather API
	.DESCRIPTION
		Uses a PostCode to retrieve current outside temperature. 
		By default the users postcode is used in the query, this can 
		be overridden using the PostCode parameter.
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
	$Uri = [uri]('' + $HiveWeatherUri + '/weather')
	
	if ($PSBoundParameters.ContainsKey('PostCode')) {
		$query = '?postcode=' + $PostCode
	} else {
		$user = Get-HiveUser
		$query = '?postcode=' + $user.postcode
	}
	$Uri = [uri]($Uri.AbsoluteUri + $query)
	$response = Invoke-RestMethod -Method Get -Uri $Uri.AbsoluteUri -Headers $HiveHeaders
	return $response.weather
}

# export public functions
Export-ModuleMember -function *-*
