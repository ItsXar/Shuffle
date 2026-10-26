--!strict

local RunService = game:GetService("RunService")

local SIDE = if RunService:IsServer() then "Server" else "Client"
local VERBOSE = RunService:IsStudio()

local function format(tag: string, message: any): string
	return `[{SIDE}][{tag}] {message}`
end

local Log = {}

function Log.Info(tag: string, message: any)
	if VERBOSE then
		print(format(tag, message))
	end
end

function Log.Warn(tag: string, message: any)
	warn(format(tag, message))
end

function Log.Error(tag: string, message: any, level: number?): never
	error(format(tag, message), (level or 1) + 1)
end

return table.freeze(Log)
