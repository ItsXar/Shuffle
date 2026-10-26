--!strict
--[[
	Image ids of the card art (assets/cards/*.png, drawn by tools/cardart). Upload the PNGs in
	Studio (View > Asset Manager > Bulk Import, or Creator Hub), then paste each id here: either
	"rbxassetid://123456" or just "123456". An empty id falls back to the card drawn from frames.
]]

local Seal = require(script.Parent.Parent.Core.Seal)

return Seal(script, {
	Back = "104699222511109",
	Fronts = {
		Common = "124272279161137",
		Uncommon = "108080585418673",
		Rare = "71511179530262",
		Epic = "121966631236058",
		Legendary = "117418024455321",
		Mythic = "104098957921952",
		Divine = "100442046803306",
		Celestial = "76781360840866",
		Secret = "126304193852297",
	},
})
