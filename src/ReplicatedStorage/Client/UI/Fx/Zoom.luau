--!strict
--[[
	Camera field-of-view punches: lean in while something charges, kick out when it hits, always
	settling back on the field of view the camera had before the first zoom.
]]

local Motion = require(script.Parent.Parent.Motion)

local Zoom = {}

local base: number? = nil

local function camera(): Camera?
	local current = workspace.CurrentCamera
	if current and not base then
		base = current.FieldOfView
	end
	return current
end

-- Eases to `offset` degrees away from the normal field of view (negative = closer).
function Zoom.To(offset: number, seconds: number, style: Enum.EasingStyle?, direction: Enum.EasingDirection?)
	local current = camera()
	if current and base then
		Motion.Tween(current, seconds, { FieldOfView = base + offset }, style, direction)
	end
end

-- Jumps `kick` degrees out, then springs back to normal.
function Zoom.Punch(kick: number, seconds: number)
	local current = camera()
	if current and base then
		current.FieldOfView = base + kick
		Motion.Tween(current, seconds, { FieldOfView = base }, Enum.EasingStyle.Back)
	end
end

function Zoom.Reset()
	Zoom.To(0, 0.3)
end

return table.freeze(Zoom)
