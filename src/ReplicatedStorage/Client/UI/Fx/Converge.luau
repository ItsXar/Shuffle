--!strict
-- Light streaks rushing in from all around into one screen point (a card charging up).

local Fit = require(script.Parent.Parent.Fit)
local Make = require(script.Parent.Parent.Make)
local Motion = require(script.Parent.Parent.Motion)
local Paint = require(script.Parent.Parent.Paint)
local Root = require(script.Parent.Parent.Root)

local Converge = {}

function Converge.Play(at: Vector2, color: Color3, count: number, seconds: number)
	local rng = Random.new()
	local unit = Fit.Unit()
	local layer = Root.Layer("Fx")
	for _ = 1, count do
		local angle = rng:NextNumber(0, math.pi * 2)
		local distance = rng:NextNumber(380, 700) * unit
		local size = rng:NextNumber(5, 12) * unit
		local start = at + Vector2.new(math.cos(angle), math.sin(angle)) * distance
		local streak: Frame = Make("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromOffset(start.X, start.Y),
			Size = UDim2.fromOffset(size * 2.2, size * 0.6),
			Rotation = math.deg(angle),
			BackgroundColor3 = Paint.Tint(color, rng:NextNumber(0, 0.5)),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Parent = layer,
		}, {
			Make("UICorner", { CornerRadius = UDim.new(1, 0) }),
		})
		local delay = rng:NextNumber(0, seconds * 0.5)
		task.delay(delay, function()
			Motion.Tween(streak, 0.1, { BackgroundTransparency = 0 })
			local goal = UDim2.fromOffset(at.X, at.Y)
			local rush = Motion.Tween(streak, seconds - delay, { Position = goal }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			rush.Completed:Once(function()
				streak:Destroy()
			end)
		end)
	end
end

return table.freeze(Converge)
