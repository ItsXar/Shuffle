--!strict
--[[
	Makes UI resolution independent. A canvas is built at a fixed design size (Config/Theme) and
	Fit keeps one UIScale on it so it fills its share of the screen on phones and monitors alike.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Make = require(script.Parent.Make)
local Theme = require(ReplicatedStorage.Shared.Config.Theme)

local REFERENCE_HEIGHT = 900
local MIN_UNIT = 0.55
local SIDE_MARGIN = 0.96

local Fit = {}

local function viewport(): Vector2
	local camera = workspace.CurrentCamera
	return if camera then camera.ViewportSize else Vector2.new(1280, 720)
end

-- Size multiplier for things drawn straight on a full-screen layer (sparks, banners).
function Fit.Unit(): number
	return math.clamp(viewport().Y / REFERENCE_HEIGHT, MIN_UNIT, Theme.MaxScale)
end

-- Scales `canvas` (sized `design` pixels) to fit the screen width and `heightShare` of its height.
function Fit.Attach(canvas: GuiObject, design: Vector2, heightShare: number): UIScale
	local scale: UIScale = Make("UIScale", { Parent = canvas })
	local function update()
		local size = viewport()
		scale.Scale = math.min(size.X * SIDE_MARGIN / design.X, size.Y * heightShare / design.Y, Theme.MaxScale)
	end
	update()

	local camera = workspace.CurrentCamera
	if camera then
		local connection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(update)
		canvas.Destroying:Once(function()
			connection:Disconnect()
		end)
	end
	return scale
end

return table.freeze(Fit)
