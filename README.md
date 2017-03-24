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

Then run the following to import the module you downloaded from GitHub.
 
### Next let's establish an authenticated session to your HiveHome account
    
   ```powershell
    Import-Module <pathtomodule>\PoshHive.psm1
    $username='your hive username usually email address'
    $password='your hive password'
    Connect-HiveSession -Username $username -Password $password
   ```

### Setting the temperature

   ```powershell
    $receiver = Get-HiveReceiver
    Set-HiveReceiver -Id $receiver.id -TargetTemperature 21
   ```
    Note: if you have more than one you might need to do a little more 
    work to get the id for the specific device (receiver in this case) 
    that you want to manipulate. For example: 

   ```powershell
    $nodes = Get-HiveNode -Filter name
    $nodes | Select-Object -Property name,id
   ```
    choose a device name that makes sense to you based on the names as 
    shown in the Hive App/WebUI.


### Set a Colour Light to on or off

   ```powershell
    $light = Get-HiveLight
    
    # basic ON or OFF functions
    Set-HiveLight -Id $light.id -PowerState ON
    Set-HiveLight -Id $light.id -PowerState OFF
    
    # Changing colour mode
    # TUNABLE = Dimmable in HIVE's terminology
    Set-HiveLight -Id $light.id -ColourMode TUNABLE
    Set-HiveLight -Id $light.id -ColourMode COLOUR
    # you can also combine actions
    Set-HiveLight -Id $light.id -PowerState ON -ColourMode COLOUR
   ```

## Debugging

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

## More complete list of functions

CommandType | Name
--- | --- 
   Function |  Connect-HiveSession
   Function |  Disconnect-HiveSession
   Function |  Get-HiveEvents
   Function |  Get-HiveHub
   Function |  Get-HiveLight
   Function |  Get-HiveNode
   Function |  Get-HiveReceiver
   Function |  Get-HiveThermostat
   Function |  Get-HiveTopology
   Function |  Get-HiveUser
   Function |  Set-HiveLight
   Function |  Set-HiveReceiver

## Coming soon
- Further abstraction, this was my very first attempt so its not as abstracted as I'd like
- Fix device indexing. Because of the first point the Get-* functions lookup is done based 
  on a lookup of friendly device names (HIVE defaults). If yours don't match because you've
  renamed a device for example, then you have to resort to the Get-HiveNode method to resolve
  your device id's and pass those to the setters.
- Bug fixes.


## Acknowledgements
- HIVE Rest Api v6 documentation published by alertme
  http://www.smartofthehome.com/wp-content/uploads/2016/03/AlertMe-API-v6.1-Documentation.pdf
- HIVE REST API V6.1, great investigation by James Saunders
  http://www.smartofthehome.com/2016/05/hive-rest-api-v6/
