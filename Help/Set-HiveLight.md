# Set-HiveLight

## SYNOPSIS
Set properties on a specific Hive light.

## SYNTAX

```
Set-HiveLight [-Id] <Guid> [[-PowerState] <String>] [[-ColourMode] <String>] [[-Hue] <UInt16>]
 [[-Brightness] <UInt16>] [[-ColourTemperature] <UInt16>] [-WhatIf] [-Confirm]
```

## DESCRIPTION
Update specified Hive light with new desired state that can include a combination of: 
Brightness, Hue, PowerState, ColourMode and ColourTemperature

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
# Simple script that increases the Brightness in increments of 5 until the maximum is reached and then reverses the direction and decreases the Brightness until minimum is reached and loops.
```

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

## PARAMETERS

### -Brightness
Desired Brightness.

```yaml
Type: UInt16
Parameter Sets: (All)
Aliases: 

Required: False
Position: 5
Default value: 5
Accept pipeline input: False
Accept wildcard characters: False
```

### -ColourMode
Desired mode of operation (Only for Hive ColourLight).

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: False
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ColourTemperature
Desired Colour Temperature.

```yaml
Type: UInt16
Parameter Sets: (All)
Aliases: 

Required: False
Position: 6
Default value: 2700
Accept pipeline input: False
Accept wildcard characters: False
```

### -Hue
Desired Hue (only for Hive ColourLight).

```yaml
Type: UInt16
Parameter Sets: (All)
Aliases: 

Required: False
Position: 4
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -Id
Hive light node identifier.

```yaml
Type: Guid
Parameter Sets: (All)
Aliases: 

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -PowerState
Desired PowerState for the device.

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Confirm
Prompts you for confirmation before running the cmdlet.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: cf

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -WhatIf
Shows what would happen if the cmdlet runs.
The cmdlet is not run.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: wi

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

## INPUTS

### Accepts pipeline input from Get-HiveLight.

## OUTPUTS

### WebResponse, TODO: this will change to updated Hive Node which is more restful.

## NOTES

## RELATED LINKS

