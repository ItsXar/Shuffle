--!strict
--[[
	Owns what a player has collected: number of rolls and how many of each card. Loaded from the
	DataStore when the player joins (Store), saved when they leave, every few minutes and when the
	server shuts down. Answers the "Inventory" remote, and mirrors rolls and best rarity into
	leaderstats so everyone in the server sees them.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Catalog = require(ReplicatedStorage.Shared.Domain.Catalog)
local Net = require(ReplicatedStorage.Shared.Net)
local Odds = require(ReplicatedStorage.Shared.Domain.Odds)
local Store = require(script.Parent.Store)

local AUTOSAVE_SECONDS = 120
local READY_TIMEOUT = 15

type Progress = {
	Data: Store.Data,
	-- Loaded = the store answered, so saving cannot overwrite data we never saw.
	Loaded: boolean,
	Ready: boolean,
	Dirty: boolean,
	RollsValue: IntValue,
	BestValue: StringValue,
}

local ProgressService = {}

local progress: { [Player]: Progress } = {}

local function bestTier(owned: { [string]: number }): number
	local best = 0
	for cardId in owned do
		best = math.max(best, Catalog.TierOf(cardId))
	end
	return best
end

local function refresh(state: Progress)
	state.RollsValue.Value = state.Data.Rolls
	local tier = bestTier(state.Data.Owned)
	state.BestValue.Value = if tier > 0 then Catalog.Rarity(tier).Name else "-"
end

-- Keeps only what this version of the game understands.
local function clean(raw: any): Store.Data
	local data: Store.Data = { Rolls = 0, Owned = {} }
	if type(raw) ~= "table" then
		return data
	end
	if type(raw.Rolls) == "number" then
		data.Rolls = math.max(0, math.floor(raw.Rolls))
	end
	if type(raw.Owned) == "table" then
		for cardId, count in raw.Owned do
			if type(cardId) == "string" and type(count) == "number" and Catalog.Has(cardId) then
				data.Owned[cardId] = math.max(0, math.floor(count))
			end
		end
	end
	return data
end

local function leaderstats(player: Player): (IntValue, StringValue)
	local folder = Instance.new("Folder")
	folder.Name = "leaderstats"
	local rolls = Instance.new("IntValue")
	rolls.Name = "Rolls"
	rolls.Parent = folder
	local best = Instance.new("StringValue")
	best.Name = "Best"
	best.Value = "-"
	best.Parent = folder
	folder.Parent = player
	return rolls, best
end

local function load(player: Player, state: Progress)
	local ok, saved = Store.Load(player.UserId)
	if progress[player] ~= state then
		return
	end
	state.Loaded = ok
	if saved then
		state.Data = clean(saved)
	end
	state.Ready = true
	refresh(state)
end

local function setup(player: Player)
	if progress[player] then
		return
	end
	local rollsValue, bestValue = leaderstats(player)
	local state: Progress = {
		Data = { Rolls = 0, Owned = {} },
		Loaded = false,
		Ready = false,
		Dirty = false,
		RollsValue = rollsValue,
		BestValue = bestValue,
	}
	progress[player] = state
	task.spawn(load, player, state)
end

local function save(player: Player, state: Progress)
	if state.Loaded and state.Dirty then
		state.Dirty = false
		if not Store.Save(player.UserId, state.Data) then
			state.Dirty = true
		end
	end
end

-- Yields until the player's saved progress is in (or the store gave up).
local function ready(player: Player): Progress?
	local started = os.clock()
	local state = progress[player]
	while state and not state.Ready and os.clock() - started < READY_TIMEOUT do
		task.wait(0.1)
		state = progress[player]
	end
	return state
end

-- Counts one roll and returns the player's total.
function ProgressService.AddRoll(player: Player): number
	local state = ready(player)
	if not state then
		return 0
	end
	state.Data.Rolls += 1
	state.Dirty = true
	state.RollsValue.Value = state.Data.Rolls
	return state.Data.Rolls
end

-- Adds a kept card; true when the player never had it before.
function ProgressService.Collect(player: Player, cardId: string): boolean
	local state = progress[player]
	if not state then
		return false
	end
	local count = (state.Data.Owned[cardId] or 0) + 1
	state.Data.Owned[cardId] = count
	state.Dirty = true
	refresh(state)
	return count == 1
end

local function inventory(player: Player): Odds.Collection
	local state = ready(player)
	if not state then
		return { Owned = {}, Rolls = 0 }
	end
	return { Owned = table.clone(state.Data.Owned), Rolls = state.Data.Rolls }
end

function ProgressService.Init()
	Net.Function("Inventory").OnServerInvoke = inventory
	Players.PlayerAdded:Connect(setup)
	Players.PlayerRemoving:Connect(function(player: Player)
		local state = progress[player]
		if state then
			save(player, state)
			progress[player] = nil
		end
	end)
	for _, player in Players:GetPlayers() do
		setup(player)
	end
	game:BindToClose(function()
		for player, state in progress do
			task.spawn(save, player, state)
		end
		task.wait(2)
	end)
end

function ProgressService.Start()
	while true do
		task.wait(AUTOSAVE_SECONDS)
		for player, state in progress do
			task.spawn(save, player, state)
		end
	end
end

return ProgressService
