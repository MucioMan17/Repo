-- Client entry point. Pure UI + input: it shows the family picker and the HUD,
-- and ASKS the server to do things via RemoteEvents. It never decides truth.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Families = require(Shared:WaitForChild("Families"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local joinFamily = Remotes.event("JoinFamily")
local stateUpdate = Remotes.event("StateUpdate")
local requestState = Remotes.event("RequestState")
local territoryUpdate = Remotes.event("TerritoryUpdate")

local function familyName(id)
	for _, family in ipairs(Families) do
		if family.id == id then
			return family.name
		end
	end
	return "Unaffiliated"
end

-- ----------------------------------------------------------------------------
-- UI
-- ----------------------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "MafiaUI"
gui.ResetOnSpawn = false
gui.Parent = playerGui

-- HUD shown once you're in a family
local hud = Instance.new("TextLabel")
hud.Name = "HUD"
hud.Position = UDim2.new(0, 12, 0, 12)
hud.Size = UDim2.new(0, 260, 0, 64)
hud.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
hud.BackgroundTransparency = 0.2
hud.TextColor3 = Color3.fromRGB(235, 235, 235)
hud.Font = Enum.Font.GothamMedium
hud.TextSize = 14
hud.TextXAlignment = Enum.TextXAlignment.Left
hud.TextYAlignment = Enum.TextYAlignment.Top
hud.Visible = false
hud.Text = ""
hud.Parent = gui

local hudCorner = Instance.new("UICorner")
hudCorner.CornerRadius = UDim.new(0, 8)
hudCorner.Parent = hud

local hudPad = Instance.new("UIPadding")
hudPad.PaddingLeft = UDim.new(0, 10)
hudPad.PaddingTop = UDim.new(0, 8)
hudPad.Parent = hud

-- Family picker shown until you join one
local picker = Instance.new("Frame")
picker.Name = "Picker"
picker.AnchorPoint = Vector2.new(0.5, 0.5)
picker.Position = UDim2.new(0.5, 0, 0.5, 0)
picker.Size = UDim2.new(0, 320, 0, 0)
picker.AutomaticSize = Enum.AutomaticSize.Y
picker.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
picker.Parent = gui

local pickerCorner = Instance.new("UICorner")
pickerCorner.CornerRadius = UDim.new(0, 10)
pickerCorner.Parent = picker

local pickerPad = Instance.new("UIPadding")
pickerPad.PaddingTop = UDim.new(0, 12)
pickerPad.PaddingBottom = UDim.new(0, 12)
pickerPad.PaddingLeft = UDim.new(0, 12)
pickerPad.PaddingRight = UDim.new(0, 12)
pickerPad.Parent = picker

local pickerList = Instance.new("UIListLayout")
pickerList.Padding = UDim.new(0, 8)
pickerList.SortOrder = Enum.SortOrder.LayoutOrder
pickerList.HorizontalAlignment = Enum.HorizontalAlignment.Center
pickerList.Parent = picker

local title = Instance.new("TextLabel")
title.LayoutOrder = 0
title.BackgroundTransparency = 1
title.Size = UDim2.new(1, 0, 0, 32)
title.Text = "Choose your Family"
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.TextColor3 = Color3.fromRGB(235, 235, 235)
title.Parent = picker

for index, family in ipairs(Families) do
	local btn = Instance.new("TextButton")
	btn.Name = family.id
	btn.LayoutOrder = index
	btn.Size = UDim2.new(1, 0, 0, 38)
	btn.BackgroundColor3 = family.color
	btn.AutoButtonColor = true
	btn.Text = family.name
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 16
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.Parent = picker

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 6)
	btnCorner.Parent = btn

	btn.Activated:Connect(function()
		joinFamily:FireServer(family.id)
	end)
end

-- ----------------------------------------------------------------------------
-- React to server state
-- ----------------------------------------------------------------------------
stateUpdate.OnClientEvent:Connect(function(state)
	if state.familyId then
		picker.Visible = false
		hud.Visible = true
		hud.Text = string.format(
			"Family: %s\nRank: %s\nReputation: %d    Money: $%d",
			familyName(state.familyId), state.rank, state.reputation, state.money
		)
	else
		picker.Visible = true
		hud.Visible = false
	end
end)

-- Toast notification (used for territory captures)
local function toast(text)
	local label = Instance.new("TextLabel")
	label.AnchorPoint = Vector2.new(0.5, 1)
	label.Position = UDim2.new(0.5, 0, 1, -24)
	label.Size = UDim2.new(0, 440, 0, 36)
	label.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	label.BackgroundTransparency = 0.2
	label.TextColor3 = Color3.fromRGB(235, 235, 235)
	label.Font = Enum.Font.GothamMedium
	label.TextSize = 15
	label.Text = text
	label.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = label

	task.delay(4, function()
		label:Destroy()
	end)
end

territoryUpdate.OnClientEvent:Connect(function(info)
	if info.kind == "captured" then
		toast(string.format("The %s family captured %s!", info.family, info.territory))
	end
end)

-- Ask for our state now that we're listening
requestState:FireServer()
