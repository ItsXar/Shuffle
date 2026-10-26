--!strict
-- Top of the backpack window: icon and title, collection progress (count and bar), close button.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Make = require(script.Parent.Parent.Parent.Make)
local Motion = require(script.Parent.Parent.Parent.Motion)
local Paint = require(script.Parent.Parent.Parent.Paint)
local Theme = require(ReplicatedStorage.Shared.Config.Theme)

local HEIGHT = 76

export type Header = {
	SetProgress: (self: Header, have: number, total: number) -> (),
}

local Header = {}

local function label(parent: Instance, text: string, props: { [string]: any }): TextLabel
	props.BackgroundTransparency = 1
	props.Text = text
	props.TextScaled = true
	props.Font = Theme.Fonts.Display
	props.TextColor3 = props.TextColor3 or Theme.Colors.Text
	props.Parent = parent
	return Make("TextLabel", props, {
		Make("UIStroke", { Thickness = 2, Color = Theme.Colors.Ink }),
	})
end

local function closeButton(parent: Instance, onClose: () -> ())
	local color = Theme.Colors.Close
	local button: TextButton = Make("TextButton", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(1, -40, 0, HEIGHT / 2),
		Size = UDim2.fromOffset(46, 46),
		BackgroundColor3 = Color3.new(1, 1, 1),
		AutoButtonColor = false,
		Text = "",
		ZIndex = 3,
		Parent = parent,
	}, {
		Make("UICorner", { CornerRadius = UDim.new(0, 12) }),
		Make("UIStroke", { Thickness = 2, Color = Theme.Colors.Ink, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
		Make("UIGradient", { Rotation = 90, Color = ColorSequence.new(Paint.Tint(color, 0.4), Paint.Shade(color, 0.1)) }),
	})
	local center = Vector2.new(0.5, 0.5)
	local mark = label(button, "✕", { AnchorPoint = center, Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.6, 0.6) })
	mark.ZIndex = 4
	local scale: UIScale = Make("UIScale", { Parent = button })
	button.MouseEnter:Connect(function()
		Motion.Tween(scale, 0.12, { Scale = 1.1 }, Enum.EasingStyle.Back)
	end)
	button.MouseLeave:Connect(function()
		Motion.Tween(scale, 0.12, { Scale = 1 })
	end)
	button.Activated:Connect(onClose)
end

function Header.new(panel: Frame, onClose: () -> ()): Header
	local colors = Theme.Colors
	local bar: Frame = Make("Frame", {
		Name = "Header",
		Size = UDim2.new(1, 0, 0, HEIGHT),
		BackgroundColor3 = Color3.new(1, 1, 1),
		ZIndex = 2,
		Parent = panel,
	}, {
		Make("UICorner", { CornerRadius = UDim.new(0, 26) }),
		Make("UIGradient", {
			Rotation = 90,
			Color = ColorSequence.new(Paint.Tint(colors.PanelEdge, 0.1), Paint.Shade(colors.PanelEdge, 0.4)),
			Transparency = NumberSequence.new(0.1, 0.4),
		}),
	})
	label(bar, "🎒", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 26, 0.5, 0), Size = UDim2.fromOffset(44, 44) })
	label(bar, "BACKPACK", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 78, 0.5, 0), Size = UDim2.fromOffset(200, 36) })

	local count = label(bar, "", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -96, 0, 26),
		Size = UDim2.fromOffset(240, 20),
		TextColor3 = Paint.Tint(colors.PanelEdge, 0.6),
	})
	local track: Frame = Make("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -96, 0, 52),
		Size = UDim2.fromOffset(240, 14),
		BackgroundColor3 = Paint.Shade(colors.PanelBottom, 0.4),
		Parent = bar,
	}, {
		Make("UICorner", { CornerRadius = UDim.new(1, 0) }),
		Make("UIStroke", { Thickness = 2, Color = colors.PanelEdge }),
	})
	local fill: Frame = Make("Frame", {
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = Color3.new(1, 1, 1),
		Parent = track,
	}, {
		Make("UICorner", { CornerRadius = UDim.new(1, 0) }),
		Make("UIGradient", { Color = ColorSequence.new(Color3.fromRGB(255, 160, 40), colors.Gold) }),
	})
	closeButton(bar, onClose)

	local self = {} :: Header
	function self.SetProgress(_: Header, have: number, total: number)
		count.Text = `COLLECTION  {have} / {total}`
		fill.Size = UDim2.fromScale(0, 1)
		Motion.Tween(fill, 0.6, { Size = UDim2.fromScale(have / math.max(total, 1), 1) }, Enum.EasingStyle.Quart)
	end
	return self
end

return table.freeze(Header)
