local M = SennyinQoL:NewModule("CooldownCentering")

M.defaults = {
	centerCooldowns = true,
	centerBuffs = false,
	anchorUtilityToEssentials = false,
	anchorBuffsToPRD = false,
	anchorBuffsToPowerBars = false,
}

M.settings = {
	name = "Cooldown Manager",
	heading = "Cooldown Centering",
	settings = {
		centerCooldowns = {
			label = "Center Cooldowns",
			default = true,
			callback = function(value)
				M:Set("centerCooldowns", value)
				if value then
					M.ApplyAll()
				end
			end,
		},
		centerBuffs = {
			label = "Center Buffs",
			default = false,
			callback = function(value)
				M:Set("centerBuffs", value)
				if value then
					M.ApplyAll()
				end
			end,
		},
		anchorUtilityToEssentials = {
			label = "Anchor Utility Below Essentials",
			default = false,
			callback = function(value)
				M:Set("anchorUtilityToEssentials", value)
				M.ApplyAll()
			end,
		},
		anchorBuffsToPRD = {
			label = "Anchor Tracked Buffs Above PRD",
			default = false,
			callback = function(value)
				M:Set("anchorBuffsToPRD", value)
				M.ApplyAll()
				if SennyinQoL.Modules.PersonalResource and SennyinQoL.Modules.PersonalResource.UpdateLayout then
					SennyinQoL.Modules.PersonalResource.UpdateLayout()
				end
			end,
		},
		anchorBuffsToPowerBars = {
			label = "Anchor Tracked Buffs Above Power Bars",
			default = false,
			callback = function(value)
				M:Set("anchorBuffsToPowerBars", value)
				M.ApplyAll()
			end,
		},
	},
}

function M.IsBuffAnchoringEnabled()
	return M:Get("anchorBuffsToPRD", false)
end

local GRID_VIEWERS = {
	"EssentialCooldownViewer",
	"UtilityCooldownViewer",
}

local isCentering = false

------------------------------------------------------------
-- Icon layout
------------------------------------------------------------
local function LayoutIcons(viewer, limit)
	if isCentering then
		return
	end

	local icons = SennyinQoL:GetVisibleIcons(viewer)

	if #icons == 0 then
		viewer.realGridWidth = 0
		return
	end

	local iconW = icons[1]:GetWidth()
	local iconH = icons[1]:GetHeight()

	if not iconW or iconW == 0 then
		return
	end

	local isVertical = (viewer.isHorizontal == false) or (viewer.isVertical == true)
	local spacing = viewer.childXPadding or viewer.childYPadding or 4

	isCentering = true

	if isVertical then
		local count = #icons
		local totalHeight = (count * iconH) + ((count - 1) * spacing)
		local startY = (totalHeight / 2) - (iconH / 2)

		for i, icon in ipairs(icons) do
			local y = startY - (i - 1) * (iconH + spacing)
			icon:ClearAllPoints()
			icon:SetPoint("LEFT", viewer, "LEFT", 0, y)
		end

		viewer.realGridWidth = iconW
		isCentering = false
		return
	end

	limit = limit or viewer.iconLimit or #icons

	local rowIndex = 0
	local maxCalculatedWidth = 0

	for i = 1, #icons, limit do
		local first = i
		local last = math.min(i + limit - 1, #icons)
		local count = last - first + 1

		local rowWidth = (count * iconW) + ((count - 1) * spacing)
		maxCalculatedWidth = math.max(maxCalculatedWidth, rowWidth)

		local startX = -(rowWidth / 2) + (iconW / 2)
		local rowYOffset = -rowIndex * (iconH + spacing)

		local firstIcon = icons[first]
		firstIcon:ClearAllPoints()
		firstIcon:SetPoint("TOP", viewer, "TOP", startX, rowYOffset)

		for j = first + 1, last do
			icons[j]:ClearAllPoints()
			icons[j]:SetPoint("LEFT", icons[j - 1], "RIGHT", spacing, 0)
		end

		rowIndex = rowIndex + 1
	end

	viewer.realGridWidth = maxCalculatedWidth
	isCentering = false

	if
		viewer:GetName() == "EssentialCooldownViewer"
		and SennyinQoL.Modules.PersonalResource
		and SennyinQoL.Modules.PersonalResource.UpdateLayout
	then
		SennyinQoL.Modules.PersonalResource.UpdateLayout()
	end
end

------------------------------------------------------------
-- Core execution loop
------------------------------------------------------------
local function RunAdjustments()
	local inEditMode = EditModeManagerFrame and EditModeManagerFrame:IsEditModeActive()

	if inEditMode then
		return
	end

	if M:Get("centerCooldowns", true) then
		for _, name in ipairs(GRID_VIEWERS) do
			local viewer = _G[name]
			if viewer and not viewer.isInEditMode then
				LayoutIcons(viewer)
			end
		end
	end

	local buffs = _G["BuffIconCooldownViewer"]

	if M:Get("centerBuffs", false) and buffs and not buffs.isInEditMode then
		local icons = SennyinQoL:GetVisibleIcons(buffs)
		LayoutIcons(buffs, #icons)
	end

	-- Anchor Utility Viewer dynamically below Essential Viewer
	if M:Get("anchorUtilityToEssentials", false) and not InCombatLockdown() then
		local essentials = _G["EssentialCooldownViewer"]
		local utility = _G["UtilityCooldownViewer"]

		if essentials and utility and not utility.isInEditMode and not essentials.isInEditMode then
			utility:ClearAllPoints()
			utility:SetPoint("TOP", essentials, "BOTTOM", 0, -6)
		end
	end

	-- Anchor Tracked Buff positioning rules
	if not InCombatLockdown() and buffs and not buffs.isInEditMode then
		if M:Get("anchorBuffsToPowerBars", false) then
			SennyinQoL:AnchorToFirstVisible(buffs, {
				"SennyinQoL_ClassBuffMainContainer",
				"SennyinSecondaryContainer",
				"SennyinPowerBar",
			}, 6, { matchWidth = false })
		elseif M:Get("anchorBuffsToPRD", false) then
			SennyinQoL:AnchorToFirstVisible(buffs, { "PersonalResourceDisplayFrame" }, 6, { matchWidth = false })
		end
	end
end

local function ApplyAll()
	SennyinQoL:Debounce("CooldownCentering", RunAdjustments)
end

local frame = CreateFrame("Frame")
local buffFrame = CreateFrame("Frame")

frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("UI_SCALE_CHANGED")

buffFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
buffFrame:RegisterEvent("UNIT_AURA")

local function HookViewer(name)
	local viewer = _G[name]

	if not viewer or viewer._sennyinHooked then
		return
	end

	viewer._sennyinHooked = true

	if viewer.Layout then
		hooksecurefunc(viewer, "Layout", ApplyAll)
	end

	viewer:HookScript("OnShow", ApplyAll)
end

frame:SetScript("OnEvent", function()
	for _, name in ipairs(GRID_VIEWERS) do
		HookViewer(name)
	end

	local buffViewer = _G["BuffIconCooldownViewer"]

	if buffViewer and not buffViewer._sennyinHooked then
		buffViewer._sennyinHooked = true
		buffViewer:HookScript("OnShow", ApplyAll)

		if buffViewer.Layout then
			hooksecurefunc(buffViewer, "Layout", ApplyAll)
		end
	end

	if EditModeManagerFrame and not EditModeManagerFrame._sennyinCooldownsHooked then
		EditModeManagerFrame._sennyinCooldownsHooked = true
		EditModeManagerFrame:HookScript("OnShow", ApplyAll)
		EditModeManagerFrame:HookScript("OnEvent", ApplyAll)
	end

	ApplyAll()
end)

buffFrame:SetScript("OnEvent", function(_, event, unit)
	if not M:Get("centerBuffs", false) then
		return
	end

	if event == "UNIT_AURA" and unit and unit ~= "player" then
		return
	end

	ApplyAll()
end)

M.ApplyAll = ApplyAll
