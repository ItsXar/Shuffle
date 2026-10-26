--!strict
--[[
	Phase 2 of a roll show: every card flips open and spins through random faces like a slot reel
	(each new face drops in, the halo flashes its colour, the card jitters), slowing down, the
	cards further right spinning longer. A common result nearly stops on a better card first
	(near miss). A Rare-or-better result closes the card and climbs the rarities instead: it glows
	green, then blue, then purple... each step with a burst and the rarity name, trembling harder,
	until it reaches its real rarity. The reveal hits with a white flash, squash and stretch,
	sparks, a shockwave and the stars popping in.
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
local Paint = require(script.Parent.Parent.Parent.Paint)
local Ring = require(script.Parent.Parent.Parent.Fx.Ring)
local Shake = require(script.Parent.Parent.Parent.Fx.Shake)
local Show = require(script.Parent.Show)
local Theme = require(ReplicatedStorage.Shared.Config.Theme)

local TAG = "Reels"
local OPEN_SECONDS = 0.08
local FIRST_SPIN = 0.05
local SLOWDOWN = 1.09
local BASE_SPINS = 8
local SPINS_PER_CARD = 4
local NEAR_MISS_HOLD = 2.4
local CLIMB_FROM = 2
local DROP = 26
local FLIP_SECONDS = 0.08
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

-- A face of a better rarity than `cardId`, or nil when there is none.
local function better(show: Show.Show, cardId: string): string?
	local tier = Catalog.TierOf(cardId)
	local target = math.min(tier + show.Rng:NextInteger(1, 2), Catalog.TierCount())
	if target <= tier then
		return nil
	end
	local pool = Catalog.CardsOf(target)
	return pool[show.Rng:NextInteger(1, #pool)].Id
end

-- The reel slows right down on a better card... and flicks past it.
local function nearMiss(show: Show.Show, card: Card.Card, cardId: string)
	local tease = better(show, cardId)
	if not tease then
		return
	end
	local color = Catalog.RarityOf(tease).Color
	card:Show(tease)
	card:Glow(color, 0.8)
	card:Glow(color, 0.3, FIRST_SPIN * NEAR_MISS_HOLD * 4)
	task.wait(FIRST_SPIN * NEAR_MISS_HOLD * 4)
end

-- Rarity name shown under the card while it climbs.
local function climbLabel(show: Show.Show, index: number): TextLabel
	local slot = Show.Slot(index, #show.Cards)
	return show.Scope:Add(Make("TextLabel", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = slot + UDim2.fromOffset(0, Theme.Card.Size.Y / 2 + 14),
		Size = UDim2.fromOffset(Theme.Card.Size.X + 30, 26),
		BackgroundTransparency = 1,
		TextScaled = true,
		Font = Theme.Fonts.Display,
		TextTransparency = 1,
		ZIndex = 7,
		Parent = show.Canvas,
	}, {
		Make("UIStroke", { Thickness = 2, Color = Theme.Colors.Ink, Transparency = 1 }),
	}))
end

-- The closed card climbs rarity by rarity up to its real one, shaking harder at every step.
local function climb(show: Show.Show, card: Card.Card, index: number, cardId: string)
	local tier = Catalog.TierOf(cardId)
	local seconds = Catalog.RarityOf(cardId).Fx.Suspense
	local slot = Show.Slot(index, #show.Cards)
	local rng = show.Rng
	local label = climbLabel(show, index)
	local scale: UIScale = Make("UIScale", { Parent = label })
	local outline = label:FindFirstChildOfClass("UIStroke") :: UIStroke
	local steps = tier - CLIMB_FROM + 1
	local stepSeconds = seconds / steps
	card:Show(nil)

	for step = 1, steps do
		local rarity = Catalog.Rarity(CLIMB_FROM + step - 1)
		local strength = step / steps
		label.Text = string.upper(rarity.Name)
		label.TextColor3 = Paint.Tint(rarity.Color, 0.2)
		label.TextTransparency = 0
		outline.Transparency = 0
		Motion.Pop(scale, 1.8, 1, 0.3)
		local at = Show.ScreenCenter(card.Root)
		Burst.Play(at, rarity.Color, 8 + step * 4, 0.5)
		Ring.Play(at, rarity.Color, 180 + step * 30, 0.4, 3 + step)
		Shake.Add(0.05 + strength * 0.12)
		card:Flash(0.2)
		Audio.Play("Tick", 1 + step * 0.15)

		local elapsed = 0
		while elapsed < stepSeconds do
			local wobble = 1 + 5 * strength
			card.Root.Rotation = rng:NextNumber(-1, 1) * (1 + 6 * strength)
			card.Root.Position = slot + UDim2.fromOffset(rng:NextNumber(-1, 1) * wobble, rng:NextNumber(-1, 1) * wobble)
			card:Glow(rarity.Color, 0.35 + 0.65 * strength * (0.75 + 0.25 * math.sin(elapsed * 30)))
			elapsed += task.wait()
		end
	end
	card.Root.Rotation = 0
	card.Root.Position = slot
	Motion.Tween(label, 0.4, { TextTransparency = 1 })
	Motion.Tween(outline, 0.4, { Transparency = 1 })
end

local function reveal(card: Card.Card, cardId: string)
	local rarity = Catalog.RarityOf(cardId)
	local tier = Catalog.TierOf(cardId)
	local fx = rarity.Fx

	-- flip: the closed side turns edge-on, the face swings out with a squash
	Motion.Await(Motion.Tween(card.Body, FLIP_SECONDS, { Size = UDim2.fromScale(0, 1.05) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In))
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
	if Catalog.TierOf(cardId) > CLIMB_FROM then
		climb(show, card, index, cardId)
	else
		nearMiss(show, card, cardId)
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
