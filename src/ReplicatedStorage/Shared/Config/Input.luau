--!strict
-- Keys for every action (keyboard + gamepad). The Hud shows the first key as a hint.

local Seal = require(script.Parent.Parent.Core.Seal)

return Seal(script, {
	Roll = { Enum.KeyCode.R, Enum.KeyCode.ButtonX },
	Auto = { Enum.KeyCode.T, Enum.KeyCode.ButtonY },
})
