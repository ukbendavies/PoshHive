# PoshHive
British Gas HIVE Home powershell wrapper that provides core HIVE platform functionality in a Windows powershell instance
that can be used interactively, scripted for expanded integrations, or scheduling e.g. at 6pm turn on the Lights (use with 
basic windows scheduler for this capability).

Copyright 2017 Ben Davies

MIT License. Full license: https://github.com/ukbendavies/PoshHive/blob/master/LICENSE

## Disclaimer
- I do not work with, for and am not in any way associated with British Gas or any organisation that creates or maintains HIVE. 
- This work is purely my own experiment after I originally asked for a supported HIVE RestAPI on the British Gas requests forum.

## Getting Started
Open a PowerShell v3 command shell (v3 should be default on Windows 8.1++)
 
### Establish an authenticated session to your HiveHome account
Import the PoshHive module downloaded from GitHub: https://github.com/ukbendavies/PoshHive.

   ```powershell
    # firstly set up a little configuration
    $username='your hive username usually email address'
    $password='your hive password'
    cd <pathtomodule>\Modules\PoshHive

    # now lets get started
    Import-Module .\PoshHive.psm1
    Connect-HiveSession -Username $username -Password $password
   ```

### Setting the temperature

   ```powershell
    $receiver = Get-HiveReceiver
    Set-HiveReceiver -Id $receiver.id -TargetTemperature 21
   ```

 Note: if you have more than one you might need to do a little more 
 work ($receiver would be a set in this case) to get the id for the 
 specific receiver that you want to manipulate.

 Note that any Get-* will return an object containing lots of data and this allows access to hidden features.
 
 ```powershell
 $receiver
 ```
 returns
```
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


### Set a Colour Light to on or off

   ```powershell
    $plug = Get-HivePlug
    
    # basic ON or OFF functions
    Set-HivePlug -Id $Plug.id -PowerState OFF
    Set-HivePlug -Id $Plug.id -PowerState ON
    
    # Interestingly the amartplug appears to report energy consumption data
    $plug.attributes.powerConsumption
   ```
   returns the following data where the values of reportedValue do change (unit appears to be in watts)
   ```
  reportedValue                  displayValue            reportReceivedTime             reportChangedTime
  -------------                  ------------            ------------------             -----------------
        2.0                           2.0                 1490444534755                 1490444534755
   ```


## Debugging

##### Using Get-HiveEvents
This is one of the most useful features so far. You can get the events
for all of the Hive actions submitted to the platform. This is useful for example
to get the last 5 events and see what the Hive App/WebUI actually did.

   ```powershell
    Get-HiveEvents | Select -First 5
   ```
   returns something like this:
   
   ```
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


## More complete list of functions

CommandType | Name
--- | --- 
   Function | Connect-HiveSession
   Function | Disconnect-HiveSession
   Function | Get-HiveEvents
   Function | Get-HiveLight
   Function | Get-HivePlug
   Function | Get-HiveNode
   Function | Get-HiveNodeByType
   Function | Get-HiveReceiver
   Function | Get-HiveThermostat
   Function | Get-HiveTopology
   Function | Get-HiveUser
   Function | Get-HiveHub
   Function | Set-HiveLight
   Function | Set-HiveReceiver
   Function | Set-HivePlug

## Coming soon
- Further abstraction, this was my very first attempt so its not as abstracted as I'd like
- Enhancement to ColourLight to set various colour parameters and brightness.
- Additional controls over the receiver.
- Various other enhancements.
- Documentation on the public functions.
- Tests
- Bug fixes.

## Acknowledgements
- HIVE Rest Api v6 documentation published by alertme
  http://www.smartofthehome.com/wp-content/uploads/2016/03/AlertMe-API-v6.1-Documentation.pdf
- HIVE REST API V6.1, great investigation by James Saunders
  http://www.smartofthehome.com/2016/05/hive-rest-api-v6/
