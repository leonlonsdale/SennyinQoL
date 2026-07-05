SennyinQoL = SennyinQoL or {}

------------------------------------------------------------
-- Borders
------------------------------------------------------------

function SennyinQoL:AddBorder(frame, inset)
	inset = inset or 1

	local border = CreateFrame("Frame", nil, frame, "BackdropTemplate")

	border:SetPoint("TOPLEFT", -inset, inset)
	border:SetPoint("BOTTOMRIGHT", inset, -inset)

	border:SetBackdrop({
		edgeFile = "Interface\\Buttons\\WHITE8X8",
		edgeSize = inset,
	})

	border:SetBackdropBorderColor(0, 0, 0, 1)

	return border
end

------------------------------------------------------------
-- Icon layout helpers
------------------------------------------------------------

function SennyinQoL:GetVisibleIcons(container)
	local icons = {}

	for _, child in ipairs({ container:GetChildren() }) do
		if child and child:IsShown() and child.Icon then
			icons[#icons + 1] = child
		end
	end

	table.sort(icons, function(a, b)
		return (a.layoutIndex or 0) < (b.layoutIndex or 0)
	end)

	return icons
end

------------------------------------------------------------
-- Segmented bars (e.g. class resource / combo point style trackers)
------------------------------------------------------------

function SennyinQoL:UpdateSegments(pool, container, current, max, color, opts)
	if not max or max <= 0 then
		return
	end

	opts = opts or {}
	local spacing = opts.spacing or 2
	local inset = opts.inset or 2

	local width = container:GetWidth()
	local segmentWidth = (width - ((max - 1) * spacing)) / max
	local height = container:GetHeight()

	for i = 1, max do
		local segment = pool[i]

		if not segment then
			segment = CreateFrame("Frame", nil, container, "BackdropTemplate")

			segment:SetBackdrop({
				edgeFile = "Interface\\Buttons\\WHITE8X8",
				edgeSize = 1,
			})
			segment:SetBackdropBorderColor(0, 0, 0, 1)

			segment.bg = segment:CreateTexture(nil, "BACKGROUND")
			segment.bg:SetAllPoints()
			segment.bg:SetColorTexture(0, 0, 0, 0.5)

			segment.tex = segment:CreateTexture(nil, "ARTWORK")
			segment.tex:SetPoint("TOPLEFT", inset, -inset)
			segment.tex:SetPoint("BOTTOMRIGHT", -inset, inset)

			pool[i] = segment
		end

		segment.tex:SetColorTexture(color[1], color[2], color[3], color[4] or 1)
		segment:SetSize(segmentWidth, height)
		segment:ClearAllPoints()

		if i == 1 then
			segment:SetPoint("LEFT", container, "LEFT")
		else
			segment:SetPoint("LEFT", pool[i - 1], "RIGHT", spacing, 0)
		end

		segment.tex:SetShown(i <= current)
		segment:Show()
	end

	for i = max + 1, #pool do
		pool[i]:Hide()
	end
end

------------------------------------------------------------
-- Anchoring
------------------------------------------------------------

function SennyinQoL:AnchorToFirstVisible(frame, candidateFrameNames, gap, opts)
	opts = opts or {}

	local matchWidth = opts.matchWidth
	if matchWidth == nil then
		matchWidth = true
	end

	for _, name in ipairs(candidateFrameNames) do
		local candidate = _G[name]

		if candidate and candidate:IsVisible() then
			frame:ClearAllPoints()
			frame:SetPoint("BOTTOM", candidate, "TOP", 0, gap or 5)

			if matchWidth then
				local width = candidate:GetWidth()

				if name == "EssentialCooldownViewer" then
					local spacing = math.abs(candidate.childXPadding or 4)
					width = width - (spacing * 2)
				end

				frame:SetWidth(width)
			end

			return candidate
		end
	end

	local fallback = opts.fallback

	if fallback then
		frame:ClearAllPoints()
		frame:SetPoint(
			fallback.point or "CENTER",
			fallback.relativeTo or UIParent,
			fallback.relativePoint or fallback.point or "CENTER",
			fallback.x or 0,
			fallback.y or 0
		)

		if fallback.width then
			frame:SetWidth(fallback.width)
		end
	end

	return nil
end

------------------------------------------------------------
-- Debouncing
------------------------------------------------------------

local pendingDefers = {}

function SennyinQoL:Debounce(key, fn)
	if pendingDefers[key] then
		return
	end

	pendingDefers[key] = true

	C_Timer.After(0, function()
		pendingDefers[key] = nil
		fn()
	end)
end
