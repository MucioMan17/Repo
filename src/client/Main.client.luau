-- Client entry point. Pure UI + input: it shows the family picker, the HUD, and
-- a live territory scoreboard, and ASKS the server to do things via RemoteEvents.
-- It never decides anything important -- the server owns all the truth.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Families = require(Shared:WaitForChild("Families"))
local Territories = require(Shared:WaitForChild("Territories"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local joinFamily = Remotes.event("JoinFamily")
local stateUpdate = Remotes.event("StateUpdate")
local requestState = Remotes.event("RequestState")
local territoryUpdate = Remotes.event("TerritoryUpdate")
local territoryState = Remotes.event("TerritoryState")
local notify = Remotes.event("Notify")
local attack = Remotes.event("Attack")

local NEUTRAL = Color3.fromRGB(170, 170, 170)

local function familyName(id)
	for _, family in ipairs(Families) do
		if family.id == id then
			return family.name
		end
	end
	return "Unaffiliated"
end

local function familyColor(id)
	for _, family in ipairs(Families) do
		if family.id == id then
			return family.color
		end
	end
	return NEUTRAL
end

local function corner(instance, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 8)
	c.Parent = instance
	return c
end

-- ----------------------------------------------------------------------------
-- GUI root
-- ----------------------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "MafiaUI"
gui.ResetOnSpawn = false
gui.Parent = playerGui

-- ---- Player HUD (top-left, shown once you're in a family) ----
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
corner(hud)
local hudPad = Instance.new("UIPadding")
hudPad.PaddingLeft = UDim.new(0, 10)
hudPad.PaddingTop = UDim.new(0, 8)
hudPad.Parent = hud

-- ---- Territory scoreboard (top-right, always shown) ----
local board = Instance.new("Frame")
board.Name = "Territories"
board.AnchorPoint = Vector2.new(1, 0)
board.Position = UDim2.new(1, -12, 0, 12)
board.Size = UDim2.new(0, 220, 0, 0)
board.AutomaticSize = Enum.AutomaticSize.Y
board.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
board.BackgroundTransparency = 0.2
board.Parent = gui
corner(board)
local boardPad = Instance.new("UIPadding")
boardPad.PaddingTop = UDim.new(0, 8)
boardPad.PaddingBottom = UDim.new(0, 8)
boardPad.PaddingLeft = UDim.new(0, 10)
boardPad.PaddingRight = UDim.new(0, 10)
boardPad.Parent = board
local boardList = Instance.new("UIListLayout")
boardList.Padding = UDim.new(0, 6)
boardList.SortOrder = Enum.SortOrder.LayoutOrder
boardList.Parent = board

local boardTitle = Instance.new("TextLabel")
boardTitle.LayoutOrder = 0
boardTitle.BackgroundTransparency = 1
boardTitle.Size = UDim2.new(1, 0, 0, 16)
boardTitle.Font = Enum.Font.GothamBold
boardTitle.TextSize = 12
boardTitle.TextColor3 = Color3.fromRGB(170, 170, 180)
boardTitle.TextXAlignment = Enum.TextXAlignment.Left
boardTitle.Text = "TERRITORY"
boardTitle.Parent = board

local rowById = {}
for index, def in ipairs(Territories) do
	local row = Instance.new("Frame")
	row.LayoutOrder = index
	row.Size = UDim2.new(1, 0, 0, 38)
	row.BackgroundTransparency = 1
	row.Parent = board

	local name = Instance.new("TextLabel")
	name.BackgroundTransparency = 1
	name.Position = UDim2.new(0, 0, 0, 0)
	name.Size = UDim2.new(1, 0, 0, 16)
	name.Font = Enum.Font.GothamMedium
	name.TextSize = 14
	name.TextColor3 = Color3.fromRGB(235, 235, 235)
	name.TextXAlignment = Enum.TextXAlignment.Left
	name.Text = def.name
	name.Parent = row

	local owner = Instance.new("TextLabel")
	owner.BackgroundTransparency = 1
	owner.Position = UDim2.new(0, 0, 0, 16)
	owner.Size = UDim2.new(1, 0, 0, 14)
	owner.Font = Enum.Font.Gotham
	owner.TextSize = 12
	owner.TextColor3 = NEUTRAL
	owner.TextXAlignment = Enum.TextXAlignment.Left
	owner.Text = "Neutral"
	owner.Parent = row

	local bar = Instance.new("Frame")
	bar.Position = UDim2.new(0, 0, 1, -4)
	bar.Size = UDim2.new(1, 0, 0, 4)
	bar.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
	bar.BorderSizePixel = 0
	bar.Visible = false
	bar.Parent = row
	corner(bar, 2)

	local fill = Instance.new("Frame")
	fill.Size = UDim2.new(0, 0, 1, 0)
	fill.BackgroundColor3 = NEUTRAL
	fill.BorderSizePixel = 0
	fill.Parent = bar
	corner(fill, 2)

	rowById[def.id] = { owner = owner, bar = bar, fill = fill }
end

-- ---- Family picker (center, shown until you join one) ----
local picker = Instance.new("Frame")
picker.Name = "Picker"
picker.AnchorPoint = Vector2.new(0.5, 0.5)
picker.Position = UDim2.new(0.5, 0, 0.5, 0)
picker.Size = UDim2.new(0, 320, 0, 0)
picker.AutomaticSize = Enum.AutomaticSize.Y
picker.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
picker.Parent = gui
corner(picker, 10)
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

local pickerTitle = Instance.new("TextLabel")
pickerTitle.LayoutOrder = 0
pickerTitle.BackgroundTransparency = 1
pickerTitle.Size = UDim2.new(1, 0, 0, 32)
pickerTitle.Text = "Choose your Family"
pickerTitle.Font = Enum.Font.GothamBold
pickerTitle.TextSize = 18
pickerTitle.TextColor3 = Color3.fromRGB(235, 235, 235)
pickerTitle.Parent = picker

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
	corner(btn, 6)
	btn.Activated:Connect(function()
		joinFamily:FireServer(family.id)
	end)
end

-- ---- Toast notifications (captures + promotions) ----
local function toast(text)
	local label = Instance.new("TextLabel")
	label.AnchorPoint = Vector2.new(0.5, 1)
	label.Position = UDim2.new(0.5, 0, 1, -24)
	label.Size = UDim2.new(0, 460, 0, 36)
	label.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	label.BackgroundTransparency = 0.2
	label.TextColor3 = Color3.fromRGB(235, 235, 235)
	label.Font = Enum.Font.GothamMedium
	label.TextSize = 15
	label.Text = text
	label.Parent = gui
	corner(label)
	task.delay(4, function()
		label:Destroy()
	end)
end

-- ----------------------------------------------------------------------------
-- React to the server
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

territoryState.OnClientEvent:Connect(function(zones)
	for _, zone in ipairs(zones) do
		local row = rowById[zone.id]
		if row then
			if zone.owner then
				row.owner.Text = familyName(zone.owner)
				row.owner.TextColor3 = familyColor(zone.owner)
			else
				row.owner.Text = "Neutral"
				row.owner.TextColor3 = NEUTRAL
			end
			if zone.capturing and zone.progress > 0 then
				row.bar.Visible = true
				row.fill.Size = UDim2.new(math.clamp(zone.progress / 100, 0, 1), 0, 1, 0)
				row.fill.BackgroundColor3 = familyColor(zone.capturing)
			else
				row.bar.Visible = false
			end
		end
	end
end)

territoryUpdate.OnClientEvent:Connect(function(info)
	if info.kind == "captured" then
		toast(string.format("The %s family captured %s!", info.family, info.territory))
	end
end)

notify.OnClientEvent:Connect(function(text)
	toast(text)
end)

-- ---- Combat input: click to swing at a nearby rival (server validates) ----
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
		attack:FireServer()
	end
end)

-- Ask for our state now that we're listening
requestState:FireServer()
