--!strict
--[[
	Phase 2 of a roll show: every card flips open and spins through random faces like a slot reel
	(each new face drops in, the halo flashes its colour, the card jitters), slowing down, the
	cards further right spinning longer. A card that landed Rare or better closes again and
	trembles, glowing ever brighter in its real colour, before it reveals. The reveal hits with a
	white flash, squash and stretch, sparks, a shockwave and the stars popping in.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Audio = require(ReplicatedStorage.Client.Core.Audio)
local Burst = require(script.Parent.Parent.Parent.Fx.Burst)
local Card = require(script.Parent.Parent.Parent.Components.Card)
local Catalog = require(ReplicatedStorage.Shared.Domain.Catalog)
local Flash = require(script.Parent.Parent.Parent.Fx.Flash)
local Log = require(ReplicatedStorage.Shared.Core.Log)
local Make = require(script.Parent.Parent.Parent.Make)
local Motion = require(script.Parent.Parent.Parent.Motion)
local Odds = require(ReplicatedStorage.Shared.Domain.Odds)
local Ring = require(script.Parent.Parent.Parent.Fx.Ring)
local Shake = require(script.Parent.Parent.Parent.Fx.Shake)
local Show = require(script.Parent.Show)

local TAG = "Reels"
local OPEN_SECONDS = 0.08
local FIRST_SPIN = 0.04
local SLOWDOWN = 1.08
local BASE_SPINS = 6
local SPINS_PER_CARD = 4
local DROP = 26
-- The reel shows faces drawn with this much luck, so gold and pink flash by and tease.
local TEASE_LUCK = 30

local Reels = {}

local function spin(show: Show.Show, card: Card.Card, index: number)
	card.Body.Size = UDim2.fromScale(0, 1)
	card:Show(Odds.RollCard(show.Rng, TEASE_LUCK))
	Motion.Await(Motion.Tween(card.Body, OPEN_SECONDS, { Size = UDim2.fromScale(1, 1) }))

	local interval = FIRST_SPIN
	local spins = BASE_SPINS + (index - 1) * SPINS_PER_CARD
	for step = 1, spins do
		local tease = Odds.RollCard(show.Rng, TEASE_LUCK)
		local color = Catalog.RarityOf(tease).Color
		card:Show(tease)
		local face = card.Face.Frame
		face.Position = UDim2.fromOffset(0, -DROP)
		Motion.Tween(face, interval * 0.9, { Position = UDim2.fromOffset(0, 0) })
		card:Glow(color, 0.7)
		card:Glow(color, 0, interval * 1.5)
		card.Root.Rotation = show.Rng:NextNumber(-2, 2)
		Audio.Play("Tick", 0.8 + step / spins * 0.7, 0.5)
		task.wait(interval)
		interval *= SLOWDOWN
	end
	card.Root.Rotation = 0
end

-- The closed card shakes harder and glows brighter in its real colour until it opens.
local function tension(show: Show.Show, card: Card.Card, index: number, cardId: string)
	local rarity = Catalog.RarityOf(cardId)
	local seconds = rarity.Fx.Suspense
	local slot = Show.Slot(index, #show.Cards)
	local rng = show.Rng
	card:Show(nil)
	local elapsed = 0
	while elapsed < seconds do
		local progress = elapsed / seconds
		local wobble = 4 * progress
		card.Root.Rotation = rng:NextNumber(-1, 1) * (1 + 7 * progress)
		card.Root.Position = slot + UDim2.fromOffset(rng:NextNumber(-1, 1) * wobble, rng:NextNumber(-1, 1) * wobble)
		card:Glow(rarity.Color, 0.25 + 0.75 * progress * (0.7 + 0.3 * math.sin(elapsed * 30)))
		if progress > 0.5 and rng:NextNumber() < 0.5 then
			Burst.Play(Show.ScreenCenter(card.Root), rarity.Color, 1, 0.3)
		end
		elapsed += task.wait()
	end
	card.Root.Rotation = 0
	card.Root.Position = slot
end

local function reveal(card: Card.Card, cardId: string)
	local rarity = Catalog.RarityOf(cardId)
	local tier = Catalog.TierOf(cardId)
	local fx = rarity.Fx

	card:Show(cardId)
	card:Flash(0.35)
	card:Squash(1.28, 0.78, 0.55)
	card:Glow(rarity.Color, 1)
	card:Glow(rarity.Color, if tier >= 3 then 0.55 else 0.15, 0.5)

	local at = Show.ScreenCenter(card.Root)
	Burst.Play(at, rarity.Color, math.floor(fx.Sparks * 0.45) + 6, 0.75)
	Ring.Play(at, rarity.Color, 220 + tier * 30, 0.5, 4 + tier)
	Shake.Add(fx.Shake * 0.5)
	if tier >= 4 then
		Flash.Play(rarity.Color, fx.Flash * 0.4, 0.35)
	end
	local stars = card.Face.Stars
	if stars then
		Motion.Pop(Make("UIScale", { Parent = stars }), 1.6, 1, 0.4)
	end
	Audio.Play("Land", 0.9 + tier * 0.06)
end

local function run(show: Show.Show, index: number)
	local card = show.Cards[index]
	local cardId = show.Result.Hand[index]
	spin(show, card, index)
	if Catalog.RarityOf(cardId).Fx.Suspense > 0 then
		tension(show, card, index, cardId)
	end
	reveal(card, cardId)
end

-- Yields until every card is revealed.
function Reels.Run(show: Show.Show)
	local running = #show.Cards
	for index in show.Cards do
		show.Scope:Spawn(function()
			local ok, err = pcall(function()
				run(show, index)
			end)
			if not ok then
				Log.Warn(TAG, err)
			end
			running -= 1
		end)
	end
	while running > 0 do
		task.wait()
	end
end

return table.freeze(Reels)
