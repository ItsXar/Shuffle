--!strict
--[[
	Owns the roll loop on the client: buttons and keys, asking the server for a roll, auto-roll,
	and handing every result to the Stage (cards on top) and then the Hud (stats). Only one roll
	plays at a time; with auto on, the next roll starts as soon as the previous show ends.
]]

local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Audio = require(script.Parent.Parent.Core.Audio)
local Hud = require(script.Parent.Parent.UI.Screens.Hud)
local Input = require(ReplicatedStorage.Shared.Config.Input)
local Log = require(ReplicatedStorage.Shared.Core.Log)
local Net = require(ReplicatedStorage.Shared.Net)
local Odds = require(ReplicatedStorage.Shared.Domain.Odds)
local Stage = require(script.Parent.Parent.UI.Screens.Stage)

local TAG = "Roll"
local RETRY_DELAY = 0.4

local RollController = {}

local busy = false
local auto = false
local remote: RemoteFunction
local stage: Stage.Stage
local hud: Hud.Hud

local function request(): Odds.Result?
	local ok, result = pcall(remote.InvokeServer, remote)
	if not ok then
		Log.Warn(TAG, result)
		return nil
	end
	return result
end

local function loop()
	repeat
		local result = request()
		if result then
			stage:Play(result, hud:Target())
			hud:Update(result)
		else
			task.wait(RETRY_DELAY)
		end
	until not auto
end

local function run()
	busy = true
	hud:SetBusy(true)
	local ok, err = pcall(function()
		loop()
	end)
	if not ok then
		Log.Warn(TAG, err)
	end
	busy = false
	hud:SetBusy(false)
end

function RollController.Roll()
	if not busy then
		task.spawn(run)
	end
end

function RollController.SetAuto(on: boolean)
	auto = on
	hud:SetAuto(on)
	if on then
		RollController.Roll()
	end
end

local function bind(name: string, keys: { Enum.KeyCode }, action: () -> ())
	ContextActionService:BindAction(name, function(_: string, state: Enum.UserInputState): Enum.ContextActionResult
		if state == Enum.UserInputState.Begin then
			action()
		end
		return Enum.ContextActionResult.Sink
	end, false, table.unpack(keys))
end

function RollController.Start()
	remote = Net.Function("Roll")
	Audio.Preload()
	stage = Stage.new()
	hud = Hud.new({
		OnRoll = RollController.Roll,
		OnAuto = function()
			RollController.SetAuto(not auto)
		end,
	})
	bind("ShuffleRoll", Input.Roll, RollController.Roll)
	bind("ShuffleAuto", Input.Auto, function()
		RollController.SetAuto(not auto)
	end)
end

return RollController
