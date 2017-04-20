# Get-HiveAlert

## SYNOPSIS
Get information about Hive alerts triggered within the last day e.g.
device not responding.

## SYNTAX

```
Get-HiveAlert
```

## DESCRIPTION
This function gets any alert events and resolves these to the faulting device.

There may be several alerts for a particular node, for example when the alert started and
another for when the alert finished.
This state can be resolved from the alertFacts.

## EXAMPLES

### Example 1
```
PS C:\> {{ Add example code here }}
```

{{ Add example description here }}

## PARAMETERS

## INPUTS

### Does not take input.

## OUTPUTS

### One or more alerts that contain alert information about the failing Hive device, when 
the device was last seen by Hive and the resolved device node in its current state.

## NOTES

## RELATED LINKS

[Get-HiveEvent]()

