--!strict
--[[
	The deck above the buttons: five small cards that fight (an empty slot shows "+"), and the
	deck's damage per hit. Attack makes one card jump and returns where its shot starts.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Battle = require(ReplicatedStorage.Shared.Config.Battle)
local Make = require(script.Parent.Parent.Make)
local MiniCard = require(script.Parent.Parent.Components.MiniCard)
local Motion = require(script.Parent.Parent.Motion)
local Power = require(ReplicatedStorage.Shared.Domain.Power)
local Theme = require(ReplicatedStorage.Shared.Config.Theme)

local SLOT = Vector2.new(60, 84)
local GAP = 8
local TOP = 26

export type DeckBar = {
	Render: (self: DeckBar, deck: { string }, owned: { [string]: number }) -> (),
	Attack: (self: DeckBar, slot: number) -> Vector2?,
}

local DeckBar = {}

function DeckBar.new(canvas: Frame, onEmpty: () -> ()): DeckBar
	local colors = Theme.Colors
	local width = Battle.DeckSize * SLOT.X + (Battle.DeckSize - 1) * GAP
	local holder: Frame = Make("Frame", {
		Name = "DeckBar",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 0),
		Size = UDim2.fromOffset(width, TOP + SLOT.Y),
		BackgroundTransparency = 1,
		Parent = canvas,
	})
	local damage: TextLabel = Make("TextLabel", {
		Size = UDim2.new(1, 0, 0, 20),
		BackgroundTransparency = 1,
		Text = "",
		TextColor3 = colors.Damage,
		TextScaled = true,
		Font = Theme.Fonts.Display,
		Parent = holder,
	}, {
		Make("UIStroke", { Thickness = 2, Color = colors.Ink }),
	})

	local slots: { Frame } = {}
	local scales: { UIScale } = {}
	for index = 1, Battle.DeckSize do
		local slot: Frame = Make("Frame", {
			Name = `Slot{index}`,
			Position = UDim2.fromOffset((index - 1) * (SLOT.X + GAP), TOP),
			Size = UDim2.fromOffset(SLOT.X, SLOT.Y),
			BackgroundTransparency = 1,
			Parent = holder,
		})
		scales[index] = Make("UIScale", { Parent = slot })
		slots[index] = slot
	end

	local self = {} :: DeckBar

	function self.Render(_: DeckBar, deck: { string }, owned: { [string]: number })
		damage.Text = if #deck > 0 then `⚔ {Power.Format(Power.Deck(deck, owned))} / HIT` else "OPEN THE BACKPACK TO BUILD YOUR DECK"
		for index, slot in slots do
			for _, child in slot:GetChildren() do
				if not child:IsA("UIScale") then
					child:Destroy()
				end
			end
			local cardId = deck[index]
			if cardId then
				MiniCard.Build(slot, cardId, true)
			else
				local empty: TextButton = Make("TextButton", {
					Size = UDim2.fromScale(1, 1),
					BackgroundColor3 = colors.Panel,
					BackgroundTransparency = 0.25,
					Text = "+",
					TextColor3 = colors.Edge,
					TextScaled = true,
					Font = Theme.Fonts.Display,
					Parent = slot,
				}, {
					Make("UICorner", { CornerRadius = UDim.new(0, 8) }),
					Make("UIStroke", { Thickness = 2, Color = colors.Edge, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
					Make("UIPadding", { PaddingTop = UDim.new(0.25, 0), PaddingBottom = UDim.new(0.25, 0) }),
				})
				empty.Activated:Connect(onEmpty)
			end
		end
	end

	function self.Attack(_: DeckBar, index: number): Vector2?
		local slot = slots[index]
		if not slot then
			return nil
		end
		local scale = scales[index]
		scale.Scale = 1.25
		Motion.Tween(scale, 0.3, { Scale = 1 }, Enum.EasingStyle.Back)
		return slot.AbsolutePosition + slot.AbsoluteSize / 2
	end

	return self
end

return table.freeze(DeckBar)
