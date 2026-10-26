--!strict
-- Where this player's monster stands: on the ground a few studs in front of the character,
-- facing it. Waits a moment for the character to appear; falls back to the world origin.

local Players = game:GetService("Players")

local DISTANCE = 18
local RAY_HEIGHT = 40
local CHARACTER_TIMEOUT = 5

local Arena = {}

-- Yields up to CHARACTER_TIMEOUT seconds while the character loads.
function Arena.SpawnCFrame(): CFrame
	local player = Players.LocalPlayer
	local character = player.Character or player.CharacterAdded:Wait()
	local root = character:WaitForChild("HumanoidRootPart", CHARACTER_TIMEOUT) :: BasePart?
	if not root then
		return CFrame.new(0, 0, -DISTANCE)
	end
	local look = root.CFrame.LookVector * Vector3.new(1, 0, 1)
	look = if look.Magnitude > 0.01 then look.Unit else Vector3.new(0, 0, -1)
	local spot = root.Position + look * DISTANCE

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character }
	local hit = workspace:Raycast(spot + Vector3.new(0, RAY_HEIGHT, 0), Vector3.new(0, -RAY_HEIGHT * 3, 0), params)
	local ground = if hit then hit.Position else spot - Vector3.new(0, 3, 0)
	local facing = Vector3.new(root.Position.X, ground.Y, root.Position.Z)
	return CFrame.lookAt(ground, facing)
end

return table.freeze(Arena)
