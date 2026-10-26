--!strict
--[[
	Chunky game button: glossy coloured face on a darker "base" so it reads as 3D, with a light
	band sweeping across it; squishes when pressed, grows on hover. Root carries a free UIScale (Breath) for idle animation by the owner.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Audio = require(ReplicatedStorage.Client.Core.Audio)
local Make = require(script.Parent.Parent.Make)
local Motion = require(script.Parent.Parent.Motion)
local Paint = require(script.Parent.Parent.Paint)
local Theme = require(ReplicatedStorage.Shared.Config.Theme)

local DEPTH = 5
local CORNER = 12
local PRESSED = 0.9
local HOVER = 1.05
local SHINE_SPEED = 0.7

local SHINE_BAND = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 1),
	NumberSequenceKeypoint.new(0.45, 1),
	NumberSequenceKeypoint.new(0.5, 0.55),
	NumberSequenceKeypoint.new(0.55, 1),
	NumberSequenceKeypoint.new(1, 1),
})

export type Options = {
	Parent: Instance,
	Position: UDim2,
	Size: UDim2,
	Color: Color3,
	Text: string,
	-- Optional emoji above a smaller caption.
	Icon: string?,
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
		Make("UIStroke", { Thickness = 2, Color = Theme.Colors.Ink, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
		press,
	})
	local paint: UIGradient = Make("UIGradient", { Rotation = 90, Parent = face })

	-- Light band sliding across the face every few seconds.
	local sweep: UIGradient = Make("UIGradient", { Rotation = 20, Transparency = SHINE_BAND })
	Make("Frame", {
		Name = "Shine",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(1, 1, 1),
		ZIndex = 3,
		Parent = face,
	}, {
		Make("UICorner", { CornerRadius = UDim.new(0, CORNER) }),
		sweep,
	})
	Paint.Animate(face, function(elapsed: number)
		sweep.Offset = Vector2.new((elapsed * SHINE_SPEED) % 2.6 - 1.3, 0)
	end)

	local label: TextLabel = Make("TextLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, if options.Icon then 0.8 else 0.5),
		Size = if options.Icon then UDim2.fromScale(0.9, 0.22) else UDim2.fromScale(0.8, 0.42),
		BackgroundTransparency = 1,
		Text = options.Text,
		TextColor3 = Theme.Colors.Text,
		Font = Theme.Fonts.Display,
		TextScaled = true,
		ZIndex = 4,
		Parent = face,
	}, {
		Make("UIStroke", { Thickness = 2, Color = Theme.Colors.Ink, Transparency = 0.2 }),
	})

	if options.Icon then
		Make("TextLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.4),
			Size = UDim2.fromScale(0.62, 0.56),
			BackgroundTransparency = 1,
			Text = options.Icon,
			TextScaled = true,
			Font = Theme.Fonts.Display,
			ZIndex = 4,
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
		face.BackgroundColor3 = Color3.new(1, 1, 1)
		paint.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Paint.Tint(color, 0.35)),
			ColorSequenceKeypoint.new(0.5, color),
			ColorSequenceKeypoint.new(1, Paint.Shade(color, 0.15)),
		})
		base.BackgroundColor3 = Paint.Shade(color, 0.5)
	end

	self:SetColor(options.Color)
	return self
end

return table.freeze(Button)
