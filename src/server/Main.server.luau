-- Server entry point. Owns the authoritative player data and validates every
-- request the client makes. The client can ASK to join a family; the server
-- decides whether that's allowed. This is the pattern that keeps the game
-- cheat-resistant: the client never decides anything important.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Families = require(Shared:WaitForChild("Families"))
local Ranks = require(Shared:WaitForChild("Ranks"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local joinFamily = Remotes.event("JoinFamily")
local stateUpdate = Remotes.event("StateUpdate")
local requestState = Remotes.event("RequestState")

-- In-memory profiles for now. Swap this for a DataStore later so progress saves.
local profiles = {}

local function findFamily(id)
	for _, family in ipairs(Families) do
		if family.id == id then
			return family
		end
	end
	return nil
end

-- Send a player their current state so the client UI can refresh.
local function sendState(player)
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

Players.PlayerAdded:Connect(function(player)
	profiles[player] = {
		familyId = nil,
		reputation = 0,
		money = 0,
	}
	sendState(player)
end)

Players.PlayerRemoving:Connect(function(player)
	profiles[player] = nil
end)

-- The client asks for its state on startup (covers any join-timing races).
requestState.OnServerEvent:Connect(function(player)
	sendState(player)
end)

-- The client requests to join a family -> the server validates it.
joinFamily.OnServerEvent:Connect(function(player, familyId)
	local profile = profiles[player]
	if not profile then
		return
	end
	if type(familyId) ~= "string" then
		return -- malformed request, ignore it
	end
	if profile.familyId ~= nil then
		return -- already in a family (no switching for now)
	end
	local family = findFamily(familyId)
	if not family then
		return -- unknown family id
	end

	profile.familyId = family.id
	sendState(player)
	print(player.Name .. " joined the " .. family.name .. " family")
end)
