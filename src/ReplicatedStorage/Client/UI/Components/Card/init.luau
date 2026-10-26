--!strict
--[[
	One playing card on screen. Shows its back or any catalog card, and gives the roll show the
	handles it animates: Scale (pops), Glow (coloured halo), Dim, Flip and a corner Tag ("NEW!").
	Where the card stands and when things happen is decided by the caller (Screens/Stage).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Back = require(script.Back)
local Front = require(script.Front)
local Make = require(script.Parent.Parent.Make)
local Motion = require(script.Parent.Parent.Motion)
local Theme = require(ReplicatedStorage.Shared.Config.Theme)

-- Soft halo behind the card: layers growing past the edge, each a share of the glow strength.
local GLOW_LAYERS = {
	{ Pad = 4, Weight = 0.5 },
	{ Pad = 12, Weight = 0.28 },
	{ Pad = 22, Weight = 0.14 },
	{ Pad = 34, Weight = 0.07 },
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

local function halo(root: Frame): { Frame }
	local layers = {}
	for index, layer in GLOW_LAYERS do
		local frame: Frame = Make("Frame", {
			Name = `Glow{index}`,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.new(1, layer.Pad * 2, 1, layer.Pad * 2),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ZIndex = 1,
			Parent = root,
		}, {
			Make("UICorner", { CornerRadius = UDim.new(0, Theme.Card.Corner + layer.Pad) }),
		})
		table.insert(layers, frame)
	end
	return layers
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
		face = if cardId then Front.Build(body, cardId) else Back.Build(body)
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
		for index, layer in glow do
			layer.BackgroundColor3 = color
			local goal = 1 - strength * GLOW_LAYERS[index].Weight
			if seconds and seconds > 0 then
				Motion.Tween(layer, seconds, { BackgroundTransparency = goal })
			else
				layer.BackgroundTransparency = goal
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
			Size = UDim2.fromOffset(58, 24),
			Rotation = 14,
			BackgroundColor3 = color,
			Text = text,
			TextColor3 = Theme.Colors.Text,
			Font = Theme.Fonts.Display,
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
