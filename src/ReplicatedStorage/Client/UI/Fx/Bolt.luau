--!strict
--[[
	A glowing shot flying across the screen from a point to a moving target (e.g. a monster's head
	seen through the camera), on a slight arc, leaving a short trail of fading dots. Calls onHit
	where it lands.
]]

local RunService = game:GetService("RunService")

local Fit = require(script.Parent.Parent.Fit)
local Make = require(script.Parent.Parent.Make)
local Motion = require(script.Parent.Parent.Motion)
local Paint = require(script.Parent.Parent.Paint)
local Root = require(script.Parent.Parent.Root)

local ARC = 120
local TRAIL_EVERY = 0.012

local Bolt = {}

local function dot(layer: Instance, at: Vector2, size: number, color: Color3, transparency: number): Frame
	return Make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(at.X, at.Y),
		Size = UDim2.fromOffset(size, size),
		BackgroundColor3 = color,
		BackgroundTransparency = transparency,
		BorderSizePixel = 0,
		Parent = layer,
	}, {
		Make("UICorner", { CornerRadius = UDim.new(1, 0) }),
	})
end

function Bolt.Fly(from: Vector2, target: () -> Vector2, color: Color3, seconds: number, onHit: (at: Vector2) -> ())
	local layer = Root.Layer("Fx")
	local unit = Fit.Unit()
	local glow = dot(layer, from, 34 * unit, color, 0.55)
	local core = dot(layer, from, 16 * unit, Paint.Tint(color, 0.6), 0)
	local side = if math.random() < 0.5 then -1 else 1
	local elapsed, sinceTrail = 0, 0

	local connection: RBXScriptConnection
	connection = RunService.RenderStepped:Connect(function(deltaTime: number)
		elapsed += deltaTime
		sinceTrail += deltaTime
		local t = math.min(elapsed / seconds, 1)
		local to = target()
		local eased = t * t
		local straight = from:Lerp(to, eased)
		local delta = to - from
		local normal = if delta.Magnitude > 1 then Vector2.new(-delta.Y, delta.X).Unit else Vector2.zero
		local at = straight + normal * side * math.sin(t * math.pi) * ARC * unit
		glow.Position = UDim2.fromOffset(at.X, at.Y)
		core.Position = glow.Position
		if sinceTrail >= TRAIL_EVERY then
			sinceTrail = 0
			local ghost = dot(layer, at, 12 * unit, color, 0.3)
			Motion.Tween(ghost, 0.2, { BackgroundTransparency = 1, Size = UDim2.fromOffset(2, 2) }).Completed:Once(function()
				ghost:Destroy()
			end)
		end
		if t >= 1 then
			connection:Disconnect()
			glow:Destroy()
			core:Destroy()
			onHit(at)
		end
	end)
end

return table.freeze(Bolt)
