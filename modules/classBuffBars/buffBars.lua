local M = SennyinQoL:NewModule("ClassBuffs")

------------------------------------------------------------
-- TRACKING MODE CONFIGURATION
------------------------------------------------------------
local BUFF_CONFIGS = {
	["WARRIOR"] = {
		[72] = {
			key = "fury_whirlwind",
			name = "Whirlwind / Meat Cleaver Tracker",
			generators = {
				[190411] = { maxStacks = 4, duration = 20, mode = "STACKS" }, -- Whirlwind
				[6343] = { maxStacks = 4, duration = 20, mode = "STACKS" }, -- Thunder Clap
				[435222] = { maxStacks = 4, duration = 20, mode = "STACKS" }, -- Thunder Blast
			},
			spenders = {
				[23881] = true,
				[85288] = true,
				[280735] = true,
				[5308] = true,
				[202168] = true,
				[184367] = true,
				[335096] = true,
				[335097] = true,
			},
			color = { 0, 0.7, 1, 1 }, -- Cyan
		},
	},
}

local _, playerClass = UnitClass("player")
local classProfile = BUFF_CONFIGS[playerClass]
local currentProfile = nil

------------------------------------------------------------
-- PROFILE RESOLUTION PIPELINE
------------------------------------------------------------
local function UpdateActiveProfile()
	if not classProfile then
		currentProfile = nil
		return
	end

	local specIndex = GetSpecialization()

	if specIndex then
		local specID = GetSpecializationInfo(specIndex)
		currentProfile = classProfile[specID]
	else
		currentProfile = nil
	end
end

local function IsActiveProfileEnabled()
	if not currentProfile then
		return false
	end

	return M:Get(currentProfile.key, true)
end

------------------------------------------------------------
-- RUNTIME MEMORY STATE
------------------------------------------------------------
local currentStacks = 0
local expiresAt = nil
local activeConfig = nil

------------------------------------------------------------
-- VISUAL LAYOUT CONTAINER FRAMES
------------------------------------------------------------
local mainFrame = CreateFrame("Frame", "SennyinQoL_ClassBuffMainContainer", UIParent)
mainFrame:SetSize(200, 10)
mainFrame:SetPoint("CENTER", UIParent, "CENTER", 0, -150)

local continuousBar = CreateFrame("StatusBar", nil, mainFrame)
continuousBar:SetAllPoints(mainFrame)
continuousBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
continuousBar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")

continuousBar.bg = continuousBar:CreateTexture(nil, "BACKGROUND")
continuousBar.bg:SetAllPoints(continuousBar)
continuousBar.bg:SetColorTexture(0, 0, 0, 0.5)

SennyinQoL:AddBorder(continuousBar)

mainFrame:Show()
continuousBar:Hide()

------------------------------------------------------------
-- DYNAMIC ANCHORING ENGINE
------------------------------------------------------------
local function AnchorBuffBar()
	local smartAnchor = M:Get("smartAnchor", true)
	local candidates = smartAnchor
			and { "SennyinSecondaryContainer", "SennyinPowerBar", "PersonalResourceDisplayFrame" }
		or {}

	SennyinQoL:AnchorToFirstVisible(mainFrame, candidates, 5, {
		fallback = { point = "CENTER", relativeTo = UIParent, x = 0, y = -150, width = 200 },
	})
end

------------------------------------------------------------
-- SEGMENTED FRAMES ENGINE (STACK MODE ONLY)
------------------------------------------------------------
local segments = {}

local function HideAllSegments()
	for _, seg in ipairs(segments) do
		seg:Hide()
	end
end

------------------------------------------------------------
-- THROTTLED UPDATE TICKER
------------------------------------------------------------
-- Runs only while a tracked buff is actually active, at 10Hz instead of
-- once per rendered frame -- the countdown bar/expiry check doesn't need
-- finer resolution than that to feel real-time.
local ticker = nil
local UpdateVisuals

local function StopTicker()
	if ticker then
		ticker:Cancel()
		ticker = nil
	end
end

local function StartTicker()
	if ticker then
		return
	end

	ticker = C_Timer.NewTicker(0.1, function()
		if currentStacks > 0 and IsActiveProfileEnabled() then
			UpdateVisuals()
		else
			StopTicker()
		end
	end)
end

------------------------------------------------------------
-- VISUAL MANAGER
------------------------------------------------------------
UpdateVisuals = function()
	if not M:Get("enabled", true) or not IsActiveProfileEnabled() then
		mainFrame:Hide()
		HideAllSegments()
		continuousBar:Hide()
		return
	end

	local customHeight = M:Get("height", 10)
	mainFrame:SetHeight(customHeight)
	continuousBar:SetHeight(customHeight)

	AnchorBuffBar()

	if not mainFrame:IsShown() then
		mainFrame:Show()
	end

	if expiresAt and GetTime() >= expiresAt then
		currentStacks = 0
		expiresAt = nil
		activeConfig = nil
	end

	if currentStacks > 0 and activeConfig then
		local remaining = expiresAt and (expiresAt - GetTime()) or 0
		if remaining < 0 then
			remaining = 0
		end

		if activeConfig.mode == "STACKS" then
			continuousBar:Hide()
			SennyinQoL:UpdateSegments(
				segments,
				mainFrame,
				currentStacks,
				activeConfig.maxStacks,
				currentProfile.color,
				{
					inset = 1,
				}
			)
		else
			HideAllSegments()
			continuousBar:Show()
			continuousBar:SetMinMaxValues(0, activeConfig.duration)
			continuousBar:SetValue(remaining)

			if currentProfile.color then
				continuousBar:SetStatusBarColor(unpack(currentProfile.color))
			end
		end
	else
		continuousBar:Hide()

		local fallbackMax = 4
		for _, gen in pairs(currentProfile.generators) do
			if gen.maxStacks then
				fallbackMax = gen.maxStacks
				break
			end
		end

		SennyinQoL:UpdateSegments(segments, mainFrame, 0, fallbackMax, currentProfile.color, { inset = 1 })
	end

	if SennyinQoL.Modules.CooldownCentering and SennyinQoL.Modules.CooldownCentering.ApplyAll then
		SennyinQoL.Modules.CooldownCentering.ApplyAll()
	end
end

------------------------------------------------------------
-- COMBAT TRACKER & LIFE CYCLE EVENTS
------------------------------------------------------------
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("PLAYER_DEAD")
eventFrame:RegisterEvent("PLAYER_ALIVE")
eventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")

eventFrame:SetScript("OnEvent", function(_, event, unit, _, spellID)
	if
		event == "PLAYER_ENTERING_WORLD"
		or event == "PLAYER_DEAD"
		or event == "PLAYER_ALIVE"
		or event == "PLAYER_SPECIALIZATION_CHANGED"
	then
		UpdateActiveProfile()

		currentStacks = 0
		expiresAt = nil
		activeConfig = nil
		StopTicker()

		C_Timer.After(0.2, UpdateVisuals)
		return
	end

	if not IsActiveProfileEnabled() then
		return
	end

	if event == "UNIT_SPELLCAST_SUCCEEDED" and unit == "player" then
		local matchedGen = currentProfile.generators[spellID]

		if matchedGen then
			activeConfig = matchedGen
			currentStacks = matchedGen.maxStacks
			expiresAt = GetTime() + matchedGen.duration
			StartTicker()
		elseif currentProfile.spenders[spellID] and currentStacks > 0 and activeConfig then
			currentStacks = math.max(0, currentStacks - 1)

			if currentStacks == 0 then
				expiresAt = nil
				activeConfig = nil
			end
		end

		UpdateVisuals()
	end
end)

------------------------------------------------------------
-- EXTERNAL CROSS-MODULE HOOK INTERCEPTORS
------------------------------------------------------------
if _G["SennyinPowerBar"] then
	_G["SennyinPowerBar"]:HookScript("OnSizeChanged", UpdateVisuals)
	_G["SennyinPowerBar"]:HookScript("OnShow", UpdateVisuals)
	_G["SennyinPowerBar"]:HookScript("OnHide", UpdateVisuals)
end

------------------------------------------------------------
-- SETTINGS PANEL
------------------------------------------------------------
M.defaults = {
	enabled = true,
	smartAnchor = true,
	height = 10,
	spacing = 5,
}

M.settings = {
	name = "Class Buff Bars",
	category = "Resource Bars",
	order = 3,
	heading = "Class Buff Bars",
	settings = {
		enabled = {
			label = "Enable Class Buff Bars",
			type = "toggle",
			default = true,
			callback = function(v)
				M:Set("enabled", v)
				UpdateVisuals()
			end,
		},
		smartAnchor = {
			label = "Anchor to Resource/Power Bars",
			type = "toggle",
			default = true,
			callback = function(v)
				M:Set("smartAnchor", v)
				UpdateVisuals()
			end,
		},
	},
}

if classProfile then
	for _, config in pairs(classProfile) do
		if config.key and config.name then
			M.settings.settings[config.key] = {
				label = "Enable: " .. config.name,
				type = "toggle",
				default = true,
				callback = function(v)
					M:Set(config.key, v)
					UpdateVisuals()
				end,
			}
		end
	end
end
