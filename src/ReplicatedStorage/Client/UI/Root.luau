--!strict
--[[
	Owns the ScreenGuis. Each layer is created once, on first use, with its DisplayOrder from
	Config/Theme > Layers: Dim (blackout, flood) < Hud < Stage (cards) < Fx (flashes, sparks,
	banners) < Menu (backpack).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Make = require(script.Parent.Make)
local Theme = require(ReplicatedStorage.Shared.Config.Theme)

export type Layer = "Hud" | "Dim" | "Stage" | "Fx" | "Menu"

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
