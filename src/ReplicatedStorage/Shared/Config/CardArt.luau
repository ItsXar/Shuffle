--!strict
--[[
	Image ids of the card art (assets/cards/*.png, drawn by tools/cardart). Upload the PNGs in
	Studio (View > Asset Manager > Bulk Import, or Creator Hub), then paste each id here: either
	"rbxassetid://123456" or just "123456". An empty id falls back to the card drawn from frames.
]]

local Seal = require(script.Parent.Parent.Core.Seal)

return Seal(script, {
	Back = "",
	Fronts = {
		Common = "",
		Uncommon = "",
		Rare = "",
		Epic = "",
		Legendary = "",
		Mythic = "",
		Divine = "",
		Celestial = "",
		Secret = "",
	},
})
