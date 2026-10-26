--!strict
--[[
	One playing card on screen. Shows its back or any catalog card, and gives the roll show the
	handles it animates: Scale (pops), Squash (squash and stretch), Glow (soft coloured halo),
	Flash (white hit), Dim, and a corner Tag ("NEW"). Face is the side currently shown.
	Where the card stands and when things happen is decided by the caller (Screens/Stage).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Art = require(script.Art)
local Back = require(script.Back)
local Front = require(script.Front)
local Kit = require(script.Kit)
local Make = require(script.Parent.Parent.Make)
local Motion = require(script.Parent.Parent.Motion)
local Theme = require(ReplicatedStorage.Shared.Config.Theme)

-- Soft halo behind the card: layers growing past the edge, each a share of the glow strength.
local GLOW_LAYERS = {
	{ Pad = 4, Weight = 0.55 },
	{ Pad = 12, Weight = 0.3 },
	{ Pad = 22, Weight = 0.16 },
	{ Pad = 34, Weight = 0.08 },
}

export type Card = {
	Root: Frame,
	Body: Frame,
	Scale: UIScale,
	Face: Kit.Face,
	Show: (self: Card, cardId: string?) -> (),
	Squash: (self: Card, x: number, y: number, seconds: number) -> (),
	Glow: (self: Card, color: Color3, strength: number, seconds: number?) -> (),
	Flash: (self: Card, seconds: number) -> (),
	Dim: (self: Card, amount: number, seconds: number) -> (),
	Tag: (self: Card, text: string, color: Color3) -> (),
	Destroy: (self: Card) -> (),
}

local Card = {}

local function overlay(parent: Instance, name: string, color: Color3, zIndex: number): Frame
	return Make("Frame", {
		Name = name,
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = color,
		BackgroundTransparency = 1,
		ZIndex = zIndex,
		Parent = parent,
	}, {
		Make("UICorner", { CornerRadius = UDim.new(0, Theme.Card.Corner) }),
	})
end

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
		ZIndex = 2,
		Parent = parent,
	})
	local scale: UIScale = Make("UIScale", { Parent = root })
	local glow = halo(root)

	-- Body holds the painted face; squash and flip stretch it around its centre.
	local body: Frame = Make("Frame", {
		Name = "Body",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ZIndex = 2,
		Parent = root,
	})
	local flash = overlay(body, "Flash", Color3.new(1, 1, 1), 8)
	local dim = overlay(body, "Dim", Color3.new(0, 0, 0), 9)

	local self = { Root = root, Body = body, Scale = scale } :: Card

	function self.Show(card: Card, cardId: string?)
		if card.Face then
			card.Face.Frame:Destroy()
		end
		if cardId then
			card.Face = if Art.HasFront(cardId) then Art.Front(body, cardId) else Front.Build(body, cardId)
		else
			card.Face = if Art.HasBack() then Art.Back(body) else Back.Build(body)
		end
	end

	function self.Squash(_: Card, x: number, y: number, seconds: number)
		body.Size = UDim2.fromScale(x, y)
		Motion.Tween(body, seconds, { Size = UDim2.fromScale(1, 1) }, Enum.EasingStyle.Elastic)
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

	function self.Flash(_: Card, seconds: number)
		flash.BackgroundTransparency = 0
		Motion.Tween(flash, seconds, { BackgroundTransparency = 1 })
	end

	function self.Dim(_: Card, amount: number, seconds: number)
		Motion.Tween(dim, seconds, { BackgroundTransparency = 1 - amount })
	end

	function self.Tag(_: Card, text: string, color: Color3)
		local tag: TextLabel = Make("TextLabel", {
			Name = "Tag",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0, 10, 0, 10),
			Size = UDim2.fromOffset(52, 22),
			Rotation = -14,
			BackgroundColor3 = color,
			Text = text,
			TextColor3 = Theme.Colors.Text,
			Font = Theme.Fonts.Display,
			TextScaled = true,
			ZIndex = 4,
			Parent = root,
		}, {
			Make("UICorner", { CornerRadius = UDim.new(0, 6) }),
			Make("UIStroke", { Thickness = 2, Color = Theme.Colors.Text, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
			Make("UIPadding", { PaddingLeft = UDim.new(0, 5), PaddingRight = UDim.new(0, 5) }),
		})
		Motion.Pop(Make("UIScale", { Parent = tag }), 0, 1, 0.4)
	end

	function self.Destroy(_: Card)
		root:Destroy()
	end

	self:Show(nil)
	return self
end

return table.freeze(Card)
