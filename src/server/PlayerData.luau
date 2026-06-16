-- Authoritative per-player data, shared by all server systems.
-- Requiring this module anywhere on the server returns the SAME instance, so
-- the `profiles` table is the single source of truth. (Swap the table for a
-- DataStore later to make progress save between sessions.)
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Ranks = require(Shared:WaitForChild("Ranks"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local stateUpdate = Remotes.event("StateUpdate")

local PlayerData = {}
local profiles = {}

function PlayerData.create(player)
	profiles[player] = {
		familyId = nil,
		reputation = 0,
		money = 0,
	}
	return profiles[player]
end

function PlayerData.get(player)
	return profiles[player]
end

function PlayerData.remove(player)
	profiles[player] = nil
end

-- Push the player's current state to their client so the HUD can refresh.
function PlayerData.push(player)
	local profile = profiles[player]
	if not profile then
		return
	end
	local rank = Ranks.forReputation(profile.reputation)
	stateUpdate:FireClient(player, {
		familyId = profile.familyId,
		reputation = profile.reputation,
		money = profile.money,
		rank = rank.name,
	})
end

function PlayerData.setFamily(player, familyId)
	local profile = profiles[player]
	if not profile then
		return
	end
	profile.familyId = familyId
	PlayerData.push(player)
end

-- Grant reputation and/or money, then refresh the client.
function PlayerData.addReward(player, reputation, money)
	local profile = profiles[player]
	if not profile then
		return
	end
	profile.reputation += reputation
	profile.money += money
	PlayerData.push(player)
end

return PlayerData
