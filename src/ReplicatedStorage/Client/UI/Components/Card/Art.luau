--!strict
--[[
	Card sides drawn from the uploaded card art (Config/CardArt): one image per side, with only the
	icon and the card name added on top. The images are 800x1040: the 600x840 card plus a 100 px
	margin for the crest, wings and glow, so the image is larger than the card and centred on it.
	Spots for the icon and the name match tools/cardart/cards.html.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CardArt = require(ReplicatedStorage.Shared.Config.CardArt)
local Catalog = require(ReplicatedStorage.Shared.Domain.Catalog)
local Kit = require(script.Parent.Kit)
local Make = require(script.Parent.Parent.Parent.Make)
local Paint = require(script.Parent.Parent.Parent.Paint)
local Theme = require(ReplicatedStorage.Shared.Config.Theme)

local IMAGE_SIZE = UDim2.fromScale(800 / 600, 1040 / 840)
local ICON_Y = 0.412
local NAME_Y = 0.733
local FLOAT_TIER = 3

local Art = {}

local function asset(id: string): string?
	if id == "" then
		return nil
	end
	return if string.match(id, "^%d+$") then `rbxassetid://{id}` else id
end

local function image(parent: Instance, id: string): Frame
	local frame: Frame = Make("Frame", {
		Name = "Face",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ZIndex = 1,
		Parent = parent,
	})
	Make("ImageLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = IMAGE_SIZE,
		BackgroundTransparency = 1,
		Image = id,
		ScaleType = Enum.ScaleType.Stretch,
		ZIndex = 1,
		Parent = frame,
	})
	return frame
end

function Art.HasBack(): boolean
	return asset(CardArt.Back) ~= nil
end

function Art.HasFront(cardId: string): boolean
	return asset(CardArt.Fronts[Catalog.RarityOf(cardId).Id]) ~= nil
end

-- A card the player has not found yet: its rarity frame, darkened, with "?" and "???".
function Art.Locked(parent: Instance, cardId: string): Kit.Face
	local frame = image(parent, asset(CardArt.Fronts[Catalog.RarityOf(cardId).Id]) :: string)
	local picture = frame:FindFirstChildOfClass("ImageLabel") :: ImageLabel
	picture.ImageColor3 = Color3.fromRGB(60, 60, 66)
	local grey = Color3.fromRGB(150, 150, 165)
	Kit.Text(frame, "?", UDim2.fromScale(0.5, ICON_Y), UDim2.fromScale(0.42, 0.3), 80, grey, 2)
	Kit.Text(frame, "???", UDim2.fromScale(0.5, NAME_Y), UDim2.fromScale(0.68, 0.065), 22, grey, 0)
	return { Frame = frame, Stars = nil }
end

function Art.Back(parent: Instance): Kit.Face
	return { Frame = image(parent, asset(CardArt.Back) :: string), Stars = nil }
end

function Art.Front(parent: Instance, cardId: string): Kit.Face
	local card = Catalog.Card(cardId)
	local tier = Catalog.TierOf(cardId)
	local frame = image(parent, asset(CardArt.Fronts[Catalog.RarityOf(cardId).Id]) :: string)

	local icon = Kit.Text(frame, card.Icon, UDim2.fromScale(0.5, ICON_Y), UDim2.fromScale(0.42, 0.3), 80, Color3.new(1, 1, 1), 0)
	if tier >= FLOAT_TIER then
		Paint.Animate(icon, function(elapsed: number)
			icon.Position = UDim2.fromScale(0.5, ICON_Y + 0.02 * math.sin(elapsed * 2.6))
			icon.Rotation = 4 * math.sin(elapsed * 1.7)
		end)
	end
	local name = UDim2.fromScale(0.5, NAME_Y)
	Kit.Text(frame, card.Name, name, UDim2.fromScale(0.68, 0.065), 22, Theme.Colors.Text, 2)
	if tier >= FLOAT_TIER then
		Kit.Shine(frame)
	end
	return { Frame = frame, Stars = nil }
end

return table.freeze(Art)
