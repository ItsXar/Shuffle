--!strict
--[[
	Deck rules, shared so the client can mirror the server: a deck holds at most Config/Battle >
	DeckSize different cards the player owns. Clean drops anything else; Fill puts the strongest
	owned cards into empty slots.
]]

local Battle = require(script.Parent.Parent.Config.Battle)
local Catalog = require(script.Parent.Catalog)
local Power = require(script.Parent.Power)

local Deck = {}

function Deck.Clean(raw: any, owned: { [string]: number }): { string }
	local deck = {}
	local seen = {}
	if type(raw) ~= "table" then
		return deck
	end
	for _, cardId in raw do
		if #deck >= Battle.DeckSize then
			break
		end
		if type(cardId) == "string" and Catalog.Has(cardId) and (owned[cardId] or 0) > 0 and not seen[cardId] then
			seen[cardId] = true
			table.insert(deck, cardId)
		end
	end
	return deck
end

-- Adds the strongest owned cards not in the deck yet until it is full. Returns true if it changed.
function Deck.Fill(deck: { string }, owned: { [string]: number }): boolean
	local changed = false
	local inDeck = {}
	for _, cardId in deck do
		inDeck[cardId] = true
	end
	for _, cardId in Power.Best(owned, #Catalog.All()) do
		if #deck >= Battle.DeckSize then
			break
		end
		if not inDeck[cardId] then
			inDeck[cardId] = true
			table.insert(deck, cardId)
			changed = true
		end
	end
	return changed
end

return table.freeze(Deck)
