--!strict
-- Full-screen colour flash (on top of everything) and blackout (behind the cards).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Make = require(script.Parent.Parent.Make)
local Motion = require(script.Parent.Parent.Motion)
local Root = require(script.Parent.Parent.Root)
local Theme = require(ReplicatedStorage.Shared.Config.Theme)

local RELEASE_SECONDS = 0.6

local Flash = {}

local function overlay(layer: Root.Layer, color: Color3, transparency: number): Frame
	return Make("Frame", {
		Name = "Flash",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = color,
		BackgroundTransparency = transparency,
		BorderSizePixel = 0,
		ZIndex = 10,
		Parent = Root.Layer(layer),
	})
end

-- Flashes the screen with `color` at `strength` (0..1), fading out over `seconds`.
function Flash.Play(color: Color3, strength: number, seconds: number)
	if strength <= 0 then
		return
	end
	local frame = overlay("Fx", color, 1 - strength)
	Motion.Tween(frame, seconds, { BackgroundTransparency = 1 }).Completed:Once(function()
		frame:Destroy()
	end)
end

-- Darkens the world behind the cards; call the returned function to lift it (safe to call twice).
function Flash.Dim(amount: number, seconds: number): () -> ()
	local frame = overlay("Dim", Theme.Colors.Ink, 1)
	Motion.Tween(frame, seconds, { BackgroundTransparency = 1 - amount })
	local released = false
	return function()
		if released then
			return
		end
		released = true
		Motion.Tween(frame, RELEASE_SECONDS, { BackgroundTransparency = 1 }).Completed:Once(function()
			frame:Destroy()
		end)
	end
end

return table.freeze(Flash)
