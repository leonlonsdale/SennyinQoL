SennyinQoL = SennyinQoL or {}
SennyinQoL.Modules = SennyinQoL.Modules or {}

------------------------------------------------------------
-- Module registry
------------------------------------------------------------

function SennyinQoL:NewModule(name)
	local module = SennyinQoL.Modules[name] or {}
	module.name = name

	function module:Get(key, fallback)
		return SennyinQoL:GetSetting(name, key, fallback)
	end

	function module:Set(key, value)
		SennyinQoL:SetSetting(name, key, value)
	end

	SennyinQoL.Modules[name] = module

	return module
end

------------------------------------------------------------
-- Saved variable defaults
------------------------------------------------------------

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, _, addonName)
	if addonName ~= "SennyinQoL" then
		return
	end

	SennyinDB = SennyinDB or {}

	for moduleName, module in pairs(SennyinQoL.Modules) do
		if module.defaults then
			SennyinDB[moduleName] = SennyinQoL.CopyDefaults(module.defaults, SennyinDB[moduleName])
		end
	end

	print("|cffffff00SennyinQoL|r Loaded")

	self:UnregisterEvent("ADDON_LOADED")
end)
