local M = SennyinQoL:NewModule("UnitColors")

local UnitMap = {
	player = {
		label = "Class Colored Player Frame",
		bar = function()
			return PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.HealthBarsContainer.HealthBar
		end,
	},
	target = {
		label = "Class Colored Target Frame",
		bar = function()
			return TargetFrame.TargetFrameContent.TargetFrameContentMain.HealthBarsContainer.HealthBar
		end,
	},
	focus = {
		label = "Class Colored Focus Frame",
		bar = function()
			return FocusFrame.TargetFrameContent.TargetFrameContentMain.HealthBarsContainer.HealthBar
		end,
	},
	targettarget = {
		label = "Class Colored Target-of-Target",
		bar = function()
			return TargetFrameToT.HealthBar
		end,
	},
}

M.defaults = {
	player = true,
	target = true,
	focus = true,
	targettarget = true,
}

local function GetUnitColor(unit)
	if not UnitExists(unit) then
		return CreateColor(0.5, 0.5, 0.5)
	end

	local color

	if UnitIsPlayer(unit) then
		color = SennyinQoL:GetPlayerColor(unit)
	else
		color = SennyinQoL:GetReactionColor(unit)
	end

	return color or CreateColor(0.5, 0.5, 0.5)
end

local function GetColorRGB(color)
	if not color then
		return 1, 1, 1
	end

	if type(color.GetRGB) == "function" then
		return color:GetRGB()
	end

	return color.r or color[1] or 1, color.g or color[2] or 1, color.b or color[3] or 1
end

local function ApplyColor(unit)
	local data = UnitMap[unit]
	local statusBar = data.bar()

	if not statusBar then
		return
	end

	local texture = statusBar:GetStatusBarTexture()

	if not texture then
		return
	end

	if M:Get(unit, true) then
		local color = GetUnitColor(unit)
		local r, g, b = GetColorRGB(color)
		statusBar:SetStatusBarDesaturated(true)
		texture:SetGradient("HORIZONTAL", CreateColor(r, g, b), CreateColor(r, g, b))
	else
		statusBar:SetStatusBarDesaturated(false)
		texture:SetGradient("HORIZONTAL", CreateColor(1, 1, 1), CreateColor(1, 1, 1))

		if statusBar.UpdateColor then
			statusBar:UpdateColor()
		end
	end
end

M.settings = {
	name = "Unit Frames",
	heading = "Class Colour Health Bars",
	settings = {},
}

for unit, data in pairs(UnitMap) do
	M.settings.settings[unit] = {
		label = data.label,
		default = true,
		callback = function(value)
			M:Set(unit, value)
			ApplyColor(unit)
		end,
	}
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("PLAYER_TARGET_CHANGED")
frame:RegisterEvent("PLAYER_FOCUS_CHANGED")
frame:RegisterEvent("UNIT_TARGET")
frame:RegisterEvent("UNIT_FACTION")

frame:SetScript("OnEvent", function(_, _, unit)
	if unit and UnitMap[unit] then
		ApplyColor(unit)
	else
		for u in pairs(UnitMap) do
			ApplyColor(u)
		end
	end
end)
