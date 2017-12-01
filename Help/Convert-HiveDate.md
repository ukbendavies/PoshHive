# Convert-HiveDate

## SYNOPSIS
Provides basic date time conversion for Hive timestamps.

## SYNTAX

```
Convert-HiveDate [-Miliseconds] <UInt64>
```

## DESCRIPTION
Hive uses timestamps in milliseconds past the epoc.
This helper function converts these times to date time UTC format.

## EXAMPLES

### Example 1
```
PS C:\> {{ Add example code here }}
```

{{ Add example description here }}

## PARAMETERS

### -Miliseconds
Hive date in milliseconds since the Epoch

```yaml
Type: UInt64
Parameter Sets: (All)
Aliases: 

Required: True
Position: 1
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

## INPUTS

### Does not take pipeline input.

## OUTPUTS

### DateTime UTC.

## NOTES

## RELATED LINKS

