SennyinQoL = SennyinQoL or {}

------------------------------------------------------------
-- Defaults merging
------------------------------------------------------------

function SennyinQoL.CopyDefaults(src, dest)
	if not src then
		return dest
	end

	dest = dest or {}

	for k, v in pairs(src) do
		if type(v) == "table" then
			dest[k] = SennyinQoL.CopyDefaults(v, dest[k])
		elseif dest[k] == nil then
			dest[k] = v
		end
	end

	return dest
end

------------------------------------------------------------
-- Per-module saved variable accessors
------------------------------------------------------------

function SennyinQoL:GetSetting(moduleName, key, fallback)
	local db = SennyinDB and SennyinDB[moduleName]

	if db and db[key] ~= nil then
		return db[key]
	end

	return fallback
end

function SennyinQoL:SetSetting(moduleName, key, value)
	SennyinDB = SennyinDB or {}
	SennyinDB[moduleName] = SennyinDB[moduleName] or {}
	SennyinDB[moduleName][key] = value
end
