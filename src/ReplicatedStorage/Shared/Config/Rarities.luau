--!strict
--[[
	Every rarity, from the most common to the rarest. The position in this list is the tier:
	a higher tier always beats a lower one when the system picks the best card of a roll.

	Chance = "1 in N" for one card (Domain/Odds). Fx = how hard the show celebrates this rarity:
	  Shake, Flash   0..1 strength          Sparks    particles in the burst
	  Suspense       seconds the reel teases before locking a card of this rarity
	  Hold           seconds the winner stays on screen before it is collected
	  Banner, Rays, Blackout   the big announcement, sunburst behind the card, screen goes dark first
	Effect = card finish: "None", "Shine" (light sweep) or "Rainbow" (shine + rainbow border).
]]

local Seal = require(script.Parent.Parent.Core.Seal)

export type Effect = "None" | "Shine" | "Rainbow"

export type Fx = {
	Shake: number,
	Flash: number,
	Sparks: number,
	Suspense: number,
	Hold: number,
	Banner: boolean,
	Rays: boolean,
	Blackout: boolean,
}

export type Rarity = {
	Id: string,
	Name: string,
	Chance: number,
	Color: Color3,
	Dark: Color3,
	Effect: Effect,
	Fx: Fx,
}

local Rarities: { Rarity } = {
	{
		Id = "Common",
		Name = "Common",
		-- Tier 1 is what is left when no other tier hits, so this is only shown on the card.
		Chance = 1.5,
		Color = Color3.fromRGB(205, 211, 222),
		Dark = Color3.fromRGB(78, 84, 99),
		Effect = "None",
		Fx = { Shake = 0, Flash = 0, Sparks = 8, Suspense = 0, Hold = 0.25, Banner = false, Rays = false, Blackout = false },
	},
	{
		Id = "Uncommon",
		Name = "Uncommon",
		Chance = 4,
		Color = Color3.fromRGB(94, 232, 128),
		Dark = Color3.fromRGB(22, 96, 50),
		Effect = "None",
		Fx = { Shake = 0.05, Flash = 0.05, Sparks = 14, Suspense = 0, Hold = 0.3, Banner = false, Rays = false, Blackout = false },
	},
	{
		Id = "Rare",
		Name = "Rare",
		Chance = 12,
		Color = Color3.fromRGB(64, 170, 255),
		Dark = Color3.fromRGB(16, 58, 128),
		Effect = "None",
		Fx = { Shake = 0.15, Flash = 0.15, Sparks = 26, Suspense = 0.25, Hold = 0.5, Banner = false, Rays = false, Blackout = false },
	},
	{
		Id = "Epic",
		Name = "Epic",
		Chance = 40,
		Color = Color3.fromRGB(184, 98, 255),
		Dark = Color3.fromRGB(64, 22, 124),
		Effect = "Shine",
		Fx = { Shake = 0.3, Flash = 0.3, Sparks = 44, Suspense = 0.55, Hold = 0.9, Banner = true, Rays = true, Blackout = false },
	},
	{
		Id = "Legendary",
		Name = "Legendary",
		Chance = 150,
		Color = Color3.fromRGB(255, 198, 58),
		Dark = Color3.fromRGB(138, 78, 8),
		Effect = "Shine",
		Fx = { Shake = 0.45, Flash = 0.45, Sparks = 64, Suspense = 0.9, Hold = 1.4, Banner = true, Rays = true, Blackout = false },
	},
	{
		Id = "Mythic",
		Name = "Mythic",
		Chance = 600,
		Color = Color3.fromRGB(255, 64, 128),
		Dark = Color3.fromRGB(118, 8, 50),
		Effect = "Shine",
		Fx = { Shake = 0.6, Flash = 0.6, Sparks = 84, Suspense = 1.3, Hold = 1.8, Banner = true, Rays = true, Blackout = true },
	},
	{
		Id = "Divine",
		Name = "Divine",
		Chance = 2500,
		Color = Color3.fromRGB(130, 248, 255),
		Dark = Color3.fromRGB(14, 104, 136),
		Effect = "Rainbow",
		Fx = { Shake = 0.75, Flash = 0.75, Sparks = 104, Suspense = 1.7, Hold = 2.2, Banner = true, Rays = true, Blackout = true },
	},
	{
		Id = "Celestial",
		Name = "Celestial",
		Chance = 10000,
		Color = Color3.fromRGB(132, 102, 255),
		Dark = Color3.fromRGB(18, 10, 66),
		Effect = "Rainbow",
		Fx = { Shake = 0.9, Flash = 0.85, Sparks = 130, Suspense = 2.2, Hold = 2.8, Banner = true, Rays = true, Blackout = true },
	},
	{
		Id = "Secret",
		Name = "Secret",
		Chance = 100000,
		Color = Color3.fromRGB(255, 255, 255),
		Dark = Color3.fromRGB(12, 10, 18),
		Effect = "Rainbow",
		Fx = { Shake = 1, Flash = 1, Sparks = 160, Suspense = 2.8, Hold = 3.4, Banner = true, Rays = true, Blackout = true },
	},
}

return Seal(script, Rarities)
