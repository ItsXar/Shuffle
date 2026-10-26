--!strict
--[[
	The bottom of the screen: room for the deck bar on top (Canvas), and under it the buttons:
	BACKPACK (red badge counting cards found since it was last opened; won cards fly into it),
	AUTO ROLL (toggle) and ROLL (breathes while idle, punches when a roll starts; rolled cards fly
	out of it). Shows state only: presses call Actions, which the controllers fill in.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Badge = require(script.Badge)
local Button = require(script.Parent.Parent.Components.Button)
local Fit = require(script.Parent.Parent.Fit)
local Make = require(script.Parent.Parent.Make)
local Motion = require(script.Parent.Parent.Motion)
local Paint = require(script.Parent.Parent.Paint)
local Root = require(script.Parent.Parent.Root)
local Theme = require(ReplicatedStorage.Shared.Config.Theme)

local BREATH = 0.03
local BREATH_SPEED = 3.5
local BUTTONS_Y = 150

export type Actions = {
	OnRoll: () -> (),
	OnAuto: () -> (),
	OnBackpack: () -> (),
}

export type Hud = {
	Canvas: Frame,
	Actions: Actions,
	SetBusy: (self: Hud, busy: boolean) -> (),
	SetAuto: (self: Hud, on: boolean) -> (),
	SetBadge: (self: Hud, count: number) -> (),
	-- Where rolled cards fly out of.
	Origin: (self: Hud) -> GuiObject,
	-- Where won cards fly into; it bumps when one lands.
	Backpack: (self: Hud) -> GuiObject,
	BumpBackpack: (self: Hud) -> (),
}

local Hud = {}

function Hud.new(): Hud
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

	local actions: Actions = {
		OnRoll = function() end,
		OnAuto = function() end,
		OnBackpack = function() end,
	}
	local backpack = Button.new({
		Parent = canvas,
		Position = UDim2.fromOffset(43, BUTTONS_Y),
		Size = UDim2.fromOffset(66, 58),
		Color = colors.Backpack,
		Text = "BACKPACK",
		Icon = "🎒",
		OnClick = function()
			actions.OnBackpack()
		end,
	})
	local badge = Badge(backpack.Root)
	local auto = Button.new({
		Parent = canvas,
		Position = UDim2.fromOffset(163, BUTTONS_Y),
		Size = UDim2.fromOffset(150, 54),
		Color = colors.AutoOff,
		Text = "AUTO ROLL",
		OnClick = function()
			actions.OnAuto()
		end,
	})
	local roll = Button.new({
		Parent = canvas,
		Position = UDim2.fromOffset(350, BUTTONS_Y - 2),
		Size = UDim2.fromOffset(200, 62),
		Color = colors.Roll,
		Text = "ROLL",
		OnClick = function()
			actions.OnRoll()
		end,
	})

	local busy = false
	Paint.Animate(canvas, function(elapsed: number)
		if not busy then
			roll.Breath.Scale = 1 + BREATH * math.sin(elapsed * BREATH_SPEED)
		end
	end)

	local self = { Canvas = canvas, Actions = actions } :: Hud

	function self.SetBusy(_: Hud, value: boolean)
		busy = value
		if value then
			Motion.Pop(roll.Breath, 0.85, 1, 0.3)
		end
		roll:SetText(if value then "ROLLING..." else "ROLL")
		roll:SetColor(if value then colors.RollBusy else colors.Roll)
	end

	function self.SetAuto(_: Hud, on: boolean)
		auto:SetColor(if on then colors.AutoOn else colors.AutoOff)
	end

	function self.SetBadge(_: Hud, count: number)
		badge:Set(count)
	end

	function self.Origin(_: Hud): GuiObject
		return roll.Root
	end

	function self.Backpack(_: Hud): GuiObject
		return backpack.Root
	end

	function self.BumpBackpack(_: Hud)
		Motion.Pop(backpack.Breath, 1.25, 1, 0.4)
	end

	return self
end

return table.freeze(Hud)
