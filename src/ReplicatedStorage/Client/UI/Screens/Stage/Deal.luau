--!strict
--[[
	Phase 1 of a roll show: three closed cards shoot out of the ROLL button, spinning and growing,
	leaving a fading trail, and slam into their slots with a squash, a ring and a few sparks.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Burst = require(script.Parent.Parent.Parent.Fx.Burst)
local Card = require(script.Parent.Parent.Parent.Components.Card)
local Make = require(script.Parent.Parent.Parent.Make)
local Motion = require(script.Parent.Parent.Parent.Motion)
local Paint = require(script.Parent.Parent.Parent.Paint)
local Ring = require(script.Parent.Parent.Parent.Fx.Ring)
local Show = require(script.Parent.Show)
local Theme = require(ReplicatedStorage.Shared.Config.Theme)

local FLIGHT = 0.34
local STAGGER = 0.07
local GHOST_FADE = 0.18

local Deal = {}

-- A fading copy of the card's outline, left behind every frame while it flies.
local function trail(show: Show.Show, card: Card.Card): () -> ()
	local size = Theme.Card.Size
	local color = Paint.Tint(Theme.Colors.BackTop, 0.3)
	local root = card.Root
	local connection = RunService.RenderStepped:Connect(function()
		local scale = card.Scale.Scale
		local ghost: Frame = Make("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = root.Position,
			Size = UDim2.fromOffset(size.X * scale, size.Y * scale),
			Rotation = root.Rotation,
			BackgroundColor3 = color,
			BackgroundTransparency = 0.55,
			BorderSizePixel = 0,
			ZIndex = 1,
			Parent = show.Canvas,
		}, {
			Make("UICorner", { CornerRadius = UDim.new(0, Theme.Card.Corner) }),
		})
		Motion.Tween(ghost, GHOST_FADE, { BackgroundTransparency = 1 }).Completed:Once(function()
			ghost:Destroy()
		end)
	end)
	return function()
		connection:Disconnect()
	end
end

local function fly(show: Show.Show, index: number, from: UDim2)
	local card = show.Cards[index]
	local root = card.Root
	root.Position = from
	root.Rotation = -200 + index * 40
	card.Scale.Scale = 0.25
	root.Visible = true

	local stop = show.Scope:Add(trail(show, card))
	local style = Enum.EasingStyle.Quart
	Motion.Tween(card.Scale, FLIGHT, { Scale = 1 }, style)
	Motion.Tween(root, FLIGHT, { Position = Show.Slot(index, #show.Cards), Rotation = 0 }, style)
	task.wait(FLIGHT)
	stop()

	card:Squash(1.2, 0.82, 0.45)
	local at = Show.ScreenCenter(root)
	Ring.Play(at, Paint.Tint(Theme.Colors.BackTop, 0.4), 230, 0.4, 5)
	Burst.Play(at, Theme.Colors.BackTop, 8, 0.5)
end

-- Yields until every card has landed.
function Deal.Run(show: Show.Show)
	local from = Show.ToCanvas(show.Canvas, Show.ScreenCenter(show.Origin))
	for index in show.Cards do
		show.Scope:Delay((index - 1) * STAGGER, function()
			fly(show, index, from)
		end)
	end
	task.wait(FLIGHT + #show.Cards * STAGGER + 0.05)
end

return table.freeze(Deal)
