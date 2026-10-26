--!strict
--[[
	The face-down side: bright violet, a faint diamond lattice, a soft glow and a gold "?".
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Kit = require(script.Parent.Kit)
local Make = require(script.Parent.Parent.Parent.Make)
local Paint = require(script.Parent.Parent.Parent.Paint)
local Theme = require(ReplicatedStorage.Shared.Config.Theme)

local LATTICE_ROWS = 6
local LATTICE_COLUMNS = 4
local LATTICE_SIZE = 7

local Back = {}

local function lattice(frame: Frame)
	for row = 0, LATTICE_ROWS - 1 do
		for column = 0, LATTICE_COLUMNS - 1 do
			local x = (column + 0.5 + (row % 2) * 0.5) / (LATTICE_COLUMNS + 0.5)
			local y = (row + 0.5) / LATTICE_ROWS
			Make("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.07 + x * 0.86, 0.06 + y * 0.88),
				Size = UDim2.fromOffset(LATTICE_SIZE, LATTICE_SIZE),
				Rotation = 45,
				BackgroundColor3 = Color3.new(1, 1, 1),
				BackgroundTransparency = 0.82,
				BorderSizePixel = 0,
				Parent = frame,
			})
		end
	end
end

function Back.Build(parent: Instance): Kit.Face
	local colors = Theme.Colors
	local paint = ColorSequence.new(colors.BackTop, colors.BackBottom)
	local frame = Kit.Body(parent, paint, Paint.Shade(colors.BackBottom, 0.5), 0.55)
	lattice(frame)
	Kit.Orb(frame, UDim2.fromScale(0.5, 0.5), 0.8, colors.BackGlow, { 0.86, 0.82, 0.78 })
	local mark = UDim2.fromScale(0.5, 0.5)
	Kit.Text(frame, "?", mark, UDim2.fromScale(0.5, 0.3), 74, colors.Gold, 3, Paint.Shade(colors.BackBottom, 0.6))
	return { Frame = frame, Stars = nil }
end

return table.freeze(Back)
