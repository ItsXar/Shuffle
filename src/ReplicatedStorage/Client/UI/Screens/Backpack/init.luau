--!strict
--[[
	The backpack window: every card in the game, found ones with their count, missing ones dark
	with "?", and the collection progress on top. Opens over a blurred world with the tiles
	popping in one after another; the dark backdrop or the ✕ closes it.
]]

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Catalog = require(ReplicatedStorage.Shared.Domain.Catalog)
local Fit = require(script.Parent.Parent.Fit)
local Header = require(script.Header)
local Make = require(script.Parent.Parent.Make)
local Motion = require(script.Parent.Parent.Motion)
local Root = require(script.Parent.Parent.Root)
local Theme = require(ReplicatedStorage.Shared.Config.Theme)
local Tile = require(script.Tile)

local BLUR = 14
local BACKDROP = 0.4
local OPEN_SECONDS = 0.3
local TILE_STAGGER = 0.015

export type Backpack = {
	Open: (self: Backpack, owned: { [string]: number }, fresh: { [string]: boolean }) -> (),
	Close: (self: Backpack) -> (),
	IsOpen: (self: Backpack) -> boolean,
}

local Backpack = {}

local function grid(panel: Frame): ScrollingFrame
	local cell = Theme.Backpack.Cell
	return Make("ScrollingFrame", {
		Name = "Grid",
		Position = UDim2.fromOffset(24, 92),
		Size = UDim2.new(1, -48, 1, -108),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 6,
		ScrollBarImageColor3 = Theme.Colors.PanelEdge,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		ScrollingDirection = Enum.ScrollingDirection.Y,
		Parent = panel,
	}, {
		Make("UIGridLayout", {
			CellSize = UDim2.fromOffset(cell.X, cell.Y),
			CellPadding = UDim2.fromOffset(12, 14),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
		Make("UIPadding", { PaddingTop = UDim.new(0, 8), PaddingLeft = UDim.new(0, 6), PaddingBottom = UDim.new(0, 8) }),
	})
end

function Backpack.new(onClose: () -> ()): Backpack
	local colors = Theme.Colors
	local layer = Root.Layer("Menu")
	local backdrop: TextButton = Make("TextButton", {
		Name = "Backdrop",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = colors.Ink,
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Text = "",
		Visible = false,
		Parent = layer,
	})
	local design = Theme.Backpack.Design
	local canvas: Frame = Make("Frame", {
		Name = "Window",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(design.X, design.Y),
		BackgroundTransparency = 1,
		Visible = false,
		ZIndex = 2,
		Parent = layer,
	})
	Fit.Attach(canvas, design, Theme.Backpack.HeightShare)
	local panel: Frame = Make("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(1, 1, 1),
		Parent = canvas,
	}, {
		Make("UICorner", { CornerRadius = UDim.new(0, 26) }),
		Make("UIStroke", { Thickness = 3, Color = colors.PanelEdge }),
		Make("UIGradient", { Rotation = 90, Color = ColorSequence.new(colors.PanelTop, colors.PanelBottom) }),
	})
	local pop: UIScale = Make("UIScale", { Parent = panel })
	local header = Header.new(panel, onClose)
	local list = grid(panel)
	local blur: BlurEffect = Make("BlurEffect", { Size = 0, Enabled = false, Parent = Lighting })

	backdrop.Activated:Connect(onClose)

	local open = false
	local self = {} :: Backpack

	function self.Open(_: Backpack, owned: { [string]: number }, fresh: { [string]: boolean })
		for _, child in list:GetChildren() do
			if child:IsA("Frame") then
				child:Destroy()
			end
		end
		local cards = Catalog.All()
		local have = 0
		for order, card in cards do
			local count = owned[card.Id] or 0
			if count > 0 then
				have += 1
			end
			local tile = Tile.new(list, card.Id, count, fresh[card.Id] == true, order)
			local scale = tile:FindFirstChildOfClass("UIScale") :: UIScale
			scale.Scale = 0
			task.delay(order * TILE_STAGGER, function()
				Motion.Tween(scale, 0.3, { Scale = 1 }, Enum.EasingStyle.Back)
			end)
		end
		header:SetProgress(have, #cards)
		list.CanvasPosition = Vector2.zero

		open = true
		backdrop.Visible = true
		canvas.Visible = true
		blur.Enabled = true
		Motion.Tween(backdrop, OPEN_SECONDS, { BackgroundTransparency = BACKDROP })
		Motion.Tween(blur, OPEN_SECONDS, { Size = BLUR })
		Motion.Pop(pop, 0.85, 1, OPEN_SECONDS + 0.1)
	end

	function self.Close(_: Backpack)
		if not open then
			return
		end
		open = false
		Motion.Tween(backdrop, 0.2, { BackgroundTransparency = 1 })
		Motion.Tween(blur, 0.2, { Size = 0 })
		Motion.Tween(pop, 0.2, { Scale = 0.85 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In).Completed:Once(function()
			if not open then
				backdrop.Visible = false
				canvas.Visible = false
				blur.Enabled = false
			end
		end)
	end

	function self.IsOpen(_: Backpack): boolean
		return open
	end

	return self
end

return table.freeze(Backpack)
