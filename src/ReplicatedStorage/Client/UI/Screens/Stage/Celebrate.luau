--!strict
--[[
	Phase 3 of a roll show: the payoff, as big as the rarity of the kept card (Config/Rarities > Fx).
	Rare+ cards build up first (screen darkens, the card charges with light), then everything hits
	at once: flash, shake, shockwaves, sparks, sunburst, glowing screen edges, rising motes and the
	banner. The card holds the spotlight, then bursts into sparks and is gone.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Audio = require(ReplicatedStorage.Client.Core.Audio)
local Aura = require(script.Parent.Parent.Parent.Fx.Aura)
local Banner = require(script.Parent.Parent.Parent.Fx.Banner)
local Burst = require(script.Parent.Parent.Parent.Fx.Burst)
local Catalog = require(ReplicatedStorage.Shared.Domain.Catalog)
local Flash = require(script.Parent.Parent.Parent.Fx.Flash)
local Motion = require(script.Parent.Parent.Parent.Motion)
local Paint = require(script.Parent.Parent.Parent.Paint)
local Rays = require(script.Parent.Parent.Parent.Fx.Rays)
local Ring = require(script.Parent.Parent.Parent.Fx.Ring)
local Shake = require(script.Parent.Parent.Parent.Fx.Shake)
local Show = require(script.Parent.Show)
local Theme = require(ReplicatedStorage.Shared.Config.Theme)
local Vignette = require(script.Parent.Parent.Parent.Fx.Vignette)

local BLACKOUT = 0.78
local CHARGE_SECONDS = 0.55
local RAYS_SIZE = 470
local AURA_TIER = 3
local VIGNETTE_TIER = 4
local WIN_TIER = 5
local VANISH_SECONDS = 0.35

local Celebrate = {}

-- Before the hit: the world darkens (Fx.Blackout) and the card swells with light.
local function charge(show: Show.Show)
	local rarity, card = show.Rarity, show.Best
	if rarity.Fx.Blackout then
		show.Scope:Add(Flash.Dim(BLACKOUT, CHARGE_SECONDS))
	end
	card:Glow(rarity.Color, 1, CHARGE_SECONDS)
	Motion.Tween(card.Scale, CHARGE_SECONDS, { Scale = Show.FocusScale * 0.92 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	Ring.Play(Show.ScreenCenter(card.Root), Paint.Tint(rarity.Color, 0.4), 120, CHARGE_SECONDS, 2)
	Shake.Add(0.1 + show.Tier * 0.02)
	Audio.Play("Whoosh", 0.6)
	task.wait(CHARGE_SECONDS)
end

local function hit(show: Show.Show)
	local rarity, fx, card = show.Rarity, show.Rarity.Fx, show.Best
	local center = Show.ScreenCenter(card.Root)

	Flash.Play(Paint.Tint(rarity.Color, 0.5), fx.Flash, 0.7)
	Shake.Add(fx.Shake)
	Burst.Play(center, rarity.Color, fx.Sparks, 1 + show.Tier * 0.08)
	Ring.Wave(center, rarity.Color, 260 + show.Tier * 40, 1 + math.floor(show.Tier / 3))
	Motion.Pop(card.Scale, Show.FocusScale * 1.18, Show.FocusScale, 0.5)

	if fx.Rays then
		show.Scope:Add(Rays.Attach(show.Canvas, Show.Focus(), rarity.Color, RAYS_SIZE))
	end
	if show.Tier >= VIGNETTE_TIER then
		show.Scope:Add(Vignette.Attach(rarity.Color, math.min(0.25 + show.Tier * 0.07, 0.85)))
	end
	if show.Tier >= AURA_TIER then
		show.Scope:Add(Aura.Attach(card.Root, rarity.Color, 10 + show.Tier * 6))
	end
	if fx.Banner then
		Banner.Show(rarity, Catalog.Card(show.Result.Hand[show.Result.Best]).Name, fx.Hold)
	end
	if show.Result.New then
		card:Tag("NEW", Theme.Colors.New)
	end

	Audio.Play("Reveal", 0.7 + show.Tier * 0.07)
	if show.Tier >= WIN_TIER then
		Audio.Play("Win")
	end
end

-- The card flares, collapses and bursts into sparks.
local function vanish(show: Show.Show)
	local rarity, card = show.Rarity, show.Best
	card:Glow(rarity.Color, 1, 0.1)
	Motion.Tween(card.Scale, VANISH_SECONDS, { Scale = 0 }, Enum.EasingStyle.Back, Enum.EasingDirection.In)
	Motion.Tween(card.Root, VANISH_SECONDS, { Rotation = 12 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	task.wait(VANISH_SECONDS * 0.85)

	local center = Show.ScreenCenter(card.Root)
	Burst.Play(center, rarity.Color, 18 + show.Tier * 4, 0.6)
	Ring.Play(center, rarity.Color, 160, 0.4, 3)
	Audio.Play("Snap", 1.2)
	task.wait(VANISH_SECONDS * 0.15)
	card.Root.Visible = false
end

function Celebrate.Run(show: Show.Show)
	local fx = show.Rarity.Fx
	if show.Tier >= AURA_TIER then
		charge(show)
	end
	hit(show)
	task.wait(fx.Hold)
	vanish(show)
end

return table.freeze(Celebrate)
