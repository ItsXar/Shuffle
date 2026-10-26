--!strict
-- Confetti raining over the whole screen in the rarity colour, its light tint, white and gold.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Fit = require(script.Parent.Parent.Fit)
local Make = require(script.Parent.Parent.Make)
local Paint = require(script.Parent.Parent.Paint)
local Root = require(script.Parent.Parent.Root)
local Theme = require(ReplicatedStorage.Shared.Config.Theme)

type Piece = {
	Frame: Frame,
	X: number,
	Y: number,
	Fall: number,
	Sway: number,
	Spin: number,
	Age: number,
}

local Confetti = {}

function Confetti.Play(color: Color3, count: number)
	local camera = workspace.CurrentCamera
	local screen = if camera then camera.ViewportSize else Vector2.new(1920, 1080)
	local rng = Random.new()
	local unit = Fit.Unit()
	local palette = { color, Paint.Tint(color, 0.5), Color3.new(1, 1, 1), Theme.Colors.Gold }
	local layer = Root.Layer("Fx")

	local pieces: { Piece } = {}
	for index = 1, count do
		local width = rng:NextNumber(8, 14) * unit
		local x, y = rng:NextNumber(0, screen.X), rng:NextNumber(-400, -20) * unit
		local frame: Frame = Make("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromOffset(x, y),
			Size = UDim2.fromOffset(width, width * 0.55),
			BackgroundColor3 = palette[(index - 1) % #palette + 1],
			BorderSizePixel = 0,
			Parent = layer,
		})
		table.insert(pieces, {
			Frame = frame,
			X = x,
			Y = y,
			Fall = rng:NextNumber(520, 900) * unit,
			Sway = rng:NextNumber(0, 6),
			Spin = rng:NextNumber(-400, 400),
			Age = 0,
		})
	end

	local connection: RBXScriptConnection
	connection = RunService.RenderStepped:Connect(function(deltaTime: number)
		for index = #pieces, 1, -1 do
			local piece = pieces[index]
			piece.Age += deltaTime
			piece.Y += piece.Fall * deltaTime
			if piece.Y > screen.Y + 40 then
				piece.Frame:Destroy()
				table.remove(pieces, index)
			else
				piece.Frame.Position = UDim2.fromOffset(piece.X + math.sin(piece.Sway + piece.Age * 4) * 30 * unit, piece.Y)
				piece.Frame.Rotation += piece.Spin * deltaTime
			end
		end
		if #pieces == 0 then
			connection:Disconnect()
		end
	end)
end

return table.freeze(Confetti)
