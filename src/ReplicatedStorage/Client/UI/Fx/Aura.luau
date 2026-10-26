--!strict
--[[
	Glowing motes that keep rising from behind a gui (the winning card) while attached. Drawn on the
	Dim layer, so they float behind the cards but above the darkened world. Attach returns the
	function that stops new motes; the ones in flight finish their life.
]]

local RunService = game:GetService("RunService")

local Fit = require(script.Parent.Parent.Fit)
local Make = require(script.Parent.Parent.Make)
local Paint = require(script.Parent.Parent.Paint)
local Root = require(script.Parent.Parent.Root)

type Mote = {
	Frame: Frame,
	Position: Vector2,
	Speed: number,
	Sway: number,
	Age: number,
	Life: number,
}

local Aura = {}

local function spawnMote(rng: Random, gui: GuiObject, color: Color3, unit: number): Mote
	local center = gui.AbsolutePosition + gui.AbsoluteSize / 2
	local spread = gui.AbsoluteSize * 0.6
	local size = rng:NextNumber(4, 10) * unit
	local start = center + Vector2.new(rng:NextNumber(-1, 1) * spread.X, rng:NextNumber(-0.2, 1) * spread.Y)
	local frame: Frame = Make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(start.X, start.Y),
		Size = UDim2.fromOffset(size, size),
		BackgroundColor3 = Paint.Tint(color, rng:NextNumber(0, 0.7)),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 11,
		Parent = Root.Layer("Dim"),
	}, {
		Make("UICorner", { CornerRadius = UDim.new(1, 0) }),
	})
	return {
		Frame = frame,
		Position = start,
		Speed = rng:NextNumber(60, 170) * unit,
		Sway = rng:NextNumber(0, math.pi * 2),
		Age = 0,
		Life = rng:NextNumber(0.9, 1.8),
	}
end

-- `rate` = motes per second.
function Aura.Attach(gui: GuiObject, color: Color3, rate: number): () -> ()
	local rng = Random.new()
	local unit = Fit.Unit()
	local motes: { Mote } = {}
	local spawning = true
	local due = 0

	local connection: RBXScriptConnection
	connection = RunService.RenderStepped:Connect(function(deltaTime: number)
		if spawning and gui.Parent then
			due += rate * deltaTime
			while due >= 1 do
				due -= 1
				table.insert(motes, spawnMote(rng, gui, color, unit))
			end
		end

		for index = #motes, 1, -1 do
			local mote = motes[index]
			mote.Age += deltaTime
			if mote.Age >= mote.Life then
				mote.Frame:Destroy()
				table.remove(motes, index)
			else
				local progress = mote.Age / mote.Life
				mote.Position -= Vector2.new(0, mote.Speed * deltaTime)
				local x = mote.Position.X + math.sin(mote.Sway + mote.Age * 3) * 10 * unit
				mote.Frame.Position = UDim2.fromOffset(x, mote.Position.Y)
				mote.Frame.BackgroundTransparency = 0.15 + 0.85 * math.abs(progress * 2 - 1) ^ 2
			end
		end

		if not spawning and #motes == 0 then
			connection:Disconnect()
		end
	end)

	return function()
		spawning = false
	end
end

return table.freeze(Aura)
