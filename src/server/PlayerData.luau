-- Authoritative per-player data, shared by all server systems.
-- Requiring this module anywhere on the server returns the SAME instance, so
-- the `profiles` table is the single source of truth. Backed by DataStore so
-- progress saves, and mirrored to leaderstats so it shows in the player list.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Ranks = require(Shared:WaitForChild("Ranks"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local DataStore = require(script.Parent:WaitForChild("DataStore"))

local stateUpdate = Remotes.event("StateUpdate")
local notify = Remotes.event("Notify")

local PlayerData = {}
local profiles = {}

local function updateLeaderstats(player, profile)
	local stats = player:FindFirstChild("leaderstats")
	if not stats then
		return
	end
	local rep = stats:FindFirstChild("Reputation")
	local money = stats:FindFirstChild("Money")
	local rank = stats:FindFirstChild("Rank")
	if rep then
		rep.Value = profile.reputation
	end
	if money then
		money.Value = profile.money
	end
	if rank then
		rank.Value = Ranks.forReputation(profile.reputation).name
	end
end

local function snapshot(profile)
	return {
		familyId = profile.familyId,
		reputation = profile.reputation,
		money = profile.money,
	}
end

function PlayerData.create(player)
	-- Load saved data (yields if DataStores are available).
	local saved = DataStore.load(player.UserId)
	if not player.Parent then
		return -- player left while we were loading
	end

	local profile = {
		familyId = (saved and saved.familyId) or nil,
		reputation = (saved and saved.reputation) or 0,
		money = (saved and saved.money) or 0,
	}
	profiles[player] = profile

	-- leaderstats (shows in the Roblox player list, top-right)
	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	local rep = Instance.new("IntValue")
	rep.Name = "Reputation"
	rep.Parent = stats
	local money = Instance.new("IntValue")
	money.Name = "Money"
	money.Parent = stats
	local rank = Instance.new("StringValue")
	rank.Name = "Rank"
	rank.Parent = stats
	stats.Parent = player

	updateLeaderstats(player, profile)
	PlayerData.push(player)
	return profile
end

function PlayerData.get(player)
	return profiles[player]
end

function PlayerData.remove(player)
	local profile = profiles[player]
	if profile then
		DataStore.save(player.UserId, snapshot(profile))
	end
	profiles[player] = nil
end

-- Push the player's current state to their client so the HUD can refresh.
function PlayerData.push(player)
	local profile = profiles[player]
	if not profile then
		return
	end
	updateLeaderstats(player, profile)
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

-- Grant reputation and/or money, announce promotions, refresh the client.
function PlayerData.addReward(player, reputation, money)
	local profile = profiles[player]
	if not profile then
		return
	end
	local oldRank = Ranks.forReputation(profile.reputation).name
	profile.reputation += reputation
	profile.money += money
	local newRank = Ranks.forReputation(profile.reputation).name
	if newRank ~= oldRank then
		notify:FireClient(player, "You've been promoted to " .. newRank .. "!")
	end
	PlayerData.push(player)
end

-- Save everyone (used on server shutdown).
function PlayerData.saveAll()
	for player, profile in pairs(profiles) do
		DataStore.save(player.UserId, snapshot(profile))
	end
end

return PlayerData
