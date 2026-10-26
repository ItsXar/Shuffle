--!strict
--[[
	Progress bar towards the next lucky roll (Config/Roll > LuckyEvery). When the next roll is the
	lucky one, the bar is full, says so, and pulses gold.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Make = require(script.Parent.Parent.Parent.Make)
local Motion = require(script.Parent.Parent.Parent.Motion)
local Paint = require(script.Parent.Parent.Parent.Paint)
local RollConfig = require(ReplicatedStorage.Shared.Config.Roll)
local Theme = require(ReplicatedStorage.Shared.Config.Theme)

local PULSE_SPEED = 6

export type LuckyMeter = {
	Root: Frame,
	Set: (self: LuckyMeter, untilLucky: number) -> (),
}

local LuckyMeter = {}

function LuckyMeter.new(parent: Instance, position: UDim2, size: UDim2): LuckyMeter
	local colors = Theme.Colors
	local stroke: UIStroke = Make("UIStroke", { Thickness = 3, Color = colors.PanelEdge })
	local root: Frame = Make("Frame", {
		Name = "LuckyMeter",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = position,
		Size = size,
		BackgroundColor3 = colors.Panel,
		BackgroundTransparency = 0.1,
		ClipsDescendants = true,
		Parent = parent,
	}, {
		Make("UICorner", { CornerRadius = UDim.new(1, 0) }),
		stroke,
	})
	local fill: Frame = Make("Frame", {
		Name = "Fill",
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = colors.Lucky,
		Parent = root,
	}, {
		Make("UICorner", { CornerRadius = UDim.new(1, 0) }),
		Make("UIGradient", { Color = ColorSequence.new(Paint.Shade(colors.Lucky, 0.25), colors.Lucky) }),
	})
	local label: TextLabel = Make("TextLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.9, 0.6),
		BackgroundTransparency = 1,
		TextColor3 = colors.Text,
		TextScaled = true,
		Font = Theme.Fonts.Title,
		ZIndex = 2,
		Parent = root,
	}, {
		Make("UIStroke", { Thickness = 2, Color = colors.Ink }),
	})

	local ready = false
	Paint.Animate(root, function(elapsed: number)
		if ready then
			stroke.Color = colors.PanelEdge:Lerp(colors.Lucky, 0.5 + 0.5 * math.sin(elapsed * PULSE_SPEED))
		end
	end)

	local self = { Root = root } :: LuckyMeter

	function self.Set(_: LuckyMeter, untilLucky: number)
		local every = RollConfig.LuckyEvery
		ready = untilLucky <= 1
		local progress = if ready then 1 else (every - untilLucky) / (every - 1)
		Motion.Tween(fill, 0.35, { Size = UDim2.fromScale(progress, 1) }, Enum.EasingStyle.Back)
		label.Text = if ready then `🍀 NEXT ROLL: x{RollConfig.LuckyMultiplier} LUCK!` else `🍀 Lucky roll in {untilLucky}`
		if not ready then
			stroke.Color = colors.PanelEdge
		end
	end

	self:Set(RollConfig.LuckyEvery)
	return self
end

return table.freeze(LuckyMeter)
