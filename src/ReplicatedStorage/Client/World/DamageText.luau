--!strict
-- Damage numbers popping out of a monster: they slam in big, rise, drift sideways and fade.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Make = require(script.Parent.Parent.UI.Make)
local Motion = require(script.Parent.Parent.UI.Motion)
local Power = require(ReplicatedStorage.Shared.Domain.Power)
local Theme = require(ReplicatedStorage.Shared.Config.Theme)

local LIFE = 0.9

local DamageText = {}

local rng = Random.new()

-- `big` = the killing blow or a strong hit: larger and in the crit colour.
function DamageText.Pop(head: BasePart, amount: number, big: boolean)
	local start = Vector3.new(rng:NextNumber(-2.2, 2.2), rng:NextNumber(0, 2), rng:NextNumber(-0.5, 0.5))
	local gui: BillboardGui = Make("BillboardGui", {
		Adornee = head,
		Size = UDim2.fromOffset(if big then 180 else 120, if big then 64 else 44),
		StudsOffsetWorldSpace = start,
		AlwaysOnTop = true,
		LightInfluence = 0,
		Parent = head,
	})
	local label: TextLabel = Make("TextLabel", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = Power.Format(amount),
		TextColor3 = if big then Theme.Colors.Crit else Theme.Colors.Damage,
		TextScaled = true,
		Font = Theme.Fonts.Display,
		Parent = gui,
	})
	local stroke: UIStroke = Make("UIStroke", { Thickness = 3, Color = Theme.Colors.Ink, Parent = label })
	Motion.Pop(Make("UIScale", { Parent = label }), 2, 1, 0.25)

	local drift = Vector3.new(rng:NextNumber(-1.5, 1.5), 3.5, 0)
	Motion.Tween(gui, LIFE, { StudsOffsetWorldSpace = start + drift }, Enum.EasingStyle.Quad)
	task.delay(LIFE * 0.5, function()
		Motion.Tween(label, LIFE * 0.5, { TextTransparency = 1 })
		Motion.Tween(stroke, LIFE * 0.5, { Transparency = 1 })
	end)
	task.delay(LIFE, function()
		gui:Destroy()
	end)
end

return table.freeze(DamageText)
