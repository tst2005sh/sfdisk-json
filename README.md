# partition table utility

My goal

```bash
# backup the server partitions
sfdisk --json /dev/sda > /tmp/sda.json

# at restore time (on rescue boot)
cat /tmp/sda.json \
	| my_json_util --size-ratio 0.5 --drop uuid \
	| sfdisk-json-to-text \
	| sfdisk /dev/$another_disk
```

## export to text

```bash
sfdisk -d /dev/sda > /tmp/sda.txt
```

## import from text

```bash
sfdisk /dev/sdNEW < /tmp/sda.txt
```

## export to json

```bash
sfdisk --json /dev/sda > /tmp/sda.json
```

## import from json

It is not supported by sfdisk.

```bash
$ man sfdisk | grep -i json | grep input                          
              sfdisk is not able to use JSON as input format.
```

## convert json to text

With lua script
```bash
sfdisk-json-to-text.lua < /tmp/sda.json > /tmp/sda.txt
```

With shell script (require `jq`)
```bash
sfdisk-json-to-text.sh < /tmp/sda.json > /tmp/sda.txt
```

## Summary

```bash
sfdisk --json /dev/sda > /tmp/sda.json
# modify the /tmp/sda.json
sfdisk-json-to-text.lua < /tmp/sda.json > /tmp/sda.txt
sfdisk /dev/sdNEW < /tmp/sda.txt
```

