SennyinQoL = SennyinQoL or {}

------------------------------------------------------------
-- Shared write-then-notify handler, used by every widget type
------------------------------------------------------------

function SennyinQoL:ApplySetting(moduleName, key, value, setting, module)
	self:SetSetting(moduleName, key, value)

	if setting.callback then
		setting.callback(value)
	end

	if module and module.Refresh then
		C_Timer.After(0, function()
			module:Refresh()
		end)
	end
end

------------------------------------------------------------
-- Category discovery
------------------------------------------------------------

local DEFAULT_CATEGORY_ORDER = {
	General = 1,
}

local function GetCategories()
	local groups = {}

	for moduleName, module in pairs(SennyinQoL.Modules) do
		if module.settings and module.settings.settings then
			local groupKey = module.settings.category or module.settings.name or moduleName
			local displayName = module.settings.category or module.settings.name or moduleName
			local defaultOrder = DEFAULT_CATEGORY_ORDER[groupKey] or 999
			local groupOrder = module.settings.categoryOrder or defaultOrder
			local moduleOrder = module.settings.order or 999

			if not groups[groupKey] then
				groups[groupKey] = {
					displayName = displayName,
					groupKey = groupKey,
					order = groupOrder,
					modules = {},
				}
			else
				groups[groupKey].order = math.min(groups[groupKey].order, groupOrder)
			end

			groups[groupKey].modules[#groups[groupKey].modules + 1] = {
				moduleName = moduleName,
				module = module,
				order = moduleOrder,
				displayName = module.settings.name or moduleName,
			}
		end
	end

	local ordered = {}
	for _, group in pairs(groups) do
		ordered[#ordered + 1] = group
	end

	table.sort(ordered, function(a, b)
		if a.order ~= b.order then
			return a.order < b.order
		end
		return a.displayName < b.displayName
	end)

	for _, group in ipairs(ordered) do
		table.sort(group.modules, function(a, b)
			if a.order ~= b.order then
				return a.order < b.order
			end
			return a.displayName < b.displayName
		end)

		if #group.modules > 1 then
			group.group = true
		else
			local single = group.modules[1]
			group.moduleName = single.moduleName
			group.module = single.module
		end
	end

	return ordered
end

local UI = {
	bgColor = { 0.08, 0.09, 0.12, 0.98 },
	panelColor = { 0.10, 0.11, 0.15, 0.95 },
	borderColor = { 0.76, 0.62, 0.14, 1 },
	highlightColor = { 0.95, 0.84, 0.28, 1 },
	textColor = { 1, 1, 1, 1 },
}

local function StyleBackdrop(frame)
	frame:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8X8",
		edgeFile = "Interface\\Buttons\\WHITE8X8",
		tile = true,
		tileSize = 8,
		edgeSize = 1,
		insets = { left = 1, right = 1, top = 1, bottom = 1 },
	})
	frame:SetBackdropColor(unpack(UI.panelColor))
	frame:SetBackdropBorderColor(unpack(UI.borderColor))
end

local function CreateModernButton(parent, text, width, height)
	local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
	button:SetSize(width or 128, height or 24)
	StyleBackdrop(button)
	button:SetBackdropColor(0.14, 0.16, 0.20, 1)

	button.text = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	button.text:SetPoint("CENTER")
	button.text:SetText(text)
	button.text:SetTextColor(1, 0.9, 0.2, 1)

	button:SetScript("OnEnter", function(self)
		self:SetBackdropColor(0.18, 0.20, 0.24, 1)
	end)
	button:SetScript("OnLeave", function(self)
		self:SetBackdropColor(0.14, 0.16, 0.20, 1)
	end)
	button:SetScript("OnMouseDown", function(self)
		self:SetBackdropColor(0.12, 0.14, 0.18, 1)
	end)
	button:SetScript("OnMouseUp", function(self)
		self:SetBackdropColor(0.18, 0.20, 0.24, 1)
	end)

	function button:SetSelected(selected)
		if selected then
			self:SetBackdropBorderColor(unpack(UI.highlightColor))
			self.text:SetTextColor(1, 1, 1, 1)
		else
			self:SetBackdropBorderColor(unpack(UI.borderColor))
			self.text:SetTextColor(1, 0.9, 0.2, 1)
		end
	end

	return button
end

------------------------------------------------------------
-- Frame construction
------------------------------------------------------------

local frame = CreateFrame("Frame", "SennyinQoLSettingsFrame", UIParent, "BackdropTemplate")
frame:SetSize(820, 560)
frame:SetPoint("CENTER")
frame:SetFrameStrata("HIGH")
frame:SetClampedToScreen(true)
frame:SetMovable(true)
frame:EnableMouse(true)
StyleBackdrop(frame)
frame:SetBackdropColor(unpack(UI.bgColor))
frame:Hide()

tinsert(UISpecialFrames, "SennyinQoLSettingsFrame")

local titleBar = CreateFrame("Frame", nil, frame, "BackdropTemplate")
titleBar:SetPoint("TOPLEFT")
titleBar:SetPoint("TOPRIGHT")
titleBar:SetHeight(36)
StyleBackdrop(titleBar)
titleBar:SetBackdropColor(0.10, 0.11, 0.16, 0.96)
titleBar:EnableMouse(true)
titleBar:RegisterForDrag("LeftButton")
titleBar:SetScript("OnDragStart", function()
	frame:StartMoving()
end)
titleBar:SetScript("OnDragStop", function()
	frame:StopMovingOrSizing()
end)

local title = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("LEFT", 16, 0)
title:SetText("SennyinQoL Settings")
title:SetTextColor(1, 0.9, 0.2, 1)

local closeButton = CreateModernButton(titleBar, "×", 24, 24)
closeButton:SetPoint("TOPRIGHT", -4, -4)
closeButton:SetScript("OnClick", function()
	frame:Hide()
end)

local reloadButton = CreateFrame("Button", nil, titleBar, "BackdropTemplate")
reloadButton:SetSize(80, 24)
reloadButton:SetPoint("RIGHT", closeButton, "LEFT", -6, 0)
StyleBackdrop(reloadButton)
reloadButton:SetBackdropColor(0.14, 0.16, 0.20, 1)
reloadButton:SetBackdropBorderColor(unpack(UI.borderColor))

reloadButton.text = reloadButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
reloadButton.text:SetPoint("CENTER")
reloadButton.text:SetText("Reload UI")
reloadButton.text:SetTextColor(1, 0.9, 0.2, 1)

reloadButton:SetScript("OnEnter", function(self)
	self:SetBackdropColor(0.18, 0.20, 0.24, 1)
end)
reloadButton:SetScript("OnLeave", function(self)
	self:SetBackdropColor(0.14, 0.16, 0.20, 1)
end)
reloadButton:SetScript("OnMouseDown", function(self)
	self:SetBackdropColor(0.12, 0.14, 0.18, 1)
end)
reloadButton:SetScript("OnMouseUp", function(self)
	self:SetBackdropColor(0.18, 0.20, 0.24, 1)
end)
reloadButton:SetScript("OnClick", function()
	ReloadUI()
end)

------------------------------------------------------------
-- Sidebar (category list)
------------------------------------------------------------

local sidebar = CreateFrame("Frame", nil, frame, "BackdropTemplate")
sidebar:SetPoint("TOPLEFT", 16, -48)
sidebar:SetPoint("BOTTOMLEFT", 16, 16)
sidebar:SetWidth(220)
StyleBackdrop(sidebar)
sidebar:SetBackdropColor(0.10, 0.11, 0.16, 0.95)

local contentBG = CreateFrame("Frame", nil, frame, "BackdropTemplate")
contentBG:SetPoint("TOPLEFT", sidebar, "TOPRIGHT", 16, 0)
contentBG:SetPoint("BOTTOMRIGHT", -16, 16)
StyleBackdrop(contentBG)
contentBG:SetBackdropColor(0.10, 0.11, 0.15, 0.95)

------------------------------------------------------------
-- Content area (scrolling settings list)
------------------------------------------------------------

local scrollFrame = CreateFrame("ScrollFrame", "SennyinQoLSettingsScrollFrame", contentBG, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", 8, -8)
scrollFrame:SetPoint("BOTTOMRIGHT", -26, 8)

local content = CreateFrame("Frame", nil, scrollFrame)
content:SetPoint("TOPLEFT")
content:SetSize(320, 1)
scrollFrame:SetScrollChild(content)

scrollFrame:SetScript("OnSizeChanged", function(self, width)
	content:SetWidth(width - 4)
end)

------------------------------------------------------------
-- Populating a category's controls
------------------------------------------------------------

local activeWidgets = {}
local currentEntry = nil
local settingsCategories = {}

local function ClearContent()
	for _, widget in ipairs(activeWidgets) do
		widget:Hide()
		widget:SetParent(nil)
	end

	wipe(activeWidgets)
end

local function AddCheckbox(moduleName, module, key, setting, y)
	local checkbox = CreateFrame("CheckButton", nil, content, "BackdropTemplate")
	checkbox:SetSize(20, 20)
	checkbox:SetPoint("TOPLEFT", 8, y)
	StyleBackdrop(checkbox)
	checkbox:SetBackdropColor(0.14, 0.16, 0.20, 1)
	checkbox:SetBackdropBorderColor(unpack(UI.borderColor))

	checkbox.check = checkbox:CreateTexture(nil, "OVERLAY")
	checkbox.check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
	checkbox.check:SetPoint("CENTER")
	checkbox.check:SetSize(16, 16)
	checkbox.check:SetVertexColor(unpack(UI.highlightColor))
	checkbox.check:Hide()

	checkbox.text = checkbox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	checkbox.text:SetPoint("LEFT", checkbox, "RIGHT", 8, 0)
	checkbox.text:SetText(setting.label)
	checkbox.text:SetTextColor(1, 0.9, 0.2, 1)

	local function UpdateState()
		local checked = checkbox:GetChecked()
		checkbox.check:SetShown(checked)
		if checked then
			checkbox:SetBackdropBorderColor(unpack(UI.highlightColor))
		else
			checkbox:SetBackdropBorderColor(unpack(UI.borderColor))
		end
	end

	checkbox:SetScript("OnClick", function(self)
		UpdateState()
		SennyinQoL:ApplySetting(moduleName, key, self:GetChecked() and true or false, setting, module)
	end)

	checkbox:SetScript("OnEnter", function(self)
		self:SetBackdropColor(0.18, 0.20, 0.24, 1)
	end)
	checkbox:SetScript("OnLeave", function(self)
		self:SetBackdropColor(0.14, 0.16, 0.20, 1)
	end)

	local initialValue = SennyinQoL:GetSetting(moduleName, key, setting.default or false)
	checkbox:SetChecked(initialValue)
	UpdateState()

	activeWidgets[#activeWidgets + 1] = checkbox

	return 28
end

local function AddSlider(moduleName, module, key, setting, y)
	local slider = CreateFrame("Slider", nil, content, "OptionsSliderTemplate")
	slider:SetPoint("TOPLEFT", 12, y - 10)
	slider:SetWidth(220)
	slider:SetMinMaxValues(setting.min, setting.max)
	slider:SetValueStep(setting.step or 1)
	slider:SetObeyStepOnDrag(true)

	local value = SennyinQoL:GetSetting(moduleName, key, setting.default or setting.min or 0)
	slider:SetValue(value)
	slider.Text:SetText(setting.label .. ": " .. value)
	slider.Low:SetText(tostring(setting.min))
	slider.High:SetText(tostring(setting.max))
	slider.Text:SetTextColor(1, 0.9, 0.2, 1)
	slider.Low:SetTextColor(0.8, 0.8, 0.8, 1)
	slider.High:SetTextColor(0.8, 0.8, 0.8, 1)

	slider:SetScript("OnValueChanged", function(self, val)
		val = math.floor(val + 0.5)
		self.Text:SetText(setting.label .. ": " .. val)
		SennyinQoL:ApplySetting(moduleName, key, val, setting, module)
	end)

	activeWidgets[#activeWidgets + 1] = slider

	return 56
end

local function AddSectionHeading(text, y)
	local heading = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	heading:SetPoint("TOPLEFT", 4, y)
	heading:SetText(text)
	heading:SetTextColor(0.92, 0.82, 0.50, 1)
	activeWidgets[#activeWidgets + 1] = heading

	return 26
end

local function AddSeparator(y)
	local sep = content:CreateTexture(nil, "ARTWORK")
	sep:SetColorTexture(0.6, 0.6, 0.65, 0.16)
	sep:SetPoint("TOPLEFT", 4, y)
	sep:SetPoint("TOPRIGHT", -4, y)
	sep:SetHeight(1)
	activeWidgets[#activeWidgets + 1] = sep

	return 14
end

local function SelectCategory(entry)
	currentEntry = entry
	ClearContent()

	for _, categoryEntry in ipairs(settingsCategories) do
		if categoryEntry.button then
			categoryEntry.button:SetSelected(categoryEntry == entry)
		end
	end

	local y = -8

	if entry.group then
		for subIndex, subEntry in ipairs(entry.modules) do
			local module = subEntry.module
			if module and module.settings and module.settings.settings then
				y = y - AddSectionHeading(module.settings.heading or module.settings.name or subEntry.moduleName, y)

				for key, setting in pairs(module.settings.settings) do
					if setting.heading then
						y = y - 20
						local heading = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
						heading:SetPoint("TOPLEFT", 8, y)
						heading:SetText(setting.heading)
						heading:SetTextColor(0.9, 0.9, 0.9, 1)
						activeWidgets[#activeWidgets + 1] = heading
					end

					if setting.type == "slider" then
						y = y - AddSlider(subEntry.moduleName, module, key, setting, y)
					else
						y = y - AddCheckbox(subEntry.moduleName, module, key, setting, y)
					end
				end

				y = y - 10
				if subIndex < #entry.modules then
					y = y - AddSeparator(y)
				end
			end
		end
	else
		local module = entry.module
		y = y - AddSectionHeading(module.settings.heading or module.settings.name or entry.moduleName, y)
		for key, setting in pairs(module.settings.settings) do
			if setting.heading then
				local heading = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
				heading:SetPoint("TOPLEFT", 4, y)
				heading:SetText(setting.heading)
				heading:SetTextColor(0.9, 0.9, 0.9, 1)
				activeWidgets[#activeWidgets + 1] = heading
				y = y - 20
			end

			if setting.type == "slider" then
				y = y - AddSlider(entry.moduleName, module, key, setting, y)
			else
				y = y - AddCheckbox(entry.moduleName, module, key, setting, y)
			end
		end
	end

	content:SetHeight(math.max(-y + 16, 1))
end

------------------------------------------------------------
-- Category buttons (built lazily on first open)
------------------------------------------------------------

local built = false

local function BuildCategories()
	if built then
		return
	end

	built = true

	local categories = GetCategories()
	local y = -8

	for _, entry in ipairs(categories) do
		local label = entry.displayName
			or (entry.module and entry.module.settings and entry.module.settings.name)
			or entry.moduleName
		local button = CreateModernButton(sidebar, label, 200, 28)
		button:SetPoint("TOP", sidebar, "TOP", 0, y)
		button:SetScript("OnClick", function()
			SelectCategory(entry)
		end)
		entry.button = button
		settingsCategories[#settingsCategories + 1] = entry

		y = y - 34
	end

	if settingsCategories[1] then
		SelectCategory(settingsCategories[1])
	end
end

------------------------------------------------------------
-- Public toggle + slash command
------------------------------------------------------------

function SennyinQoL:ToggleSettings()
	BuildCategories()

	if frame:IsShown() then
		frame:Hide()
		return
	end

	if currentEntry then
		SelectCategory(currentEntry)
	end

	frame:Show()
end

SLASH_SENNYINQOL1 = "/sennui"
SLASH_SENNYINQOL2 = "/sqol"
SlashCmdList["SENNYINQOL"] = function()
	SennyinQoL:ToggleSettings()
end

------------------------------------------------------------
-- Blizzard AddOns > Options Launcher
------------------------------------------------------------

local launcherPanel = CreateFrame("Frame")
launcherPanel.name = "SennyinQoL"

local launcherButton = CreateFrame("Button", nil, launcherPanel, "UIPanelButtonTemplate")
launcherButton:SetSize(200, 24)
launcherButton:SetPoint("TOPLEFT", 16, -16)
launcherButton:SetText("Open SennyinQoL Settings")
launcherButton:SetScript("OnClick", function()
	SennyinQoL:ToggleSettings()
end)

local launcherDesc = launcherPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
launcherDesc:SetPoint("TOPLEFT", launcherButton, "BOTTOMLEFT", 0, -12)
launcherDesc:SetPoint("RIGHT", -16, 0)
launcherDesc:SetJustifyH("LEFT")
launcherDesc:SetText(
	"SennyinQoL uses its own settings window. Click the button above, or type /sennui or /sqol, to open it."
)

local launcherCategory = Settings.RegisterCanvasLayoutCategory(launcherPanel, launcherPanel.name)
launcherCategory.ID = launcherPanel.name
Settings.RegisterAddOnCategory(launcherCategory)
