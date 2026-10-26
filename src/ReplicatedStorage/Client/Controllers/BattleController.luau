--!strict
--[[
	Plays the battle the server runs (BattleService): spawns this player's monster in front of the
	character with its health bar, and for every tick of hits makes each deck card jump and fire a
	shot at the monster; when a shot lands the monster flinches, a damage number pops and the bar
	drops. On the killing blow the monster bursts apart and the next level is announced.
	Also keeps the deck bar (above the buttons) in sync with the backpack.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Arena = require(script.Parent.Parent.World.Arena)
local BackpackController = require(script.Parent.BackpackController)
local Banner = require(script.Parent.Parent.UI.Fx.Banner)
local Bolt = require(script.Parent.Parent.UI.Fx.Bolt)
local Burst = require(script.Parent.Parent.UI.Fx.Burst)
local Catalog = require(ReplicatedStorage.Shared.Domain.Catalog)
local DamageText = require(script.Parent.Parent.World.DamageText)
local DeckBar = require(script.Parent.Parent.UI.Screens.DeckBar)
local HealthBar = require(script.Parent.Parent.World.HealthBar)
local HudController = require(script.Parent.HudController)
local Monsters = require(script.Parent.Parent.World.Monsters)
local Net = require(ReplicatedStorage.Shared.Net)
local Power = require(ReplicatedStorage.Shared.Domain.Power)
local Shake = require(script.Parent.Parent.UI.Fx.Shake)
local Theme = require(ReplicatedStorage.Shared.Config.Theme)

local HIT_STAGGER = 0.12
local FLIGHT = 0.35
local BAR_HEIGHT = 5

type Current = {
	Monster: Monsters.Monster,
	Bar: HealthBar.HealthBar,
	Hp: number,
	MaxHp: number,
}

local BattleController = {}

local current: Current? = nil
local deckBar: DeckBar.DeckBar
-- Spawns can overlap while waiting for the character; only the newest one may finish.
local generation = 0

local function headOnScreen(target: Current): Vector2
	local camera = workspace.CurrentCamera
	local point = camera:WorldToViewportPoint(target.Monster.Head.Position)
	return Vector2.new(point.X, point.Y)
end

local function spawnMonster(level: number, hp: number, maxHp: number)
	generation += 1
	local mine = generation
	local at = Arena.SpawnCFrame()
	if mine ~= generation then
		return
	end
	local old = current
	if old then
		old.Monster:Destroy()
		old.Bar:Destroy()
	end
	local kind = Power.Monster(level)
	local monster = Monsters.Spawn(kind, at)
	local bar = HealthBar.new(monster.Head, BAR_HEIGHT, `Lv {level}  {kind.Name}`)
	bar:Set(hp, maxHp)
	current = { Monster = monster, Bar = bar, Hp = hp, MaxHp = maxHp }
end

local function land(target: Current, damage: number, killing: boolean, at: Vector2)
	if current ~= target then
		return
	end
	target.Hp = math.max(target.Hp - damage, 0)
	target.Monster:Hit(if killing then 1 else 0.5)
	target.Bar:Set(target.Hp, target.MaxHp)
	DamageText.Pop(target.Monster.Head, damage, killing or damage >= target.MaxHp * 0.25)
	Burst.Play(at, Theme.Colors.Damage, if killing then 30 else 8, if killing then 0.9 else 0.4)
	Shake.Add(if killing then 0.35 else 0.04)
	if killing then
		target.Monster:Die()
		target.Bar:Destroy()
		current = nil
		Banner.Toast("LEVEL UP!", Theme.Colors.Gold, 0.6)
	end
end

local function hits(list: { number }, killed: boolean, finalHp: number)
	local target = current
	if not target then
		return
	end
	local deck = BackpackController.State().Deck
	for slot, damage in list do
		local last = slot == #list
		task.delay((slot - 1) * HIT_STAGGER, function()
			local from = deckBar:Attack(slot)
			local cardId = deck[slot]
			local color = if cardId and Catalog.Has(cardId) then Catalog.RarityOf(cardId).Color else Theme.Colors.Damage
			if not from or current ~= target then
				return
			end
			local function aim(): Vector2
				return headOnScreen(target)
			end
			local function onHit(at: Vector2)
				land(target, damage, last and killed, at)
				if last and not killed and current == target then
					-- Settle on the server's number in case a hit was missed.
					target.Hp = finalHp
					target.Bar:Set(finalHp, target.MaxHp)
				end
			end
			Bolt.Fly(from, aim, color, FLIGHT, onHit)
		end)
	end
end

local function onEvent(event: Power.BattleEvent)
	if event.Kind == "Spawn" then
		task.spawn(spawnMonster, event.Level, event.Hp, event.MaxHp)
	elseif event.Kind == "Hits" and event.Hits then
		hits(event.Hits, event.Killed == true, event.Hp)
	end
end

function BattleController.Start()
	local hud = HudController.Get()
	deckBar = DeckBar.new(hud.Canvas, function()
		hud.Actions.OnBackpack()
	end)
	BackpackController.OnChanged(function(state)
		deckBar:Render(state.Deck, state.Owned)
	end)

	local remote = Net.Event("Battle")
	remote.OnClientEvent:Connect(onEvent)
	remote:FireServer()
end

return BattleController
