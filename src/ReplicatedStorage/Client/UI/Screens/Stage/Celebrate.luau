--!strict
--[[
	Phase 3 of a roll show: the payoff, as big as the rarity of the kept card (Config/Rarities > Fx).
	Optional blackout, then flash, shake, sparks, sunburst, banner and sound all hit at once; the
	card holds the spotlight, then shrinks and flies into the Hud.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Audio = require(ReplicatedStorage.Client.Core.Audio)
local Banner = require(script.Parent.Parent.Parent.Fx.Banner)
local Burst = require(script.Parent.Parent.Parent.Fx.Burst)
local Catalog = require(ReplicatedStorage.Shared.Domain.Catalog)
local Flash = require(script.Parent.Parent.Parent.Fx.Flash)
local Motion = require(script.Parent.Parent.Parent.Motion)
local Paint = require(script.Parent.Parent.Parent.Paint)
local Rays = require(script.Parent.Parent.Parent.Fx.Rays)
local Shake = require(script.Parent.Parent.Parent.Fx.Shake)
local Show = require(script.Parent.Show)
local Theme = require(ReplicatedStorage.Shared.Config.Theme)

local BLACKOUT = 0.75
local BLACKOUT_SECONDS = 0.55
local RAYS_SIZE = 560
local WIN_TIER = 5
local COLLECT_SECONDS = 0.42

local Celebrate = {}

local function blackout(show: Show.Show): () -> ()
	local lift = show.Scope:Add(Flash.Dim(BLACKOUT, BLACKOUT_SECONDS))
	show.Best:Glow(show.Rarity.Color, 0.9, BLACKOUT_SECONDS)
	Shake.Add(0.15)
	Audio.Play("Whoosh", 0.6)
	task.wait(BLACKOUT_SECONDS + 0.15)
	return lift
end

local function explode(show: Show.Show)
	local rarity, fx, card = show.Rarity, show.Rarity.Fx, show.Best
	Flash.Play(Paint.Tint(rarity.Color, 0.5), fx.Flash, 0.7)
	Shake.Add(fx.Shake)
	Burst.Play(Show.ScreenCenter(card.Root), rarity.Color, fx.Sparks, 1 + show.Tier * 0.08)
	card:Glow(rarity.Color, 1, 0.15)
	Motion.Pop(card.Scale, Show.FocusScale * 1.2, Show.FocusScale, 0.5)

	if fx.Rays then
		show.Scope:Add(Rays.Attach(show.Canvas, Show.Focus(), rarity.Color, RAYS_SIZE))
	end
	if fx.Banner then
		Banner.Show(rarity, Catalog.Card(show.Result.Hand[show.Result.Best]).Name, fx.Hold)
	end
	if show.Result.New then
		card:Tag("NEW!", Theme.Colors.New)
	end

	Audio.Play("Reveal", 0.7 + show.Tier * 0.07)
	if show.Tier >= WIN_TIER then
		Audio.Play("Win")
	end
end

local function collect(show: Show.Show, target: GuiObject?)
	local root = show.Best.Root
	Motion.Tween(show.Best.Scale, COLLECT_SECONDS, { Scale = 0.2 }, Enum.EasingStyle.Back, Enum.EasingDirection.In)
	if target then
		local goal = Show.ToCanvas(show.Canvas, Show.ScreenCenter(target))
		Motion.Tween(root, COLLECT_SECONDS, { Position = goal, Rotation = 25 }, Enum.EasingStyle.Back, Enum.EasingDirection.In)
	end
	Audio.Play("Whoosh", 1.4)
	task.wait(COLLECT_SECONDS)

	root.Visible = false
	Audio.Play("Snap", 1.2)
	if target then
		Burst.Play(Show.ScreenCenter(target), show.Rarity.Color, 14, 0.45)
	end
end

function Celebrate.Run(show: Show.Show, target: GuiObject?)
	local lift = if show.Rarity.Fx.Blackout then blackout(show) else nil
	explode(show)
	if lift then
		lift()
	end
	task.wait(show.Rarity.Fx.Hold)
	collect(show, target)
end

return table.freeze(Celebrate)
