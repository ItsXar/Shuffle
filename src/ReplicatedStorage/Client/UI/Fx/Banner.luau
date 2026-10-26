--!strict
--[[
	Big announcements on the Fx layer. Show sweeps a rarity-coloured band across the screen and
	slams the rarity name onto it, card name and odds below; it returns the function that takes it
	away. Toast is a single line that leaves on its own ("LUCKY ROLL x3").
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

local SLAM_FROM = 3
local LEAVE = 0.3
local RISE = 30

local BAND_FADE = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 1),
	NumberSequenceKeypoint.new(0.2, 0.15),
	NumberSequenceKeypoint.new(0.8, 0.15),
	NumberSequenceKeypoint.new(1, 1),
})

local Banner = {}

-- `props` is completed in place with the shared look and handed to Make.
local function text(parent: Instance, props: { [string]: any }, maxSize: number, stroke: number): TextLabel
	props.AnchorPoint = props.AnchorPoint or Vector2.new(0.5, 0.5)
	props.BackgroundTransparency = 1
	props.TextScaled = true
	props.TextTransparency = 1
	props.ZIndex = 3
	props.Parent = parent
	return Make("TextLabel", props, {
		Make("UITextSizeConstraint", { MaxTextSize = maxSize }),
		Make("UIStroke", { Thickness = stroke, Color = Theme.Colors.Ink, Transparency = 1 }),
	})
end

local function holder(position: UDim2, size: Vector2): Frame
	local unit = Fit.Unit()
	return Make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = position,
		Size = UDim2.fromOffset(size.X * unit, size.Y * unit),
		BackgroundTransparency = 1,
		ZIndex = 30,
		Parent = Root.Layer("Fx"),
	})
end

local function fade(frame: Frame, transparency: number, seconds: number)
	for _, child in frame:GetDescendants() do
		if child:IsA("TextLabel") then
			Motion.Tween(child, seconds, { TextTransparency = transparency })
		elseif child:IsA("UIStroke") then
			Motion.Tween(child, seconds, { Transparency = transparency })
		end
	end
end

local function leave(frame: Frame)
	fade(frame, 1, LEAVE)
	for _, child in frame:GetChildren() do
		if child:IsA("Frame") then
			Motion.Tween(child, LEAVE, { BackgroundTransparency = 1 })
		end
	end
	local goal = frame.Position - UDim2.fromOffset(0, RISE)
	Motion.Tween(frame, LEAVE, { Position = goal }).Completed:Once(function()
		frame:Destroy()
	end)
end

function Banner.Show(rarity: Rarities.Rarity, cardName: string): () -> ()
	local unit = Fit.Unit()
	local frame = holder(UDim2.fromScale(0.5, 0.58), Vector2.new(900, 120))

	local band: Frame = Make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.42),
		Size = UDim2.new(0, 0, 0, 74 * unit),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		ZIndex = 1,
		Parent = frame,
	}, {
		Make("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Paint.Shade(rarity.Dark, 0.3)),
				ColorSequenceKeypoint.new(0.5, rarity.Color),
				ColorSequenceKeypoint.new(1, Paint.Shade(rarity.Dark, 0.3)),
			}),
			Transparency = BAND_FADE,
		}),
	})
	Motion.Tween(band, 0.3, { Size = UDim2.new(1, 0, 0, 74 * unit) }, Enum.EasingStyle.Quart)

	local title = text(frame, {
		Text = string.upper(rarity.Name),
		Font = Theme.Fonts.Display,
		TextColor3 = Theme.Colors.Text,
		Position = UDim2.fromScale(0.5, 0.42),
		Size = UDim2.fromScale(0.78, 0.53),
	}, 60 * unit, 3 * unit)
	local scale: UIScale = Make("UIScale", { Scale = SLAM_FROM, Parent = title })
	Motion.Tween(scale, 0.35, { Scale = 1 }, Enum.EasingStyle.Back)
	Motion.Tween(title, 0.35, { TextTransparency = 0 })
	Motion.Tween(title:FindFirstChildOfClass("UIStroke") :: UIStroke, 0.35, { Transparency = 0 })

	local sub = text(frame, {
		Text = `{cardName}  •  {Odds.Format(rarity.Chance)}`,
		Font = Theme.Fonts.Body,
		TextColor3 = Theme.Colors.Text,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.8),
		Size = UDim2.fromScale(0.56, 0.22),
	}, 22 * unit, 2 * unit)
	task.delay(0.2, function()
		Motion.Tween(sub, 0.2, { TextTransparency = 0 })
		Motion.Tween(sub:FindFirstChildOfClass("UIStroke") :: UIStroke, 0.2, { Transparency = 0.2 })
	end)

	local left = false
	return function()
		if not left then
			left = true
			leave(frame)
		end
	end
end

function Banner.Toast(message: string, color: Color3, hold: number)
	local unit = Fit.Unit()
	local frame = holder(UDim2.fromScale(0.5, 0.5), Vector2.new(520, 50))
	local label = text(frame, {
		Text = message,
		Font = Theme.Fonts.Display,
		TextColor3 = color,
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1, 1),
	}, 44 * unit, 3 * unit)
	Motion.Pop(Make("UIScale", { Parent = label }), 2, 1, 0.35)
	fade(frame, 0, 0.15)
	task.delay(hold, leave, frame)
end

return table.freeze(Banner)
