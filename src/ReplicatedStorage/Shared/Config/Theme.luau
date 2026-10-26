--!strict
--[[
	Look of the whole UI: fonts, colours, layers and sizes. Sizes are in design pixels; Client/UI/Fit
	scales every canvas to the screen, so nothing else needs to care about resolution.
]]

local Seal = require(script.Parent.Parent.Core.Seal)

return Seal(script, {
	Fonts = {
		Title = Enum.Font.FredokaOne,
		Body = Enum.Font.GothamBold,
	},

	Colors = {
		Ink = Color3.fromRGB(14, 10, 28),
		Panel = Color3.fromRGB(32, 24, 62),
		PanelEdge = Color3.fromRGB(96, 74, 176),
		Text = Color3.fromRGB(255, 255, 255),
		Muted = Color3.fromRGB(196, 188, 228),
		BackTop = Color3.fromRGB(74, 44, 158),
		BackBottom = Color3.fromRGB(26, 14, 66),
		BackEdge = Color3.fromRGB(164, 136, 255),
		Roll = Color3.fromRGB(255, 196, 40),
		RollBusy = Color3.fromRGB(116, 106, 150),
		AutoOff = Color3.fromRGB(84, 74, 124),
		AutoOn = Color3.fromRGB(64, 214, 116),
		Lucky = Color3.fromRGB(255, 214, 64),
		Selector = Color3.fromRGB(255, 255, 255),
		New = Color3.fromRGB(255, 72, 96),
	},

	-- ScreenGui DisplayOrder per layer (Client/UI/Root).
	Layers = {
		Hud = 1,
		Dim = 2,
		Stage = 3,
		Fx = 4,
	},

	-- Largest scale any canvas may reach on big screens.
	MaxScale = 1.3,

	Card = {
		Size = Vector2.new(170, 236),
		Gap = 28,
		Corner = 16,
	},

	-- The card row at the top of the screen. HeightShare = part of the screen height it may use.
	Stage = {
		Design = Vector2.new(640, 360),
		HeightShare = 0.46,
		Top = 8,
	},

	-- The controls at the bottom of the screen.
	Hud = {
		Design = Vector2.new(640, 190),
		HeightShare = 0.27,
		Bottom = 12,
	},
})
