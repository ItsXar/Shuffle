--!strict
--[[
	The card list of the backpack: every card in the game, found ones with their count (a green
	frame and tick when in the deck, "NEW" when found since the last visit), missing ones dark.
	Clicking a found card adds it to the deck or takes it out.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Catalog = require(ReplicatedStorage.Shared.Domain.Catalog)
local Make = require(script.Parent.Parent.Parent.Make)
local MiniCard = require(script.Parent.Parent.Parent.Components.MiniCard)
local Motion = require(script.Parent.Parent.Parent.Motion)
local Parts = require(script.Parent.Parts)
local Theme = require(ReplicatedStorage.Shared.Config.Theme)

local TILE_STAGGER = 0.012

export type State = {
	Owned: { [string]: number },
	Deck: { string },
	Fresh: { [string]: boolean },
}

export type Collection = {
	Render: (self: Collection, state: State, animate: boolean) -> (),
}

local Collection = {}

local function equippedMark(tile: Frame)
	local green = Theme.Colors.Equipped
	Make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(1, 6, 1, 6),
		BackgroundTransparency = 1,
		ZIndex = 4,
		Parent = tile,
	}, {
		Make("UICorner", { CornerRadius = UDim.new(0, 14) }),
		Make("UIStroke", { Thickness = 3, Color = green }),
	})
	local tick: Frame = Make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(6, 6),
		Size = UDim2.fromOffset(24, 24),
		BackgroundColor3 = green,
		ZIndex = 6,
		Parent = tile,
	}, {
		Make("UICorner", { CornerRadius = UDim.new(1, 0) }),
		Make("UIStroke", { Thickness = 2, Color = Theme.Colors.Ink, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
	})
	Parts.Label(tick, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.7, 0.7),
		Text = "✓",
		ZIndex = 7,
	})
end

local function newTag(tile: Frame)
	local tag: Frame = Make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(1, -8, 0, 6),
		Size = UDim2.fromOffset(40, 18),
		Rotation = 12,
		BackgroundColor3 = Theme.Colors.New,
		ZIndex = 6,
		Parent = tile,
	}, {
		Make("UICorner", { CornerRadius = UDim.new(0, 5) }),
		Make("UIStroke", { Thickness = 2, Color = Theme.Colors.Text, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
	})
	Parts.Label(tag, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.8, 0.75),
		Text = "NEW",
		ZIndex = 7,
	})
end

function Collection.new(list: ScrollingFrame, onCard: (cardId: string) -> ()): Collection
	local cell = Theme.Backpack.Cell
	Make("UIGridLayout", {
		CellSize = UDim2.fromOffset(cell.X, cell.Y),
		CellPadding = UDim2.fromOffset(10, 16),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = list,
	})
	Make("UIPadding", { PaddingTop = UDim.new(0, 8), PaddingLeft = UDim.new(0, 6), PaddingBottom = UDim.new(0, 12), Parent = list })

	local self = {} :: Collection

	function self.Render(_: Collection, state: State, animate: boolean)
		for _, child in list:GetChildren() do
			if child:IsA("Frame") then
				child:Destroy()
			end
		end
		local inDeck = {}
		for _, cardId in state.Deck do
			inDeck[cardId] = true
		end
		for order, card in Catalog.All() do
			local count = state.Owned[card.Id] or 0
			local tile: Frame = Make("Frame", { Name = card.Id, BackgroundTransparency = 1, LayoutOrder = order, Parent = list })
			MiniCard.Build(tile, card.Id, count > 0)
			if count > 0 then
				Parts.Pill(tile, `x{count}`, Theme.Colors.Text, UDim2.new(1, 4, 1, 4), Vector2.new(1, 1), 36)
				if inDeck[card.Id] then
					equippedMark(tile)
				end
				if state.Fresh[card.Id] then
					newTag(tile)
				end
				Parts.Hover(tile, function()
					onCard(card.Id)
				end)
			end
			if animate then
				local scale = tile:FindFirstChildOfClass("UIScale") or Make("UIScale", { Parent = tile })
				scale.Scale = 0
				task.delay(order * TILE_STAGGER, function()
					Motion.Tween(scale, 0.3, { Scale = 1 }, Enum.EasingStyle.Back)
				end)
			end
		end
	end

	return self
end

return table.freeze(Collection)
