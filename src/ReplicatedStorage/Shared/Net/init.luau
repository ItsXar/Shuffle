--!strict
--[[
	Owns every RemoteEvent / RemoteFunction. Remotes are declared in Net/Remotes and created once by
	the server boot (Net.Setup) inside ReplicatedStorage.Remotes. Services and controllers only ask
	for them by name; nobody calls Instance.new("RemoteEvent") anywhere else.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Log = require(ReplicatedStorage.Shared.Core.Log)
local Remotes = require(script.Remotes)

local TAG = "Net"
local FOLDER = "Remotes"
local CLASSES: { [Remotes.Kind]: string } = {
	Event = "RemoteEvent",
	Unreliable = "UnreliableRemoteEvent",
	Function = "RemoteFunction",
}

local IS_SERVER = RunService:IsServer()

local Net = {}

local folder: Folder? = nil

local function container(): Instance
	local existing = folder
	if existing then
		return existing
	end
	if IS_SERVER then
		Log.Error(TAG, "Net.Setup must run before any service asks for a remote", 3)
	end
	local found = ReplicatedStorage:WaitForChild(FOLDER) :: Folder
	folder = found
	return found
end

local function get(name: string, kind: Remotes.Kind): any
	local spec = Remotes[name]
	if not spec then
		Log.Error(TAG, `No remote "{name}", declare it in Shared > Net > Remotes`, 3)
	end
	if spec.Kind ~= kind then
		Log.Error(TAG, `Remote "{name}" is a {spec.Kind}, not a {kind}`, 3)
	end
	local parent = container()
	return if IS_SERVER then parent:FindFirstChild(name) else parent:WaitForChild(name)
end

-- Server only, called once by the boot script before the Loader starts.
function Net.Setup()
	if not IS_SERVER then
		Log.Error(TAG, "Setup is server only", 2)
	end
	if folder then
		Log.Error(TAG, "Setup can only run once", 2)
	end
	local created = Instance.new("Folder")
	created.Name = FOLDER
	for name, spec in Remotes do
		local remote = Instance.new(CLASSES[spec.Kind])
		remote.Name = name
		remote.Parent = created
	end
	created.Parent = ReplicatedStorage
	folder = created
end

-- On the client these yield until the remote replicates.
function Net.Event(name: string): RemoteEvent
	return get(name, "Event")
end

function Net.Unreliable(name: string): UnreliableRemoteEvent
	return get(name, "Unreliable")
end

function Net.Function(name: string): RemoteFunction
	return get(name, "Function")
end

return table.freeze(Net)
