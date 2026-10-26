--!strict
--[[
	One playing card on screen. Shows its back or any catalog card, and gives the roll show the
	handles it animates: Scale (pops), Glow (coloured halo), Dim, Flip and a corner Tag ("NEW!").
	Where the card stands and when things happen is decided by the caller (Screens/Stage).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Face = require(script.Face)
local Make = require(script.Parent.Parent.Make)
local Motion = require(script.Parent.Parent.Motion)
local Theme = require(ReplicatedStorage.Shared.Config.Theme)

-- Halo rings around the card: distance from the edge, line thickness, share of the glow strength.
local GLOW_RINGS = {
	{ Pad = 8, Thickness = 6, Weight = 1 },
	{ Pad = 20, Thickness = 12, Weight = 0.45 },
}

export type Card = {
	Root: Frame,
	Scale: UIScale,
	Show: (self: Card, cardId: string?) -> (),
	Flip: (self: Card, cardId: string?, seconds: number) -> (),
	Glow: (self: Card, color: Color3, strength: number, seconds: number?) -> (),
	Dim: (self: Card, amount: number, seconds: number) -> (),
	Tag: (self: Card, text: string, color: Color3) -> (),
	Destroy: (self: Card) -> (),
}

local Card = {}

local function halo(root: Frame): { UIStroke }
	local strokes = {}
	for index, ring in GLOW_RINGS do
		local stroke: UIStroke = Make("UIStroke", { Thickness = ring.Thickness, Transparency = 1 })
		Make("Frame", {
			Name = `Glow{index}`,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.new(1, ring.Pad * 2, 1, ring.Pad * 2),
			BackgroundTransparency = 1,
			ZIndex = 1,
			Parent = root,
		}, {
			Make("UICorner", { CornerRadius = UDim.new(0, Theme.Card.Corner + ring.Pad) }),
			stroke,
		})
		table.insert(strokes, stroke)
	end
	return strokes
end

function Card.new(parent: Instance): Card
	local size = Theme.Card.Size
	local root: Frame = Make("Frame", {
		Name = "Card",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(size.X, size.Y),
		BackgroundTransparency = 1,
		Parent = parent,
	})
	local scale: UIScale = Make("UIScale", { Parent = root })
	local glow = halo(root)

	-- Body holds the painted face; flipping squeezes its width to zero and back.
	local body: Frame = Make("Frame", {
		Name = "Body",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ZIndex = 2,
		Parent = root,
	})
	local dim: Frame = Make("Frame", {
		Name = "Dim",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 1,
		ZIndex = 3,
		Parent = body,
	}, {
		Make("UICorner", { CornerRadius = UDim.new(0, Theme.Card.Corner) }),
	})

	local face: Frame? = nil
	local self = { Root = root, Scale = scale } :: Card

	function self.Show(_: Card, cardId: string?)
		if face then
			face:Destroy()
		end
		face = if cardId then Face.Front(body, cardId) else Face.Back(body)
	end

	-- Yields for `seconds`.
	function self.Flip(card: Card, cardId: string?, seconds: number)
		local half = seconds / 2
		Motion.Await(Motion.Tween(body, half, { Size = UDim2.fromScale(0, 1) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In))
		card:Show(cardId)
		Motion.Await(Motion.Tween(body, half, { Size = UDim2.fromScale(1, 1) }, Enum.EasingStyle.Quad, Enum.EasingDirection.Out))
	end

	-- Strength 0..1; without `seconds` the change is instant.
	function self.Glow(_: Card, color: Color3, strength: number, seconds: number?)
		for index, stroke in glow do
			stroke.Color = color
			local goal = 1 - strength * GLOW_RINGS[index].Weight
			if seconds and seconds > 0 then
				Motion.Tween(stroke, seconds, { Transparency = goal })
			else
				stroke.Transparency = goal
			end
		end
	end

	function self.Dim(_: Card, amount: number, seconds: number)
		Motion.Tween(dim, seconds, { BackgroundTransparency = 1 - amount })
	end

	function self.Tag(_: Card, text: string, color: Color3)
		local tag: TextLabel = Make("TextLabel", {
			Name = "Tag",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(1, -12, 0, 10),
			Size = UDim2.fromOffset(78, 32),
			Rotation = 14,
			BackgroundColor3 = color,
			Text = text,
			TextColor3 = Theme.Colors.Text,
			Font = Theme.Fonts.Title,
			TextScaled = true,
			ZIndex = 4,
			Parent = root,
		}, {
			Make("UICorner", { CornerRadius = UDim.new(0, 8) }),
			Make("UIStroke", { Thickness = 2, Color = Theme.Colors.Text, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
			Make("UIPadding", { PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6) }),
		})
		Motion.Pop(Make("UIScale", { Parent = tag }), 0, 1, 0.4)
	end

	function self.Destroy(_: Card)
		root:Destroy()
	end

	return self
end

return table.freeze(Card)
