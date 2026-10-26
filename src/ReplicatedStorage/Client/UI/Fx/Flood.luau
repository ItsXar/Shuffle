--!strict
--[[
	Colour flood for big pulls: the whole screen behind the cards washes into the rarity colour,
	strongest at the edges, and pulses. Drawn on the Dim layer (under buttons, cards and effects).
	Attach returns the function that fades it out and removes it (safe to call twice).
]]

local Make = require(script.Parent.Parent.Make)
local Paint = require(script.Parent.Parent.Paint)
local Root = require(script.Parent.Parent.Root)

local FADE_IN = 0.25
local FADE_OUT = 0.4
local PULSE_SPEED = 6
local WASH = 0.18

-- Each edge: anchor/position, size, and the gradient rotation pointing from the edge inwards.
local EDGES = {
	{ Anchor = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0), Size = UDim2.fromScale(1, 0.35), Rotation = 90 },
	{ Anchor = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.5, 1), Size = UDim2.fromScale(1, 0.35), Rotation = 270 },
	{ Anchor = Vector2.new(0, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.fromScale(0.3, 1), Rotation = 0 },
	{ Anchor = Vector2.new(1, 0.5), Position = UDim2.fromScale(1, 0.5), Size = UDim2.fromScale(0.3, 1), Rotation = 180 },
}

local Flood = {}

function Flood.Attach(color: Color3, strength: number): () -> ()
	local holder: Frame = Make("Frame", {
		Name = "Flood",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ZIndex = 5,
		Parent = Root.Layer("Dim"),
	})
	local wash: Frame = Make("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = color,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Parent = holder,
	})
	local gradients: { UIGradient } = {}
	for _, edge in EDGES do
		local gradient: UIGradient = Make("UIGradient", { Rotation = edge.Rotation, Transparency = NumberSequence.new(1) })
		Make("Frame", {
			AnchorPoint = edge.Anchor,
			Position = edge.Position,
			Size = edge.Size,
			BackgroundColor3 = color,
			BorderSizePixel = 0,
			Parent = holder,
		}, { gradient })
		table.insert(gradients, gradient)
	end

	local now = 0
	local releasedAt: number? = nil
	Paint.Animate(holder, function(elapsed: number)
		now = elapsed
		local level = math.min(elapsed / FADE_IN, 1)
		if releasedAt then
			local out = (elapsed - releasedAt) / FADE_OUT
			if out >= 1 then
				holder:Destroy()
				return
			end
			level *= 1 - out
		end
		local alpha = strength * level * (0.8 + 0.2 * math.sin(elapsed * PULSE_SPEED))
		local sequence = NumberSequence.new(1 - alpha, 1)
		for _, gradient in gradients do
			gradient.Transparency = sequence
		end
		wash.BackgroundTransparency = 1 - alpha * WASH
	end)

	return function()
		if releasedAt == nil then
			releasedAt = now
		end
	end
end

return table.freeze(Flood)
