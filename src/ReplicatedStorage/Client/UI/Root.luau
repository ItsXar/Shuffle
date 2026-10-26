--!strict
--[[
	Owns the ScreenGuis. Each layer is created once, on first use, with its DisplayOrder from
	Config/Theme > Layers: Hud (bottom) < Dim < Stage (cards) < Fx (flashes, sparks, banners).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Make = require(script.Parent.Make)
local Theme = require(ReplicatedStorage.Shared.Config.Theme)

export type Layer = "Hud" | "Dim" | "Stage" | "Fx"

local Root = {}

local layers: { [string]: ScreenGui } = {}

function Root.Layer(name: Layer): ScreenGui
	local existing = layers[name]
	if existing then
		return existing
	end
	local gui: ScreenGui = Make("ScreenGui", {
		Name = name,
		DisplayOrder = Theme.Layers[name],
		IgnoreGuiInset = true,
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = Players.LocalPlayer:WaitForChild("PlayerGui"),
	})
	layers[name] = gui
	return gui
end

return table.freeze(Root)
