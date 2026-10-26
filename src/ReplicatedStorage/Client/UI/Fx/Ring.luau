--!strict
-- Shockwave: a coloured ring that bursts out from a screen point and thins away.

local Fit = require(script.Parent.Parent.Fit)
local Make = require(script.Parent.Parent.Make)
local Motion = require(script.Parent.Parent.Motion)
local Root = require(script.Parent.Parent.Root)

local Ring = {}

-- `size` = final diameter and `thickness` = starting line width, both in design pixels.
function Ring.Play(at: Vector2, color: Color3, size: number, seconds: number?, thickness: number?)
	local unit = Fit.Unit()
	local duration = seconds or 0.55
	local stroke: UIStroke = Make("UIStroke", { Color = color, Thickness = (thickness or 8) * unit })
	local frame: Frame = Make("Frame", {
		Name = "Ring",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(at.X, at.Y),
		Size = UDim2.fromOffset(size * 0.15 * unit, size * 0.15 * unit),
		BackgroundTransparency = 1,
		Parent = Root.Layer("Fx"),
	}, {
		Make("UICorner", { CornerRadius = UDim.new(1, 0) }),
		stroke,
	})
	local style = Enum.EasingStyle.Quart
	Motion.Tween(frame, duration, { Size = UDim2.fromOffset(size * unit, size * unit) }, style)
	Motion.Tween(stroke, duration, { Thickness = 0, Transparency = 1 }, style).Completed:Once(function()
		frame:Destroy()
	end)
end

-- Several rings one after another, for bigger hits.
function Ring.Wave(at: Vector2, color: Color3, size: number, count: number)
	for index = 1, count do
		task.delay((index - 1) * 0.12, Ring.Play, at, color, size * (1 + (index - 1) * 0.25), 0.6 + index * 0.1)
	end
end

return table.freeze(Ring)
