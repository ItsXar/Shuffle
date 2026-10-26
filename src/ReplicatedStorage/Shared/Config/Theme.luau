--!strict
--[[
	Look of the whole UI: fonts, colours, layers and sizes. Sizes are in design pixels; Client/UI/Fit
	scales every canvas to the screen, so nothing else needs to care about resolution.
]]

local Seal = require(script.Parent.Parent.Core.Seal)

return Seal(script, {
	Fonts = {
		Display = Enum.Font.GothamBlack,
		Body = Enum.Font.GothamBold,
	},

	Colors = {
		Ink = Color3.fromRGB(10, 8, 20),
		Text = Color3.fromRGB(255, 255, 255),
		Muted = Color3.fromRGB(176, 170, 204),
		BackTop = Color3.fromRGB(122, 76, 255),
		BackBottom = Color3.fromRGB(46, 18, 128),
		BackGlow = Color3.fromRGB(220, 200, 255),
		Gold = Color3.fromRGB(255, 214, 64),
		Roll = Color3.fromRGB(255, 184, 36),
		RollBusy = Color3.fromRGB(104, 100, 128),
		AutoOff = Color3.fromRGB(70, 78, 106),
		AutoOn = Color3.fromRGB(52, 200, 120),
		Lucky = Color3.fromRGB(255, 214, 64),
		Selector = Color3.fromRGB(255, 255, 255),
		New = Color3.fromRGB(255, 64, 96),
	},

	-- ScreenGui DisplayOrder per layer (Client/UI/Root): Dim (blackout, colour flood, motes) sits
	-- under the buttons so they stay readable; cards and effects are on top.
	Layers = {
		Dim = 1,
		Hud = 2,
		Stage = 3,
		Fx = 4,
	},

	-- Largest scale any canvas may reach on big screens.
	MaxScale = 1,

	Card = {
		Size = Vector2.new(160, 224),
		Gap = 22,
		Corner = 14,
	},

	-- The card row at the top of the screen. HeightShare = part of the screen height it may use.
	Stage = {
		Design = Vector2.new(600, 340),
		HeightShare = 0.4,
		Top = 6,
	},

	-- The two buttons at the bottom of the screen.
	Hud = {
		Design = Vector2.new(400, 80),
		HeightShare = 0.11,
		Bottom = 18,
	},
})
