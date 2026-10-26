--!strict
--[[
	Big announcements on the Fx layer. Show slams the rarity name onto the screen
	("LEGENDARY" + card name and odds); Toast is a smaller line ("LUCKY ROLL x3").
	Both remove themselves; neither yields.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Fit = require(script.Parent.Parent.Fit)
local Make = require(script.Parent.Parent.Make)
local Motion = require(script.Parent.Parent.Motion)
local Odds = require(ReplicatedStorage.Shared.Domain.Odds)
local Paint = require(script.Parent.Parent.Paint)
local Rarities = require(ReplicatedStorage.Shared.Config.Rarities)
local Root = require(script.Parent.Parent.Root)
local Theme = require(ReplicatedStorage.Shared.Config.Theme)

local SLAM_FROM = 2.2
local RISE = 40

local Banner = {}

-- `props` is completed in place with the shared look and handed to Make.
local function text(parent: Instance, props: { [string]: any }, stroke: number): TextLabel
	props.AnchorPoint = Vector2.new(0.5, 0.5)
	props.BackgroundTransparency = 1
	props.TextScaled = true
	props.TextTransparency = 1
	props.Parent = parent
	return Make("TextLabel", props, {
		Make("UIStroke", { Thickness = stroke, Color = Theme.Colors.Ink, Transparency = 1 }),
	})
end

local function holder(position: UDim2, size: Vector2): (Frame, UIScale)
	local unit = Fit.Unit()
	local frame: Frame = Make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = position,
		Size = UDim2.fromOffset(size.X * unit, size.Y * unit),
		BackgroundTransparency = 1,
		Parent = Root.Layer("Fx"),
	})
	return frame, Make("UIScale", { Parent = frame })
end

local function fadeLabels(frame: Frame, transparency: number, seconds: number)
	for _, child in frame:GetDescendants() do
		if child:IsA("TextLabel") then
			Motion.Tween(child, seconds, { TextTransparency = transparency })
		elseif child:IsA("UIStroke") then
			Motion.Tween(child, seconds, { Transparency = transparency })
		end
	end
end

local function leave(frame: Frame, after: number)
	task.delay(after, function()
		fadeLabels(frame, 1, 0.35)
		Motion.Tween(frame, 0.35, { Position = frame.Position - UDim2.fromOffset(0, RISE) }).Completed:Once(function()
			frame:Destroy()
		end)
	end)
end

function Banner.Show(rarity: Rarities.Rarity, cardName: string, hold: number)
	local unit = Fit.Unit()
	local frame, scale = holder(UDim2.fromScale(0.5, 0.56), Vector2.new(560, 110))

	local title = text(frame, {
		Text = string.upper(rarity.Name),
		Font = Theme.Fonts.Display,
		TextColor3 = Color3.new(1, 1, 1),
		Position = UDim2.fromScale(0.5, 0.33),
		Size = UDim2.fromScale(1, 0.66),
	}, 3 * unit)
	local paint: UIGradient = Make("UIGradient", {
		Rotation = 90,
		Color = ColorSequence.new(Paint.Tint(rarity.Color, 0.45), rarity.Color),
		Parent = title,
	})
	if rarity.Effect == "Rainbow" then
		Paint.Animate(title, function(elapsed: number)
			paint.Color = Paint.Rainbow(elapsed * 0.4)
		end)
	end

	text(frame, {
		Text = `{cardName}  •  {Odds.Format(rarity.Chance)}`,
		Font = Theme.Fonts.Body,
		TextColor3 = Theme.Colors.Text,
		Position = UDim2.fromScale(0.5, 0.82),
		Size = UDim2.fromScale(0.7, 0.22),
	}, 2 * unit)

	scale.Scale = SLAM_FROM
	Motion.Tween(scale, 0.38, { Scale = 1 }, Enum.EasingStyle.Back)
	fadeLabels(frame, 0, 0.15)
	leave(frame, hold)
end

function Banner.Toast(message: string, color: Color3, hold: number)
	local unit = Fit.Unit()
	local frame, scale = holder(UDim2.fromScale(0.5, 0.5), Vector2.new(420, 42))
	text(frame, {
		Text = message,
		Font = Theme.Fonts.Display,
		TextColor3 = color,
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1, 1),
	}, 2.5 * unit)
	Motion.Pop(scale, 0.4, 1, 0.4)
	fadeLabels(frame, 0, 0.15)
	leave(frame, hold)
end

return table.freeze(Banner)
