--!strict
--[[
	The card row at the top of the screen. Play runs one roll show from the server's result:
	Deal (cards fly out of `origin`, the ROLL button) -> Reels (spin and reveal) -> Pick (the
	system chooses the best card) -> Celebrate (the payoff, then the card flies into `target`,
	the BACKPACK button). Play yields until the show is over and always leaves the stage empty, even if a
	phase fails.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Banner = require(script.Parent.Parent.Fx.Banner)
local Celebrate = require(script.Celebrate)
local Deal = require(script.Deal)
local Fit = require(script.Parent.Parent.Fit)
local Log = require(ReplicatedStorage.Shared.Core.Log)
local Make = require(script.Parent.Parent.Make)
local Odds = require(ReplicatedStorage.Shared.Domain.Odds)
local Pick = require(script.Pick)
local Reels = require(script.Reels)
local Root = require(script.Parent.Parent.Root)
local Shake = require(script.Parent.Parent.Fx.Shake)
local Show = require(script.Show)
local Theme = require(ReplicatedStorage.Shared.Config.Theme)

local TAG = "Stage"
local LUCKY_PAUSE = 0.7

export type Stage = {
	Play: (self: Stage, result: Odds.Result, origin: GuiObject, target: GuiObject) -> (),
}

local Stage = {}

function Stage.new(): Stage
	local design = Theme.Stage.Design
	local canvas: Frame = Make("Frame", {
		Name = "Canvas",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, Theme.Stage.Top),
		Size = UDim2.fromOffset(design.X, design.Y),
		BackgroundTransparency = 1,
		Parent = Root.Layer("Stage"),
	})
	Fit.Attach(canvas, design, Theme.Stage.HeightShare)
	Shake.Track(canvas)

	local self = {} :: Stage

	function self.Play(_: Stage, result: Odds.Result, origin: GuiObject, target: GuiObject)
		local show = Show.new(canvas, result, origin, target)
		local ok, err = pcall(function()
			if result.Lucky then
				Banner.Toast(`🍀 LUCKY ROLL  x{result.Luck} LUCK`, Theme.Colors.Lucky, LUCKY_PAUSE)
				task.wait(LUCKY_PAUSE)
			end
			Deal.Run(show)
			Reels.Run(show)
			Pick.Run(show)
			Celebrate.Run(show)
		end)
		show.Scope:Clean()
		if not ok then
			Log.Warn(TAG, err)
		end
	end

	return self
end

return table.freeze(Stage)
