-- Tiny helper so the client and server agree on the same RemoteEvents.
-- The server creates them; the client waits for them.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Remotes = {}

local function getFolder()
	if RunService:IsServer() then
		local existing = ReplicatedStorage:FindFirstChild("Remotes")
		if existing then
			return existing
		end
		local created = Instance.new("Folder")
		created.Name = "Remotes"
		created.Parent = ReplicatedStorage
		return created
	end
	return ReplicatedStorage:WaitForChild("Remotes")
end

-- Returns a RemoteEvent by name (created on the server, waited for on the client).
function Remotes.event(name)
	local folder = getFolder()
	if RunService:IsServer() then
		local existing = folder:FindFirstChild(name)
		if existing then
			return existing
		end
		local created = Instance.new("RemoteEvent")
		created.Name = name
		created.Parent = folder
		return created
	end
	return folder:WaitForChild(name)
end

return Remotes
