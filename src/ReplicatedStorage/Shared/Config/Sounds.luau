--!strict
--[[
	Every sound the game plays, by name (Client/Core/Audio). Enabled switches all of them; it is off
	until the game gets its own sound design. The ids are sounds built into Roblox; swap them for
	Creator Store sounds ("rbxassetid://123...") freely.
]]

local Seal = require(script.Parent.Parent.Core.Seal)

export type Sound = { Id: string, Volume: number }

local List: { [string]: Sound } = {
	Click = { Id = "rbxasset://sounds/button.wav", Volume = 0.5 },
	Tick = { Id = "rbxasset://sounds/clickfast.wav", Volume = 0.3 },
	Land = { Id = "rbxasset://sounds/button.wav", Volume = 0.6 },
	Reveal = { Id = "rbxasset://sounds/electronicpingshort.wav", Volume = 0.6 },
	Whoosh = { Id = "rbxasset://sounds/swoosh.wav", Volume = 0.45 },
	Snap = { Id = "rbxasset://sounds/snap.wav", Volume = 0.6 },
	Win = { Id = "rbxasset://sounds/victory.wav", Volume = 0.6 },
}

return Seal(script, {
	Enabled = false,
	List = List,
})
