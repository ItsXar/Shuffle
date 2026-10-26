--!strict
--[[
	Owns what a player has achieved this session: number of rolls, cards owned, best rarity pulled.
	Mirrors the headline numbers into leaderstats so everyone in the server sees them.
	Nothing is saved yet: progress lives as long as the player stays in the server.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Catalog = require(ReplicatedStorage.Shared.Domain.Catalog)

type Progress = {
	Rolls: number,
	Owned: { [string]: number },
	BestTier: number,
	RollsValue: IntValue,
	BestValue: StringValue,
}

local ProgressService = {}

local progress: { [Player]: Progress } = {}

local function setup(player: Player): Progress
	local existing = progress[player]
	if existing then
		return existing
	end

	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"

	local rollsValue = Instance.new("IntValue")
	rollsValue.Name = "Rolls"
	rollsValue.Parent = leaderstats

	local bestValue = Instance.new("StringValue")
	bestValue.Name = "Best"
	bestValue.Value = "-"
	bestValue.Parent = leaderstats

	leaderstats.Parent = player

	local created: Progress = {
		Rolls = 0,
		Owned = {},
		BestTier = 0,
		RollsValue = rollsValue,
		BestValue = bestValue,
	}
	progress[player] = created
	return created
end

-- Counts one roll and returns the player's total.
function ProgressService.AddRoll(player: Player): number
	local state = setup(player)
	state.Rolls += 1
	state.RollsValue.Value = state.Rolls
	return state.Rolls
end

-- Adds a kept card; true when the player never had it before.
function ProgressService.Collect(player: Player, cardId: string): boolean
	local state = setup(player)
	local count = (state.Owned[cardId] or 0) + 1
	state.Owned[cardId] = count

	local tier = Catalog.TierOf(cardId)
	if tier > state.BestTier then
		state.BestTier = tier
		state.BestValue.Value = Catalog.Rarity(tier).Name
	end
	return count == 1
end

function ProgressService.Init()
	Players.PlayerAdded:Connect(setup)
	Players.PlayerRemoving:Connect(function(player: Player)
		progress[player] = nil
	end)
	for _, player in Players:GetPlayers() do
		setup(player)
	end
end

return ProgressService
