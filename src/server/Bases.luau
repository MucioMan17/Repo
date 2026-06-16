-- Family bases (HQs) + family-based spawning.
--   * Spawns a colored HQ platform for each family (visible, stood-on).
--   * When you join a family you're sent to your HQ, and you respawn there
--     after dying. Players with no family use the default spawn.
-- All positions come from Families.luau (`base`), so there's nothing to build.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Families = require(Shared:WaitForChild("Families"))

local PlayerData = require(script.Parent:WaitForChild("PlayerData"))

local Bases = {}

local SPAWN_HEIGHT = 4 -- studs above the pad to drop players in at
local SPREAD = 6       -- random spawn scatter so members don't stack

local function familyDef(id)
	for _, family in ipairs(Families) do
		if family.id == id then
			return family
		end
	end
	return nil
end

local function spawnPad(def)
	local pad = Instance.new("Part")
	pad.Name = "Base_" .. def.id
	pad.Anchored = true
	pad.Size = Vector3.new(28, 1, 28)
	pad.Position = def.base + Vector3.new(0, 0.5, 0)
	pad.Color = def.color
	pad.Material = Enum.Material.SmoothPlastic
	pad.TopSurface = Enum.SurfaceType.Smooth
	pad.Parent = Workspace

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "Label"
	billboard.Adornee = pad
	billboard.AlwaysOnTop = true
	billboard.Size = UDim2.new(0, 200, 0, 28)
	billboard.StudsOffset = Vector3.new(0, 8, 0)
	billboard.Parent = pad

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(1, 0, 1, 0)
	label.Font = Enum.Font.GothamBold
	label.TextSize = 16
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextStrokeTransparency = 0.4
	label.Text = def.name .. " HQ"
	label.Parent = billboard
end

-- Teleport a player to their family's HQ (no-op if they have no family).
function Bases.sendToBase(player)
	local profile = PlayerData.get(player)
	if not profile or not profile.familyId then
		return
	end
	local def = familyDef(profile.familyId)
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not (def and def.base and root) then
		return
	end
	local offset = Vector3.new(math.random(-SPREAD, SPREAD), SPAWN_HEIGHT, math.random(-SPREAD, SPREAD))
	root.CFrame = CFrame.new(def.base + offset)
end

local function hook(player)
	player.CharacterAdded:Connect(function(char)
		char:WaitForChild("HumanoidRootPart", 5)
		task.wait(0.1) -- let the default spawn finish first
		Bases.sendToBase(player)
	end)
end

function Bases.start()
	for _, def in ipairs(Families) do
		if def.base then
			spawnPad(def)
		end
	end
	for _, player in ipairs(Players:GetPlayers()) do
		hook(player)
		if player.Character then
			Bases.sendToBase(player)
		end
	end
	Players.PlayerAdded:Connect(hook)
end

return Bases
