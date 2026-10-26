--!strict
--[[
	Chunky game button: coloured face on a darker "base" so it reads as 3D, squishes when pressed,
	grows on hover, clicks. Root carries a free UIScale (Breath) for idle animation by the owner.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Audio = require(ReplicatedStorage.Client.Core.Audio)
local Make = require(script.Parent.Parent.Make)
local Motion = require(script.Parent.Parent.Motion)
local Paint = require(script.Parent.Parent.Paint)
local Theme = require(ReplicatedStorage.Shared.Config.Theme)

local DEPTH = 6
local CORNER = 16
local PRESSED = 0.9
local HOVER = 1.05

export type Options = {
	Parent: Instance,
	Position: UDim2,
	Size: UDim2,
	Color: Color3,
	Text: string,
	Hint: string?,
	OnClick: () -> (),
}

export type Button = {
	Root: Frame,
	Breath: UIScale,
	SetText: (self: Button, text: string) -> (),
	SetColor: (self: Button, color: Color3) -> (),
}

local Button = {}

function Button.new(options: Options): Button
	local root: Frame = Make("Frame", {
		Name = "Button",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = options.Position,
		Size = options.Size,
		BackgroundTransparency = 1,
		Parent = options.Parent,
	})
	local breath: UIScale = Make("UIScale", { Parent = root })

	local base: Frame = Make("Frame", {
		Name = "Base",
		Position = UDim2.fromOffset(0, DEPTH),
		Size = UDim2.fromScale(1, 1),
		BorderSizePixel = 0,
		ZIndex = 1,
		Parent = root,
	}, {
		Make("UICorner", { CornerRadius = UDim.new(0, CORNER) }),
	})

	local press: UIScale = Make("UIScale", {})
	local face: TextButton = Make("TextButton", {
		Name = "Face",
		Size = UDim2.fromScale(1, 1),
		AutoButtonColor = false,
		Text = "",
		BorderSizePixel = 0,
		ZIndex = 2,
		Parent = root,
	}, {
		Make("UICorner", { CornerRadius = UDim.new(0, CORNER) }),
		Make("UIStroke", { Thickness = 3, Color = Theme.Colors.Ink, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
		Make("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(200, 200, 200)) }),
		press,
	})

	local label: TextLabel = Make("TextLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.82, 0.58),
		BackgroundTransparency = 1,
		Text = options.Text,
		TextColor3 = Theme.Colors.Text,
		Font = Theme.Fonts.Title,
		TextScaled = true,
		Parent = face,
	}, {
		Make("UIStroke", { Thickness = 3, Color = Theme.Colors.Ink }),
	})

	if options.Hint then
		Make("TextLabel", {
			AnchorPoint = Vector2.new(1, 1),
			Position = UDim2.new(1, -8, 1, -4),
			Size = UDim2.fromScale(0.3, 0.26),
			BackgroundTransparency = 1,
			Text = options.Hint,
			TextColor3 = Theme.Colors.Text,
			TextTransparency = 0.25,
			TextXAlignment = Enum.TextXAlignment.Right,
			Font = Theme.Fonts.Body,
			TextScaled = true,
			Parent = face,
		})
	end

	local function squish(goal: number)
		Motion.Tween(press, 0.12, { Scale = goal }, Enum.EasingStyle.Back)
	end
	face.MouseEnter:Connect(function()
		squish(HOVER)
	end)
	face.MouseLeave:Connect(function()
		squish(1)
	end)
	face.MouseButton1Down:Connect(function()
		squish(PRESSED)
	end)
	face.MouseButton1Up:Connect(function()
		squish(1)
	end)
	face.Activated:Connect(function()
		Audio.Play("Click")
		options.OnClick()
	end)

	local self = { Root = root, Breath = breath } :: Button

	function self.SetText(_: Button, text: string)
		label.Text = text
	end

	function self.SetColor(_: Button, color: Color3)
		face.BackgroundColor3 = color
		base.BackgroundColor3 = Paint.Shade(color, 0.45)
	end

	self:SetColor(options.Color)
	return self
end

return table.freeze(Button)
