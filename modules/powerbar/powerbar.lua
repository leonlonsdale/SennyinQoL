------------------------------------------------------------
-- MAIN POWER BAR
------------------------------------------------------------

local M = SennyinQoL:NewModule("PowerBar")

M.defaults = {
	enabled = true,
	height = 10,
}

local bar = CreateFrame("StatusBar", "SennyinPowerBar", UIParent)

bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
bar:SetSize(200, 10)
bar:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 150)

bar.bg = bar:CreateTexture(nil, "BACKGROUND")
bar.bg:SetAllPoints()
bar.bg:SetColorTexture(0, 0, 0, 0.5)

bar.text = bar:CreateFontString(nil, "OVERLAY")
bar.text:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
bar.text:SetPoint("CENTER")

SennyinQoL:AddBorder(bar)

------------------------------------------------------------
-- SECONDARY POWER BAR
------------------------------------------------------------

local S = SennyinQoL:NewModule("SecondaryPower")

S.defaults = {
	enabled = true,
	height = 10,
}

local SecondaryPowerColours = {
	PALADIN = { 1.00, 0.85, 0.00, 1 },
	WARLOCK = { 0.58, 0.00, 1.00, 1 },
	MONK = { 0.00, 1.00, 0.59, 1 },
	PRIEST = { 0.40, 0.00, 1.00, 1 },
	EVOKER = { 0.00, 0.80, 1.00, 1 },
	DRUID = { 1.00, 0.49, 0.00, 1 },
}

local SecondaryPowerType = {
	PALADIN = Enum.PowerType.HolyPower,
	WARLOCK = Enum.PowerType.SoulShards,
	MONK = Enum.PowerType.Chi,
	PRIEST = Enum.PowerType.Insanity,
	EVOKER = Enum.PowerType.Essence,
	DRUID = Enum.PowerType.ComboPoints,
}

local secContainer = CreateFrame("Frame", "SennyinSecondaryContainer", UIParent)
local segments = {}

------------------------------------------------------------
-- POSITIONING
------------------------------------------------------------

local function AnchorBars()
	SennyinQoL:AnchorToFirstVisible(bar, { "EssentialCooldownViewer" }, 5)

	secContainer:ClearAllPoints()
	secContainer:SetPoint("BOTTOM", bar, "TOP", 0, 5)
	secContainer:SetSize(bar:GetWidth(), S:Get("height", 10))
end

------------------------------------------------------------
-- UPDATE POWER BARS
------------------------------------------------------------

local function UpdatePowerBars()
	bar:SetShown(M:Get("enabled", true))

	local current = UnitPower("player")
	local max = UnitPowerMax("player")

	bar:SetMinMaxValues(0, max)
	bar:SetValue(current)
	bar.text:SetText(current .. " / " .. max)

	local powerType = UnitPowerType("player")
	local colour = PowerBarColor[powerType] or { r = 1, g = 1, b = 1 }

	bar:SetStatusBarColor(colour.r, colour.g, colour.b)

	------------------------------------------------------------
	-- SECONDARY POWER
	------------------------------------------------------------

	local _, class = UnitClass("player")
	local secondary = SecondaryPowerType[class]

	if secondary and S:Get("enabled", true) then
		local cur = UnitPower("player", secondary)
		local maxPower = UnitPowerMax("player", secondary)

		if maxPower > 0 then
			secContainer:Show()
			SennyinQoL:UpdateSegments(
				segments,
				secContainer,
				cur,
				maxPower,
				SecondaryPowerColours[class] or { 1, 1, 1, 1 }
			)
		else
			secContainer:Hide()
		end
	else
		secContainer:Hide()
	end
end

------------------------------------------------------------
-- EVENTS
------------------------------------------------------------

local eventFrame = CreateFrame("Frame")

eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterUnitEvent("UNIT_POWER_UPDATE", "player")
eventFrame:RegisterUnitEvent("UNIT_MAXPOWER", "player")

eventFrame:SetScript("OnEvent", function(_, event)
	if event == "PLAYER_ENTERING_WORLD" then
		bar:SetHeight(M:Get("height", 10))
		bar:SetShown(M:Get("enabled", true))

		secContainer:SetHeight(S:Get("height", 10))
		secContainer:SetShown(S:Get("enabled", true))

		C_Timer.After(1, function()
			AnchorBars()
			UpdatePowerBars()
		end)
	else
		UpdatePowerBars()
	end
end)

if _G["EssentialCooldownViewer"] then
	_G["EssentialCooldownViewer"]:HookScript("OnSizeChanged", function()
		AnchorBars()
		UpdatePowerBars()
	end)
end

------------------------------------------------------------
-- SETTINGS
------------------------------------------------------------

M.settings = {
	name = "Power Bar",
	category = "Resource Bars",
	order = 1,
	heading = "Power Bar",
	settings = {
		enabled = {
			label = "Enable Power Bar",
			type = "toggle",
			default = true,
			callback = function(v)
				M:Set("enabled", v)
				bar:SetShown(v)
				AnchorBars()
				UpdatePowerBars()
			end,
		},
		height = {
			label = "Bar Height",
			type = "slider",
			min = 5,
			max = 50,
			step = 1,
			default = 10,
			callback = function(v)
				M:Set("height", v)
				bar:SetHeight(v)
				AnchorBars()
				UpdatePowerBars()
			end,
		},
	},
}

S.settings = {
	name = "Secondary Power",
	category = "Resource Bars",
	order = 2,
	heading = "Secondary Power",
	settings = {
		enabled = {
			label = "Enable Secondary Bar",
			type = "toggle",
			default = true,
			callback = function(v)
				S:Set("enabled", v)
				secContainer:SetShown(v)
				UpdatePowerBars()
			end,
		},
		height = {
			label = "Secondary Height",
			type = "slider",
			min = 5,
			max = 50,
			step = 1,
			default = 10,
			callback = function(v)
				S:Set("height", v)
				secContainer:SetHeight(v)
				AnchorBars()
				UpdatePowerBars()
			end,
		},
	},
}
