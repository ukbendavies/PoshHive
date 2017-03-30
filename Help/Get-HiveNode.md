# Get-HiveNode

## SYNOPSIS
Get nodes that make up the Hive system.

## SYNTAX

```
Get-HiveNode [[-Id] <Guid>] [[-Filter] <Array>] [-Minimal]
```

## DESCRIPTION
Get all Hive nodes or a specific node.
Filters can be applied to minimise data and
improve overall response times.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
Get-HiveNode
```

Get all nodes

### -------------------------- EXAMPLE 2 --------------------------
```
Get-HiveNode -Minimal -Filter name
```

Get all nodes and restrict the response data to mandatory fields and name.

## PARAMETERS

### -Filter
Apply custom filters that reduce the requested data fields to the requested set
and any mandatory fields like id.

```yaml
Type: Array
Parameter Sets: (All)
Aliases: 

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Id
Hive node identifier

```yaml
Type: Guid
Parameter Sets: (All)
Aliases: 

Required: False
Position: 1
Default value: [guid]::Empty
Accept pipeline input: False
Accept wildcard characters: False
```

### -Minimal
Reduce requested data to minimal working set that consists of id and nodeType 
that are required for resolving most objects.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: 

Required: False
Position: 3
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

## INPUTS

### Does not take pipeline input.

## OUTPUTS

### Hashtable of Hive Nodes.

## NOTES

## RELATED LINKS

