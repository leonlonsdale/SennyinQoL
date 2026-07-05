local M = SennyinQoL:NewModule("Nameplates")

local state = {
	referenceLevel = UnitLevel("player"),
}

local activeEnemyPlates = {}
local ApplyColor

------------------------------------------------------------
-- Colours
------------------------------------------------------------

local defaults = {
	caster = { r = 0.2, g = 0.6, b = 1.0 },
	miniboss = { r = 0.6, g = 0.2, b = 0.8 },
	melee = { r = 0.5, g = 0.5, b = 0.5 },
	trivial = { r = 0.3, g = 0.3, b = 0.3 },
	boss = { r = 1.0, g = 0.0, b = 0.0 },
	tank_safe = { r = 0.0, g = 1.0, b = 0.0 },
	tank_warn = { r = 1.0, g = 0.5, b = 0.0 },
}

local function GetColor(role)
	local saved = SennyinDB
		and SennyinDB.Nameplates
		and SennyinDB.Nameplates.colors
		and SennyinDB.Nameplates.colors[role]

	if
		type(saved) == "table"
		and type(saved.r) == "number"
		and type(saved.g) == "number"
		and type(saved.b) == "number"
	then
		return saved
	end

	return defaults[role] or defaults.melee
end

------------------------------------------------------------
-- Settings
------------------------------------------------------------

local frame = CreateFrame("Frame")

local function RegisterEvents()
	frame:RegisterEvent("PLAYER_LEVEL_UP")
	frame:RegisterEvent("PLAYER_ENTERING_WORLD")
	frame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
	frame:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
	frame:RegisterEvent("UNIT_THREAT_LIST_UPDATE")
	frame:RegisterEvent("UNIT_HEALTH")
end

local function UnregisterEvents()
	frame:UnregisterAllEvents()
end

local function IsEnabled()
	return M:Get("enabled", true)
end

M.settings = {
	name = "Nameplates",
	heading = "Nameplate Coloring",
	settings = {
		enabled = {
			label = "Enable Nameplate Coloring",
			type = "toggle",
			default = true,
			callback = function(value)
				M:Set("enabled", value)

				if value then
					RegisterEvents()
					M:Refresh()
				else
					UnregisterEvents()

					for unit in pairs(activeEnemyPlates) do
						if UnitExists(unit) then
							ApplyColor(unit)
						end
					end
				end
			end,
		},
		tankMode = {
			label = "Enable Tank Threat Colors",
			type = "toggle",
			default = true,
			callback = function(value)
				M:Set("tankMode", value)

				if IsEnabled() then
					M:Refresh()
				end
			end,
		},
		friendlyNameplates = {
			label = "Simplified Friendly Nameplates",
			type = "toggle",
			default = false,
			callback = function(value)
				M:Set("friendlyNameplates", value)
				if C_CVar and C_CVar.SetCVar then
					C_CVar.SetCVar("nameplateShowOnlyNameForFriendlyPlayerUnits", value and "1" or "0")
					C_CVar.SetCVar("nameplateUseClassColorForFriendlyPlayerUnitNames", value and "1" or "0")
				end
			end,
		},
	},
}

------------------------------------------------------------
-- Role detection
------------------------------------------------------------

local function GetRole(unit)
	local tankMode = M:Get("tankMode", true)

	if
		tankMode
		and PlayerUtil
		and PlayerUtil.IsPlayerEffectivelyTank
		and PlayerUtil.IsPlayerEffectivelyTank()
		and UnitAffectingCombat("player")
	then
		local threat = UnitThreatSituation("player", unit)

		if threat == 3 then
			return "tank_safe"
		elseif threat and threat > 0 then
			return "tank_warn"
		end
	end

	local classification = UnitClassification(unit)
	local level = UnitLevel(unit)
	local _, power = UnitPowerType(unit)

	if level == -1 or classification == "worldboss" or level >= state.referenceLevel + 2 then
		return "boss"
	end

	if
		(classification == "elite" or classification == "rare" or classification == "rareelite")
		and level >= state.referenceLevel + 1
	then
		return "miniboss"
	end

	if power == "MANA" then
		return "caster"
	end

	if classification == "minus" or classification == "trivial" then
		return "trivial"
	end

	return "melee"
end

------------------------------------------------------------
-- Restore Blizzard-like colours
------------------------------------------------------------

local function RestoreDefault(unit, healthBar)
	local color = SennyinQoL:GetReactionColor(unit) or CreateColor(1, 1, 1)

	healthBar:SetStatusBarColor(color.r, color.g, color.b, 1)

	local tex = healthBar:GetStatusBarTexture()

	if tex then
		tex:SetVertexColor(color.r, color.g, color.b, 1)
	end
end

------------------------------------------------------------
-- Apply colour
------------------------------------------------------------

ApplyColor = function(unit)
	if type(unit) ~= "string" or not unit:find("nameplate") then
		return
	end

	if UnitIsFriend("player", unit) then
		return
	end

	local plate = C_NamePlate.GetNamePlateForUnit(unit)

	if not plate or not plate.UnitFrame or not plate.UnitFrame.healthBar then
		return
	end

	local healthBar = plate.UnitFrame.healthBar

	if IsEnabled() then
		local c = GetColor(GetRole(unit))

		healthBar:SetStatusBarColor(c.r, c.g, c.b, 1)

		local tex = healthBar:GetStatusBarTexture()

		if tex then
			tex:SetVertexColor(c.r, c.g, c.b)
		end
	else
		RestoreDefault(unit, healthBar)
	end
end

------------------------------------------------------------
-- Refresh active plates
------------------------------------------------------------

function M:Refresh()
	if not IsEnabled() then
		return
	end

	for unit in pairs(activeEnemyPlates) do
		if UnitExists(unit) then
			ApplyColor(unit)
		else
			activeEnemyPlates[unit] = nil
		end
	end
end

------------------------------------------------------------
-- Events
------------------------------------------------------------

if IsEnabled() then
	RegisterEvents()
end

frame:SetScript("OnEvent", function(_, event, unit)
	if not IsEnabled() then
		return
	end

	if event == "PLAYER_LEVEL_UP" then
		state.referenceLevel = UnitLevel("player")
		M:Refresh()
	elseif event == "PLAYER_ENTERING_WORLD" then
		state.referenceLevel = UnitLevel("player")
		M:Refresh()
	elseif event == "NAME_PLATE_UNIT_ADDED" then
		if type(unit) == "string" then
			if not UnitIsFriend("player", unit) then
				activeEnemyPlates[unit] = true
			end
			SennyinQoL:Debounce("Nameplate:" .. unit, function()
				ApplyColor(unit)
			end)
		end
	elseif event == "NAME_PLATE_UNIT_REMOVED" then
		if type(unit) == "string" then
			activeEnemyPlates[unit] = nil
		end
	elseif event == "UNIT_HEALTH" or event == "UNIT_THREAT_LIST_UPDATE" then
		if type(unit) == "string" and unit:find("nameplate") then
			-- Apply immediately for UNIT_HEALTH to prevent flicker, debounce threat updates
			if event == "UNIT_HEALTH" then
				ApplyColor(unit)
			else
				SennyinQoL:Debounce("Nameplate:" .. unit, function()
					ApplyColor(unit)
				end)
			end
		end
	end
end)
