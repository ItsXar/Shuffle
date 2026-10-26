--!strict
--[[
	State of one roll show on the Stage, shared by its phases (Deal -> Reels -> Pick -> Celebrate):
	the canvas, the server's result, the dealt cards, the button the cards fly out of and back into,
	and the geometry of the card row. Everything a show creates goes into its Scope, so one Clean()
	always leaves the stage empty.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Card = require(script.Parent.Parent.Parent.Components.Card)
local Catalog = require(ReplicatedStorage.Shared.Domain.Catalog)
local Odds = require(ReplicatedStorage.Shared.Domain.Odds)
local Rarities = require(ReplicatedStorage.Shared.Config.Rarities)
local Scope = require(ReplicatedStorage.Shared.Util.Scope)
local Theme = require(ReplicatedStorage.Shared.Config.Theme)

-- Gap above the card row, and where the winner stands (centre) and how big it grows there.
local ROW_TOP = 22
local FOCUS_Y = 182
local FOCUS_SCALE = 1.3

export type Show = {
	Canvas: Frame,
	Origin: GuiObject,
	Result: Odds.Result,
	Cards: { Card.Card },
	Best: Card.Card,
	Rarity: Rarities.Rarity,
	Tier: number,
	Rng: Random,
	Scope: Scope.Scope,
}

local Show = {}

Show.FocusScale = FOCUS_SCALE
Show.RowY = ROW_TOP + Theme.Card.Size.Y / 2

-- Resting place of card `index` of `count`, centred in the canvas.
function Show.Slot(index: number, count: number): UDim2
	local x = (index - (count + 1) / 2) * (Theme.Card.Size.X + Theme.Card.Gap)
	return UDim2.new(0.5, x, 0, Show.RowY)
end

function Show.Focus(): UDim2
	return UDim2.new(0.5, 0, 0, FOCUS_Y)
end

-- Screen-space centre of a gui, for effects drawn on full-screen layers.
function Show.ScreenCenter(gui: GuiObject): Vector2
	return gui.AbsolutePosition + gui.AbsoluteSize / 2
end

-- A screen point in the canvas' own design pixels (undoes the canvas UIScale).
function Show.ToCanvas(canvas: GuiObject, point: Vector2): UDim2
	local scale = canvas.AbsoluteSize.X / Theme.Stage.Design.X
	local inside = (point - canvas.AbsolutePosition) / scale
	return UDim2.fromOffset(inside.X, inside.Y)
end

function Show.new(canvas: Frame, result: Odds.Result, origin: GuiObject): Show
	local scope = Scope.new()
	local cards = {}
	for index in result.Hand do
		local card = scope:Add(Card.new(canvas))
		card.Root.Visible = false
		cards[index] = card
	end

	local bestId = result.Hand[result.Best]
	return {
		Canvas = canvas,
		Origin = origin,
		Result = result,
		Cards = cards,
		Best = cards[result.Best],
		Rarity = Catalog.RarityOf(bestId),
		Tier = Catalog.TierOf(bestId),
		Rng = Random.new(),
		Scope = scope,
	}
end

return table.freeze(Show)
