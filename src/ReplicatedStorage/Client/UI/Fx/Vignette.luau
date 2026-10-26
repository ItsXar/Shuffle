--!strict
--[[
	Screen edges glowing in one colour and slowly pulsing, behind the cards. Attach returns the
	function that fades it out and removes it (safe to call twice).
]]

local Make = require(script.Parent.Parent.Make)
local Paint = require(script.Parent.Parent.Paint)
local Root = require(script.Parent.Parent.Root)

local DEPTH = 0.22
local PULSE_SPEED = 3
local FADE_IN = 0.3
local FADE_OUT = 0.45

-- Each edge: anchor/position, size, and the gradient rotation that points from the edge inwards.
local EDGES = {
	{ Anchor = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0), Size = UDim2.fromScale(1, DEPTH), Rotation = 90 },
	{ Anchor = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.5, 1), Size = UDim2.fromScale(1, DEPTH), Rotation = 270 },
	{ Anchor = Vector2.new(0, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.fromScale(DEPTH, 1), Rotation = 0 },
	{ Anchor = Vector2.new(1, 0.5), Position = UDim2.fromScale(1, 0.5), Size = UDim2.fromScale(DEPTH, 1), Rotation = 180 },
}

local Vignette = {}

function Vignette.Attach(color: Color3, strength: number): () -> ()
	local holder: Frame = Make("Frame", {
		Name = "Vignette",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ZIndex = 9,
		Parent = Root.Layer("Dim"),
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
		local alpha = strength * level * (0.75 + 0.25 * math.sin(elapsed * PULSE_SPEED))
		local sequence = NumberSequence.new(1 - alpha, 1)
		for _, gradient in gradients do
			gradient.Transparency = sequence
		end
	end)

	return function()
		if releasedAt == nil then
			releasedAt = now
		end
	end
end

return table.freeze(Vignette)
