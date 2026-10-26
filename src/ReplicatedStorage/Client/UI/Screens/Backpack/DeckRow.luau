--!strict
--[[
	The deck section of the backpack: five slots (the cards that fight, each with its power; a
	click takes the card out), the total damage per hit, and the EQUIP BEST button.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Battle = require(ReplicatedStorage.Shared.Config.Battle)
local Make = require(script.Parent.Parent.Parent.Make)
local MiniCard = require(script.Parent.Parent.Parent.Components.MiniCard)
local Parts = require(script.Parent.Parts)
local Power = require(ReplicatedStorage.Shared.Domain.Power)
local Theme = require(ReplicatedStorage.Shared.Config.Theme)

local HEIGHT = 190
local SLOT_GAP = 12

export type Actions = {
	OnSlot: (index: number) -> (),
	OnEquipBest: () -> (),
}

export type DeckRow = {
	Render: (self: DeckRow, deck: { string }, owned: { [string]: number }) -> (),
}

local DeckRow = {}

local function emptySlot(slot: Frame)
	local colors = Theme.Colors
	Parts.Label(slot, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.45),
		Size = UDim2.fromScale(0.45, 0.28),
		Text = "+",
		TextColor3 = colors.Edge,
	})
	Parts.Label(slot, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.72),
		Size = UDim2.fromScale(0.8, 0.1),
		Text = "EMPTY",
		TextColor3 = colors.Edge,
	})
end

function DeckRow.new(window: Frame, y: number, actions: Actions): DeckRow
	local colors = Theme.Colors
	local box, note = Parts.Section(window, y, HEIGHT, `DECK  •  {Battle.DeckSize} SLOTS`)
	local size = Theme.Backpack.Slot
	local slots: { Frame } = {}
	for index = 1, Battle.DeckSize do
		slots[index] = Make("Frame", {
			Name = `Slot{index}`,
			Position = UDim2.fromOffset(18 + (index - 1) * (size.X + SLOT_GAP), 44),
			Size = UDim2.fromOffset(size.X, size.Y),
			BackgroundColor3 = colors.Panel,
			Parent = box,
		}, {
			Make("UICorner", { CornerRadius = UDim.new(0, 12) }),
			Make("UIStroke", { Thickness = 2, Color = colors.Edge, Transparency = 0.3 }),
		})
	end
	Parts.Button(box, "EQUIP BEST", colors.Equip, UDim2.new(1, -18, 0, 111), Vector2.new(250, 46), actions.OnEquipBest)
	Parts.Label(box, {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -18, 0, 144),
		Size = UDim2.fromOffset(250, 14),
		Text = "Click a card to add or remove it",
		TextColor3 = colors.Muted,
		Font = Theme.Fonts.Body,
	})

	local self = {} :: DeckRow

	function self.Render(_: DeckRow, deck: { string }, owned: { [string]: number })
		note.Text = `⚔ {Power.Format(Power.Deck(deck, owned))} DAMAGE / HIT`
		for index, slot in slots do
			slot:ClearAllChildren()
			Make("UICorner", { CornerRadius = UDim.new(0, 12), Parent = slot })
			Make("UIStroke", { Thickness = 2, Color = colors.Edge, Transparency = 0.3, Parent = slot })
			local cardId = deck[index]
			if cardId then
				MiniCard.Build(slot, cardId, true)
				local power = Power.Card(cardId, owned[cardId] or 1)
				Parts.Pill(slot, `⚔ {Power.Format(power)}`, colors.Damage, UDim2.new(0.5, 0, 1, 6), Vector2.new(0.5, 0.5), 56)
				Parts.Hover(slot, function()
					actions.OnSlot(index)
				end)
			else
				emptySlot(slot)
			end
		end
	end

	return self
end

return table.freeze(DeckRow)
