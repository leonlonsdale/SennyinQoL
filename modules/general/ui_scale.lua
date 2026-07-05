local M = SennyinQoL:NewModule("General")

M.defaults = {
	autoScale = true,
}

local function GetScale()
	local _, height = GetPhysicalScreenSize()
	return 768 / height
end

local function ApplyScale(enabled)
	if enabled then
		UIParent:SetScale(GetScale())
	else
		UIParent:SetScale(0.65)
	end
end

M.settings = {
	name = "General",
	heading = "General Settings",
	settings = {
		autoScale = {
			label = "Auto UI Scale",
			default = true,
			callback = ApplyScale,
		},
	},
}

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function()
	ApplyScale(M:Get("autoScale", true))
end)
