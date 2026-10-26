--!strict
--[[
	Building blocks shared by both sides of a card: the body (gradient, dark rim, white inner line),
	scaled labels, a soft round glow, a slowly turning sunburst and the holographic light sweep.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Make = require(script.Parent.Parent.Parent.Make)
local Paint = require(script.Parent.Parent.Parent.Paint)
local Theme = require(ReplicatedStorage.Shared.Config.Theme)

local RIM = 3
local INSET = 6
local SHINE_SPEED = 0.9
local SUNBURST_BARS = 8
local SUNBURST_WIDTH = 12

local SHINE_BAND = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 1),
	NumberSequenceKeypoint.new(0.44, 1),
	NumberSequenceKeypoint.new(0.5, 0.55),
	NumberSequenceKeypoint.new(0.56, 1),
	NumberSequenceKeypoint.new(1, 1),
})

local BAR_FADE = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 1),
	NumberSequenceKeypoint.new(0.5, 0.7),
	NumberSequenceKeypoint.new(1, 1),
})

export type Face = {
	Frame: Frame,
	Stars: TextLabel?,
}

local Kit = {}

local function corner(radius: number): UICorner
	return Make("UICorner", { CornerRadius = UDim.new(0, radius) })
end

-- The card body: vertical `paint` gradient, dark rim in `edge`, white inner line.
function Kit.Body(parent: Instance, paint: ColorSequence, edge: Color3, inset: number): (Frame, UIStroke)
	local rim: UIStroke = Make("UIStroke", { Thickness = RIM, Color = edge, ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
	local frame: Frame = Make("Frame", {
		Name = "Face",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(1, 1, 1),
		ZIndex = 1,
		Parent = parent,
	}, {
		corner(Theme.Card.Corner),
		Make("UIGradient", { Rotation = 90, Color = paint }),
		rim,
	})
	Make("Frame", {
		Name = "Inset",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(1, -INSET * 2, 1, -INSET * 2),
		BackgroundTransparency = 1,
		ZIndex = 2,
		Parent = frame,
	}, {
		corner(Theme.Card.Corner - 4),
		Make("UIStroke", { Thickness = 2, Color = Color3.new(1, 1, 1), Transparency = inset }),
	})
	return frame, rim
end

-- Scaled text capped at `maxSize`. `stroke` = outline thickness (0 = none) in `strokeColor`.
function Kit.Text(
	parent: Instance,
	text: string,
	position: UDim2,
	size: UDim2,
	maxSize: number,
	color: Color3,
	stroke: number,
	strokeColor: Color3?
): TextLabel
	local label: TextLabel = Make("TextLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = position,
		Size = size,
		BackgroundTransparency = 1,
		Text = text,
		Font = Theme.Fonts.Display,
		TextColor3 = color,
		TextScaled = true,
		ZIndex = 4,
		Parent = parent,
	}, {
		Make("UITextSizeConstraint", { MaxTextSize = maxSize }),
	})
	if stroke > 0 then
		Make("UIStroke", { Thickness = stroke, Color = strokeColor or Theme.Colors.Ink, Parent = label })
	end
	return label
end

-- Soft round glow: three stacked circles. `size` is a share of the parent width.
function Kit.Orb(parent: Instance, position: UDim2, size: number, color: Color3, transparency: { number }): Frame
	local holder: Frame = Make("Frame", {
		Name = "Orb",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = position,
		Size = UDim2.fromScale(size, size),
		BackgroundTransparency = 1,
		ZIndex = 2,
		Parent = parent,
	}, {
		Make("UIAspectRatioConstraint", { DominantAxis = Enum.DominantAxis.Width }),
	})
	for index, share in { 1, 0.72, 0.48 } do
		Make("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(share, share),
			BackgroundColor3 = color,
			BackgroundTransparency = transparency[index],
			BorderSizePixel = 0,
			Parent = holder,
		}, {
			Make("UICorner", { CornerRadius = UDim.new(1, 0) }),
		})
	end
	return holder
end

-- Soft white sunburst turning at `speed` degrees per second.
function Kit.Sunburst(parent: Instance, position: UDim2, size: number, speed: number)
	local holder: Frame = Make("Frame", {
		Name = "Sunburst",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = position,
		Size = UDim2.fromScale(size, size),
		BackgroundTransparency = 1,
		ZIndex = 1,
		Parent = parent,
	}, {
		Make("UIAspectRatioConstraint", { DominantAxis = Enum.DominantAxis.Width }),
	})
	for index = 1, SUNBURST_BARS do
		Make("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.new(0, SUNBURST_WIDTH, 1, 0),
			Rotation = (index - 1) * 180 / SUNBURST_BARS,
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderSizePixel = 0,
			Parent = holder,
		}, {
			Make("UIGradient", { Rotation = 90, Transparency = BAR_FADE }),
		})
	end
	Paint.Animate(holder, function(elapsed: number)
		holder.Rotation = elapsed * speed
	end)
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
		corner(Theme.Card.Corner),
		sweep,
	})
	Paint.Animate(frame, function(elapsed: number)
		sweep.Offset = Vector2.new((elapsed * SHINE_SPEED) % 2.6 - 1.3, 0)
	end)
end

return table.freeze(Kit)
