--!strict
--[[
	Screen shake driven by "trauma" (0..1): every Add raises it, it decays on its own, and the
	shake strength is trauma squared, so small hits stay subtle and big ones really kick.
	Moves the camera and every tracked gui (the card row), then puts everything back.
]]

local RunService = game:GetService("RunService")

local BIND_NAME = "ShuffleShake"
local DECAY = 1.5
local MAX_ANGLE = math.rad(2.5)
local MAX_PIXELS = 16
local FREQUENCY = 18

local Shake = {}

local trauma = 0
local clock = 0
local running = false
local tracked: { [GuiObject]: UDim2 } = {}

local function noise(seed: number): number
	return math.noise(clock * FREQUENCY, seed) * 2
end

local function stop()
	running = false
	RunService:UnbindFromRenderStep(BIND_NAME)
	for gui, base in tracked do
		gui.Position = base
	end
end

local function step(deltaTime: number)
	clock += deltaTime
	trauma = math.max(trauma - DECAY * deltaTime, 0)
	if trauma == 0 then
		stop()
		return
	end

	local power = trauma * trauma
	local x, y, roll = noise(1.7), noise(5.3), noise(9.1)
	local camera = workspace.CurrentCamera
	if camera then
		camera.CFrame *= CFrame.Angles(x * MAX_ANGLE * power, y * MAX_ANGLE * power, roll * MAX_ANGLE * power)
	end
	for gui, base in tracked do
		gui.Position = base + UDim2.fromOffset(x * MAX_PIXELS * power, y * MAX_PIXELS * power)
	end
end

function Shake.Add(amount: number)
	if amount <= 0 then
		return
	end
	trauma = math.min(trauma + amount, 1)
	if not running then
		running = true
		RunService:BindToRenderStep(BIND_NAME, Enum.RenderPriority.Camera.Value + 1, step)
	end
end

-- The gui shakes along with the camera. Its Position must not be animated by anyone else.
function Shake.Track(gui: GuiObject)
	tracked[gui] = gui.Position
	gui.Destroying:Once(function()
		tracked[gui] = nil
	end)
end

return table.freeze(Shake)
