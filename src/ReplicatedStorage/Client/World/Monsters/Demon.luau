--!strict
-- Void Demon: a floating dark spirit with horns, glowing eyes and beating wings. Front = -Z.

local Rig = require(script.Parent.Rig)

-- Swings around the wing's hinge (the rest CFrame), then moves out to the piece's place.
local function flap(side: number, offset: Vector3): (elapsed: number) -> CFrame
	return function(elapsed: number): CFrame
		return CFrame.Angles(0, side * math.sin(elapsed * 5) * 0.45, 0) * CFrame.new(offset)
	end
end

return function(rig: Rig.Rig, color: Color3, glow: Color3): BasePart
	local dark = color:Lerp(Color3.new(0, 0, 0), 0.5)
	local neon = { Material = Enum.Material.Neon }
	rig:Add("Body", "Ball", Vector3.new(4.6, 5.6, 4), color, CFrame.new(0, 4.6, 0))
	rig:Add("Belly", "Ball", Vector3.new(3, 3.4, 1), dark, CFrame.new(0, 4.2, -1.6))
	rig:Add("Core", "Ball", Vector3.new(1.3, 1.3, 0.6), glow, CFrame.new(0, 4.6, -2.05), neon)
	rig:Add("Tail", "Ball", Vector3.new(2.4, 2.6, 2.2), dark, CFrame.new(0, 1.7, 0.3))
	local head = rig:Add("Head", "Ball", Vector3.new(3.6, 3.4, 3.4), color, CFrame.new(0, 8.4, 0))
	for side = -1, 1, 2 do
		local eye = CFrame.new(side * 0.75, 8.6, -1.6) * CFrame.Angles(0, 0, side * -0.3)
		rig:Add("Eye", "Ball", Vector3.new(0.9, 0.5, 0.3), glow, eye, neon)
		local horn = CFrame.new(side * 1.2, 10.4, 0) * CFrame.Angles(0, math.pi / 2, side * 0.35)
		rig:Add("Horn", "Wedge", Vector3.new(0.6, 2.4, 1.2), dark, horn)
		rig:Add("Claw", "Ball", Vector3.new(1.2, 1.4, 1.2), dark, CFrame.new(side * 2.7, 3.6, -0.8))
		local wing = CFrame.new(side * 2, 6, 1.2) * CFrame.Angles(0, side * 0.5, side * 0.25)
		rig:Add("Wing", "Block", Vector3.new(5, 3.4, 0.25), dark, wing, { Motion = flap(side, Vector3.new(side * 2.4, 0.6, 0)) })
		rig:Add("WingEdge", "Block", Vector3.new(5, 0.3, 0.3), glow, wing, {
			Material = Enum.Material.Neon,
			Motion = flap(side, Vector3.new(side * 2.4, 2.25, 0)),
		})
	end
	return head
end
