--!strict
--[[
	Loads and saves progress in a DataStore. Every call is protected and retried. When DataStores
	are not available (an unpublished place, or Studio without "Enable Studio Access to API
	Services") the store switches itself off and progress lives for the session only.
]]

local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Log = require(ReplicatedStorage.Shared.Core.Log)

local TAG = "Store"
local STORE_NAME = "Progress_v1"
local RETRIES = 3

export type Data = {
	Rolls: number,
	Owned: { [string]: number },
}

local Store = {}

local store: DataStore? = nil
local disabled = false

local function disable(reason: any)
	if not disabled then
		disabled = true
		Log.Warn(TAG, `DataStores unavailable, progress is not saved this session: {reason}`)
	end
end

local function open(): DataStore?
	if disabled then
		return nil
	end
	if not store then
		local ok, result = pcall(DataStoreService.GetDataStore, DataStoreService, STORE_NAME)
		if not ok then
			disable(result)
			return nil
		end
		store = result
	end
	return store
end

-- Runs `action` up to RETRIES times; a "no access" error switches the store off at once.
local function attempt(action: () -> any): (boolean, any)
	local ok, result = false, nil
	for try = 1, RETRIES do
		ok, result = pcall(action)
		if ok then
			return true, result
		end
		if string.find(tostring(result), "Studio", 1, true) or string.find(tostring(result), "403", 1, true) then
			disable(result)
			return false, result
		end
		task.wait(try)
	end
	return false, result
end

local function key(userId: number): string
	return `u{userId}`
end

-- ok = the store answered (data may be nil for a new player). Not ok = do not save over it later.
function Store.Load(userId: number): (boolean, Data?)
	local target = open()
	if not target then
		return false, nil
	end
	local ok, result = attempt(function()
		return target:GetAsync(key(userId))
	end)
	if not ok then
		Log.Warn(TAG, `Load failed for {userId}: {result}`)
		return false, nil
	end
	return true, if type(result) == "table" then result else nil
end

function Store.Save(userId: number, data: Data): boolean
	local target = open()
	if not target then
		return false
	end
	local ok, err = attempt(function()
		return target:SetAsync(key(userId), data, { userId })
	end)
	if not ok then
		Log.Warn(TAG, `Save failed for {userId}: {err}`)
	end
	return ok
end

function Store.Enabled(): boolean
	return open() ~= nil
end

return table.freeze(Store)
