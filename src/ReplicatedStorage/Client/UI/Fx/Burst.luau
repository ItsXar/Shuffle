--!strict
--[[
	Particle explosion on the full-screen Fx layer: squares, dots and stars in shades of one colour
	fly out from a screen point, arc down under gravity, spin and fade.
]]

local RunService = game:GetService("RunService")

local Fit = require(script.Parent.Parent.Fit)
local Make = require(script.Parent.Parent.Make)
local Paint = require(script.Parent.Parent.Paint)
local Root = require(script.Parent.Parent.Root)

local MAX_PARTICLES = 180
local GRAVITY = 1400
local DRAG = 1.6
local LIFT = 260
local STAR = "✦"

type Particle = {
	Gui: GuiObject,
	Fade: (alpha: number) -> (),
	Position: Vector2,
	Velocity: Vector2,
	Spin: number,
	Age: number,
	Life: number,
}

local Burst = {}

local function shape(rng: Random, color: Color3, size: number): (GuiObject, (alpha: number) -> ())
	local roll = rng:NextNumber()
	if roll < 0.3 then
		local star: TextLabel = Make("TextLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromOffset(size * 2.2, size * 2.2),
			BackgroundTransparency = 1,
			Text = STAR,
			TextColor3 = color,
			TextScaled = true,
		})
		return star, function(alpha: number)
			star.TextTransparency = alpha
		end
	end

	local piece: Frame = Make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(size, if roll < 0.65 then size else size * 0.45),
		BackgroundColor3 = color,
		BorderSizePixel = 0,
	})
	if roll < 0.65 then
		Make("UICorner", { CornerRadius = UDim.new(1, 0), Parent = piece })
	end
	return piece, function(alpha: number)
		piece.BackgroundTransparency = alpha
	end
end

local function spawnParticle(rng: Random, at: Vector2, color: Color3, power: number, unit: number, layer: Instance): Particle
	local angle = rng:NextNumber(0, math.pi * 2)
	local speed = rng:NextNumber(240, 820) * unit * power
	local gui, fade = shape(rng, Paint.Tint(color, rng:NextNumber(0, 0.6)), rng:NextNumber(6, 15) * unit)
	gui.Position = UDim2.fromOffset(at.X, at.Y)
	gui.Rotation = rng:NextNumber(0, 360)
	gui.Parent = layer
	return {
		Gui = gui,
		Fade = fade,
		Position = at,
		Velocity = Vector2.new(math.cos(angle), math.sin(angle)) * speed - Vector2.new(0, LIFT * unit),
		Spin = rng:NextNumber(-540, 540),
		Age = 0,
		Life = rng:NextNumber(0.6, 1.3),
	}
end

-- Bursts `count` particles from screen point `at`. `power` scales their speed (default 1).
function Burst.Play(at: Vector2, color: Color3, count: number, power: number?)
	if count <= 0 then
		return
	end
	local rng = Random.new()
	local unit = Fit.Unit()
	local layer = Root.Layer("Fx")
	local particles: { Particle } = {}
	for _ = 1, math.min(count, MAX_PARTICLES) do
		table.insert(particles, spawnParticle(rng, at, color, power or 1, unit, layer))
	end

	local connection: RBXScriptConnection
	connection = RunService.RenderStepped:Connect(function(deltaTime: number)
		local alive = 0
		for _, particle in particles do
			if particle.Age < particle.Life then
				particle.Age += deltaTime
				particle.Velocity = particle.Velocity * (1 - DRAG * deltaTime) + Vector2.new(0, GRAVITY * unit * deltaTime)
				particle.Position += particle.Velocity * deltaTime
				particle.Gui.Position = UDim2.fromOffset(particle.Position.X, particle.Position.Y)
				particle.Gui.Rotation += particle.Spin * deltaTime
				local progress = particle.Age / particle.Life
				particle.Fade(progress * progress)
				if particle.Age >= particle.Life then
					particle.Gui:Destroy()
				else
					alive += 1
				end
			end
		end
		if alive == 0 then
			connection:Disconnect()
		end
	end)
end

return table.freeze(Burst)
