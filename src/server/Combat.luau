-- Server-authoritative melee combat.
-- The client only ASKS to attack (a click). The server decides whether there's
-- a valid rival in range, applies the damage, enforces the cooldown, and pays
-- out kills. Nothing about damage or kills is trusted to the client.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes"))

local PlayerData = require(script.Parent:WaitForChild("PlayerData"))

local attackEvent = Remotes.event("Attack")
local notify = Remotes.event("Notify")

-- Tuning
local RANGE = 9          -- studs you can hit from
local DAMAGE = 25        -- damage per hit
local COOLDOWN = 0.7     -- seconds between your hits
local KILL_REP = 30      -- reputation for a kill
local KILL_MONEY = 50    -- money for a kill

local lastAttack = {} -- [player] = os.clock()

local function aliveParts(player)
	local char = player.Character
	if not char then
		return nil
	end
	local humanoid = char:FindFirstChildOfClass("Humanoid")
	local root = char:FindFirstChild("HumanoidRootPart")
	if humanoid and root and humanoid.Health > 0 then
		return humanoid, root
	end
	return nil
end

-- Nearest living rival (not in your family) within RANGE.
local function findTarget(attacker, attackerRoot, attackerFamily)
	local bestPlayer, bestHumanoid, bestDist = nil, nil, RANGE
	for _, other in ipairs(Players:GetPlayers()) do
		if other ~= attacker then
			local profile = PlayerData.get(other)
			local humanoid, root = aliveParts(other)
			if humanoid and (not profile or profile.familyId ~= attackerFamily) then
				local dist = (root.Position - attackerRoot.Position).Magnitude
				if dist <= bestDist then
					bestPlayer, bestHumanoid, bestDist = other, humanoid, dist
				end
			end
		end
	end
	return bestPlayer, bestHumanoid
end

attackEvent.OnServerEvent:Connect(function(attacker)
	local profile = PlayerData.get(attacker)
	if not profile or not profile.familyId then
		return -- you must be in a family to fight
	end

	local now = os.clock()
	if lastAttack[attacker] and (now - lastAttack[attacker]) < COOLDOWN then
		return -- still on cooldown
	end

	local humanoid, root = aliveParts(attacker)
	if not humanoid then
		return
	end
	lastAttack[attacker] = now

	local targetPlayer, targetHumanoid = findTarget(attacker, root, profile.familyId)
	if targetPlayer and targetHumanoid then
		targetHumanoid:TakeDamage(DAMAGE)
		if targetHumanoid.Health <= 0 then
			PlayerData.addReward(attacker, KILL_REP, KILL_MONEY)
			notify:FireClient(attacker, "You took out " .. targetPlayer.DisplayName .. "!")
		end
	end
end)

Players.PlayerRemoving:Connect(function(player)
	lastAttack[player] = nil
end)

return {}
