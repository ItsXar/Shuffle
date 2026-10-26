--!strict
--[[
	Controls at the bottom of the screen: the big ROLL button (breathes while idle), the AUTO
	toggle, rolls count, best rarity (where won cards fly to) and the lucky roll meter.
	Shows state only: every press goes to the actions given by the owner (RollController).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Button = require(script.Parent.Parent.Components.Button)
local Catalog = require(ReplicatedStorage.Shared.Domain.Catalog)
local Chip = require(script.Parent.Parent.Components.Chip)
local Fit = require(script.Parent.Parent.Fit)
local Input = require(ReplicatedStorage.Shared.Config.Input)
local LuckyMeter = require(script.LuckyMeter)
local Make = require(script.Parent.Parent.Make)
local Odds = require(ReplicatedStorage.Shared.Domain.Odds)
local Paint = require(script.Parent.Parent.Paint)
local Root = require(script.Parent.Parent.Root)
local Theme = require(ReplicatedStorage.Shared.Config.Theme)

local BREATH = 0.035
local BREATH_SPEED = 3.5

export type Actions = {
	OnRoll: () -> (),
	OnAuto: () -> (),
}

export type Hud = {
	SetBusy: (self: Hud, busy: boolean) -> (),
	SetAuto: (self: Hud, on: boolean) -> (),
	Update: (self: Hud, result: Odds.Result) -> (),
	Target: (self: Hud) -> GuiObject,
}

local Hud = {}

-- "[R]" on keyboards; nothing on touch screens.
local function hint(keys: { Enum.KeyCode }): string?
	if not UserInputService.KeyboardEnabled then
		return nil
	end
	return `[{UserInputService:GetStringForKeyCode(keys[1])}]`
end

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

	local rolls = Chip.new(canvas, UDim2.fromOffset(110, 28), UDim2.fromOffset(190, 48), "🎲", "Rolls: 0")
	local best = Chip.new(canvas, UDim2.fromOffset(530, 28), UDim2.fromOffset(190, 48), "🏆", "Best: -")
	local lucky = LuckyMeter.new(canvas, UDim2.fromOffset(320, 28), UDim2.fromOffset(210, 40))

	local roll = Button.new({
		Parent = canvas,
		Position = UDim2.fromOffset(320, 128),
		Size = UDim2.fromOffset(250, 90),
		Color = colors.Roll,
		Text = "ROLL",
		Hint = hint(Input.Roll),
		OnClick = actions.OnRoll,
	})
	local auto = Button.new({
		Parent = canvas,
		Position = UDim2.fromOffset(110, 134),
		Size = UDim2.fromOffset(150, 70),
		Color = colors.AutoOff,
		Text = "AUTO: OFF",
		Hint = hint(Input.Auto),
		OnClick = actions.OnAuto,
	})

	local busy = false
	local bestTier = 0
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
		auto:SetText(if on then "AUTO: ON" else "AUTO: OFF")
		auto:SetColor(if on then colors.AutoOn else colors.AutoOff)
	end

	function self.Update(_: Hud, result: Odds.Result)
		rolls:SetText(`Rolls: {result.Rolls}`)
		rolls:Bump()
		lucky:Set(result.UntilLucky)

		local tier = Catalog.TierOf(result.Hand[result.Best])
		if tier > bestTier then
			bestTier = tier
			local rarity = Catalog.Rarity(tier)
			best:SetText(`Best: {rarity.Name}`)
			best:SetColor(rarity.Color)
			best:Bump(0.35)
		else
			best:Bump(0.1)
		end
	end

	function self.Target(_: Hud): GuiObject
		return best.Root
	end

	return self
end

return table.freeze(Hud)
