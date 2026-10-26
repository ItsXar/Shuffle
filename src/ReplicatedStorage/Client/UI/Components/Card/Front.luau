--!strict
--[[
	The face-up side of a catalog card, dressed by its rarity (Config/Rarities): dark tinted body,
	metallic rim that spins faster the rarer it is, rarity title, glowing art window with the icon,
	name and odds. Rare and up: the icon floats; Epic and up: a small sunburst behind it; Effect
	"Shine" adds a holographic sweep, "Rainbow" a rainbow rim as well.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Catalog = require(ReplicatedStorage.Shared.Domain.Catalog)
local Kit = require(script.Parent.Kit)
local Make = require(script.Parent.Parent.Parent.Make)
local Odds = require(ReplicatedStorage.Shared.Domain.Odds)
local Paint = require(script.Parent.Parent.Parent.Paint)
local Rays = require(script.Parent.Parent.Parent.Fx.Rays)
local Theme = require(ReplicatedStorage.Shared.Config.Theme)

local FLOAT_TIER = 3
local RAYS_TIER = 4
local RAYS_SIZE = 130
local RAINBOW_SPEED = 0.3

local DIVIDER_FADE = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 1),
	NumberSequenceKeypoint.new(0.5, 0),
	NumberSequenceKeypoint.new(1, 1),
})

local Front = {}

local function rimSpeed(tier: number): number
	return if tier <= 1 then 0 else 30 + tier * 18
end

local function art(frame: Frame, icon: string, color: Color3, tier: number)
	local window: Frame = Make("Frame", {
		Name = "Art",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.43),
		Size = UDim2.fromScale(0.84, 0.5),
		BackgroundTransparency = 1,
		ZIndex = 2,
		Parent = frame,
	})
	if tier >= RAYS_TIER then
		Rays.Attach(window, UDim2.fromScale(0.5, 0.5), color, RAYS_SIZE)
	end
	Kit.Orb(window, UDim2.fromScale(0.5, 0.5), 0.95, color, 0.45 + tier * 0.05)

	local center = UDim2.fromScale(0.5, 0.5)
	local label = Kit.Text(window, icon, Theme.Fonts.Display, center, UDim2.fromScale(0.62, 0.7), Theme.Colors.Text, 72, false)
	if tier >= FLOAT_TIER then
		Paint.Animate(label, function(elapsed: number)
			label.Position = UDim2.fromScale(0.5, 0.5 + 0.035 * math.sin(elapsed * 2.4))
			label.Rotation = 4 * math.sin(elapsed * 1.7)
		end)
	end
end

local function divider(frame: Frame, color: Color3)
	Make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.71),
		Size = UDim2.new(0.72, 0, 0, 2),
		BackgroundColor3 = color,
		BorderSizePixel = 0,
		Parent = frame,
	}, {
		Make("UIGradient", { Transparency = DIVIDER_FADE }),
	})
end

function Front.Build(parent: Instance, cardId: string): Frame
	local card = Catalog.Card(cardId)
	local rarity = Catalog.RarityOf(cardId)
	local tier = Catalog.TierOf(cardId)
	local color = rarity.Color
	local fonts = Theme.Fonts

	local top = Paint.Shade(color, 0.55)
	local bottom = Paint.Shade(rarity.Dark, 0.65)
	local frame, rim = Kit.Body(parent, top, bottom, Kit.Metal(color), rimSpeed(tier))

	local title = string.upper(rarity.Name)
	Kit.Text(frame, title, fonts.Display, UDim2.fromScale(0.5, 0.09), UDim2.fromScale(0.8, 0.065), Paint.Tint(color, 0.2), 14)
	art(frame, card.Icon, color, tier)
	divider(frame, color)
	Kit.Text(frame, card.Name, fonts.Display, UDim2.fromScale(0.5, 0.79), UDim2.fromScale(0.84, 0.085), Theme.Colors.Text, 20)
	local odds = Odds.Format(rarity.Chance)
	Kit.Text(frame, odds, fonts.Body, UDim2.fromScale(0.5, 0.885), UDim2.fromScale(0.6, 0.055), Theme.Colors.Muted, 12)

	if rarity.Effect ~= "None" then
		Kit.Shine(frame)
	end
	if rarity.Effect == "Rainbow" then
		Paint.Animate(frame, function(elapsed: number)
			rim.Color = Paint.Rainbow(elapsed * RAINBOW_SPEED)
		end)
	end
	return frame
end

return table.freeze(Front)
