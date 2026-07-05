local M = SennyinQoL:NewModule("Commands")

local CommandMap = {
	rl = { cmd = "/reload", label = "Enable /rl (Reload UI)" },
	lg = { cmd = "/leaveparty", label = "Enable /lg (Leave Group)" },
	rc = { cmd = "/readycheck", label = "Enable /rc (Ready Check)" },
}

M.defaults = {}
M.settings = {
	name = "Commands",
	heading = "Slash Command Shortcuts",
	settings = {},
}

local isFirst = true

for key, data in pairs(CommandMap) do
	M.defaults[key] = true

	local function ToggleCommand(enabled)
		local globalName = "SENNYINQOL_" .. key:upper()

		if enabled then
			_G["SLASH_" .. globalName .. "1"] = "/" .. key
			SlashCmdList[globalName] = function()
				local editBox = ChatEdit_GetActiveWindow() or ChatFrame1EditBox
				ChatEdit_ActivateChat(editBox)
				editBox:SetText(data.cmd)
				ChatEdit_SendText(editBox)
				ChatEdit_DeactivateChat(editBox)
			end
		else
			SlashCmdList[globalName] = function() end
		end
	end

	M.settings.settings[key] = {
		label = data.label,
		default = true,
		callback = ToggleCommand,
	}

	isFirst = false
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function()
	for key in pairs(CommandMap) do
		M.settings.settings[key].callback(M:Get(key, M.defaults[key]))
	end
end)
