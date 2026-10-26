--!strict
--[[
	A monster in the world, seen only by this player. Spawn builds it (Slime, Golem or Demon, see
	Config/Battle) standing on the ground at a CFrame and grows it in; it then breathes and bobs.
	Hit flashes it white, knocks it back and squashes it; Die bursts it into falling pieces and
	sparks. Head is where the health bar and damage numbers sit.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Battle = require(ReplicatedStorage.Shared.Config.Battle)
local Rig = require(script.Rig)

local BUILDERS: { [string]: (rig: Rig.Rig, color: Color3, glow: Color3) -> BasePart } = {
	Slime = require(script.Slime),
	Golem = require(script.Golem),
	Demon = require(script.Demon),
}

local GROW_SECONDS = 0.5
local KNOCK_DECAY = 6
local DEATH_SECONDS = 1.4
local FLOATS = { Demon = 1.2 }

export type Monster = {
	Model: Model,
	Head: BasePart,
	Hit: (self: Monster, strength: number) -> (),
	Die: (self: Monster) -> (),
	Destroy: (self: Monster) -> (),
}

local Monsters = {}

local function backOut(t: number): number
	local c = 1.70158
	return 1 + (c + 1) * (t - 1) ^ 3 + c * (t - 1) ^ 2
end

local function sparks(at: Vector3, color: Color3, count: number)
	local holder = Instance.new("Part")
	holder.Anchored = true
	holder.CanCollide = false
	holder.CanQuery = false
	holder.Transparency = 1
	holder.Size = Vector3.one
	holder.Position = at
	local emitter = Instance.new("ParticleEmitter")
	emitter.Color = ColorSequence.new(color)
	emitter.LightEmission = 1
	emitter.Size = NumberSequence.new(0.6, 0)
	emitter.Speed = NumberRange.new(18, 40)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Lifetime = NumberRange.new(0.5, 1.1)
	emitter.Drag = 3
	emitter.Enabled = false
	emitter.Parent = holder
	holder.Parent = workspace
	emitter:Emit(count)
	task.delay(1.5, function()
		holder:Destroy()
	end)
end

function Monsters.Spawn(kind: Battle.Monster, at: CFrame): Monster
	local rig = Rig.new(kind.Name)
	local head = BUILDERS[kind.Model](rig, kind.Color, kind.Glow)
	local highlight = Instance.new("Highlight")
	highlight.FillColor = Color3.new(1, 1, 1)
	highlight.FillTransparency = 1
	highlight.OutlineColor = Color3.fromRGB(10, 8, 20)
	highlight.OutlineTransparency = 0.4
	highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	highlight.Parent = rig.Model

	local float = FLOATS[kind.Model] or 0
	local born = os.clock()
	local knock = 0
	local alive = true
	rig:Pose(at, Vector3.one * 0.05, 0)
	rig.Model.Parent = workspace
	sparks(at.Position + Vector3.new(0, 2, 0), kind.Glow, 30)

	local connection = RunService.RenderStepped:Connect(function(deltaTime: number)
		local elapsed = os.clock() - born
		knock = math.max(knock - KNOCK_DECAY * deltaTime, 0)
		highlight.FillTransparency = 1 - knock * 0.8
		local grow = if elapsed < GROW_SECONDS then backOut(elapsed / GROW_SECONDS) else 1
		local breath = math.sin(elapsed * 2.4) * 0.04
		local squash = knock * 0.18
		local scale = Vector3.new(1 + breath + squash, 1 - breath - squash, 1 + breath + squash) * math.max(grow, 0.05)
		local bob = float + math.sin(elapsed * 2) * (0.15 + float * 0.3)
		local root = at * CFrame.new(0, bob, knock * 0.8) * CFrame.Angles(-knock * 0.25, math.sin(elapsed * 0.8) * 0.06, 0)
		rig:Pose(root, scale, elapsed)
	end)

	local self = { Model = rig.Model, Head = head } :: Monster

	function self.Hit(_: Monster, strength: number)
		if alive then
			knock = math.min(knock + strength, 1)
		end
	end

	function self.Die(monster: Monster)
		if not alive then
			return
		end
		alive = false
		connection:Disconnect()
		highlight.FillTransparency = 0
		sparks(head.Position, kind.Glow, 80)
		sparks(head.Position, Color3.new(1, 1, 1), 40)
		for _, piece in rig.Pieces do
			local part = piece.Part
			part.Anchored = false
			part.CanCollide = true
			local away = (part.Position - at.Position) * Vector3.new(1, 0, 1)
			local direction = if away.Magnitude > 0.01 then away.Unit else Vector3.zero
			part.AssemblyLinearVelocity = direction * math.random(14, 26) + Vector3.new(0, math.random(18, 34), 0)
			part.AssemblyAngularVelocity = Vector3.new(math.random(-8, 8), math.random(-8, 8), math.random(-8, 8))
		end
		task.delay(0.25, function()
			highlight.FillTransparency = 1
		end)
		task.delay(DEATH_SECONDS, function()
			monster:Destroy()
		end)
	end

	function self.Destroy(_: Monster)
		alive = false
		if connection.Connected then
			connection:Disconnect()
		end
		rig.Model:Destroy()
	end

	return self
end

return table.freeze(Monsters)
