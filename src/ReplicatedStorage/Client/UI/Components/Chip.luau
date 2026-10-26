--!strict
-- Small rounded panel with an icon and one line of text (stats in the Hud). Bump = quick pop.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Make = require(script.Parent.Parent.Make)
local Motion = require(script.Parent.Parent.Motion)
local Theme = require(ReplicatedStorage.Shared.Config.Theme)

export type Chip = {
	Root: Frame,
	SetText: (self: Chip, text: string) -> (),
	SetColor: (self: Chip, color: Color3) -> (),
	Bump: (self: Chip, strength: number?) -> (),
}

local Chip = {}

function Chip.new(parent: Instance, position: UDim2, size: UDim2, icon: string, text: string): Chip
	local colors = Theme.Colors
	local stroke: UIStroke = Make("UIStroke", { Thickness = 3, Color = colors.PanelEdge })
	local scale: UIScale = Make("UIScale", {})
	local root: Frame = Make("Frame", {
		Name = "Chip",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = position,
		Size = size,
		BackgroundColor3 = colors.Panel,
		BackgroundTransparency = 0.1,
		Parent = parent,
	}, {
		Make("UICorner", { CornerRadius = UDim.new(1, 0) }),
		stroke,
		scale,
	})

	Make("TextLabel", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.fromScale(0.05, 0.5),
		Size = UDim2.fromScale(0.2, 0.7),
		BackgroundTransparency = 1,
		Text = icon,
		TextScaled = true,
		Font = Theme.Fonts.Title,
		Parent = root,
	})
	local label: TextLabel = Make("TextLabel", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.fromScale(0.27, 0.5),
		Size = UDim2.fromScale(0.68, 0.56),
		BackgroundTransparency = 1,
		Text = text,
		TextColor3 = colors.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextScaled = true,
		Font = Theme.Fonts.Title,
		Parent = root,
	})

	local self = { Root = root } :: Chip

	function self.SetText(_: Chip, value: string)
		label.Text = value
	end

	function self.SetColor(_: Chip, color: Color3)
		stroke.Color = color
		label.TextColor3 = color
	end

	function self.Bump(_: Chip, strength: number?)
		Motion.Pop(scale, 1 + (strength or 0.15), 1, 0.35)
	end

	return self
end

return table.freeze(Chip)
