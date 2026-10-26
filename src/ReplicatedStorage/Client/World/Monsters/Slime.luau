--!strict
-- Gloop: a big wobbly jelly ball with a glowing core, googly eyes and a grin. Front = -Z.

local Rig = require(script.Parent.Rig)

local function wobble(speed: number, amount: number): (elapsed: number) -> CFrame
	return function(elapsed: number): CFrame
		return CFrame.new(0, math.sin(elapsed * speed) * amount, 0)
	end
end

return function(rig: Rig.Rig, color: Color3, glow: Color3): BasePart
	local white = Color3.new(1, 1, 1)
	local black = Color3.fromRGB(20, 20, 26)
	local jelly = { Transparency = 0.12, Material = Enum.Material.Glass }
	rig:Add("Body", "Ball", Vector3.new(7.5, 6.4, 7.5), color, CFrame.new(0, 3.2, 0), jelly)
	rig:Add("Core", "Ball", Vector3.new(4, 3.4, 4), glow, CFrame.new(0, 3, 0), { Material = Enum.Material.Neon, Transparency = 0.35 })
	rig:Add("Shine", "Ball", Vector3.new(1.6, 1, 1.2), white, CFrame.new(-1.9, 5.3, -1.9), { Transparency = 0.35 })
	for side = -1, 1, 2 do
		rig:Add("Eye", "Ball", Vector3.new(1.6, 1.8, 1.2), white, CFrame.new(side * 1.25, 4.2, -3.1))
		local pupil = { Motion = wobble(3 + side, 0.12) }
		rig:Add("Pupil", "Ball", Vector3.new(0.75, 0.9, 0.6), black, CFrame.new(side * 1.2, 4.1, -3.65), pupil)
	end
	rig:Add("Mouth", "Ball", Vector3.new(2.2, 0.7, 0.6), black, CFrame.new(0, 2.7, -3.55))
	rig:Add("Tooth", "Block", Vector3.new(0.35, 0.35, 0.2), white, CFrame.new(0.45, 2.85, -3.82))
	for index = 1, 3 do
		local angle = index * 2.1
		rig:Add("Blob", "Ball", Vector3.new(1.2, 1, 1.2), color, CFrame.new(math.cos(angle) * 3.3, 0.5, math.sin(angle) * 3.3), {
			Transparency = 0.2,
			Material = Enum.Material.Glass,
			Motion = wobble(2 + index, 0.2),
		})
	end
	return rig.Model:FindFirstChild("Body") :: BasePart
end
