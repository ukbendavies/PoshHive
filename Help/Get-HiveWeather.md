---
external help file: PoshHive-help.xml
online version: 
schema: 2.0.0
---

# Get-HiveWeather

## SYNOPSIS
Provides basic temperature reading from the Hive Weather API

## SYNTAX

```
Get-HiveWeather [[-PostCode] <String>]
```

## DESCRIPTION
Uses a PostCode to retrieve current outside temperature. 
By default the users postcode is used in the query, this can 
be overridden using the PostCode parameter.

## EXAMPLES

### Example 1
```
PS C:\> {{ Add example code here }}
```

{{ Add example description here }}

## PARAMETERS

### -PostCode
PostCode used in Weather query.
By default the current user postcode is used.

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

## INPUTS

## OUTPUTS

### Current weather data retrieved from Hive.

## NOTES

## RELATED LINKS

