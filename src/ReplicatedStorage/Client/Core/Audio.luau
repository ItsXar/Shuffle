--!strict
--[[
	Plays the sounds named in Config/Sounds. Each call plays a fresh copy, so the same sound can
	overlap itself (fast reel ticks) and every copy can have its own pitch.
]]

local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local Sounds = require(ReplicatedStorage.Shared.Config.Sounds)

local MAX_LIFETIME = 8

local Audio = {}

local templates: { [string]: Sound } = {}

local function template(name: string): Sound
	local existing = templates[name]
	if existing then
		return existing
	end
	local spec = Sounds[name]
	local sound = Instance.new("Sound")
	sound.Name = name
	sound.SoundId = spec.Id
	sound.Volume = spec.Volume
	templates[name] = sound
	return sound
end

function Audio.Play(name: string, pitch: number?, volume: number?)
	local sound = template(name):Clone()
	sound.PlaybackSpeed = pitch or 1
	sound.Volume *= volume or 1
	sound.Parent = SoundService
	sound.Ended:Once(function()
		sound:Destroy()
	end)
	sound:Play()
	task.delay(MAX_LIFETIME, function()
		if sound.Parent then
			sound:Destroy()
		end
	end)
end

-- Loads every sound in the background so the first roll is not silent.
function Audio.Preload()
	local list = {}
	for name in Sounds do
		table.insert(list, template(name))
	end
	task.spawn(function()
		ContentProvider:PreloadAsync(list)
	end)
end

return table.freeze(Audio)
