--!strict
--[[
	Read-only lookups over Config/Cards and Config/Rarities: card by id, rarity and tier of a card,
	cards of a tier. Tier = position of the rarity in Config/Rarities (1 = most common).
	Checks the config once on load, so a typo in a card's rarity fails loudly at boot.
]]

local Cards = require(script.Parent.Parent.Config.Cards)
local Log = require(script.Parent.Parent.Core.Log)
local Rarities = require(script.Parent.Parent.Config.Rarities)

local TAG = "Catalog"

local tierById: { [string]: number } = {}
local cardById: { [string]: Cards.Card } = {}
local cardsByTier: { { Cards.Card } } = {}

for tier, rarity in Rarities do
	tierById[rarity.Id] = tier
	cardsByTier[tier] = {}
end

for _, card in Cards do
	local tier = tierById[card.Rarity]
	if not tier then
		Log.Error(TAG, `Card "{card.Id}" has unknown rarity "{card.Rarity}"`)
	end
	if cardById[card.Id] then
		Log.Error(TAG, `Card id "{card.Id}" is used twice`)
	end
	cardById[card.Id] = card
	table.insert(cardsByTier[tier], card)
end

for tier, rarity in Rarities do
	if #cardsByTier[tier] == 0 then
		Log.Error(TAG, `Rarity "{rarity.Id}" has no cards`)
	end
end

local Catalog = {}

function Catalog.Card(id: string): Cards.Card
	local card = cardById[id]
	if not card then
		Log.Error(TAG, `Unknown card "{id}"`, 2)
	end
	return card
end

function Catalog.TierOf(cardId: string): number
	return tierById[Catalog.Card(cardId).Rarity]
end

function Catalog.RarityOf(cardId: string): Rarities.Rarity
	return Rarities[Catalog.TierOf(cardId)]
end

function Catalog.Rarity(tier: number): Rarities.Rarity
	return Rarities[tier]
end

function Catalog.CardsOf(tier: number): { Cards.Card }
	return cardsByTier[tier]
end

function Catalog.TierCount(): number
	return #Rarities
end

return table.freeze(Catalog)
