--!strict
--[[
	Every card that can be rolled. Rarity = an Id from Config/Rarities; every rarity needs at least
	one card (Domain/Catalog checks this on load). Icon is any emoji or short text.
]]

local Seal = require(script.Parent.Parent.Core.Seal)

export type Card = {
	Id: string,
	Name: string,
	Rarity: string,
	Icon: string,
}

local Cards: { Card } = {
	{ Id = "Pebble", Name = "Pebble", Rarity = "Common", Icon = "🪨" },
	{ Id = "Leaf", Name = "Leaf", Rarity = "Common", Icon = "🍃" },
	{ Id = "Cookie", Name = "Cookie", Rarity = "Common", Icon = "🍪" },

	{ Id = "Clover", Name = "Clover", Rarity = "Uncommon", Icon = "🍀" },
	{ Id = "Mushroom", Name = "Mushroom", Rarity = "Uncommon", Icon = "🍄" },
	{ Id = "Feather", Name = "Feather", Rarity = "Uncommon", Icon = "🪶" },

	{ Id = "Comet", Name = "Comet", Rarity = "Rare", Icon = "☄️" },
	{ Id = "IceShard", Name = "Ice Shard", Rarity = "Rare", Icon = "🧊" },
	{ Id = "Bolt", Name = "Bolt", Rarity = "Rare", Icon = "⚡" },

	{ Id = "Diamond", Name = "Diamond", Rarity = "Epic", Icon = "💎" },
	{ Id = "CrystalBall", Name = "Crystal Ball", Rarity = "Epic", Icon = "🔮" },
	{ Id = "Rocket", Name = "Rocket", Rarity = "Epic", Icon = "🚀" },

	{ Id = "Crown", Name = "Golden Crown", Rarity = "Legendary", Icon = "👑" },
	{ Id = "Dragon", Name = "Dragon", Rarity = "Legendary", Icon = "🐉" },
	{ Id = "Trophy", Name = "Trophy", Rarity = "Legendary", Icon = "🏆" },

	{ Id = "Phoenix", Name = "Phoenix Flame", Rarity = "Mythic", Icon = "🔥" },
	{ Id = "Unicorn", Name = "Unicorn", Rarity = "Mythic", Icon = "🦄" },

	{ Id = "SolarCore", Name = "Solar Core", Rarity = "Divine", Icon = "☀️" },
	{ Id = "Halo", Name = "Halo", Rarity = "Divine", Icon = "😇" },

	{ Id = "Galaxy", Name = "Galaxy", Rarity = "Celestial", Icon = "🌌" },
	{ Id = "Saturn", Name = "Ringed World", Rarity = "Celestial", Icon = "🪐" },

	{ Id = "TheEye", Name = "The Eye", Rarity = "Secret", Icon = "👁️" },
}

return Seal(script, Cards)
