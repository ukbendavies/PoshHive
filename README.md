# PoshHive
British Gas HIVE Home powershell wrapper that provides core HIVE platform functionality in a Windows powershell instance
that can be used interactively, scripted for expanded integrations, or scheduling e.g. at 6pm turn on the Lights (use with 
basic windows scheduler for this capability).

Copyright 2017 Ben Davies

MIT License. Full license: https://github.com/ukbendavies/PoshHive/blob/master/LICENSE

## Disclaimer
- I do not work for and am not in any way associated with British Gas or any organisation that creates or maintains HIVE. 
- This work is purely my own experiment after I originally asked for a supported HIVE RestAPI on the British Gas forum.

## Getting Started
Open a PowerShell v3+ command shell (v3 or higher is default on Windows 8.1++ and is required for json support)

### Establish an authenticated session to your HiveHome account
Import the PoshHive module downloaded from GitHub: https://github.com/ukbendavies/PoshHive.

   ```powershell
    # firstly set up a little configuration
    cd <pathtomodule>\Modules\PoshHive

    # now lets get started
    Import-Module .\PoshHive.psm1
    Connect-HiveSession -Credential 'your hive username usually email address'
   ```

  - password process makes use of standard powershell Get-Credential mechanism.
  - passwords are securestring and then wrapped in https transport direct to HIVE API.

### Setting the temperature

   ```powershell
    $receiver = Get-HiveReceiver
    Set-HiveReceiver -Id $receiver.id -TargetTemperature 21
   ```

 Note: if you have more than one you might need to do a little more 
 work ($receiver would be a set in this case) to get the id for the 
 specific receiver that you want to manipulate.

 Alternatively you can use the PowerShell pipeline for any get/set combination:
   
   ```powershell
    Get-HiveReceiver -Minimal | Set-HiveReceiver -TargetTemperature 21
   ```

It is advisable to use the -Minimal switch that minimises the amount 
of data that is sent and received round-trip to the server by using Filters as this 
improves execution speed. As a rule if you are scripting then prefer the -Minimal 
switch that simply gets the Id and Name of the resource. Avoid the pipeline strategy 
if you are performing several update actions on the same resource that don't require 
round-trip state validation.

### Set a Colour Light to on or off

   ```powershell
    $light = Get-HiveLight
    
    # basic ON or OFF functions
    Set-HiveLight -Id $light.id -PowerState OFF
    Set-HiveLight -Id $light.id -PowerState ON
    
    # Changing colour mode
    # TUNABLE = Dimmable in HIVE's terminology
    Set-HiveLight -Id $light.id -ColourMode TUNABLE
    Set-HiveLight -Id $light.id -ColourMode COLOUR
   
    # you can also combine actions
    Set-HiveLight -Id $light.id -PowerState ON -ColourMode COLOUR
   ```

### Set a Smart-Plug to on or off

   ```powershell
    $plug = Get-HivePlug
    
    # basic ON or OFF functions
    Set-HivePlug -Id $plug.id -PowerState OFF
    Set-HivePlug -Id $plug.id -PowerState ON
    
    # Interestingly the smart-plug appears to report energy consumption data
    $plug.attributes.powerConsumption
   ```
   returns the following data where the values of reportedValue do change (units appear to be in watts)
   ```yaml
    reportedValue      : 2.0
    displayValue       : 2.0
    reportReceivedTime : 1490444534755
    reportChangedTime  : 1490444534755
   ```
   - my kettle has a reportedValue of 2904 watts (about right).
   - one of the many hidden features that seem to be present in the hardaware platform but not yet released 
     in the HIVE software (App/WebUI).

## Debugging

##### Using Get-HiveEvent
This is one of the most useful features so far. You can get the events
for all of the Hive actions submitted to the platform. This is useful for example
to get the last 5 events and see what the Hive App/WebUI actually did.

   ```powershell
    Get-HiveEvent | Select -First 5
   ```
   returns something like this:
   
   ```yaml
    id         : xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
    href       : https://api.prod.bgchprod.info:8443/omnia/events/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
    links      :
    eventType  : PLATFORM_SET_PROPERTIES
    source     : xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
    time       : 2017-03-24T21:34:15.613+0000
    properties : @{triggered=; property=targetHeatTemperature; value=20.0}
   ```

##### NOT_AUTHORIZED 
If you get a not authorized exception as below:
```powershell
Invoke-RestMethod : {"errors":[{"code":"NOT_AUTHORIZED"}]}
```
This is either because: 
- supplied credentials are wrong, or quotes have gotten in the way; if
in doubt use single-quotes to ensure what you enter is what's used. 
- alternatively the session may have expired in which case simply re-run the 
  Connect-HiveSession command. In future this may become a default mode 
  of operation.

##### Getting all nodes
If in doubt you can always see all your nodes (devices) by executing:
   ```powershell
    $nodes = Get-HiveNode -Filter name
    $nodes | Select-Object -Property name, id
   ```
choose a node name that makes sense to you based on the names as shown in the 
Hive App/WebUI.

##### General note on nodes
Any Get-* function will return an object containing lots of data and this allows access to hidden features (explore at your own risk!).

Using the receiver as an example (this applies to any Node though):
 ```powershell
 $receiver
 ```
 returns
```yaml
id           : xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
href         : https://api.prod.bgchprod.info:8443/omnia/nodes/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
links        :
name         : Your Receiver
nodeType     : http://alertme.com/schema/json/node.class.thermostat.json#
parentNodeId : xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
lastSeen     : 1490444982388
createdOn    : 1441739428685
userId       : xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
ownerId      : xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
attributes   : @{activeScheduleLock=; holidayModeActive=; supportsTransitionsPerDay=; optimumStartAdvanceTimeFactor=;
               activeOverrides=; activeHeatCoolMode=; holidayModeEnabled=; temperatureSensorMissing=;
               delayCompensationTime=; holidaySetPoint=; protocol=; supportsScheduleLock=; zone=; model=;
               supportsHeatCoolModes=; presence=; errorIntegral=; heatingRateEstimate=; previousConfiguration=;
               holidayMode=; previousWaterMode=; holidayEndDate=; holidayStartTime=; maxHeatTemperature=; nodeType=;
               previousHeatMode=; lastSeen=; optimumStartMinimumTemperatureChange=; deviceClass=;
               supportsScheduleDays=; softwareVersion=; optimumStartAdvanceTimeOffset=; swVersion=;
               initialisationFailure=; manufacturer=; holidayStartDate=; deviceClassName=;
               supportsScheduleLockDuration=; targetHeatTemperature=; hardwareFailure=; minHeatTemperature=;
               temperature=; supportsTransitionsPerWeek=; manufactured=; controlMode=; capabilities=;
               optimumStartEnabled=; LQI=; proportionalThreshold=; hwVersion=; supportsHotWater=; stateHeatingRelay=;
               schedule=; holidayEndTime=; RSSI=; delayCompensatedTemperature=; previousHeatSetpoint=;
               selfCalibrationFailure=; optimumStartMaximumAdvanceTime=; supportsTPI=; scheduleLockDuration=;
               minimumOffCycles=}

 ```


## Complete list of functions

Function | Syntax
--- | ---
[Connect-HiveSession](Help/Connect-HiveSession.md) | `[-Credential] <pscredential> [<CommonParameters>]`
[Disconnect-HiveSession](Help/Disconnect-HiveSession.md) | `[<CommonParameters>]`
[Get-HiveDeviceToken](Help/Get-HiveDeviceToken.md) | `[<CommonParameters>]`
[Get-HiveEvent](Help/Get-HiveEvent.md) | `[<CommonParameters>]`
[Get-HiveHub](Help/Get-HiveHub.md) | `[-Minimal] [<CommonParameters>]`
[Get-HiveLight](Help/Get-HiveLight.md) | `[-Minimal] [<CommonParameters>]`
[Get-HiveNode](Help/Get-HiveNode.md) | `[[-Id] <guid>] [[-Filter] <array>] [-Minimal] [<CommonParameters>]`
[Get-HiveNodeByType](Help/Get-HiveNodeByType.md) | `[-NodeType] <string> [-Minimal] [<CommonParameters>]`
[Get-HivePlug](Help/Get-HivePlug.md) | `[-Minimal] [<CommonParameters>]`
[Get-HiveReceiver](Help/Get-HiveReceiver.md) | `[-Minimal] [<CommonParameters>]`
[Get-HiveSession](Help/Get-HiveSession.md) | `[<CommonParameters>]`
[Get-HiveThermostat](Help/Get-HiveThermostat.md) | `[-Minimal] [<CommonParameters>]`
[Get-HiveTopology](Help/Get-HiveTopology.md) | `[<CommonParameters>]`
[Get-HiveUser](Help/Get-HiveUser.md) | `[<CommonParameters>]`
[Get-HiveWeather](Help/Get-HiveWeather.md) | `[[-PostCode] <string>] [<CommonParameters>]`
[Set-HiveLight](Help/Set-HiveLight.md) | `[-Id] <guid> [[-PowerState] <string>] [[-ColourMode] <string>] [[-Hue] <uint16>] [[-Brightness] <uint16>] [[-ColourTemperature] <uint16>] [-WhatIf] [-Confirm] [<CommonParameters>]`
[Set-HivePlug](Help/Set-HivePlug.md) | `[-Id] <guid> [-PowerState] <string> [-WhatIf] [-Confirm] [<CommonParameters>]`
[Set-HiveReceiver](Help/Set-HiveReceiver.md) | `[-Id] <guid> [-TargetTemperature] <uint16> [-WhatIf] [-Confirm] [<CommonParameters>]`

## Coming soon
- Further abstraction, this was my very first attempt so its not as abstracted as I'd like
- [in-progress] Enhancement to ColourLight to set various colour parameters and brightness.
- Additional controls over the receiver.
- [in-progress] Documentation on the public functions
  - [complete] doc generators.
- Tests
  - [complete] static code analysis 
  - [not started] pester tests
- Various other enhancements.
- Bug fixes.

## Acknowledgements
- HIVE Rest Api v6 documentation published by alertme
  https://api.prod.bgchprod.info:8443/api/docs
- HIVE REST API V6.1, great investigation by James Saunders
  http://www.smartofthehome.com/2016/05/hive-rest-api-v6/
