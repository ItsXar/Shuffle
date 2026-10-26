--!strict
--[[
	Owns the Hud (the deck bar area and the buttons at the bottom). Built on first use, so every
	controller can reach it from Start without caring who started first; each controller fills in
	the Hud actions it handles.
]]

local Hud = require(script.Parent.Parent.UI.Screens.Hud)

local HudController = {}

local hud: Hud.Hud? = nil
local building = false

function HudController.Get(): Hud.Hud
	while building do
		task.wait()
	end
	local existing = hud
	if existing then
		return existing
	end
	building = true
	local created = Hud.new()
	hud = created
	building = false
	return created
end

return HudController
