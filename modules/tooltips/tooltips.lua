local M = SennyinQoL:NewModule("Tooltips")

M.defaults = {
	enabled = true,
}

M.settings = {
	name = "Tooltips",
	category = "Tooltips",
	heading = "Tooltip Display",
	settings = {
		enabled = {
			label = "Enable Tooltip Enhancements",
			type = "toggle",
			default = true,
			callback = function(v)
				M:Set("enabled", v)
				if v then
					M:Refresh()
				end
			end,
		},
	},
}

local factionColors = {
	Alliance = { r = 0.0, g = 0.5, b = 1.0 },
	Horde = { r = 1.0, g = 0.1, b = 0.1 },
}

local function GetGuildColor(faction)
	local color = factionColors[faction]
	if not color then
		return 1, 1, 1
	end
	return color.r, color.g, color.b
end

local function GetClassColor(unit)
	if not UnitExists(unit) then
		return 1, 1, 1
	end

	if UnitIsPlayer(unit) then
		local _, class = UnitClass(unit)
		local color = RAID_CLASS_COLORS[class]
		if color then
			return color.r, color.g, color.b
		end
	end

	local reaction = UnitReaction(unit, "player")
	if reaction then
		return GetQuestDifficultyColor(reaction).r,
			GetQuestDifficultyColor(reaction).g,
			GetQuestDifficultyColor(reaction).b
	end

	return 1, 1, 1
end

local function GetTargetLine(unit)
	if not UnitExists(unit) then
		return nil
	end

	local target = unit .. "Target"
	if UnitExists(target) then
		local name = UnitName(target)
		local r, g, b = GetClassColor(target)
		return string.format("|cff%02x%02x%02xTarget:|r %s", r * 255, g * 255, b * 255, name)
	end

	return nil
end

local function FormatGuildLine(unit)
	if not UnitIsPlayer(unit) then
		return nil
	end

	local guildName, guildRank = GetGuildInfo(unit)
	if not guildName then
		return nil
	end

	local _, _, _, _, _, GuildRealm = GetGuildInfo(unit)
	local faction = UnitFactionGroup(unit) or "Alliance"
	local r, g, b = GetGuildColor(faction)
	local guildLine = string.format("|cff%02x%02x%02x%s|r - %s", r * 255, g * 255, b * 255, guildName, guildRank or "")
	return guildLine
end

local function FormatItemLevel(unit)
	if not UnitIsPlayer(unit) or not UnitExists(unit) then
		return nil
	end

	local itemLevel = C_PaperDollInfo.GetInspectItemLevel(unit)
	if itemLevel and itemLevel > 0 then
		return string.format("Item Level: %d", itemLevel)
	end

	return nil
end

local function OnTooltipSetUnit(tooltip)
	if not M:Get("enabled", true) then
		return
	end

	local unit = tooltip:GetUnit()
	if not unit and UnitExists("mouseover") then
		unit = "mouseover"
	end

	if not unit then
		return
	end

	local name = UnitName(unit)
	if UnitIsPlayer(unit) then
		name = name:gsub("%-.*$", "")
	end

	local classR, classG, classB = GetClassColor(unit)
	local coloredName = string.format("|cff%02x%02x%02x%s|r", classR * 255, classG * 255, classB * 255, name)

	tooltip:ClearLines()
	tooltip:SetText(coloredName)

	local guildLine = FormatGuildLine(unit)
	if guildLine then
		tooltip:AddLine(guildLine)
	end

	local ilvlLine = FormatItemLevel(unit)
	if ilvlLine then
		tooltip:AddLine(ilvlLine)
	end

	local targetLine = GetTargetLine(unit)
	if targetLine then
		tooltip:AddLine(targetLine)
	end

	tooltip:Show()
end

local function HookTooltip(tooltip)
	if not tooltip then
		return
	end

	if tooltip._SennyinQoLHooked then
		return
	end

	if tooltip.SetUnit then
		hooksecurefunc(tooltip, "SetUnit", function(self, unit)
			if unit then
				OnTooltipSetUnit(self)
			end
		end)
	end

	if tooltip.HookScript and tooltip.SetScript then
		pcall(function()
			tooltip:HookScript("OnTooltipSetUnit", OnTooltipSetUnit)
		end)
	end

	tooltip._SennyinQoLHooked = true
end

function M:Refresh()
	if not self:Get("enabled", true) then
		return
	end

	local tooltips = {
		GameTooltip,
		ItemRefTooltip,
		ShoppingTooltip1,
		ShoppingTooltip2,
		EmbeddedItemTooltip,
	}

	for _, tooltip in ipairs(tooltips) do
		HookTooltip(tooltip)
	end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function(self, event, addonName)
	if event == "ADDON_LOADED" then
		if addonName == "SennyinQoL" then
			M:Refresh()
		end
	else
		M:Refresh()
	end
end)
