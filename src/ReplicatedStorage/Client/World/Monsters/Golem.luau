--!strict
-- Stone Golem: chunky slate blocks held together by glowing magma cracks. Front = -Z.

local Rig = require(script.Parent.Rig)

local function swing(side: number): (elapsed: number) -> CFrame
	return function(elapsed: number): CFrame
		return CFrame.Angles(math.sin(elapsed * 1.6 + side) * 0.12, 0, 0)
	end
end

return function(rig: Rig.Rig, color: Color3, glow: Color3): BasePart
	local dark = color:Lerp(Color3.new(0, 0, 0), 0.35)
	local neon = { Material = Enum.Material.Neon }
	local stone = { Material = Enum.Material.Slate }
	for side = -1, 1, 2 do
		rig:Add("Leg", "Block", Vector3.new(1.9, 2.6, 2), dark, CFrame.new(side * 1.3, 1.3, 0), stone)
		rig:Add("Arm", "Block", Vector3.new(1.8, 4.6, 1.9), color, CFrame.new(side * 3.6, 4.6, 0) * CFrame.Angles(0, 0, side * 0.12), {
			Material = Enum.Material.Slate,
			Motion = swing(side),
		})
		local fist = { Material = Enum.Material.Slate, Motion = swing(side) }
		rig:Add("Fist", "Block", Vector3.new(2.4, 2, 2.4), dark, CFrame.new(side * 3.9, 2.1, 0), fist)
		local shoulder = CFrame.new(side * 3.3, 7, 0) * CFrame.Angles(0, 0, side * 0.3)
		rig:Add("Shoulder", "Block", Vector3.new(2.2, 1.6, 2.4), dark, shoulder, stone)
		rig:Add("Eye", "Block", Vector3.new(0.6, 0.35, 0.2), glow, CFrame.new(side * 0.6, 8.5, -1.32), neon)
	end
	rig:Add("Torso", "Block", Vector3.new(5, 4.8, 3.2), color, CFrame.new(0, 5, 0), stone)
	rig:Add("Belly", "Block", Vector3.new(4, 1.4, 3.4), dark, CFrame.new(0, 2.9, 0), stone)
	rig:Add("Crack", "Block", Vector3.new(0.3, 3, 0.2), glow, CFrame.new(0.3, 5.2, -1.62) * CFrame.Angles(0, 0, 0.4), neon)
	rig:Add("Crack", "Block", Vector3.new(0.25, 1.6, 0.2), glow, CFrame.new(-1.2, 5.8, -1.62) * CFrame.Angles(0, 0, -0.6), neon)
	rig:Add("Core", "Ball", Vector3.new(1.2, 1.2, 0.4), glow, CFrame.new(0.6, 4.6, -1.6), neon)
	local head = rig:Add("Head", "Block", Vector3.new(2.8, 2.4, 2.6), color, CFrame.new(0, 8.6, 0), stone)
	rig:Add("Brow", "Block", Vector3.new(2.9, 0.5, 0.6), dark, CFrame.new(0, 9.1, -1.2), stone)
	return head
end
