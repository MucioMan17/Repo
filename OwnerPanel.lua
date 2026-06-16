--[[
==============================================================================
    CLIENT-SIDED OWNER PANEL  (single copy-paste LocalScript)
==============================================================================

    WHAT THIS IS
        A small status HUD that shows which features are currently active.
        Each feature has a dot:  RED = off,  GREEN = on.
        You toggle features with hotkeys (there are no buttons by design).

    FEATURES
        Fly   -  press  F            (camera-relative; Space = up, Shift = down)
        ESP   -  press  E            (shows DisplayName + @username over players,
                                      visible through walls)
        Hide/show the panel  -  press  RightCtrl

    WHERE TO PUT IT
        Paste this whole script into a LocalScript inside:
            StarterPlayer  >  StarterPlayerScripts
        (A LocalScript is required - this is client-side code.)

    OWNER CHECK
        You said you'll handle who counts as the "owner" yourself.
        Do it in the isOwner() function just below. Return false and the
        whole panel never loads.

    NOTE ON SECURITY
        Everything here is client-only and only affects YOUR client (your own
        camera, your own movement, name tags only you can see). That's exactly
        what "client-sided" means and it's perfectly safe. If you later want
        powers that change the game for everyone (kick, give items, etc.) those
        MUST be done with RemoteEvents validated on the server, because the
        client can be tampered with.
==============================================================================
]]

--// Services
local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local Workspace        = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local playerGui   = LocalPlayer:WaitForChild("PlayerGui")

--==========================================================================
--  OWNER CHECK  --  put your own logic here. Return true to load the panel.
--  Example:  return LocalPlayer.UserId == game.CreatorId
--==========================================================================
local function isOwner()
	return true
end

if not isOwner() then
	return
end

--==========================================================================
--  CONFIG  --  edit keys / values here
--==========================================================================
local CONFIG = {
	FlyKey         = Enum.KeyCode.F,
	ESPKey         = Enum.KeyCode.E,
	PanelToggleKey = Enum.KeyCode.RightControl,
	FlySpeed       = 60,     -- studs per second
	ShowSelfESP    = false,  -- also tag your own character?
}

--// Status colours
local ON_COLOR  = Color3.fromRGB(70, 200, 95)   -- green
local OFF_COLOR = Color3.fromRGB(210, 60, 60)    -- red

--==========================================================================
--  STATUS PANEL (the HUD)
--==========================================================================
local gui = Instance.new("ScreenGui")
gui.Name = "OwnerStatus"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.Position = UDim2.new(0, 16, 0, 16)
panel.Size = UDim2.new(0, 176, 0, 0)
panel.AutomaticSize = Enum.AutomaticSize.Y
panel.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
panel.BackgroundTransparency = 0.05
panel.BorderSizePixel = 0
panel.Parent = gui

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 10)
panelCorner.Parent = panel

local panelPad = Instance.new("UIPadding")
panelPad.PaddingTop = UDim.new(0, 8)
panelPad.PaddingBottom = UDim.new(0, 8)
panelPad.PaddingLeft = UDim.new(0, 10)
panelPad.PaddingRight = UDim.new(0, 10)
panelPad.Parent = panel

local panelList = Instance.new("UIListLayout")
panelList.Padding = UDim.new(0, 6)
panelList.SortOrder = Enum.SortOrder.LayoutOrder
panelList.Parent = panel

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 16)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = 12
title.TextColor3 = Color3.fromRGB(150, 150, 160)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Text = "OWNER  •  STATUS"
title.LayoutOrder = 0
title.Parent = panel

-- Builds one "[dot]  Name        [Key]" row and returns a handle with setActive()
local rows = {}
local rowCount = 0
local function createRow(name, keyText)
	rowCount += 1

	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 22)
	row.BackgroundTransparency = 1
	row.LayoutOrder = rowCount
	row.Parent = panel

	local dot = Instance.new("Frame")
	dot.Size = UDim2.new(0, 12, 0, 12)
	dot.Position = UDim2.new(0, 0, 0.5, -6)
	dot.BackgroundColor3 = OFF_COLOR
	dot.BorderSizePixel = 0
	dot.Parent = row

	local dotCorner = Instance.new("UICorner")
	dotCorner.CornerRadius = UDim.new(1, 0)  -- perfect circle
	dotCorner.Parent = dot

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Position = UDim2.new(0, 20, 0, 0)
	label.Size = UDim2.new(1, -56, 1, 0)
	label.Font = Enum.Font.GothamMedium
	label.TextSize = 14
	label.TextColor3 = Color3.fromRGB(235, 235, 240)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Text = name
	label.Parent = row

	local keyHint = Instance.new("TextLabel")
	keyHint.BackgroundTransparency = 1
	keyHint.Position = UDim2.new(1, -40, 0, 0)
	keyHint.Size = UDim2.new(0, 40, 1, 0)
	keyHint.Font = Enum.Font.Gotham
	keyHint.TextSize = 12
	keyHint.TextColor3 = Color3.fromRGB(140, 140, 150)
	keyHint.TextXAlignment = Enum.TextXAlignment.Right
	keyHint.Text = "[" .. keyText .. "]"
	keyHint.Parent = row

	local handle = {
		setActive = function(on)
			dot.BackgroundColor3 = on and ON_COLOR or OFF_COLOR
		end,
	}
	rows[name] = handle
	return handle
end

createRow("Fly", CONFIG.FlyKey.Name)
createRow("ESP", CONFIG.ESPKey.Name)

-- Make the panel draggable
do
	local dragging, dragStart, startPos
	panel.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = panel.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			panel.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + delta.X,
				startPos.Y.Scale, startPos.Y.Offset + delta.Y
			)
		end
	end)
end

--==========================================================================
--  CHARACTER HELPERS
--==========================================================================
local function getHumanoid()
	local char = LocalPlayer.Character
	return char and char:FindFirstChildOfClass("Humanoid")
end

local function getRoot()
	local char = LocalPlayer.Character
	return char and char:FindFirstChild("HumanoidRootPart")
end

--==========================================================================
--  FEATURE: FLY
--==========================================================================
local flying = false
local flyConn

local function stopFly()
	flying = false
	if flyConn then
		flyConn:Disconnect()
		flyConn = nil
	end
	local hum = getHumanoid()
	if hum then
		hum.PlatformStand = false
	end
	rows.Fly.setActive(false)
end

local function startFly()
	local hum, root = getHumanoid(), getRoot()
	if not (hum and root) then
		return
	end
	flying = true
	hum.PlatformStand = true
	rows.Fly.setActive(true)

	flyConn = RunService.RenderStepped:Connect(function(dt)
		if not flying then
			return
		end
		local h, hrp = getHumanoid(), getRoot()
		if not (h and hrp) then
			return
		end

		local cam = Workspace.CurrentCamera
		local dir = Vector3.zero
		local function down(k)
			return UserInputService:IsKeyDown(k)
		end

		if down(Enum.KeyCode.W) then dir += cam.CFrame.LookVector end
		if down(Enum.KeyCode.S) then dir -= cam.CFrame.LookVector end
		if down(Enum.KeyCode.A) then dir -= cam.CFrame.RightVector end
		if down(Enum.KeyCode.D) then dir += cam.CFrame.RightVector end
		if down(Enum.KeyCode.Space) then dir += Vector3.yAxis end
		if down(Enum.KeyCode.LeftShift) or down(Enum.KeyCode.LeftControl) then
			dir -= Vector3.yAxis
		end

		if dir.Magnitude > 0 then
			dir = dir.Unit
		end

		hrp.AssemblyLinearVelocity = Vector3.zero
		hrp.CFrame = hrp.CFrame + dir * CONFIG.FlySpeed * dt
	end)
end

local function toggleFly()
	if flying then
		stopFly()
	else
		startFly()
	end
end

--==========================================================================
--  FEATURE: ESP  (DisplayName + @username, through walls)
--==========================================================================
local espEnabled = false
local tags = {}  -- [player] = BillboardGui

local function removeTag(plr)
	if tags[plr] then
		tags[plr]:Destroy()
		tags[plr] = nil
	end
end

local function makeTag(plr)
	if not espEnabled then
		return
	end
	if plr == LocalPlayer and not CONFIG.ShowSelfESP then
		return
	end

	local char = plr.Character
	if not char then
		return
	end
	local head = char:FindFirstChild("Head") or char:FindFirstChildWhichIsA("BasePart")
	if not head then
		return
	end

	removeTag(plr)

	local bb = Instance.new("BillboardGui")
	bb.Name = "OwnerESP"
	bb.Adornee = head
	bb.AlwaysOnTop = true            -- show through walls
	bb.LightInfluence = 0            -- stay bright
	bb.Size = UDim2.new(0, 200, 0, 36)
	bb.StudsOffset = Vector3.new(0, 2.6, 0)
	bb.Parent = head

	local displayName = Instance.new("TextLabel")
	displayName.BackgroundTransparency = 1
	displayName.Position = UDim2.new(0, 0, 0, 0)
	displayName.Size = UDim2.new(1, 0, 0, 18)
	displayName.Font = Enum.Font.GothamBold
	displayName.TextSize = 15
	displayName.TextColor3 = Color3.fromRGB(255, 255, 255)
	displayName.TextStrokeTransparency = 0.4
	displayName.Text = plr.DisplayName
	displayName.Parent = bb

	local userName = Instance.new("TextLabel")
	userName.BackgroundTransparency = 1
	userName.Position = UDim2.new(0, 0, 0, 18)
	userName.Size = UDim2.new(1, 0, 0, 16)
	userName.Font = Enum.Font.Gotham
	userName.TextSize = 12
	userName.TextColor3 = Color3.fromRGB(200, 200, 210)
	userName.TextStrokeTransparency = 0.5
	userName.Text = "@" .. plr.Name
	userName.Parent = bb

	tags[plr] = bb
end

local function setESP(on)
	espEnabled = on
	rows.ESP.setActive(on)
	for _, plr in ipairs(Players:GetPlayers()) do
		if on then
			makeTag(plr)
		else
			removeTag(plr)
		end
	end
end

local function toggleESP()
	setESP(not espEnabled)
end

-- Re-create a player's tag whenever they respawn
local function hookPlayer(plr)
	plr.CharacterAdded:Connect(function()
		if espEnabled then
			task.wait(0.3)  -- let the head load
			makeTag(plr)
		end
	end)
end

for _, plr in ipairs(Players:GetPlayers()) do
	hookPlayer(plr)
end
Players.PlayerAdded:Connect(hookPlayer)
Players.PlayerRemoving:Connect(removeTag)

--==========================================================================
--  INPUT  (hotkeys)
--==========================================================================
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	if input.KeyCode == CONFIG.FlyKey then
		toggleFly()
	elseif input.KeyCode == CONFIG.ESPKey then
		toggleESP()
	elseif input.KeyCode == CONFIG.PanelToggleKey then
		panel.Visible = not panel.Visible
	end
end)

-- Fly does not survive a respawn; reset its state cleanly
LocalPlayer.CharacterAdded:Connect(function()
	if flyConn then
		flyConn:Disconnect()
		flyConn = nil
	end
	flying = false
	rows.Fly.setActive(false)
end)
