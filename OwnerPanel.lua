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
local mouse       = LocalPlayer:GetMouse()

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

-- Tracks every persistent event connection so the kill switch can tear them
-- all down. Wrap a :Connect(...) call in track() to register it.
local connections = {}
local function track(conn)
	table.insert(connections, conn)
	return conn
end

--==========================================================================
--  CONFIG  --  edit keys / values here
--==========================================================================
local CONFIG = {
	FlyKey         = Enum.KeyCode.F,
	ESPKey         = Enum.KeyCode.E,
	PanelToggleKey = Enum.KeyCode.RightControl,

	-- Fly tuning
	FlySpeed           = 200,   -- fixed flight speed (studs/sec)
	FlyBoostMultiplier = 2.5,   -- speed multiplier while holding LeftShift
	FlyAcceleration    = 10,    -- higher = snappier, lower = floatier

	-- ESP
	ShowSelfESP        = false, -- also tag your own character?

	-- Target (highlight + tracer)
	TargetKey          = Enum.KeyCode.Q,
	TargetFillColor    = Color3.fromRGB(255, 65, 65),
	TargetOutlineColor = Color3.fromRGB(255, 255, 255),
	TargetFillTransparency = 0.6,
	TracerColor        = Color3.fromRGB(255, 65, 65),
	TracerThickness    = 2,

	-- Camera lock-on (engages automatically while you have a target)
	CamLockDistance    = 14,   -- how far behind you the camera sits (studs)
	CamLockHeight      = 4,    -- how high above you the camera sits (studs)
	CamLockSmooth      = 30,   -- tracking smoothness (higher = snappier)
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
		setText = function(text)
			label.Text = text
		end,
	}
	rows[name] = handle
	return handle
end

createRow("Fly", CONFIG.FlyKey.Name)
createRow("ESP", CONFIG.ESPKey.Name)
createRow("Target", CONFIG.TargetKey.Name)

-- Kill switch: fully unloads the script (assigned its action at the bottom)
local killButton = Instance.new("TextButton")
killButton.Name = "KillButton"
killButton.Size = UDim2.new(1, 0, 0, 26)
killButton.LayoutOrder = 1000
killButton.BackgroundColor3 = Color3.fromRGB(190, 45, 45)
killButton.AutoButtonColor = true
killButton.Font = Enum.Font.GothamBold
killButton.TextSize = 12
killButton.TextColor3 = Color3.fromRGB(255, 255, 255)
killButton.Text = "KILL SCRIPT"
killButton.Parent = panel

local killCorner = Instance.new("UICorner")
killCorner.CornerRadius = UDim.new(0, 6)
killCorner.Parent = killButton

-- Make the panel draggable
do
	local dragging, dragStart, startPos
	track(panel.InputBegan:Connect(function(input)
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
	end))
	track(UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			panel.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + delta.X,
				startPos.Y.Scale, startPos.Y.Offset + delta.Y
			)
		end
	end))
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
--  FEATURE: FLY  (physics-based, smooth)
--
--    F            toggle fly
--    W A S D      move (relative to the camera)
--    Space        up        LeftControl   down
--    LeftShift    boost
--    Gamepad      left stick = move, triggers = up/down
--==========================================================================
local flying = false
local flyConn
local flyAtt, flyVelocity, flyOrient   -- physics objects we create on the root
local flyCurrentVel = Vector3.zero      -- smoothed velocity (gives momentum)

-- Builds a camera-relative input direction (keyboard + gamepad). Magnitude <= 1.
local function getFlyDirection(cam)
	-- Don't fly around while the player is typing in a text box
	if UserInputService:GetFocusedTextBox() then
		return Vector3.zero
	end

	local function key(k)
		return UserInputService:IsKeyDown(k) and 1 or 0
	end
	local fwd  = key(Enum.KeyCode.W) - key(Enum.KeyCode.S)
	local side = key(Enum.KeyCode.D) - key(Enum.KeyCode.A)
	local vert = key(Enum.KeyCode.Space) - key(Enum.KeyCode.LeftControl)

	-- Gamepad: left stick moves, triggers go up/down
	if UserInputService.GamepadEnabled then
		local ok, state = pcall(function()
			return UserInputService:GetGamepadState(Enum.UserInputType.Gamepad1)
		end)
		if ok and state then
			for _, obj in ipairs(state) do
				if obj.KeyCode == Enum.KeyCode.Thumbstick1 then
					side += obj.Position.X
					fwd  += obj.Position.Y
				elseif obj.KeyCode == Enum.KeyCode.ButtonR2 then
					vert += obj.Position.Z
				elseif obj.KeyCode == Enum.KeyCode.ButtonL2 then
					vert -= obj.Position.Z
				end
			end
		end
	end

	local camCF = cam.CFrame
	local dir = (camCF.LookVector * fwd) + (camCF.RightVector * side) + (Vector3.yAxis * vert)
	-- Clamp diagonals to 1 but keep analog (sub-1) magnitudes from the stick
	if dir.Magnitude > 1 then
		dir = dir.Unit
	end
	return dir
end

-- Creates the LinearVelocity (movement) and AlignOrientation (stays upright)
local function buildFlyForces(hrp)
	local att = Instance.new("Attachment")
	att.Name = "OwnerFlyAttachment"
	att.Parent = hrp

	local lv = Instance.new("LinearVelocity")
	lv.Name = "OwnerFlyVelocity"
	lv.Attachment0 = att
	lv.RelativeTo = Enum.ActuatorRelativeTo.World
	lv.MaxForce = math.huge
	lv.VectorVelocity = Vector3.zero
	lv.Parent = hrp

	local ao = Instance.new("AlignOrientation")
	ao.Name = "OwnerFlyOrientation"
	ao.Attachment0 = att
	ao.Mode = Enum.OrientationAlignmentMode.OneAttachment
	ao.RigidityEnabled = false
	ao.Responsiveness = 50
	ao.MaxTorque = math.huge
	ao.CFrame = hrp.CFrame
	ao.Parent = hrp

	return att, lv, ao
end

local function teardownFly()
	if flyConn then
		flyConn:Disconnect()
		flyConn = nil
	end
	for _, obj in ipairs({ flyVelocity, flyOrient, flyAtt }) do
		if obj then
			obj:Destroy()
		end
	end
	flyAtt, flyVelocity, flyOrient = nil, nil, nil
	flyCurrentVel = Vector3.zero
end

local function stopFly()
	flying = false
	teardownFly()

	local hum = getHumanoid()
	if hum then
		hum.PlatformStand = false
		hum.AutoRotate = true
		hum:ChangeState(Enum.HumanoidStateType.GettingUp)
	end

	rows.Fly.setActive(false)
end

local function startFly()
	local hum, hrp = getHumanoid(), getRoot()
	if not (hum and hrp) then
		return
	end

	flying = true
	hum.PlatformStand = true   -- stop the humanoid from walking / standing
	hum.AutoRotate = false     -- we handle facing via AlignOrientation

	flyAtt, flyVelocity, flyOrient = buildFlyForces(hrp)
	flyCurrentVel = hrp.AssemblyLinearVelocity   -- carry momentum from running/jumping

	rows.Fly.setActive(true)

	flyConn = RunService.RenderStepped:Connect(function(dt)
		if not flying then
			return
		end
		local h, root = getHumanoid(), getRoot()
		if not (h and root and flyVelocity and flyOrient) then
			return
		end

		local cam = Workspace.CurrentCamera
		local dir = getFlyDirection(cam)

		local boosting = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
		local speed = CONFIG.FlySpeed * (boosting and CONFIG.FlyBoostMultiplier or 1)
		local targetVel = dir * speed

		-- Frame-rate-independent easing toward the target -> smooth momentum
		local alpha = 1 - math.exp(-dt * CONFIG.FlyAcceleration)
		flyCurrentVel = flyCurrentVel:Lerp(targetVel, alpha)
		flyVelocity.VectorVelocity = flyCurrentVel

		-- Stay upright, facing where the camera looks (horizontal only)
		local look = cam.CFrame.LookVector
		local lookXZ = Vector3.new(look.X, 0, look.Z)
		if lookXZ.Magnitude > 0.01 then
			flyOrient.CFrame = CFrame.lookAt(Vector3.zero, lookXZ.Unit)
		end
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
	track(plr.CharacterAdded:Connect(function()
		if espEnabled then
			task.wait(0.3)  -- let the head load
			makeTag(plr)
		end
	end))
end

for _, plr in ipairs(Players:GetPlayers()) do
	hookPlayer(plr)
end
track(Players.PlayerAdded:Connect(hookPlayer))
track(Players.PlayerRemoving:Connect(removeTag))

--==========================================================================
--  FEATURE: TARGET  (highlight + tracer from the mouse)
--
--    Q  locks onto the player nearest the mouse. Press Q on the same target
--       to unlock, or aim at someone else and press Q to switch.
--==========================================================================

-- Separate ScreenGui for the tracer. IgnoreGuiInset = false so its pixel
-- coordinates line up with mouse.X/Y and Camera:WorldToViewportPoint().
local worldGui = Instance.new("ScreenGui")
worldGui.Name = "OwnerWorld"
worldGui.ResetOnSpawn = false
worldGui.IgnoreGuiInset = false
worldGui.DisplayOrder = 5
worldGui.Parent = playerGui

local tracer = Instance.new("Frame")
tracer.Name = "Tracer"
tracer.AnchorPoint = Vector2.new(0.5, 0.5)
tracer.BorderSizePixel = 0
tracer.BackgroundColor3 = CONFIG.TracerColor
tracer.Visible = false
tracer.Parent = worldGui

local tracerCorner = Instance.new("UICorner")
tracerCorner.CornerRadius = UDim.new(1, 0)
tracerCorner.Parent = tracer

local currentTarget = nil
local targetHighlight = nil

local function clearTarget()
	if targetHighlight then
		targetHighlight:Destroy()
		targetHighlight = nil
	end
	tracer.Visible = false
	currentTarget = nil
	rows.Target.setActive(false)
	rows.Target.setText("Target")
end

local function setTarget(plr)
	clearTarget()
	local char = plr.Character
	if not char then
		return
	end
	currentTarget = plr

	local hl = Instance.new("Highlight")
	hl.Name = "OwnerTargetHighlight"
	hl.Adornee = char
	hl.FillColor = CONFIG.TargetFillColor
	hl.FillTransparency = CONFIG.TargetFillTransparency
	hl.OutlineColor = CONFIG.TargetOutlineColor
	hl.OutlineTransparency = 0
	hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop  -- show through walls
	hl.Parent = char
	targetHighlight = hl

	rows.Target.setActive(true)
	rows.Target.setText("Target · " .. plr.DisplayName)
end

-- Player whose character is closest to the mouse on screen (in front of camera)
local function getNearestPlayerToMouse()
	local cam = Workspace.CurrentCamera
	local mousePos = Vector2.new(mouse.X, mouse.Y)
	local best, bestDist = nil, math.huge

	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= LocalPlayer and plr.Character then
			local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
			local hum = plr.Character:FindFirstChildOfClass("Humanoid")
			if hrp and hum and hum.Health > 0 then
				local sp = cam:WorldToViewportPoint(hrp.Position)
				if sp.Z > 0 then  -- in front of the camera
					local dist = (Vector2.new(sp.X, sp.Y) - mousePos).Magnitude
					if dist < bestDist then
						bestDist = dist
						best = plr
					end
				end
			end
		end
	end
	return best
end

local function onTargetKey()
	-- Strict toggle: if we already have a target, deselect it no matter what.
	if currentTarget then
		clearTarget()
		return
	end
	-- Otherwise try to lock the player nearest the mouse.
	local nearest = getNearestPlayerToMouse()
	if nearest then
		setTarget(nearest)
	end
end

-- Clear immediately if the target leaves the game
track(Players.PlayerRemoving:Connect(function(plr)
	if plr == currentTarget then
		clearTarget()
	end
end))

-- Per-frame: validate the target, then draw the tracer mouse -> target
track(RunService.RenderStepped:Connect(function()
	if not currentTarget then
		return
	end

	local char = currentTarget.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if currentTarget.Parent == nil or not (char and hum and hrp) or hum.Health <= 0 then
		clearTarget()
		return
	end

	local cam = Workspace.CurrentCamera
	local sp = cam:WorldToViewportPoint(hrp.Position)
	if sp.Z <= 0 then
		tracer.Visible = false  -- target is behind us
		return
	end

	local p1 = Vector2.new(mouse.X, mouse.Y)        -- from the mouse
	local p2 = Vector2.new(sp.X, sp.Y)              -- to the target
	local delta = p2 - p1

	tracer.Visible = true
	tracer.Size = UDim2.fromOffset(delta.Magnitude, CONFIG.TracerThickness)
	tracer.Position = UDim2.fromOffset((p1.X + p2.X) / 2, (p1.Y + p2.Y) / 2)
	tracer.Rotation = math.deg(math.atan2(delta.Y, delta.X))
end))

--==========================================================================
--  FEATURE: CAMERA LOCK-ON
--
--    Engages automatically whenever you have a target (set with Q). The camera
--    sits behind you and keeps the target framed, and releases your camera when
--    the target is cleared (press Q again, or the target dies/leaves).
--==========================================================================
local camEngaged = false
local savedCameraType = nil

local function engageCam()
	if camEngaged then
		return
	end
	local cam = Workspace.CurrentCamera
	if cam.CameraType ~= Enum.CameraType.Scriptable then
		savedCameraType = cam.CameraType
	end
	cam.CameraType = Enum.CameraType.Scriptable
	camEngaged = true
end

local function releaseCam()
	if not camEngaged then
		return
	end
	Workspace.CurrentCamera.CameraType = savedCameraType or Enum.CameraType.Custom
	camEngaged = false
end

RunService:BindToRenderStep("OwnerCamLock", Enum.RenderPriority.Camera.Value + 1, function(dt)
	-- Track only while we have a valid target and our own root;
	-- otherwise leave the camera alone.
	local tChar = currentTarget and currentTarget.Character
	local tPart = tChar and (tChar:FindFirstChild("Head") or tChar:FindFirstChild("HumanoidRootPart"))
	local myChar = LocalPlayer.Character
	local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
	if not (tPart and myRoot) then
		releaseCam()
		return
	end

	engageCam()
	local cam = Workspace.CurrentCamera
	local myPos = myRoot.Position
	local targetPos = tPart.Position

	-- Sit behind us along the (flattened) line to the target
	local flat = myPos - targetPos
	flat = Vector3.new(flat.X, 0, flat.Z)
	if flat.Magnitude < 0.1 then
		-- stacked on the target: fall back to facing direction, then a default
		local lv = myRoot.CFrame.LookVector
		flat = Vector3.new(-lv.X, 0, -lv.Z)
		if flat.Magnitude < 0.1 then
			flat = Vector3.new(0, 0, 1)
		end
	end
	flat = flat.Unit

	local camPos = myPos + flat * CONFIG.CamLockDistance + Vector3.new(0, CONFIG.CamLockHeight, 0)
	local goal = CFrame.lookAt(camPos, targetPos)
	local alpha = 1 - math.exp(-dt * CONFIG.CamLockSmooth)
	cam.CFrame = cam.CFrame:Lerp(goal, alpha)
end)

--==========================================================================
--  INPUT  (hotkeys)
--==========================================================================
track(UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	if input.KeyCode == CONFIG.FlyKey then
		toggleFly()
	elseif input.KeyCode == CONFIG.ESPKey then
		toggleESP()
	elseif input.KeyCode == CONFIG.TargetKey then
		onTargetKey()
	elseif input.KeyCode == CONFIG.PanelToggleKey then
		panel.Visible = not panel.Visible
	end
end))

-- Fly does not survive a respawn; reset its state cleanly
track(LocalPlayer.CharacterAdded:Connect(function()
	flying = false
	teardownFly()
	rows.Fly.setActive(false)

	-- Camera resets on respawn; let the lock re-engage from a clean state
	camEngaged = false
end))

--==========================================================================
--  KILL SWITCH  --  fully unloads the script and restores everything
--==========================================================================
local function killScript()
	-- Turn features off and restore game state
	pcall(stopFly)
	pcall(clearTarget)
	pcall(function() setESP(false) end)
	pcall(releaseCam)
	pcall(function() RunService:UnbindFromRenderStep("OwnerCamLock") end)

	-- Disconnect every tracked event connection
	for _, conn in ipairs(connections) do
		pcall(function() conn:Disconnect() end)
	end
	connections = {}

	-- Remove all UI we created
	if gui then gui:Destroy() end
	if worldGui then worldGui:Destroy() end

	-- Finally, remove the script instance itself
	script:Destroy()
end

killButton.Activated:Connect(killScript)
