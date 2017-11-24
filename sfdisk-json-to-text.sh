#!/bin/sh

headers_fields='label id device unit firstlba lastlba'
partitions_fields='start size type uuid name attrs bootable'

json_action() {
	jq < "$file" "$@";
}

sfdisk_fix() {
	case "$1" in
		(id)		echo "label-id";;
		(firstlba)	echo "first-lba";;
		(lastlba)	echo "last-lba";;
		(*)		echo "$1";;
	esac
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
	case "$1" in
		(????????-????-????-????-????????????)
			# UUID
			echo "$1"
		;;
		(*[^0-9]*)
			# text
			printf '"%s"' "$1"
		;;
		(*)	# a number
			case "$2" in
				(start|size) printf '%12s' "$1" ;;
				(*) echo "$1";;
			esac
		;;
	esac
}

#getkeys() { jq -r 'keys|@sh'; }
#for k in $(json_action '.partitiontable|del(.partitions)' | getkeys); do
print_headers() {
	for k in $headers_fields; do
		jq_fix_k
		kfixed="$(sfdisk_fix "$k")"
		v="$(json_action -r '.partitiontable|del(.partitions)|.'"$k"'|select(.!=null)')"
		[ -z "$v" ] || echo "$kfixed: $v"
	done
}

partition_n() {
	local n="$1";shift;
	local filter='.partitiontable.partitions| .['"$n"']'

	local k=node
	printf '%s : ' "$(json_action -r "$filter | $(printf '.["%s"]' "$k")")"

	local first=true
	#for k in start size type uuid name attrs bootable; do
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
	len=$(json_action '.partitiontable.partitions|length')
	if [ ${len:-0} -gt 0 ]; then 
		for n in $(seq 0 $(( $len -1 )) ); do
			partition_n $n
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

print_headers
echo ""
print_partitions


