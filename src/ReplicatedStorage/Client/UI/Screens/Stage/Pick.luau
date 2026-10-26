--!strict
--[[
	Phase 3 of a roll show: the system picks the best card. A beam of light sweeps across the row,
	the winner pops up glowing while the others dim, shrink and shatter into shards, and the winner
	spins once to the centre of the stage, growing.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Audio = require(ReplicatedStorage.Client.Core.Audio)
local Burst = require(script.Parent.Parent.Parent.Fx.Burst)
local Catalog = require(ReplicatedStorage.Shared.Domain.Catalog)
local Make = require(script.Parent.Parent.Parent.Make)
local Motion = require(script.Parent.Parent.Parent.Motion)
local Ring = require(script.Parent.Parent.Parent.Fx.Ring)
local Show = require(script.Parent.Show)
local Theme = require(ReplicatedStorage.Shared.Config.Theme)

local PAUSE = 0.12
local SWEEP_SECONDS = 0.32
local SWEEP_REACH = 330
local LOSER_SCALE = 0.88
local SHATTER_SECONDS = 0.16
local FOCUS_SECONDS = 0.45

local BEAM_FADE = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 1),
	NumberSequenceKeypoint.new(0.5, 0.2),
	NumberSequenceKeypoint.new(1, 1),
})

local Pick = {}

local function sweep(show: Show.Show)
	local beam: Frame = show.Scope:Add(Make("Frame", {
		Name = "Beam",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, -SWEEP_REACH, 0, Show.RowY),
		Size = UDim2.fromOffset(70, Theme.Card.Size.Y + 60),
		Rotation = 12,
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		ZIndex = 6,
		Parent = show.Canvas,
	}, {
		Make("UIGradient", { Transparency = BEAM_FADE }),
	}))
	local goal = UDim2.new(0.5, SWEEP_REACH, 0, Show.RowY)
	Audio.Play("Whoosh", 1.3)
	Motion.Await(Motion.Tween(beam, SWEEP_SECONDS, { Position = goal }, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut))
	beam:Destroy()
end

local function choose(show: Show.Show)
	local winner = show.Best
	winner.Root.ZIndex = 4
	Motion.Pop(winner.Scale, 1.18, 1.08, 0.35)
	winner:Glow(show.Rarity.Color, 1, 0.15)
	Ring.Play(Show.ScreenCenter(winner.Root), Color3.new(1, 1, 1), 260, 0.45, 5)
	for index, card in show.Cards do
		if index ~= show.Result.Best then
			card:Dim(0.6, 0.2)
			Motion.Tween(card.Scale, 0.2, { Scale = LOSER_SCALE })
		end
	end
	Audio.Play("Snap")
	task.wait(0.32)
end

local function shatter(show: Show.Show)
	for index, card in show.Cards do
		if index ~= show.Result.Best then
			local color = Catalog.RarityOf(show.Result.Hand[index]).Color
			Burst.Play(Show.ScreenCenter(card.Root), color, 22, 0.55, true)
			local tilt = show.Rng:NextNumber(-60, 60)
			Motion.Tween(card.Root, SHATTER_SECONDS, { Rotation = tilt }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			Motion.Tween(card.Scale, SHATTER_SECONDS, { Scale = 0 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		end
	end
end

local function focus(show: Show.Show)
	local winner = show.Best
	winner.Root.Rotation = 0
	Motion.Tween(winner.Root, FOCUS_SECONDS + 0.05, { Rotation = 360 }, Enum.EasingStyle.Back)
	Motion.Tween(winner.Scale, FOCUS_SECONDS, { Scale = Show.FocusScale }, Enum.EasingStyle.Back)
	Motion.Tween(winner.Root, FOCUS_SECONDS, { Position = Show.Focus() }, Enum.EasingStyle.Quart)
	Audio.Play("Whoosh", 1.1)
	task.wait(FOCUS_SECONDS + 0.05)
	winner.Root.Rotation = 0
end

function Pick.Run(show: Show.Show)
	task.wait(PAUSE)
	sweep(show)
	choose(show)
	shatter(show)
	focus(show)
end

return table.freeze(Pick)
