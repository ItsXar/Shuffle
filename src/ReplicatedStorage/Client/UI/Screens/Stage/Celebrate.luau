--!strict
--[[
	Phase 4 of a roll show: the payoff, as big as the rarity of the kept card (Config/Rarities > Fx).
	Blackout rarities charge up first: the world goes dark, light streaks rush into the card and it
	shudders. Then everything hits at once: card flash, screen flash, shake, sparks, rings, and by
	rarity a sunburst with rising motes, a colour flood with the big banner, confetti. The card
	holds the spotlight, then flies into the BACKPACK button.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Audio = require(ReplicatedStorage.Client.Core.Audio)
local Aura = require(script.Parent.Parent.Parent.Fx.Aura)
local Banner = require(script.Parent.Parent.Parent.Fx.Banner)
local Burst = require(script.Parent.Parent.Parent.Fx.Burst)
local Catalog = require(ReplicatedStorage.Shared.Domain.Catalog)
local Confetti = require(script.Parent.Parent.Parent.Fx.Confetti)
local Converge = require(script.Parent.Parent.Parent.Fx.Converge)
local Flash = require(script.Parent.Parent.Parent.Fx.Flash)
local Flood = require(script.Parent.Parent.Parent.Fx.Flood)
local Make = require(script.Parent.Parent.Parent.Make)
local Motion = require(script.Parent.Parent.Parent.Motion)
local Paint = require(script.Parent.Parent.Parent.Paint)
local Rays = require(script.Parent.Parent.Parent.Fx.Rays)
local Ring = require(script.Parent.Parent.Parent.Fx.Ring)
local Shake = require(script.Parent.Parent.Parent.Fx.Shake)
local Show = require(script.Parent.Show)
local Theme = require(ReplicatedStorage.Shared.Config.Theme)
local Zoom = require(script.Parent.Parent.Parent.Fx.Zoom)

local BLACKOUT = 0.75
local CHARGE_SECONDS = 0.7
local CHARGE_BEATS = 7
local COLLECT_SECONDS = 0.38

local Celebrate = {}

local function charge(show: Show.Show): () -> ()
	local rarity, card = show.Rarity, show.Best
	local lift = show.Scope:Add(Flash.Dim(BLACKOUT, 0.45))
	show.Scope:Add(Zoom.Reset)
	Zoom.To(-10, CHARGE_SECONDS, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	Converge.Play(Show.ScreenCenter(card.Root), rarity.Color, 40 + show.Tier * 8, CHARGE_SECONDS)
	card:Glow(rarity.Color, 1, CHARGE_SECONDS)
	Motion.Tween(card.Scale, CHARGE_SECONDS, { Scale = Show.FocusScale * 0.9 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	Audio.Play("Whoosh", 0.6)
	for _ = 1, CHARGE_BEATS do
		Shake.Add(0.06)
		task.wait(CHARGE_SECONDS / CHARGE_BEATS)
	end
	return lift
end

-- Small rarity name under the card, for pulls without the big banner.
local function label(show: Show.Show): () -> ()
	local rarity = show.Rarity
	local text: TextLabel = Make("TextLabel", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = Show.Focus() + UDim2.fromOffset(0, Theme.Card.Size.Y * Show.FocusScale / 2 + 8),
		Size = UDim2.fromOffset(300, 30),
		BackgroundTransparency = 1,
		Text = string.upper(rarity.Name),
		TextColor3 = Paint.Tint(rarity.Color, 0.2),
		TextTransparency = 1,
		TextScaled = true,
		Font = Theme.Fonts.Display,
		ZIndex = 7,
		Parent = show.Canvas,
	}, {
		Make("UIStroke", { Thickness = 2, Color = Theme.Colors.Ink }),
	})
	Motion.Pop(Make("UIScale", { Parent = text }), 2.2, 1, 0.3)
	Motion.Tween(text, 0.3, { TextTransparency = 0 })
	return function()
		Motion.Tween(text, 0.25, { TextTransparency = 1 })
		Motion.Tween(text:FindFirstChildOfClass("UIStroke") :: UIStroke, 0.25, { Transparency = 1 })
	end
end

local function hit(show: Show.Show, cleanup: { () -> () })
	local rarity, fx, card, tier = show.Rarity, show.Rarity.Fx, show.Best, show.Tier
	local at = Show.ScreenCenter(card.Root)

	card:Flash(0.5)
	if tier >= 3 then
		Zoom.Punch(4 + tier * 1.5, 0.7)
	end
	Flash.Play(Paint.Tint(rarity.Color, 0.5), math.max(fx.Flash, 0.12), 0.7)
	Shake.Add(math.max(fx.Shake, 0.12))
	Burst.Play(at, rarity.Color, fx.Sparks + 20, 1 + tier * 0.08)
	Ring.Wave(at, rarity.Color, 300 + tier * 40, 1 + math.floor(tier / 2))
	Motion.Pop(card.Scale, Show.FocusScale * 1.2, Show.FocusScale, 0.55)

	if fx.Rays then
		table.insert(cleanup, Rays.Attach(show.Canvas, Show.Focus(), rarity.Color, 380 + tier * 30))
		table.insert(cleanup, Aura.Attach(card.Root, rarity.Color, 12 + tier * 6))
	end
	if fx.Banner then
		table.insert(cleanup, Flood.Attach(rarity.Color, math.min(0.35 + tier * 0.06, 0.9)))
		table.insert(cleanup, Banner.Show(rarity, Catalog.Card(show.Result.Hand[show.Result.Best]).Name))
	else
		table.insert(cleanup, label(show))
	end
	if fx.Confetti then
		Confetti.Play(rarity.Color, 60 + tier * 12)
	end
	if show.Result.New then
		card:Tag("NEW", Theme.Colors.New)
	end

	Audio.Play("Reveal", 0.7 + tier * 0.07)
	if fx.Banner then
		Audio.Play("Win")
	end
end

-- The card winds back and flies into the BACKPACK button.
local function collect(show: Show.Show)
	local card = show.Best
	local goal = Show.ToCanvas(show.Canvas, Show.ScreenCenter(show.Target))
	local style, direction = Enum.EasingStyle.Back, Enum.EasingDirection.In
	Motion.Tween(card.Scale, COLLECT_SECONDS, { Scale = 0.15 }, style, direction)
	Motion.Tween(card.Root, COLLECT_SECONDS, { Position = goal, Rotation = 25 }, style, direction)
	Audio.Play("Whoosh", 1.4)
	task.wait(COLLECT_SECONDS)

	card.Root.Visible = false
	local at = Show.ScreenCenter(show.Target)
	Burst.Play(at, show.Rarity.Color, 18, 0.5)
	Ring.Play(at, show.Rarity.Color, 200, 0.4, 4)
	Audio.Play("Snap", 1.2)
end

function Celebrate.Run(show: Show.Show)
	local fx = show.Rarity.Fx
	local lift = if fx.Blackout then charge(show) else nil
	local cleanup: { () -> () } = {}
	if lift then
		lift()
	end
	hit(show, cleanup)
	for _, release in cleanup do
		show.Scope:Add(release)
	end
	task.wait(fx.Hold)
	for _, release in cleanup do
		release()
	end
	collect(show)
end

return table.freeze(Celebrate)
