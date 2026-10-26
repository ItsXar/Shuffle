--!strict
--[[
	Builds a monster out of plain parts and poses it every frame. Each piece has a rest offset from
	the monster's feet and an optional Motion (extra offset over time: flapping wings, wobbling
	eyes). Pose places every piece for a root CFrame and a per-axis scale, so the whole body can
	bob, squash on hits and grow when it spawns without Motor6Ds.
]]

export type Shape = "Ball" | "Block" | "Wedge" | "Cylinder"

export type Piece = {
	Part: BasePart,
	Rest: CFrame,
	Size: Vector3,
	Motion: ((elapsed: number) -> CFrame)?,
}

export type Options = {
	Material: Enum.Material?,
	Transparency: number?,
	Motion: ((elapsed: number) -> CFrame)?,
}

export type Rig = {
	Model: Model,
	Pieces: { Piece },
	Add: (self: Rig, name: string, shape: Shape, size: Vector3, color: Color3, rest: CFrame, options: Options?) -> BasePart,
	Pose: (self: Rig, root: CFrame, scale: Vector3, elapsed: number) -> (),
}

local Rig = {}

local function create(shape: Shape): BasePart
	if shape == "Wedge" then
		return Instance.new("WedgePart")
	end
	local part = Instance.new("Part")
	if shape == "Ball" then
		-- A sphere mesh (not Shape = Ball) so the ball can be squashed into ovals.
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Sphere
		mesh.Parent = part
	elseif shape == "Cylinder" then
		part.Shape = Enum.PartType.Cylinder
	end
	return part
end

function Rig.new(name: string): Rig
	local model = Instance.new("Model")
	model.Name = name
	local self = { Model = model, Pieces = {} } :: Rig

	function self.Add(rig: Rig, partName: string, shape: Shape, size: Vector3, color: Color3, rest: CFrame, options: Options?): BasePart
		local part = create(shape)
		part.Name = partName
		part.Size = size
		part.Color = color
		part.Material = if options and options.Material then options.Material else Enum.Material.SmoothPlastic
		part.Transparency = if options and options.Transparency then options.Transparency else 0
		part.Anchored = true
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.TopSurface = Enum.SurfaceType.Smooth
		part.BottomSurface = Enum.SurfaceType.Smooth
		part.Parent = rig.Model
		table.insert(rig.Pieces, { Part = part, Rest = rest, Size = size, Motion = options and options.Motion })
		return part
	end

	function self.Pose(rig: Rig, root: CFrame, scale: Vector3, elapsed: number)
		for _, piece in rig.Pieces do
			local rest = piece.Rest
			local motion = piece.Motion
			if motion then
				rest *= motion(elapsed)
			end
			local position = rest.Position * scale
			piece.Part.CFrame = root * CFrame.new(position) * rest.Rotation
			piece.Part.Size = piece.Size * scale
		end
	end

	return self
end

return table.freeze(Rig)
