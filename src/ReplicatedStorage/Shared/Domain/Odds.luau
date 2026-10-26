--!strict
--[[
	The rules of drawing cards, shared by both sides: the server rolls with them, the client uses
	them to fill the spinning reel and to print odds. Pure functions, no state.

	One card: the rarest tier is tested first; each tier hits with chance luck / Chance, so a
	"1 in 150" card really is about 1 in 150 at luck 1. Nothing hit = tier 1.
]]

local Catalog = require(script.Parent.Catalog)

-- What the server answers to one roll (Net remote "Roll").
export type Result = {
	Hand: { string }, -- card ids, left to right
	Best: number, -- index into Hand of the card the system kept
	Luck: number,
	Lucky: boolean, -- this was a lucky roll (Config/Roll > LuckyEvery)
	New: boolean, -- the kept card was never pulled before
	Rolls: number, -- rolls done by the player, this one included
	UntilLucky: number, -- rolls left until the next lucky roll (1 = the next one)
}

-- What the server answers to "Inventory": how many of each card the player owns.
export type Collection = {
	Owned: { [string]: number },
	Rolls: number,
}

local Odds = {}

function Odds.RollTier(rng: Random, luck: number): number
	for tier = Catalog.TierCount(), 2, -1 do
		if rng:NextNumber() * Catalog.Rarity(tier).Chance < luck then
			return tier
		end
	end
	return 1
end

function Odds.RollCard(rng: Random, luck: number): string
	local pool = Catalog.CardsOf(Odds.RollTier(rng, luck))
	return pool[rng:NextInteger(1, #pool)].Id
end

function Odds.RollHand(rng: Random, luck: number, count: number): { string }
	local hand = table.create(count)
	for index = 1, count do
		hand[index] = Odds.RollCard(rng, luck)
	end
	return hand
end

-- Index of the highest tier in the hand; the leftmost wins a tie.
function Odds.Best(hand: { string }): number
	local best, bestTier = 1, 0
	for index, cardId in hand do
		local tier = Catalog.TierOf(cardId)
		if tier > bestTier then
			best, bestTier = index, tier
		end
	end
	return best
end

-- 150 -> "150", 2500 -> "2.5K", 100000 -> "100K".
local function compact(chance: number): string
	local value, suffix = chance, ""
	if chance >= 1e6 then
		value, suffix = chance / 1e6, "M"
	elseif chance >= 1e3 then
		value, suffix = chance / 1e3, "K"
	end
	local text = string.gsub(string.format("%.1f", value), "%.0$", "")
	return text .. suffix
end

-- "1 in 150"
function Odds.Format(chance: number): string
	return `1 in {compact(chance)}`
end

-- "1/150", for small badges.
function Odds.Short(chance: number): string
	return `1/{compact(chance)}`
end

return table.freeze(Odds)
