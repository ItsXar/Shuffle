--!strict
--[[
	The face-up side of a catalog card, dressed by its rarity: bright rarity gradient with a turning
	sunburst, glowing orb behind the icon, odds badge, name, and a ribbon with the rarity and its
	stars (one per tier, up to six). Rare and up: the icon floats and a light sweep crosses the card.
	Effect "Rainbow": rim and stars cycle through the rainbow.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Catalog = require(ReplicatedStorage.Shared.Domain.Catalog)
local Kit = require(script.Parent.Kit)
local Make = require(script.Parent.Parent.Parent.Make)
local Odds = require(ReplicatedStorage.Shared.Domain.Odds)
local Paint = require(script.Parent.Parent.Parent.Paint)
local Theme = require(ReplicatedStorage.Shared.Config.Theme)

local ART_Y = 0.42
local MAX_STARS = 6
local FLOAT_TIER = 3
local RAINBOW_SPEED = 0.4

local Front = {}

local function badge(frame: Frame, text: string)
	local pill: Frame = Make("Frame", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -10, 0, 10),
		Size = UDim2.fromOffset(46, 16),
		BackgroundColor3 = Theme.Colors.Ink,
		BackgroundTransparency = 0.35,
		ZIndex = 3,
		Parent = frame,
	}, {
		Make("UICorner", { CornerRadius = UDim.new(1, 0) }),
	})
	local label = Kit.Text(pill, text, UDim2.fromScale(0.5, 0.5), UDim2.fromScale(0.9, 0.8), 10, Theme.Colors.Text, 0)
	label.Font = Theme.Fonts.Body
end

local function ribbon(frame: Frame, name: string, tier: number, color: Color3, dark: Color3): TextLabel
	local band: Frame = Make("Frame", {
		Name = "Ribbon",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -8),
		Size = UDim2.new(1, -16, 0, 40),
		BackgroundColor3 = Paint.Shade(dark, 0.35),
		BackgroundTransparency = 0.15,
		ZIndex = 3,
		Parent = frame,
	}, {
		Make("UICorner", { CornerRadius = UDim.new(0, 8) }),
	})
	Kit.Text(band, string.upper(name), UDim2.new(0.5, 0, 0, 10), UDim2.new(0.9, 0, 0, 13), 12, Paint.Tint(color, 0.3), 0)
	local stars = string.rep("★", math.min(tier, MAX_STARS))
	return Kit.Text(band, stars, UDim2.new(0.5, 0, 1, -11), UDim2.new(0.9, 0, 0, 17), 15, Theme.Colors.Gold, 1)
end

function Front.Build(parent: Instance, cardId: string): Kit.Face
	local card = Catalog.Card(cardId)
	local rarity = Catalog.RarityOf(cardId)
	local tier = Catalog.TierOf(cardId)
	local color, dark = rarity.Color, rarity.Dark

	local paint = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Paint.Tint(color, 0.3)),
		ColorSequenceKeypoint.new(0.5, color),
		ColorSequenceKeypoint.new(1, Paint.Shade(dark, 0.2)),
	})
	local frame, rim = Kit.Body(parent, paint, Paint.Shade(color, 0.55), 0.25)
	local art = UDim2.fromScale(0.5, ART_Y)

	Kit.Sunburst(frame, art, 1.2, 20 + tier * 8)
	Kit.Orb(frame, art, 0.78, Color3.new(1, 1, 1), { 0.8, 0.7, 0.6 })
	local icon = Kit.Text(frame, card.Icon, art, UDim2.fromScale(0.6, 0.36), 64, Color3.new(1, 1, 1), 0)
	if tier >= FLOAT_TIER then
		Paint.Animate(icon, function(elapsed: number)
			icon.Position = UDim2.fromScale(0.5, ART_Y + 0.025 * math.sin(elapsed * 2.6))
		end)
	end

	badge(frame, Odds.Short(rarity.Chance))
	Kit.Text(frame, card.Name, UDim2.fromScale(0.5, 0.69), UDim2.fromScale(0.88, 0.1), 19, Theme.Colors.Text, 2, Paint.Shade(dark, 0.4))
	local stars = ribbon(frame, rarity.Name, tier, color, dark)

	if rarity.Effect ~= "None" then
		Kit.Shine(frame)
	end
	if rarity.Effect == "Rainbow" then
		Paint.Animate(frame, function(elapsed: number)
			rim.Color = Color3.fromHSV((elapsed * RAINBOW_SPEED) % 1, 0.7, 1)
			stars.TextColor3 = Color3.fromHSV((elapsed * RAINBOW_SPEED + 0.5) % 1, 0.5, 1)
		end)
	end
	return { Frame = frame, Stars = stars }
end

return table.freeze(Front)
