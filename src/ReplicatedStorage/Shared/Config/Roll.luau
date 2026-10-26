--!strict
-- Rules of one roll. The server enforces all of them; the client only displays them.

local Seal = require(script.Parent.Parent.Core.Seal)

return Seal(script, {
	-- Cards drawn per roll; the best one is kept.
	CardsPerRoll = 3,
	-- Minimum seconds between two rolls of one player (server-side guard against spam).
	Cooldown = 0.5,
	-- Luck divides every "1 in N": luck 2 makes a 1 in 100 card a 1 in 50 card.
	BaseLuck = 1,
	-- Every LuckyEvery-th roll is a lucky roll with LuckyMultiplier times the luck.
	LuckyEvery = 10,
	LuckyMultiplier = 3,
})
