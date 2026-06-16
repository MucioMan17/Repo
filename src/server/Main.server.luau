-- Server entry point. Wires up the systems and validates every client request.
-- The client can ASK to join a family; the server decides whether that's allowed.
-- Authoritative player data lives in PlayerData; territory logic in Territory.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Families = require(Shared:WaitForChild("Families"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local PlayerData = require(script.Parent:WaitForChild("PlayerData"))
local Territory = require(script.Parent:WaitForChild("Territory"))

local joinFamily = Remotes.event("JoinFamily")
local requestState = Remotes.event("RequestState")

local function findFamily(id)
	for _, family in ipairs(Families) do
		if family.id == id then
			return family
		end
	end
	return nil
end

Players.PlayerAdded:Connect(function(player)
	PlayerData.create(player)
	PlayerData.push(player)
end)

Players.PlayerRemoving:Connect(function(player)
	PlayerData.remove(player)
end)

-- The client asks for its state on startup (covers any join-timing races).
requestState.OnServerEvent:Connect(function(player)
	PlayerData.push(player)
end)

-- The client requests to join a family -> the server validates it.
joinFamily.OnServerEvent:Connect(function(player, familyId)
	local profile = PlayerData.get(player)
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

	PlayerData.setFamily(player, family.id)
	print(player.Name .. " joined the " .. family.name .. " family")
end)

Territory.start()
