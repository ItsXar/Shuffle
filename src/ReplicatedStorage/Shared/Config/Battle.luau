--!strict
--[[
	Rules of the battle: the deck of cards fights an endless line of monsters. Every TickSeconds
	each card in the deck hits once for its power (Domain/Power); a monster that drops to 0 HP is
	replaced by the next level, which is stronger.

	Monsters take turns by level (level 1 = the first one, level 4 = the first one again...).
	Model = which builder draws it (Client/World/Monsters).
]]

local Seal = require(script.Parent.Parent.Core.Seal)

export type Monster = {
	Id: string,
	Name: string,
	Model: "Slime" | "Golem" | "Demon",
	Color: Color3,
	Glow: Color3,
}

local Monsters: { Monster } = {
	{ Id = "Slime", Name = "Gloop", Model = "Slime", Color = Color3.fromRGB(92, 220, 110), Glow = Color3.fromRGB(200, 255, 140) },
	{ Id = "Golem", Name = "Stone Golem", Model = "Golem", Color = Color3.fromRGB(120, 116, 130), Glow = Color3.fromRGB(255, 140, 40) },
	{ Id = "Demon", Name = "Void Demon", Model = "Demon", Color = Color3.fromRGB(110, 50, 190), Glow = Color3.fromRGB(255, 70, 200) },
}

return Seal(script, {
	DeckSize = 5,
	TickSeconds = 1,
	-- HP of level 1, and how much more every next level has.
	BaseHp = 40,
	HpGrowth = 1.3,
	-- Every extra copy of a card adds this much power, up to MaxCopyBonus (+200 %).
	CopyBonus = 0.1,
	MaxCopyBonus = 2,
	Monsters = Monsters,
})
