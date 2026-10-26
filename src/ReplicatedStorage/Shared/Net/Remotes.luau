--!strict
--[[
	The single list of every remote in the game. Adding a remote = adding one line here.
]]

export type Kind = "Event" | "Unreliable" | "Function"
export type Spec = { Kind: Kind }

local Remotes: { [string]: Spec } = {
	-- Client asks for one roll; the server draws the cards and answers with an Odds.Result.
	Roll = { Kind = "Function" },
	-- Client asks for its collection (Shared/Domain/Odds > Collection) once, when it starts.
	Inventory = { Kind = "Function" },
	-- Client asks to change its deck (card ids); the server answers with the deck it kept.
	SetDeck = { Kind = "Function" },
	-- Server -> client: the battle (Shared/Domain/Power > BattleEvent): a monster spawns, hits land.
	Battle = { Kind = "Event" },
}

return table.freeze(Remotes)
