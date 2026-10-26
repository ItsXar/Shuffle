--!strict
--[[
	The two buttons at the bottom of the screen: AUTO ROLL (toggle) and ROLL (breathes while idle).
	Shows state only: every press goes to the actions given by the owner (RollController).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Button = require(script.Parent.Parent.Components.Button)
local Fit = require(script.Parent.Parent.Fit)
local Make = require(script.Parent.Parent.Make)
local Paint = require(script.Parent.Parent.Paint)
local Root = require(script.Parent.Parent.Root)
local Theme = require(ReplicatedStorage.Shared.Config.Theme)

local BREATH = 0.03
local BREATH_SPEED = 3.5

export type Actions = {
	OnRoll: () -> (),
	OnAuto: () -> (),
}

export type Hud = {
	SetBusy: (self: Hud, busy: boolean) -> (),
	SetAuto: (self: Hud, on: boolean) -> (),
}

local Hud = {}

function Hud.new(actions: Actions): Hud
	local design = Theme.Hud.Design
	local colors = Theme.Colors
	local canvas: Frame = Make("Frame", {
		Name = "Canvas",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -Theme.Hud.Bottom),
		Size = UDim2.fromOffset(design.X, design.Y),
		BackgroundTransparency = 1,
		Parent = Root.Layer("Hud"),
	})
	Fit.Attach(canvas, design, Theme.Hud.HeightShare)

	local auto = Button.new({
		Parent = canvas,
		Position = UDim2.fromOffset(88, 40),
		Size = UDim2.fromOffset(156, 54),
		Color = colors.AutoOff,
		Text = "AUTO ROLL",
		OnClick = actions.OnAuto,
	})
	local roll = Button.new({
		Parent = canvas,
		Position = UDim2.fromOffset(284, 38),
		Size = UDim2.fromOffset(212, 62),
		Color = colors.Roll,
		Text = "ROLL",
		OnClick = actions.OnRoll,
	})

	local busy = false
	Paint.Animate(canvas, function(elapsed: number)
		roll.Breath.Scale = if busy then 1 else 1 + BREATH * math.sin(elapsed * BREATH_SPEED)
	end)

	local self = {} :: Hud

	function self.SetBusy(_: Hud, value: boolean)
		busy = value
		roll:SetText(if value then "ROLLING..." else "ROLL")
		roll:SetColor(if value then colors.RollBusy else colors.Roll)
	end

	function self.SetAuto(_: Hud, on: boolean)
		auto:SetColor(if on then colors.AutoOn else colors.AutoOff)
	end

	return self
end

return table.freeze(Hud)
