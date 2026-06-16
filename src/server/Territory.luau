-- Server-authoritative territory control.
--   * Spawns a visible disc marker for each zone (so it's testable with no map).
--   * Every tick, finds who is standing in each zone.
--   * If only ONE family is present, they capture it; capturing grants
--     reputation, and HOLDING a captured zone pays money + a little rep.
--   * If two+ families are present, the zone is contested and progress freezes.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Territories = require(Shared:WaitForChild("Territories"))
local Families = require(Shared:WaitForChild("Families"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local PlayerData = require(script.Parent:WaitForChild("PlayerData"))

local territoryUpdate = Remotes.event("TerritoryUpdate")
local territoryState = Remotes.event("TerritoryState")

-- Tuning (tweak freely)
local TICK = 1               -- seconds between updates
local CAPTURE_PER_TICK = 25  -- capture progress a lone family adds per tick (100 = captured)
local DECAY_PER_TICK = 10    -- progress lost per tick when the zone is empty
local CAPTURE_REP = 50       -- reputation each capturer gets when a zone flips
local HOLD_MONEY = 10        -- money per tick to each member holding their zone
local HOLD_REP = 2           -- reputation per tick to each member holding their zone

local NEUTRAL_COLOR = Color3.fromRGB(120, 120, 120)

local Territory = {}
local zones = {} -- [id] = { owner, progress, capturing, part }

local function familyColor(id)
	for _, family in ipairs(Families) do
		if family.id == id then
			return family.color
		end
	end
	return NEUTRAL_COLOR
end

local function familyName(id)
	for _, family in ipairs(Families) do
		if family.id == id then
			return family.name
		end
	end
	return "Nobody"
end

-- A flat translucent disc on the ground marking the zone.
local function spawnMarker(def)
	local part = Instance.new("Part")
	part.Name = "Territory_" .. def.id
	part.Anchored = true
	part.CanCollide = false
	part.Shape = Enum.PartType.Cylinder
	-- Cylinders run along their X axis; rotate so it lies flat as a disc.
	part.Size = Vector3.new(1, def.radius * 2, def.radius * 2)
	part.CFrame = CFrame.new(def.position) * CFrame.Angles(0, 0, math.rad(90))
	part.Color = NEUTRAL_COLOR
	part.Material = Enum.Material.Neon
	part.Transparency = 0.6
	part.Parent = Workspace

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "Label"
	billboard.Adornee = part
	billboard.AlwaysOnTop = true
	billboard.Size = UDim2.new(0, 190, 0, 26)
	billboard.StudsOffset = Vector3.new(0, 6, 0)
	billboard.Parent = part

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(1, 0, 1, 0)
	label.Font = Enum.Font.GothamBold
	label.TextSize = 16
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextStrokeTransparency = 0.4
	label.Text = def.name
	label.Parent = billboard

	return part
end

-- Returns a map of familyId -> list of players standing in the zone.
local function occupantsByFamily(def)
	local byFamily = {}
	for _, player in ipairs(Players:GetPlayers()) do
		local profile = PlayerData.get(player)
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		local humanoid = char and char:FindFirstChildOfClass("Humanoid")
		if profile and profile.familyId and root and humanoid and humanoid.Health > 0 then
			local dx = root.Position.X - def.position.X
			local dz = root.Position.Z - def.position.Z
			if (dx * dx + dz * dz) <= def.radius * def.radius then
				byFamily[profile.familyId] = byFamily[profile.familyId] or {}
				table.insert(byFamily[profile.familyId], player)
			end
		end
	end
	return byFamily
end

local function tick()
	for _, def in ipairs(Territories) do
		local zone = zones[def.id]
		local byFamily = occupantsByFamily(def)

		local present = {}
		for familyId in pairs(byFamily) do
			table.insert(present, familyId)
		end

		if #present == 1 then
			local familyId = present[1]
			if zone.owner == familyId then
				-- Held by its owner: pay everyone defending it.
				zone.progress = 0
				zone.capturing = nil
				for _, player in ipairs(byFamily[familyId]) do
					PlayerData.addReward(player, HOLD_REP, HOLD_MONEY)
				end
			else
				-- A single other family is capturing it.
				if zone.capturing ~= familyId then
					zone.capturing = familyId
					zone.progress = 0
				end
				zone.progress += CAPTURE_PER_TICK
				if zone.progress >= 100 then
					zone.owner = familyId
					zone.progress = 0
					zone.capturing = nil
					zone.part.Color = familyColor(familyId)
					for _, player in ipairs(byFamily[familyId]) do
						PlayerData.addReward(player, CAPTURE_REP, 0)
					end
					territoryUpdate:FireAllClients({
						kind = "captured",
						territory = def.name,
						family = familyName(familyId),
					})
				end
			end
		elseif #present == 0 then
			-- Empty: a capture-in-progress slips back toward 0 (owner still holds).
			if zone.capturing then
				zone.progress = math.max(0, zone.progress - DECAY_PER_TICK)
				if zone.progress == 0 then
					zone.capturing = nil
				end
			end
		end
		-- #present >= 2 => contested: progress is frozen, nobody is paid.
	end

	-- Broadcast the full state so clients can show a live territory HUD.
	local snapshot = {}
	for _, def in ipairs(Territories) do
		local zone = zones[def.id]
		table.insert(snapshot, {
			id = def.id,
			owner = zone.owner,
			progress = zone.progress,
			capturing = zone.capturing,
		})
	end
	territoryState:FireAllClients(snapshot)
end

function Territory.start()
	for _, def in ipairs(Territories) do
		zones[def.id] = {
			owner = nil,
			progress = 0,
			capturing = nil,
			part = spawnMarker(def),
		}
	end

	task.spawn(function()
		while true do
			task.wait(TICK)
			tick()
		end
	end)
end

return Territory
