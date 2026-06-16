-- Mafia rank ladder, lowest to highest.
-- `rep` is the total reputation a player needs to reach that rank.
local Ranks = {}

Ranks.Ladder = {
	{ name = "Associate",   rep = 0 },
	{ name = "Soldier",     rep = 100 },
	{ name = "Capo",        rep = 300 },
	{ name = "Consigliere", rep = 600 },
	{ name = "Underboss",   rep = 1000 },
	{ name = "Boss",        rep = 1500 },
}

-- Returns the highest rank the given reputation qualifies for.
function Ranks.forReputation(rep)
	local current = Ranks.Ladder[1]
	for _, rank in ipairs(Ranks.Ladder) do
		if rep >= rank.rep then
			current = rank
		else
			break
		end
	end
	return current
end

return Ranks
