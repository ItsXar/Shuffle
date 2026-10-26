--!strict
--[[
	Owns rolling. The client only asks (remote "Roll"); the server draws the cards, picks the best
	one and records it, so odds and results can't be tampered with. Every LuckyEvery-th roll of a
	player is a lucky roll with boosted luck (Config/Roll).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage.Shared.Net)
local Odds = require(ReplicatedStorage.Shared.Domain.Odds)
local ProgressService = require(script.Parent.Parent.Progress.ProgressService)
local RollConfig = require(ReplicatedStorage.Shared.Config.Roll)

type Session = {
	Rng: Random,
	LastRoll: number,
}

local RollService = {}

local sessions: { [Player]: Session } = {}

local function session(player: Player): Session
	local existing = sessions[player]
	if existing then
		return existing
	end
	local created: Session = { Rng = Random.new(), LastRoll = -math.huge }
	sessions[player] = created
	return created
end

-- Rolls left until the next lucky roll, counting the next one as 1.
local function untilLucky(rolls: number): number
	return RollConfig.LuckyEvery - rolls % RollConfig.LuckyEvery
end

local function roll(player: Player): Odds.Result?
	local state = session(player)
	local now = os.clock()
	if now - state.LastRoll < RollConfig.Cooldown then
		return nil
	end
	state.LastRoll = now

	local rolls = ProgressService.AddRoll(player)
	local lucky = rolls % RollConfig.LuckyEvery == 0
	local luck = RollConfig.BaseLuck * (if lucky then RollConfig.LuckyMultiplier else 1)
	local hand = Odds.RollHand(state.Rng, luck, RollConfig.CardsPerRoll)
	local best = Odds.Best(hand)

	return {
		Hand = hand,
		Best = best,
		Luck = luck,
		Lucky = lucky,
		New = ProgressService.Collect(player, hand[best]),
		Rolls = rolls,
		UntilLucky = untilLucky(rolls),
	}
end

function RollService.Init()
	Net.Function("Roll").OnServerInvoke = roll
	Players.PlayerRemoving:Connect(function(player: Player)
		sessions[player] = nil
	end)
end

return RollService
