--!strict
--[[
	A still card for lists (the backpack): the card art with icon and name, or the darkened frame of
	its rarity with "?" when the card is locked. Falls back to the frame-drawn card sides when the
	card art is not uploaded. Fills its parent.
]]

local Art = require(script.Parent.Card.Art)
local Back = require(script.Parent.Card.Back)
local Front = require(script.Parent.Card.Front)
local Make = require(script.Parent.Parent.Make)

local MiniCard = {}

function MiniCard.Build(parent: Instance, cardId: string, owned: boolean): Frame
	local holder: Frame = Make("Frame", {
		Name = "MiniCard",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Parent = parent,
	})
	if Art.HasFront(cardId) then
		if owned then
			Art.Front(holder, cardId)
		else
			Art.Locked(holder, cardId)
		end
	elseif owned then
		Front.Build(holder, cardId)
	else
		Back.Build(holder)
	end
	return holder
end

return table.freeze(MiniCard)
