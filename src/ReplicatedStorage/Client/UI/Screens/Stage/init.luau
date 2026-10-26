--!strict
--[[
	The card row at the top of the screen. Play runs one roll show from the server's result:
	Shuffle (deal + spin + lock) -> Pick (the system chooses the best card) -> Celebrate (the
	payoff). Play yields until the show is over and always leaves the stage empty, even if a
	phase fails.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Banner = require(script.Parent.Parent.Fx.Banner)
local Celebrate = require(script.Celebrate)
local Fit = require(script.Parent.Parent.Fit)
local Log = require(ReplicatedStorage.Shared.Core.Log)
local Make = require(script.Parent.Parent.Make)
local Odds = require(ReplicatedStorage.Shared.Domain.Odds)
local Pick = require(script.Pick)
local Root = require(script.Parent.Parent.Root)
local Shake = require(script.Parent.Parent.Fx.Shake)
local Show = require(script.Show)
local Shuffle = require(script.Shuffle)
local Theme = require(ReplicatedStorage.Shared.Config.Theme)

local TAG = "Stage"
local LUCKY_PAUSE = 0.7

export type Stage = {
	Play: (self: Stage, result: Odds.Result) -> (),
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

	function self.Play(_: Stage, result: Odds.Result)
		local show = Show.new(canvas, result)
		local ok, err = pcall(function()
			if result.Lucky then
				Banner.Toast(`🍀 LUCKY ROLL  x{result.Luck} LUCK`, Theme.Colors.Lucky, LUCKY_PAUSE)
				task.wait(LUCKY_PAUSE)
			end
			Shuffle.Run(show)
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
