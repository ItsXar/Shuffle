--!strict
-- Red counter bubble on the corner of a button; hidden at 0, pops whenever the number changes.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Make = require(script.Parent.Parent.Parent.Make)
local Motion = require(script.Parent.Parent.Parent.Motion)
local Theme = require(ReplicatedStorage.Shared.Config.Theme)

export type Badge = {
	Set: (self: Badge, count: number) -> (),
}

local function Badge(parent: GuiObject): Badge
	local bubble: Frame = Make("Frame", {
		Name = "Badge",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(1, -4, 0, 4),
		Size = UDim2.fromOffset(26, 26),
		BackgroundColor3 = Theme.Colors.New,
		Visible = false,
		ZIndex = 6,
		Parent = parent,
	}, {
		Make("UICorner", { CornerRadius = UDim.new(1, 0) }),
		Make("UIStroke", { Thickness = 2, Color = Theme.Colors.Text, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
	})
	local scale: UIScale = Make("UIScale", { Parent = bubble })
	local label: TextLabel = Make("TextLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.75, 0.7),
		BackgroundTransparency = 1,
		TextColor3 = Theme.Colors.Text,
		TextScaled = true,
		Font = Theme.Fonts.Display,
		ZIndex = 7,
		Parent = bubble,
	})

	local current = 0
	local self = {} :: Badge
	function self.Set(_: Badge, count: number)
		bubble.Visible = count > 0
		label.Text = if count > 99 then "99+" else tostring(count)
		if count > current then
			Motion.Pop(scale, 1.6, 1, 0.4)
		end
		current = count
	end
	return self
end

return Badge
