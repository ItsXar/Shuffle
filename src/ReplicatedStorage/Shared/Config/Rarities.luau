--!strict
--[[
	Every rarity, from the most common to the rarest. The position in this list is the tier:
	a higher tier always beats a lower one when the system picks the best card of a roll.

	Chance = "1 in N" for one card (Domain/Odds). Power = damage a card of this rarity deals per
	hit in battle (Domain/Power). Fx = how hard the roll show celebrates this rarity:
	  Shake, Flash   0..1 strength          Sparks     particles in the burst
	  Suspense       seconds the closed card spends climbing the rarities up to this one
	  Hold           seconds the winner stays on screen before it is collected
	  Rays           sunburst, rising motes        Banner     colour flood + big title
	  Blackout       dark build-up, light pouring into the card     Confetti   confetti rain
	Effect = card finish: "None", "Shine" (light sweep) or "Rainbow" (shine + rainbow rim).
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
	Confetti: boolean,
}

export type Rarity = {
	Id: string,
	Name: string,
	Chance: number,
	Color: Color3,
	Dark: Color3,
	Power: number,
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
		Power = 1,
		Effect = "None",
		Fx = {
			Shake = 0,
			Flash = 0,
			Sparks = 10,
			Suspense = 0,
			Hold = 0.35,
			Banner = false,
			Rays = false,
			Blackout = false,
			Confetti = false,
		},
	},
	{
		Id = "Uncommon",
		Name = "Uncommon",
		Chance = 4,
		Color = Color3.fromRGB(94, 232, 128),
		Dark = Color3.fromRGB(22, 96, 50),
		Power = 3,
		Effect = "None",
		Fx = {
			Shake = 0.08,
			Flash = 0.1,
			Sparks = 16,
			Suspense = 0,
			Hold = 0.45,
			Banner = false,
			Rays = false,
			Blackout = false,
			Confetti = false,
		},
	},
	{
		Id = "Rare",
		Name = "Rare",
		Chance = 12,
		Color = Color3.fromRGB(64, 170, 255),
		Dark = Color3.fromRGB(16, 58, 128),
		Power = 8,
		Effect = "Shine",
		Fx = {
			Shake = 0.18,
			Flash = 0.2,
			Sparks = 28,
			Suspense = 0.7,
			Hold = 0.7,
			Banner = false,
			Rays = true,
			Blackout = false,
			Confetti = false,
		},
	},
	{
		Id = "Epic",
		Name = "Epic",
		Chance = 40,
		Color = Color3.fromRGB(184, 98, 255),
		Dark = Color3.fromRGB(64, 22, 124),
		Power = 20,
		Effect = "Shine",
		Fx = {
			Shake = 0.32,
			Flash = 0.35,
			Sparks = 46,
			Suspense = 1.2,
			Hold = 1.1,
			Banner = true,
			Rays = true,
			Blackout = false,
			Confetti = false,
		},
	},
	{
		Id = "Legendary",
		Name = "Legendary",
		Chance = 150,
		Color = Color3.fromRGB(255, 198, 58),
		Dark = Color3.fromRGB(138, 78, 8),
		Power = 55,
		Effect = "Shine",
		Fx = {
			Shake = 0.5,
			Flash = 0.5,
			Sparks = 70,
			Suspense = 1.8,
			Hold = 1.6,
			Banner = true,
			Rays = true,
			Blackout = true,
			Confetti = true,
		},
	},
	{
		Id = "Mythic",
		Name = "Mythic",
		Chance = 600,
		Color = Color3.fromRGB(255, 64, 128),
		Dark = Color3.fromRGB(118, 8, 50),
		Power = 150,
		Effect = "Shine",
		Fx = {
			Shake = 0.65,
			Flash = 0.65,
			Sparks = 90,
			Suspense = 2.3,
			Hold = 2,
			Banner = true,
			Rays = true,
			Blackout = true,
			Confetti = true,
		},
	},
	{
		Id = "Divine",
		Name = "Divine",
		Chance = 2500,
		Color = Color3.fromRGB(130, 248, 255),
		Dark = Color3.fromRGB(14, 104, 136),
		Power = 420,
		Effect = "Rainbow",
		Fx = {
			Shake = 0.8,
			Flash = 0.8,
			Sparks = 110,
			Suspense = 2.8,
			Hold = 2.4,
			Banner = true,
			Rays = true,
			Blackout = true,
			Confetti = true,
		},
	},
	{
		Id = "Celestial",
		Name = "Celestial",
		Chance = 10000,
		Color = Color3.fromRGB(132, 102, 255),
		Dark = Color3.fromRGB(18, 10, 66),
		Power = 1200,
		Effect = "Rainbow",
		Fx = {
			Shake = 0.9,
			Flash = 0.85,
			Sparks = 130,
			Suspense = 3.2,
			Hold = 2.8,
			Banner = true,
			Rays = true,
			Blackout = true,
			Confetti = true,
		},
	},
	{
		Id = "Secret",
		Name = "Secret",
		Chance = 100000,
		Color = Color3.fromRGB(255, 255, 255),
		Dark = Color3.fromRGB(12, 10, 18),
		Power = 4000,
		Effect = "Rainbow",
		Fx = {
			Shake = 1,
			Flash = 1,
			Sparks = 160,
			Suspense = 3.8,
			Hold = 3.4,
			Banner = true,
			Rays = true,
			Blackout = true,
			Confetti = true,
		},
	},
}

return Seal(script, Rarities)
