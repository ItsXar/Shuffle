--!strict
--[[
	The face-down side: deep violet body with a faint diamond lattice and a glowing emblem that
	slowly breathes, so even a closed card feels alive.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Kit = require(script.Parent.Kit)
local Make = require(script.Parent.Parent.Parent.Make)
local Paint = require(script.Parent.Parent.Parent.Paint)
local Theme = require(ReplicatedStorage.Shared.Config.Theme)

local LATTICE_COLUMNS = 5
local LATTICE_ROWS = 7
local LATTICE_SIZE = 8
local RIM_SPEED = 40

local Back = {}

local function diamond(parent: Instance, position: UDim2, size: UDim2, props: { [string]: any }): Frame
	props.AnchorPoint = Vector2.new(0.5, 0.5)
	props.Position = position
	props.Size = size
	props.Rotation = 45
	props.BorderSizePixel = 0
	props.Parent = parent
	return Make("Frame", props, {
		Make("UIAspectRatioConstraint", { DominantAxis = Enum.DominantAxis.Width }),
	})
end

local function lattice(frame: Frame, color: Color3)
	for row = 1, LATTICE_ROWS do
		for column = 1, LATTICE_COLUMNS do
			local shift = if row % 2 == 0 then 0.5 else 0
			local x = (column - 0.5 + shift) / LATTICE_COLUMNS
			local y = (row - 0.5) / LATTICE_ROWS
			if x < 1 then
				diamond(frame, UDim2.fromScale(x, y), UDim2.fromOffset(LATTICE_SIZE, LATTICE_SIZE), {
					BackgroundColor3 = color,
					BackgroundTransparency = 0.86,
				})
			end
		end
	end
end

local function emblem(frame: Frame, color: Color3): Frame
	local holder: Frame = Make("Frame", {
		Name = "Emblem",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.9, 0.9),
		BackgroundTransparency = 1,
		ZIndex = 2,
		Parent = frame,
	})
	local scale: UIScale = Make("UIScale", { Parent = holder })
	Kit.Orb(holder, UDim2.fromScale(0.5, 0.5), 0.8, color, 0.5)
	local outline = diamond(holder, UDim2.fromScale(0.5, 0.5), UDim2.fromScale(0.42, 0.42), { BackgroundTransparency = 1 })
	Make("UIStroke", { Thickness = 2, Color = color, Parent = outline })

	local core = diamond(holder, UDim2.fromScale(0.5, 0.5), UDim2.fromScale(0.24, 0.24), {
		BackgroundColor3 = Paint.Tint(color, 0.3),
	})
	Make("UIGradient", {
		Rotation = 90,
		Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(150, 150, 150)),
		Parent = core,
	})

	Paint.Animate(holder, function(elapsed: number)
		scale.Scale = 1 + 0.04 * math.sin(elapsed * 2.2)
		core.Rotation = 45 + elapsed * 30
	end)
	return holder
end

function Back.Build(parent: Instance): Frame
	local colors = Theme.Colors
	local frame = Kit.Body(parent, colors.BackTop, colors.BackBottom, Kit.Metal(colors.BackEdge), RIM_SPEED)
	lattice(frame, colors.BackEdge)
	emblem(frame, colors.BackEdge)
	return frame
end

return table.freeze(Back)
