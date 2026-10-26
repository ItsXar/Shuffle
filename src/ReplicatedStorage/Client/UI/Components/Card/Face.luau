--!strict
--[[
	Paints one side of a card: the face-down back, or the front of a catalog card in its rarity
	colours (gradient body, art window with the icon, name, rarity, odds). Higher rarities get a
	moving light sweep, the rarest a rainbow border too (Config/Rarities > Effect).
	Each call returns one Frame; destroying it removes the side and stops its animation.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Catalog = require(ReplicatedStorage.Shared.Domain.Catalog)
local Make = require(script.Parent.Parent.Parent.Make)
local Odds = require(ReplicatedStorage.Shared.Domain.Odds)
local Paint = require(script.Parent.Parent.Parent.Paint)
local Theme = require(ReplicatedStorage.Shared.Config.Theme)

local BORDER = 4
local SHINE_SPEED = 0.9
local RAINBOW_SPEED = 0.35

local SHINE_BAND = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 1),
	NumberSequenceKeypoint.new(0.42, 1),
	NumberSequenceKeypoint.new(0.5, 0.45),
	NumberSequenceKeypoint.new(0.58, 1),
	NumberSequenceKeypoint.new(1, 1),
})

local Face = {}

local function base(parent: Instance, top: Color3, bottom: Color3, edge: Color3): (Frame, UIStroke)
	local border: UIStroke = Make("UIStroke", {
		Thickness = BORDER,
		Color = edge,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
	local frame: Frame = Make("Frame", {
		Name = "Face",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(1, 1, 1),
		ZIndex = 1,
		Parent = parent,
	}, {
		Make("UICorner", { CornerRadius = UDim.new(0, Theme.Card.Corner) }),
		Make("UIGradient", { Rotation = 90, Color = ColorSequence.new(top, bottom) }),
		border,
	})
	return frame, border
end

local function label(parent: Instance, text: string, font: Enum.Font, position: UDim2, size: UDim2, color: Color3): TextLabel
	return Make("TextLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = position,
		Size = size,
		BackgroundTransparency = 1,
		Text = text,
		Font = font,
		TextColor3 = color,
		TextScaled = true,
		Parent = parent,
	}, {
		Make("UIStroke", { Thickness = 2, Color = Theme.Colors.Ink, Transparency = 0.25 }),
	})
end

local function shine(frame: Frame, border: UIStroke, rainbow: boolean)
	local sweep: UIGradient = Make("UIGradient", { Rotation = 20, Transparency = SHINE_BAND })
	Make("Frame", {
		Name = "Shine",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(1, 1, 1),
		ZIndex = 5,
		Parent = frame,
	}, {
		Make("UICorner", { CornerRadius = UDim.new(0, Theme.Card.Corner) }),
		sweep,
	})

	local edge: UIGradient? = if rainbow then Make("UIGradient", { Parent = border }) else nil
	Paint.Animate(frame, function(elapsed: number)
		sweep.Offset = Vector2.new((elapsed * SHINE_SPEED) % 2.4 - 1.2, 0)
		if edge then
			edge.Color = Paint.Rainbow(elapsed * RAINBOW_SPEED)
			edge.Rotation = (elapsed * 120) % 360
		end
	end)
end

function Face.Back(parent: Instance): Frame
	local colors = Theme.Colors
	local frame = base(parent, colors.BackTop, colors.BackBottom, colors.BackEdge)
	label(frame, "?", Theme.Fonts.Title, UDim2.fromScale(0.5, 0.45), UDim2.fromScale(0.6, 0.45), colors.BackEdge)
	label(frame, "SHUFFLE", Theme.Fonts.Title, UDim2.fromScale(0.5, 0.86), UDim2.fromScale(0.7, 0.09), colors.Muted)
	return frame
end

function Face.Front(parent: Instance, cardId: string): Frame
	local card = Catalog.Card(cardId)
	local rarity = Catalog.RarityOf(cardId)
	local colors = Theme.Colors
	local fonts = Theme.Fonts

	local frame, border = base(parent, Paint.Tint(rarity.Color, 0.1), rarity.Dark, Paint.Tint(rarity.Color, 0.35))

	label(frame, string.upper(rarity.Name), fonts.Title, UDim2.fromScale(0.5, 0.08), UDim2.fromScale(0.84, 0.09), colors.Text)

	local art: Frame = Make("Frame", {
		Name = "Art",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.43),
		Size = UDim2.fromScale(0.8, 0.5),
		BackgroundColor3 = Paint.Shade(rarity.Dark, 0.55),
		BackgroundTransparency = 0.35,
		Parent = frame,
	}, {
		Make("UICorner", { CornerRadius = UDim.new(0, Theme.Card.Corner - 4) }),
		Make("UIStroke", { Thickness = 2, Color = Paint.Tint(rarity.Color, 0.5), Transparency = 0.4 }),
	})
	label(art, card.Icon, fonts.Title, UDim2.fromScale(0.5, 0.5), UDim2.fromScale(0.8, 0.8), colors.Text)

	label(frame, card.Name, fonts.Title, UDim2.fromScale(0.5, 0.77), UDim2.fromScale(0.9, 0.12), colors.Text)
	label(frame, Odds.Format(rarity.Chance), fonts.Body, UDim2.fromScale(0.5, 0.9), UDim2.fromScale(0.7, 0.07), colors.Muted)

	if rarity.Effect ~= "None" then
		shine(frame, border, rarity.Effect == "Rainbow")
	end
	return frame
end

return table.freeze(Face)
