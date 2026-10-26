--!strict
-- Colour helpers and per-frame animation tied to the life of an instance.

local RunService = game:GetService("RunService")

local Paint = {}

local BLACK = Color3.new(0, 0, 0)
local WHITE = Color3.new(1, 1, 1)
local RAINBOW_STEPS = 6

function Paint.Shade(color: Color3, amount: number): Color3
	return color:Lerp(BLACK, amount)
end

function Paint.Tint(color: Color3, amount: number): Color3
	return color:Lerp(WHITE, amount)
end

-- Full hue circle, rotated by `phase` (0..1). Animate the phase for a moving rainbow.
function Paint.Rainbow(phase: number): ColorSequence
	local points = table.create(RAINBOW_STEPS + 1)
	for step = 0, RAINBOW_STEPS do
		local at = step / RAINBOW_STEPS
		table.insert(points, ColorSequenceKeypoint.new(at, Color3.fromHSV((phase + at) % 1, 0.6, 1)))
	end
	return ColorSequence.new(points)
end

-- Calls `step(seconds since start)` every frame until `owner` is destroyed or removed.
function Paint.Animate(owner: Instance, step: (elapsed: number) -> ())
	local started = os.clock()
	local connection: RBXScriptConnection
	connection = RunService.RenderStepped:Connect(function()
		if owner.Parent == nil then
			connection:Disconnect()
			return
		end
		step(os.clock() - started)
	end)
end

return table.freeze(Paint)
