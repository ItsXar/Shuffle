--!strict
--[[
	Spinning sunburst with a soft core, drawn behind a card. Attach returns the function that
	fades it out and removes it.
]]

local Make = require(script.Parent.Parent.Make)
local Motion = require(script.Parent.Parent.Motion)
local Paint = require(script.Parent.Parent.Paint)

local RAY_COUNT = 10
local RAY_WIDTH = 30
local SPIN_SPEED = 28
local CORE_RINGS = { 0.3, 0.45, 0.6 }

local Rays = {}

local RAY_FADE = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 1),
	NumberSequenceKeypoint.new(0.5, 0.3),
	NumberSequenceKeypoint.new(1, 1),
})

function Rays.Attach(parent: GuiObject, position: UDim2, color: Color3, size: number): () -> ()
	local holder: Frame = Make("Frame", {
		Name = "Rays",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = position,
		Size = UDim2.fromOffset(size, size),
		BackgroundTransparency = 1,
		ZIndex = 0,
		Parent = parent,
	})
	local scale: UIScale = Make("UIScale", { Scale = 0, Parent = holder })

	-- Each bar is centred, so it draws two opposite rays; RAY_COUNT bars = twice as many rays.
	for index = 1, RAY_COUNT do
		Make("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.new(0, RAY_WIDTH, 1, 0),
			Rotation = (index - 1) * 180 / RAY_COUNT,
			BackgroundColor3 = Paint.Tint(color, 0.25),
			BorderSizePixel = 0,
			Parent = holder,
		}, {
			Make("UIGradient", { Rotation = 90, Transparency = RAY_FADE }),
		})
	end

	for index, share in CORE_RINGS do
		Make("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(share, share),
			BackgroundColor3 = Paint.Tint(color, 0.4),
			BackgroundTransparency = 0.55 + index * 0.12,
			BorderSizePixel = 0,
			Parent = holder,
		}, {
			Make("UICorner", { CornerRadius = UDim.new(1, 0) }),
		})
	end

	Motion.Tween(scale, 0.5, { Scale = 1 }, Enum.EasingStyle.Back)
	Paint.Animate(holder, function(elapsed: number)
		holder.Rotation = elapsed * SPIN_SPEED
	end)

	return function()
		Motion.Tween(scale, 0.3, { Scale = 0 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In).Completed:Once(function()
			holder:Destroy()
		end)
	end
end

return table.freeze(Rays)
