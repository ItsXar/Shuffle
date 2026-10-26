--!strict
--[[
	Building blocks shared by both sides of a card: the body (dark gradient, animated metallic rim,
	inner hairline), labels, a soft round glow, and the holographic light sweep.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Make = require(script.Parent.Parent.Parent.Make)
local Paint = require(script.Parent.Parent.Parent.Paint)
local Theme = require(ReplicatedStorage.Shared.Config.Theme)

local RIM = 3
local INSET = 6
local SHINE_SPEED = 0.8
local ORB_RINGS = { 1, 0.74, 0.5, 0.3 }

local SHINE_BAND = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 1),
	NumberSequenceKeypoint.new(0.44, 1),
	NumberSequenceKeypoint.new(0.5, 0.6),
	NumberSequenceKeypoint.new(0.56, 1),
	NumberSequenceKeypoint.new(1, 1),
})

local Kit = {}

-- Metallic rim colours: light, colour, dark, colour, light, so a rotating gradient glints.
function Kit.Metal(color: Color3): ColorSequence
	return ColorSequence.new({
		ColorSequenceKeypoint.new(0, Paint.Tint(color, 0.75)),
		ColorSequenceKeypoint.new(0.25, color),
		ColorSequenceKeypoint.new(0.5, Paint.Shade(color, 0.45)),
		ColorSequenceKeypoint.new(0.75, color),
		ColorSequenceKeypoint.new(1, Paint.Tint(color, 0.75)),
	})
end

-- The card body. The rim gradient spins at `rimSpeed` degrees per second (0 = still).
function Kit.Body(parent: Instance, top: Color3, bottom: Color3, rim: ColorSequence, rimSpeed: number): (Frame, UIGradient)
	local corner = Theme.Card.Corner
	local rimPaint: UIGradient = Make("UIGradient", { Color = rim, Rotation = 45 })
	local frame: Frame = Make("Frame", {
		Name = "Face",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(1, 1, 1),
		ZIndex = 1,
		Parent = parent,
	}, {
		Make("UICorner", { CornerRadius = UDim.new(0, corner) }),
		Make("UIGradient", { Rotation = 90, Color = ColorSequence.new(top, bottom) }),
		Make("UIStroke", { Thickness = RIM, Color = Color3.new(1, 1, 1), ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, { rimPaint }),
	})
	Make("Frame", {
		Name = "Inset",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(1, -INSET * 2, 1, -INSET * 2),
		BackgroundTransparency = 1,
		Parent = frame,
	}, {
		Make("UICorner", { CornerRadius = UDim.new(0, corner - INSET / 2) }),
		Make("UIStroke", { Thickness = 1, Color = Color3.new(1, 1, 1), Transparency = 0.82 }),
	})
	if rimSpeed > 0 then
		Paint.Animate(frame, function(elapsed: number)
			rimPaint.Rotation = (45 + elapsed * rimSpeed) % 360
		end)
	end
	return frame, rimPaint
end

-- Scaled text, capped at `maxSize` so it stays crisp. `outline` adds a soft dark stroke.
function Kit.Text(
	parent: Instance,
	text: string,
	font: Enum.Font,
	position: UDim2,
	size: UDim2,
	color: Color3,
	maxSize: number,
	outline: boolean?
): TextLabel
	local label: TextLabel = Make("TextLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = position,
		Size = size,
		BackgroundTransparency = 1,
		Text = text,
		Font = font,
		TextColor3 = color,
		TextScaled = true,
		ZIndex = 3,
		Parent = parent,
	}, {
		Make("UITextSizeConstraint", { MaxTextSize = maxSize }),
	})
	if outline ~= false then
		Make("UIStroke", { Thickness = 1.5, Color = Theme.Colors.Ink, Transparency = 0.35, Parent = label })
	end
	return label
end

-- Soft round glow: stacked circles, more opaque towards the middle. `size` is a share of the parent width.
function Kit.Orb(parent: Instance, position: UDim2, size: number, color: Color3, strength: number): Frame
	local holder: Frame = Make("Frame", {
		Name = "Orb",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = position,
		Size = UDim2.fromScale(size, size),
		BackgroundTransparency = 1,
		ZIndex = 1,
		Parent = parent,
	}, {
		Make("UIAspectRatioConstraint", { DominantAxis = Enum.DominantAxis.Width }),
	})
	for index, share in ORB_RINGS do
		Make("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(share, share),
			BackgroundColor3 = Paint.Tint(color, (index - 1) * 0.15),
			BackgroundTransparency = 1 - strength * 0.25,
			BorderSizePixel = 0,
			Parent = holder,
		}, {
			Make("UICorner", { CornerRadius = UDim.new(1, 0) }),
		})
	end
	return holder
end

-- Holographic light band sweeping across the card, forever.
function Kit.Shine(frame: Frame)
	local sweep: UIGradient = Make("UIGradient", { Rotation = 22, Transparency = SHINE_BAND })
	Make("Frame", {
		Name = "Shine",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(1, 1, 1),
		ZIndex = 6,
		Parent = frame,
	}, {
		Make("UICorner", { CornerRadius = UDim.new(0, Theme.Card.Corner) }),
		sweep,
	})
	Paint.Animate(frame, function(elapsed: number)
		sweep.Offset = Vector2.new((elapsed * SHINE_SPEED) % 2.6 - 1.3, 0)
	end)
end

return table.freeze(Kit)
