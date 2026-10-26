--!strict
--[[
	Health bar floating over a monster: "Lv 4  Stone Golem", a red bar with a white trail that
	catches up after each hit, and "1.2K / 3K". Always drawn on top so it never hides behind
	the monster.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Make = require(script.Parent.Parent.UI.Make)
local Motion = require(script.Parent.Parent.UI.Motion)
local Paint = require(script.Parent.Parent.UI.Paint)
local Power = require(ReplicatedStorage.Shared.Domain.Power)
local Theme = require(ReplicatedStorage.Shared.Config.Theme)

local TRAIL_DELAY = 0.25

export type HealthBar = {
	Set: (self: HealthBar, hp: number, maxHp: number) -> (),
	Destroy: (self: HealthBar) -> (),
}

local HealthBar = {}

local function label(parent: Instance, props: { [string]: any }): TextLabel
	props.BackgroundTransparency = 1
	props.TextScaled = true
	props.Font = Theme.Fonts.Display
	props.TextColor3 = props.TextColor3 or Theme.Colors.Text
	props.Parent = parent
	return Make("TextLabel", props, {
		Make("UIStroke", { Thickness = 2, Color = Theme.Colors.Ink }),
	})
end

function HealthBar.new(head: BasePart, height: number, title: string): HealthBar
	local colors = Theme.Colors
	local gui: BillboardGui = Make("BillboardGui", {
		Name = "HealthBar",
		Adornee = head,
		Size = UDim2.fromOffset(250, 62),
		StudsOffsetWorldSpace = Vector3.new(0, height, 0),
		AlwaysOnTop = true,
		LightInfluence = 0,
		MaxDistance = 200,
		Parent = head,
	})
	label(gui, { Size = UDim2.new(1, 0, 0, 22), Text = title })
	local track: Frame = Make("Frame", {
		Position = UDim2.fromOffset(0, 26),
		Size = UDim2.new(1, 0, 0, 22),
		BackgroundColor3 = colors.Ink,
		Parent = gui,
	}, {
		Make("UICorner", { CornerRadius = UDim.new(0, 8) }),
		Make("UIStroke", { Thickness = 2, Color = colors.Ink }),
	})
	local trail: Frame = Make("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(1, 1, 1),
		Parent = track,
	}, {
		Make("UICorner", { CornerRadius = UDim.new(0, 8) }),
	})
	local fill: Frame = Make("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(1, 1, 1),
		ZIndex = 2,
		Parent = track,
	}, {
		Make("UICorner", { CornerRadius = UDim.new(0, 8) }),
		Make("UIGradient", { Rotation = 90, Color = ColorSequence.new(Paint.Tint(colors.Health, 0.35), Paint.Shade(colors.Health, 0.2)) }),
	})
	local amount = label(track, { Size = UDim2.fromScale(1, 0.8), Position = UDim2.fromScale(0, 0.1), Text = "", ZIndex = 3 })

	local self = {} :: HealthBar

	function self.Set(_: HealthBar, hp: number, maxHp: number)
		local share = math.clamp(hp / math.max(maxHp, 1), 0, 1)
		amount.Text = `{Power.Format(hp)} / {Power.Format(maxHp)}`
		Motion.Tween(fill, 0.12, { Size = UDim2.fromScale(share, 1) })
		task.delay(TRAIL_DELAY, function()
			if trail.Parent then
				Motion.Tween(trail, 0.35, { Size = UDim2.fromScale(share, 1) })
			end
		end)
	end

	function self.Destroy(_: HealthBar)
		gui:Destroy()
	end

	return self
end

return table.freeze(HealthBar)
