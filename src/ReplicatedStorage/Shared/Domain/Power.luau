--!strict
--[[
	Battle numbers shared by both sides: a card's power (rarity power, plus a bonus for every extra
	copy owned), a deck's total, a monster's HP and which monster a level brings.
]]

local Battle = require(script.Parent.Parent.Config.Battle)
local Catalog = require(script.Parent.Catalog)

-- Server -> client over the "Battle" remote. Spawn = a monster appears (or the client asked for
-- the current state); Hits = one tick of damage, one entry per deck slot, Killed when it died.
export type BattleEvent = {
	Kind: "Spawn" | "Hits",
	Level: number,
	Hp: number,
	MaxHp: number,
	Hits: { number }?,
	Killed: boolean?,
}

local Power = {}

function Power.Card(cardId: string, copies: number): number
	local bonus = math.min(math.max(copies - 1, 0) * Battle.CopyBonus, Battle.MaxCopyBonus)
	return math.floor(Catalog.RarityOf(cardId).Power * (1 + bonus) + 0.5)
end

function Power.Deck(deck: { string }, owned: { [string]: number }): number
	local total = 0
	for _, cardId in deck do
		total += Power.Card(cardId, owned[cardId] or 1)
	end
	return total
end

function Power.MonsterHp(level: number): number
	return math.floor(Battle.BaseHp * Battle.HpGrowth ^ (level - 1))
end

function Power.Monster(level: number): Battle.Monster
	local monsters = Battle.Monsters
	return monsters[(level - 1) % #monsters + 1]
end

-- The strongest cards owned, best first, at most `size` of them.
function Power.Best(owned: { [string]: number }, size: number): { string }
	local cards = {}
	for cardId, count in owned do
		if count > 0 and Catalog.Has(cardId) then
			table.insert(cards, cardId)
		end
	end
	table.sort(cards, function(a: string, b: string): boolean
		local powerA, powerB = Power.Card(a, owned[a]), Power.Card(b, owned[b])
		if powerA ~= powerB then
			return powerA > powerB
		end
		return a < b
	end)
	local best = {}
	for index = 1, math.min(size, #cards) do
		best[index] = cards[index]
	end
	return best
end

-- 1234 -> "1.2K", 3400000 -> "3.4M".
function Power.Format(value: number): string
	local units = { { 1e12, "T" }, { 1e9, "B" }, { 1e6, "M" }, { 1e3, "K" } }
	for _, unit in units do
		if value >= unit[1] then
			local text = string.gsub(string.format("%.1f", value / unit[1]), "%.0$", "")
			return text .. unit[2]
		end
	end
	return tostring(math.floor(value))
end

return table.freeze(Power)
