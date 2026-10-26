--!strict
--[[
	Owns what a player has: number of rolls, how many of each card, the deck (Deck) and the
	monster level reached. Loaded from the DataStore when the player joins (Store), saved when
	they leave, every few minutes and when the server shuts down. Answers "Inventory" and
	"SetDeck", fills empty deck slots with the best cards, and mirrors rolls, best rarity and
	level into leaderstats so everyone in the server sees them.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Catalog = require(ReplicatedStorage.Shared.Domain.Catalog)
local Deck = require(ReplicatedStorage.Shared.Domain.Deck)
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
	LevelValue: IntValue,
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
	state.LevelValue.Value = state.Data.Level
	local tier = bestTier(state.Data.Owned)
	state.BestValue.Value = if tier > 0 then Catalog.Rarity(tier).Name else "-"
end

-- Keeps only what this version of the game understands.
local function clean(raw: any): Store.Data
	local data: Store.Data = { Rolls = 0, Owned = {}, Deck = {}, Level = 1 }
	if type(raw) ~= "table" then
		return data
	end
	if type(raw.Level) == "number" then
		data.Level = math.max(1, math.floor(raw.Level))
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
	data.Deck = Deck.Clean(raw.Deck, data.Owned)
	return data
end

local function leaderstats(player: Player): (IntValue, StringValue, IntValue)
	local folder = Instance.new("Folder")
	folder.Name = "leaderstats"
	local rolls = Instance.new("IntValue")
	rolls.Name = "Rolls"
	rolls.Parent = folder
	local best = Instance.new("StringValue")
	best.Name = "Best"
	best.Value = "-"
	best.Parent = folder
	local level = Instance.new("IntValue")
	level.Name = "Level"
	level.Value = 1
	level.Parent = folder
	folder.Parent = player
	return rolls, best, level
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
	Deck.Fill(state.Data.Deck, state.Data.Owned)
	state.Ready = true
	refresh(state)
end

local function setup(player: Player)
	if progress[player] then
		return
	end
	local rollsValue, bestValue, levelValue = leaderstats(player)
	local state: Progress = {
		Data = { Rolls = 0, Owned = {}, Deck = {}, Level = 1 },
		Loaded = false,
		Ready = false,
		Dirty = false,
		RollsValue = rollsValue,
		BestValue = bestValue,
		LevelValue = levelValue,
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
	Deck.Fill(state.Data.Deck, state.Data.Owned)
	state.Dirty = true
	refresh(state)
	return count == 1
end

-- The player's data once loaded, for reading only (BattleService); nil while still loading.
function ProgressService.Peek(player: Player): Store.Data?
	local state = progress[player]
	return if state and state.Ready then state.Data else nil
end

-- The monster of the current level died: one level up. Returns the new level.
function ProgressService.LevelUp(player: Player): number
	local state = progress[player]
	if not state then
		return 1
	end
	state.Data.Level += 1
	state.Dirty = true
	state.LevelValue.Value = state.Data.Level
	return state.Data.Level
end

local function setDeck(player: Player, raw: any): { string }
	local state = ready(player)
	if not state then
		return {}
	end
	state.Data.Deck = Deck.Clean(raw, state.Data.Owned)
	state.Dirty = true
	return table.clone(state.Data.Deck)
end

local function inventory(player: Player): Odds.Collection
	local state = ready(player)
	if not state then
		return { Owned = {}, Rolls = 0, Deck = {}, Level = 1 }
	end
	local data = state.Data
	return { Owned = table.clone(data.Owned), Rolls = data.Rolls, Deck = table.clone(data.Deck), Level = data.Level }
end

function ProgressService.Init()
	Net.Function("Inventory").OnServerInvoke = inventory
	Net.Function("SetDeck").OnServerInvoke = setDeck
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
