--!strict
-- Small building blocks of the backpack window: plain labels, pills, sections, the green button.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Make = require(script.Parent.Parent.Parent.Make)
local Motion = require(script.Parent.Parent.Parent.Motion)
local Paint = require(script.Parent.Parent.Parent.Paint)
local Theme = require(ReplicatedStorage.Shared.Config.Theme)

local Parts = {}

function Parts.Label(parent: Instance, props: { [string]: any }): TextLabel
	props.BackgroundTransparency = 1
	props.TextScaled = true
	props.Font = props.Font or Theme.Fonts.Display
	props.TextColor3 = props.TextColor3 or Theme.Colors.Text
	props.Parent = parent
	return Make("TextLabel", props)
end

-- Rounded dark pill with coloured outline and text, e.g. "x12" or "⚔ 55".
function Parts.Pill(parent: Instance, text: string, color: Color3, position: UDim2, anchor: Vector2, width: number): Frame
	local pill: Frame = Make("Frame", {
		AnchorPoint = anchor,
		Position = position,
		Size = UDim2.fromOffset(width, 20),
		BackgroundColor3 = Theme.Colors.Ink,
		ZIndex = 5,
		Parent = parent,
	}, {
		Make("UICorner", { CornerRadius = UDim.new(1, 0) }),
		Make("UIStroke", { Thickness = 2, Color = color, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
	})
	Parts.Label(pill, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.86, 0.72),
		Text = text,
		TextColor3 = color,
		ZIndex = 6,
	})
	return pill
end

-- Rounded box with a small caps title on the left and an optional gold note on the right.
function Parts.Section(parent: Instance, y: number, height: number, title: string): (Frame, TextLabel)
	local colors = Theme.Colors
	local box: Frame = Make("Frame", {
		Position = UDim2.fromOffset(20, y),
		Size = UDim2.new(1, -40, 0, height),
		BackgroundColor3 = colors.Section,
		Parent = parent,
	}, {
		Make("UICorner", { CornerRadius = UDim.new(0, 16) }),
		Make("UIStroke", { Thickness = 1, Color = colors.Edge }),
	})
	Parts.Label(box, {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.fromOffset(18, 22),
		Size = UDim2.fromOffset(300, 16),
		Text = title,
		TextColor3 = colors.Muted,
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	local note = Parts.Label(box, {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -18, 0, 22),
		Size = UDim2.fromOffset(320, 16),
		Text = "",
		TextColor3 = colors.Damage,
		TextXAlignment = Enum.TextXAlignment.Right,
	})
	return box, note
end

-- Glossy coloured button with a dark outline that squishes when pressed.
function Parts.Button(parent: Instance, text: string, color: Color3, position: UDim2, size: Vector2, onClick: () -> ()): TextButton
	local button: TextButton = Make("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = position,
		Size = UDim2.fromOffset(size.X, size.Y),
		BackgroundColor3 = Color3.new(1, 1, 1),
		AutoButtonColor = false,
		Text = "",
		Parent = parent,
	}, {
		Make("UICorner", { CornerRadius = UDim.new(0, 12) }),
		Make("UIStroke", { Thickness = 2, Color = Theme.Colors.Ink, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
		Make("UIGradient", { Rotation = 90, Color = ColorSequence.new(Paint.Tint(color, 0.4), Paint.Shade(color, 0.15)) }),
	})
	local label = Parts.Label(button, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.85, 0.46),
		Text = text,
	})
	Make("UIStroke", { Thickness = 2, Color = Theme.Colors.Ink, Transparency = 0.2, Parent = label })
	local scale: UIScale = Make("UIScale", { Parent = button })
	button.MouseButton1Down:Connect(function()
		Motion.Tween(scale, 0.1, { Scale = 0.92 })
	end)
	button.MouseButton1Up:Connect(function()
		Motion.Tween(scale, 0.15, { Scale = 1 }, Enum.EasingStyle.Back)
	end)
	button.MouseLeave:Connect(function()
		Motion.Tween(scale, 0.15, { Scale = 1 })
	end)
	button.Activated:Connect(onClick)
	return button
end

-- A whole-tile click area with a small lift on hover.
function Parts.Hover(holder: GuiObject, onClick: () -> ()): TextButton
	local scale: UIScale = Make("UIScale", { Parent = holder })
	local button: TextButton = Make("TextButton", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = "",
		ZIndex = 8,
		Parent = holder,
	})
	button.MouseEnter:Connect(function()
		Motion.Tween(scale, 0.15, { Scale = 1.06 }, Enum.EasingStyle.Back)
	end)
	button.MouseLeave:Connect(function()
		Motion.Tween(scale, 0.15, { Scale = 1 })
	end)
	button.Activated:Connect(onClick)
	return button
end

return table.freeze(Parts)
