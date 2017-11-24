#!/usr/bin/lua

local json = require "json"

local headers_fields = {
	"label",
	{"id", "label-id"},
	"device",
	"unit",
	{"firstlba", "first-lba"},
	{"lastlba", "last-lba"},
}

local partitions_fields = {
	"start", "size", "type", "uuid", "name", "attrs", "bootable",
}

local function print_headers(d)
	local kfixed
	for _,k in ipairs(headers_fields) do
		if type(k) == "table" then
			kfixed=k[2]
			k=k[1]
		else
			kfixed=k
		end
		if d[k] then
			print(kfixed..": "..d[k])
		end
	end
end

local function part_formatvalue(v, k)
	if k=="type" or k=="uuid" then -- UUID or number
		return v
	elseif k=="start" or k=="size" then
		return ("%12s"):format(v)
	elseif (k=="name" or k=="attrs") then
		return ('"%s"'):format(v)
	else
		error("field "..k.." is not implemented, fix the code")
	end
end
local function print_partitions(parts)
	for _,part in ipairs(parts) do
		local line=("%s : "):format(part.node)
		local tmp={}
		for _2, k in ipairs(partitions_fields) do
			local v=part[k]
			if v then
				if k=="bootable" and tostring(v)=="true" then
					table.insert(tmp, "bootable")
				else
					table.insert(tmp, ("%s=%s"):format(k, part_formatvalue(tostring(v),k)) )
				end
			end
		end
		print( line..table.concat(tmp, ", ") )
	end
end

local fd = io.stdin
if #{...}==0 or (...)=="-" then
	fd = io.stdin
else
	fd = io.open( (...), "r")
end
local d = fd:read("*a")
d = json.decode(d)

print_headers(d.partitiontable)
print("")
print_partitions(d.partitiontable.partitions)
