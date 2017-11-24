#!/bin/sh

headers_fields='label id device unit firstlba lastlba'
partitions_fields='start size type uuid name attrs bootable'

# because sfdisk does not export in json with the exact txt required key!
sfdisk_fix() {
	case "$1" in
		(id)		echo "label-id";;
		(firstlba)	echo "first-lba";;
		(lastlba)	echo "last-lba";;
		(*)		echo "$1";;
	esac
}

json_action() {
	jq < "$file" "$@";
}

# jq export value for sh with single quote
# 'value' => value
jq_fix_k() {
	case "$k" in
		("'"*"'") k="${k#'}"; k="${k%'}";;
	esac
}

# part_fix_v $v $k
part_fix_v() {
	case "$2" in
		(start|size)	printf '%12s' "$1"	;;
		(type|uuid)	printf '%s' "$1"	;;
		(name|attrs)	printf '"%s"' "$1"	;;
		(*)	echo >&2 "field "..$2.." is not implemented, fix the code"
			exit 1
		;;
	esac
}

#getkeys() { jq -r 'keys|@sh'; }
#for k in $(json_action '.partitiontable|del(.partitions)' | getkeys); do
print_headers() {
	local filter="${1:-.}";shift;
	for k in $headers_fields; do
		jq_fix_k
		local kfixed="$(sfdisk_fix "$k")"
		local v="$(json_action -r "$filter"'|.'"$k"'|select(.!=null)')"
		[ -z "$v" ] || echo "$kfixed: $v"
	done
}

partition_n() {
	local n="$1";shift;
	local filter="${1:-.}"'|.['"$n"']'

	local k=node
	printf '%s : ' "$(json_action -r "$filter | $(printf '.["%s"]' "$k")")"

	local first=true
	for k in $partitions_fields; do
		jq_fix_k
		[ "$k" != "node" ] || continue
		v="$(json_action -r "$filter | $(printf '.["%s"]|select(.!=null)' "$k")")"
		if [ "$k" = "bootable" ] && [ "$v" != "true" ]; then
			continue
		fi
		if [ -n "$v" ]; then
			if ${first:-false}; then
				first=false
			else
				printf ', '
			fi
			if [ "$k" = "bootable" ]; then
				printf '%s' "bootable"
			else
				v="$(part_fix_v "$v" "$k")"
				printf '%s=%s' "${k}" "$(printf '%s' "$v")"
			fi
		fi
	done
	printf '\n'
}
print_partitions() {
	local filter="${1:-.}";shift;
	len=$(json_action "$filter"'|length')
	if [ ${len:-0} -gt 0 ]; then 
		for n in $(seq 0 $(( $len -1 )) ); do
			partition_n $n "$filter"
		done
	fi
}

if [ $# -eq 0 ] || [ "$1" = "-" ]; then
	file=$(mktemp) || exit 1
	trap -- "rm -f -- '$file'" EXIT
	cat > "$file"
else
	file="$1";shift;
	[ -f "$file" ] || exit 1
fi

print_headers '.partitiontable'
echo ""
print_partitions '.partitiontable.partitions'


