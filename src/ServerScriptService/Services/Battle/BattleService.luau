--!strict
--[[
	Owns every player's fight. Each player fights their own monster: every Config/Battle >
	TickSeconds each card in their deck hits once for its power. When the monster drops to 0 HP the
	player levels up and, one tick later, the next (stronger) monster spawns. All damage is decided
	here; the client only plays it back from the "Battle" events (Shared/Domain/Power > BattleEvent).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Battle = require(ReplicatedStorage.Shared.Config.Battle)
local Net = require(ReplicatedStorage.Shared.Net)
local Power = require(ReplicatedStorage.Shared.Domain.Power)
local ProgressService = require(script.Parent.Parent.Progress.ProgressService)

type Fight = {
	Level: number,
	Hp: number,
	MaxHp: number,
	-- The monster died last tick; the next one spawns this tick.
	Dead: boolean,
}

local BattleService = {}

local fights: { [Player]: Fight } = {}
local remote: RemoteEvent

local function send(player: Player, event: Power.BattleEvent)
	remote:FireClient(player, event)
end

local function spawnMonster(player: Player, level: number): Fight
	local hp = Power.MonsterHp(level)
	local fight: Fight = { Level = level, Hp = hp, MaxHp = hp, Dead = false }
	fights[player] = fight
	send(player, { Kind = "Spawn", Level = level, Hp = hp, MaxHp = hp })
	return fight
end

local function tick(player: Player)
	local data = ProgressService.Peek(player)
	if not data then
		return
	end
	local fight = fights[player]
	if not fight or fight.Dead or fight.Level ~= data.Level then
		spawnMonster(player, data.Level)
		return
	end
	if #data.Deck == 0 then
		return
	end

	local hits = {}
	local total = 0
	for slot, cardId in data.Deck do
		local damage = Power.Card(cardId, data.Owned[cardId] or 1)
		hits[slot] = damage
		total += damage
	end
	fight.Hp = math.max(fight.Hp - total, 0)
	local killed = fight.Hp <= 0
	send(player, { Kind = "Hits", Level = fight.Level, Hp = fight.Hp, MaxHp = fight.MaxHp, Hits = hits, Killed = killed })
	if killed then
		fight.Dead = true
		fight.Level = ProgressService.LevelUp(player)
	end
end

-- A client (re)joined the battle and wants the current monster.
local function hello(player: Player)
	local fight = fights[player]
	if fight and not fight.Dead then
		send(player, { Kind = "Spawn", Level = fight.Level, Hp = fight.Hp, MaxHp = fight.MaxHp })
	end
end

function BattleService.Init()
	remote = Net.Event("Battle")
	remote.OnServerEvent:Connect(hello)
	Players.PlayerRemoving:Connect(function(player: Player)
		fights[player] = nil
	end)
end

function BattleService.Start()
	while true do
		task.wait(Battle.TickSeconds)
		for _, player in Players:GetPlayers() do
			task.spawn(tick, player)
		end
	end
end

return BattleService
