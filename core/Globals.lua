SennyinQoL = SennyinQoL or {}

------------------------------------------------------------
-- Shared color helpers
------------------------------------------------------------

function SennyinQoL:GetPlayerColor(unit)
	if not UnitIsPlayer(unit) then
		return nil
	end

	local _, classFile = UnitClass(unit)

	return C_ClassColor.GetClassColor(classFile)
end

function SennyinQoL:GetReactionColor(unit)
	local reaction = UnitReaction(unit, "player")

	if not reaction then
		return nil
	end

	if reaction >= 5 then
		return CreateColor(0, 1, 0) -- Friendly (Green)
	elseif reaction == 4 then
		return CreateColor(1, 1, 0) -- Neutral (Yellow)
	else
		return CreateColor(1, 0, 0) -- Hostile (Red)
	end
end
