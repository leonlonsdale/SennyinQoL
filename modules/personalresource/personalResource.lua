local M = SennyinQoL:NewModule("PersonalResource")

------------------------------------------------------------
-- Defaults
------------------------------------------------------------

M.defaults = {
	anchorToEssentials = false,
	matchWidthToEssentials = false,
}

------------------------------------------------------------
-- Settings
------------------------------------------------------------

M.settings = {
	name = "Personal Resource Display",
	heading = "Personal Resource Display",
	settings = {
		anchorToEssentials = {
			label = "Anchor to Essential Cooldowns",
			default = false,
			callback = function(value)
				M:Set("anchorToEssentials", value)
				M.UpdateLayout()
			end,
		},
		matchWidthToEssentials = {
			label = "Match Width to Essential Cooldowns",
			default = false,
			callback = function(value)
				M:Set("matchWidthToEssentials", value)
				M.UpdateLayout()
			end,
		},
	},
}

------------------------------------------------------------
-- Layout Logic
------------------------------------------------------------

local function UpdateLayout()
	local prd = _G["PersonalResourceDisplayFrame"]
	local cooldowns = _G["EssentialCooldownViewer"]

	if not prd or not cooldowns or InCombatLockdown() then
		return
	end

	-- Skip completely if user is rearranging in Edit Mode
	if prd.isInEditMode or (EditModeManagerFrame and EditModeManagerFrame:IsEditModeActive()) then
		return
	end

	local shouldAnchor = M:Get("anchorToEssentials", false)
	local shouldMatchWidth = M:Get("matchWidthToEssentials", false)

	if not shouldAnchor and not shouldMatchWidth then
		return
	end

	local icons = SennyinQoL:GetVisibleIcons(cooldowns)

	if #icons == 0 then
		return
	end

	local firstIcon = icons[1]
	local lastIcon = icons[#icons]

	--------------------------------------------------------
	-- Option 1: Anchor Positioning
	--------------------------------------------------------
	if shouldAnchor then
		prd:ClearAllPoints()

		if shouldMatchWidth then
			prd:SetPoint("LEFT", firstIcon, "LEFT", 0, 0)
			prd:SetPoint("RIGHT", lastIcon, "RIGHT", 0, 0)
			prd:SetPoint("BOTTOM", firstIcon, "TOP", 0, 6)
		else
			prd:SetPoint("BOTTOM", cooldowns, "TOP", 0, 6)
		end
	end

	--------------------------------------------------------
	-- Option 2: Sizing / Width Matching
	--------------------------------------------------------
	if shouldMatchWidth then
		if prd.HealthBarsContainer then
			prd.HealthBarsContainer:ClearAllPoints()
			prd.HealthBarsContainer:SetPoint("LEFT", firstIcon, "LEFT", 0, 0)
			prd.HealthBarsContainer:SetPoint("RIGHT", lastIcon, "RIGHT", 0, 0)
			prd.HealthBarsContainer:SetPoint("TOP", prd, "TOP", 0, 0)

			if prd.HealthBarsContainer.healthBar then
				prd.HealthBarsContainer.healthBar:ClearAllPoints()
				prd.HealthBarsContainer.healthBar:SetAllPoints(prd.HealthBarsContainer)
			end
		end

		if prd.PowerBar then
			prd.PowerBar:ClearAllPoints()
			prd.PowerBar:SetPoint("LEFT", firstIcon, "LEFT", 0, 0)
			prd.PowerBar:SetPoint("RIGHT", lastIcon, "RIGHT", 0, 0)
			prd.PowerBar:SetPoint("BOTTOM", prd, "BOTTOM", 0, 0)
		end
	else
		if prd.HealthBarsContainer then
			prd.HealthBarsContainer:ClearAllPoints()
			prd.HealthBarsContainer:SetPoint("TOPLEFT", prd, "TOPLEFT", 0, 0)
			prd.HealthBarsContainer:SetPoint("BOTTOMRIGHT", prd, "BOTTOMRIGHT", 0, 0)

			if prd.HealthBarsContainer.healthBar then
				prd.HealthBarsContainer.healthBar:ClearAllPoints()
				prd.HealthBarsContainer.healthBar:SetAllPoints(prd.HealthBarsContainer)
			end
		end

		if prd.PowerBar then
			prd.PowerBar:ClearAllPoints()
			prd.PowerBar:SetPoint("BOTTOMLEFT", prd, "BOTTOMLEFT", 0, 0)
			prd.PowerBar:SetPoint("BOTTOMRIGHT", prd, "BOTTOMRIGHT", 0, 0)
		end
	end
end

------------------------------------------------------------
-- Hook Setup
------------------------------------------------------------

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")

frame:SetScript("OnEvent", function()
	local cooldowns = _G["EssentialCooldownViewer"]

	if cooldowns and not cooldowns._sennyinPRDHooked then
		cooldowns._sennyinPRDHooked = true

		cooldowns:HookScript("OnShow", UpdateLayout)

		if cooldowns.Layout then
			hooksecurefunc(cooldowns, "Layout", UpdateLayout)
		end
	end

	if EditModeManagerFrame and not EditModeManagerFrame._sennyinPRDHooked then
		EditModeManagerFrame._sennyinPRDHooked = true
		EditModeManagerFrame:HookScript("OnHide", function()
			SennyinQoL:Debounce("PersonalResource", UpdateLayout)
		end)
	end

	UpdateLayout()
end)

M.UpdateLayout = UpdateLayout
