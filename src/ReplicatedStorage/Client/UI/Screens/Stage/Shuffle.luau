--!strict
--[[
	Phase 1 of a roll show. The cards are dealt face down, flip, and spin through random faces like
	slot reels, slowing down and locking left to right on the real result. A card that landed rare
	makes the player wait: it trembles and glows in its rarity colour before it locks.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Audio = require(ReplicatedStorage.Client.Core.Audio)
local Burst = require(script.Parent.Parent.Parent.Fx.Burst)
local Catalog = require(ReplicatedStorage.Shared.Domain.Catalog)
local Card = require(script.Parent.Parent.Parent.Components.Card)
local Flash = require(script.Parent.Parent.Parent.Fx.Flash)
local Log = require(ReplicatedStorage.Shared.Core.Log)
local Motion = require(script.Parent.Parent.Parent.Motion)
local Odds = require(ReplicatedStorage.Shared.Domain.Odds)
local Rarities = require(ReplicatedStorage.Shared.Config.Rarities)
local Shake = require(script.Parent.Parent.Parent.Fx.Shake)
local Show = require(script.Parent.Show)

local TAG = "Shuffle"
local DEAL_DROP = 320
local DEAL_SECONDS = 0.38
local DEAL_STAGGER = 0.07
local FLIP_SECONDS = 0.16
local FIRST_SPIN = 0.045
local SLOWDOWN = 1.11
local BASE_SPINS = 7
local SPINS_PER_CARD = 4
-- The reel shows faces drawn with this much luck, so gold and pink flash by and tease.
local TEASE_LUCK = 30
local TREMBLE_STEP = 0.03

local Shuffle = {}

local function deal(show: Show.Show)
	local count = #show.Cards
	for index, card in show.Cards do
		local slot = Show.Slot(index, count)
		card.Root.Position = slot - UDim2.fromOffset(0, DEAL_DROP)
		card.Root.Rotation = show.Rng:NextNumber(-30, 30)
		card.Root.Visible = true
		Motion.Tween(card.Root, DEAL_SECONDS + index * DEAL_STAGGER, { Position = slot, Rotation = 0 }, Enum.EasingStyle.Back)
	end
	Audio.Play("Whoosh")
	task.wait(DEAL_SECONDS + count * DEAL_STAGGER)
end

local function tremble(show: Show.Show, card: Card.Card, rarity: Rarities.Rarity)
	local seconds = rarity.Fx.Suspense
	local elapsed = 0
	local beat = 0
	while elapsed < seconds do
		local tension = elapsed / seconds
		card.Root.Rotation = show.Rng:NextNumber(-1, 1) * (1 + 6 * tension)
		card:Glow(rarity.Color, 0.2 + 0.7 * tension)
		beat += 1
		if beat % 3 == 0 then
			Audio.Play("Tick", 1 + tension, 0.5 + 0.5 * tension)
		end
		elapsed += task.wait(TREMBLE_STEP)
	end
	card.Root.Rotation = 0
end

local function land(card: Card.Card, cardId: string)
	local rarity = Catalog.RarityOf(cardId)
	local tier = Catalog.TierOf(cardId)
	local fx = rarity.Fx

	card:Show(cardId)
	card:Glow(rarity.Color, 1)
	card:Glow(rarity.Color, if tier >= 3 then 0.45 else 0, 0.5)
	Motion.Pop(card.Scale, 1.22, 1, 0.4)

	Audio.Play("Land", 0.9 + tier * 0.06)
	if tier >= 3 then
		Audio.Play("Reveal", 0.8 + tier * 0.08, 0.7)
	end
	Burst.Play(Show.ScreenCenter(card.Root), rarity.Color, math.floor(fx.Sparks * 0.4), 0.7)
	Shake.Add(fx.Shake * 0.5)
	if tier >= 4 then
		Flash.Play(rarity.Color, fx.Flash * 0.4, 0.35)
	end
end

local function spin(show: Show.Show, index: number)
	local card = show.Cards[index]
	local cardId = show.Result.Hand[index]
	local rarity = Catalog.RarityOf(cardId)
	local spins = BASE_SPINS + (index - 1) * SPINS_PER_CARD
	local interval = FIRST_SPIN

	card:Flip(Odds.RollCard(show.Rng, TEASE_LUCK), FLIP_SECONDS)
	for step = 1, spins do
		card:Show(Odds.RollCard(show.Rng, TEASE_LUCK))
		Motion.Pop(card.Scale, 1.05, 1, interval)
		Audio.Play("Tick", 0.8 + step / spins * 0.7, 0.5)
		task.wait(interval)
		interval *= SLOWDOWN
	end
	if rarity.Fx.Suspense > 0 then
		tremble(show, card, rarity)
	end
	land(card, cardId)
end

-- Yields until every card has locked.
function Shuffle.Run(show: Show.Show)
	deal(show)
	local spinning = #show.Cards
	for index in show.Cards do
		show.Scope:Spawn(function()
			local ok, err = pcall(spin, show, index)
			if not ok then
				Log.Warn(TAG, err)
			end
			spinning -= 1
		end)
	end
	while spinning > 0 do
		task.wait()
	end
end

return table.freeze(Shuffle)
