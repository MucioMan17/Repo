-- Thin, crash-proof wrapper around DataStores.
-- Every call is pcall'd, so in Studio without "Enable Studio Access to API
-- Services" (or any transient error) the game keeps running with fresh data
-- instead of erroring -- it just won't persist until published / enabled.
local DataStoreService = game:GetService("DataStoreService")

local DataStore = {}

local store
pcall(function()
	store = DataStoreService:GetDataStore("MafiaPlayerData_v1")
end)

local function keyFor(userId)
	return "player_" .. userId
end

-- Returns the saved table for a user, or nil if none / unavailable.
function DataStore.load(userId)
	if not store then
		return nil
	end
	local ok, result = pcall(function()
		return store:GetAsync(keyFor(userId))
	end)
	if ok then
		return result
	end
	return nil
end

function DataStore.save(userId, data)
	if not store then
		return
	end
	pcall(function()
		store:SetAsync(keyFor(userId), data)
	end)
end

return DataStore
