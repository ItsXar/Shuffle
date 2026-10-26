--!strict
--[[
	Phase 2 of a roll show: the system picks the best card. A selector frame races across the row
	like a roulette, slows down and stops on the winner. The other cards dim and fall away; the
	winner moves to the centre and grows. A high rarity gets an extra lap of the roulette.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Audio = require(ReplicatedStorage.Client.Core.Audio)
local Make = require(script.Parent.Parent.Parent.Make)
local Motion = require(script.Parent.Parent.Parent.Motion)
local Show = require(script.Parent.Show)
local Theme = require(ReplicatedStorage.Shared.Config.Theme)

local FIRST_HOP = 0.07
local HOP_SLOWDOWN = 1.17
local EXTRA_LAP_TIER = 5
local SELECTOR_PAD = 22
local FALL_DISTANCE = 420
local FOCUS_SECONDS = 0.45

local Pick = {}

type Selector = { Frame: Frame, Stroke: UIStroke, Scale: UIScale }

local function selector(show: Show.Show): Selector
	local size = Theme.Card.Size
	local stroke: UIStroke = Make("UIStroke", { Thickness = 6, Color = Theme.Colors.Selector })
	local scale: UIScale = Make("UIScale", {})
	local frame: Frame = show.Scope:Add(Make("Frame", {
		Name = "Selector",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(size.X + SELECTOR_PAD, size.Y + SELECTOR_PAD),
		BackgroundTransparency = 1,
		Visible = false,
		ZIndex = 5,
		Parent = show.Canvas,
	}, {
		Make("UICorner", { CornerRadius = UDim.new(0, Theme.Card.Corner + SELECTOR_PAD / 2) }),
		stroke,
		scale,
	}))
	return { Frame = frame, Stroke = stroke, Scale = scale }
end

-- Every card once per lap, then up to the winner.
local function route(show: Show.Show): { number }
	local count = #show.Cards
	local laps = if show.Tier >= EXTRA_LAP_TIER then 2 else 1
	local path = {}
	for _ = 1, laps do
		for index = 1, count do
			table.insert(path, index)
		end
	end
	for index = 1, show.Result.Best do
		table.insert(path, index)
	end
	return path
end

local function race(show: Show.Show, target: Selector)
	local count = #show.Cards
	local path = route(show)
	local interval = FIRST_HOP
	target.Frame.Visible = true
	for step, index in path do
		target.Frame.Position = Show.Slot(index, count)
		Motion.Pop(target.Scale, 1.08, 1, interval)
		Motion.Pop(show.Cards[index].Scale, 1.06, 1, interval)
		Audio.Play("Tick", 1.1 + step / #path * 0.6, 0.6)
		task.wait(interval)
		interval *= HOP_SLOWDOWN
	end

	target.Stroke.Color = show.Rarity.Color
	Motion.Pop(target.Scale, 1.18, 1, 0.3)
	Audio.Play("Snap")
	task.wait(0.25)
end

local function focus(show: Show.Show, target: Selector)
	for index, card in show.Cards do
		if index ~= show.Result.Best then
			card:Dim(0.6, 0.2)
			local fall = card.Root.Position + UDim2.fromOffset(0, FALL_DISTANCE)
			local tilt = show.Rng:NextNumber(-40, 40)
			Motion.Tween(card.Root, 0.55, { Position = fall, Rotation = tilt }, Enum.EasingStyle.Back, Enum.EasingDirection.In)
			Motion.Tween(card.Scale, 0.55, { Scale = 0.6 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		end
	end

	Motion.Tween(target.Stroke, 0.2, { Transparency = 1 })
	Motion.Tween(show.Best.Root, FOCUS_SECONDS, { Position = Show.Focus() }, Enum.EasingStyle.Back)
	Motion.Tween(show.Best.Scale, FOCUS_SECONDS, { Scale = Show.FocusScale }, Enum.EasingStyle.Back)
	Audio.Play("Whoosh", 1.2)
	task.wait(FOCUS_SECONDS)
end

function Pick.Run(show: Show.Show)
	local target = selector(show)
	race(show, target)
	focus(show, target)
end

return table.freeze(Pick)
