--!strict
--[[
	One card slot in the backpack: the mini card, a gold "x12" count badge, a "NEW" tag for cards
	found since the backpack was last opened, and a little lift on hover.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Make = require(script.Parent.Parent.Parent.Make)
local MiniCard = require(script.Parent.Parent.Parent.Components.MiniCard)
local Motion = require(script.Parent.Parent.Parent.Motion)
local Theme = require(ReplicatedStorage.Shared.Config.Theme)

local HOVER = 1.07

local Tile = {}

local function badge(root: Frame, count: number)
	local pill: Frame = Make("Frame", {
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, 2, 1, 2),
		Size = UDim2.fromOffset(36, 20),
		BackgroundColor3 = Theme.Colors.Ink,
		ZIndex = 5,
		Parent = root,
	}, {
		Make("UICorner", { CornerRadius = UDim.new(1, 0) }),
		Make("UIStroke", { Thickness = 2, Color = Theme.Colors.Gold, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
	})
	Make("TextLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.82, 0.75),
		BackgroundTransparency = 1,
		Text = `x{count}`,
		TextColor3 = Theme.Colors.Gold,
		TextScaled = true,
		Font = Theme.Fonts.Display,
		ZIndex = 6,
		Parent = pill,
	})
end

local function newTag(root: Frame)
	local tag: TextLabel = Make("TextLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(8, 8),
		Size = UDim2.fromOffset(40, 18),
		Rotation = -14,
		BackgroundColor3 = Theme.Colors.New,
		Text = "NEW",
		TextColor3 = Theme.Colors.Text,
		TextScaled = true,
		Font = Theme.Fonts.Display,
		ZIndex = 6,
		Parent = root,
	}, {
		Make("UICorner", { CornerRadius = UDim.new(0, 5) }),
		Make("UIStroke", { Thickness = 2, Color = Theme.Colors.Text, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
		Make("UIPadding", { PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4) }),
	})
	local scale: UIScale = Make("UIScale", { Parent = tag })
	Motion.Pop(scale, 1.6, 1, 0.4)
end

-- `count` 0 = locked. `order` sets the slot in the grid.
function Tile.new(parent: Instance, cardId: string, count: number, isNew: boolean, order: number): Frame
	local root: Frame = Make("Frame", {
		Name = cardId,
		BackgroundTransparency = 1,
		LayoutOrder = order,
		Parent = parent,
	})
	local scale: UIScale = Make("UIScale", { Parent = root })
	local button: TextButton = Make("TextButton", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = "",
		ZIndex = 1,
		Parent = root,
	})
	MiniCard.Build(button, cardId, count > 0)
	if count > 0 then
		badge(root, count)
	end
	if isNew then
		newTag(root)
	end

	button.MouseEnter:Connect(function()
		Motion.Tween(scale, 0.15, { Scale = HOVER }, Enum.EasingStyle.Back)
	end)
	button.MouseLeave:Connect(function()
		Motion.Tween(scale, 0.15, { Scale = 1 })
	end)
	return root
end

return table.freeze(Tile)
