--!strict
--[[
	Lifecycle for game modules. Only modules named *Service (server) or *Controller (client)
	are loaded; every other ModuleScript is a library owned by whoever requires it.
	All Init run first (must not yield), then every Start runs in its own thread.
	See docs/ARCHITECTURE.md.
]]

local RunService = game:GetService("RunService")

local Log = require(script.Parent.Log)

local TAG = "Loader"
local SUFFIX = if RunService:IsServer() then "Service" else "Controller"

type Phase = "Idle" | "Loading" | "Init" | "Start" | "Ready"

local modules: { [string]: any } = {}
local order: { string } = {}
local failed: { [string]: boolean } = {}
local initTimes: { [string]: number } = {}
local waiting: { thread } = {}
local phase: Phase = "Idle"

local function trace(err: any): string
	return debug.traceback(tostring(err), 2)
end

local function elapsed(since: number): number
	return (os.clock() - since) * 1000
end

local function isEntry(item: Instance): boolean
	return item:IsA("ModuleScript") and string.sub(item.Name, -#SUFFIX) == SUFFIX and not item:FindFirstAncestorWhichIsA("ModuleScript")
end

local function collect(roots: { Instance }): { ModuleScript }
	local found = {}
	for _, root in roots do
		for _, item in root:GetDescendants() do
			if isEntry(item) then
				table.insert(found, item :: ModuleScript)
			end
		end
	end
	table.sort(found, function(a: ModuleScript, b: ModuleScript)
		if a.Name ~= b.Name then
			return a.Name < b.Name
		end
		return a:GetFullName() < b:GetFullName()
	end)
	return found
end

local function checkNaming(name: string, module: any)
	for _, method in { "Init", "Start" } do
		local lower = string.lower(method)
		if rawget(module, lower) ~= nil and rawget(module, method) == nil then
			Log.Warn(TAG, `{name} has "{lower}", did you mean "{method}"?`)
		end
	end
end

local function load(moduleScript: ModuleScript)
	local name = moduleScript.Name
	if modules[name] ~= nil or failed[name] then
		Log.Warn(TAG, `Duplicate module "{name}" skipped: {moduleScript:GetFullName()}`)
		return
	end

	local ok, result = pcall(require, moduleScript)
	if not ok then
		failed[name] = true
		Log.Warn(TAG, `{name} failed to load:\n{result}`)
	elseif type(result) ~= "table" then
		failed[name] = true
		Log.Warn(TAG, `{name} must return a table`)
	else
		checkNaming(name, result)
		modules[name] = result
		table.insert(order, name)
	end
end

local function init(name: string)
	local method = rawget(modules[name], "Init")
	if type(method) ~= "function" then
		return
	end

	local started = os.clock()
	local caller = coroutine.running()
	local done, parked = false, false
	local ok, err = false, nil

	task.spawn(function()
		ok, err = xpcall(method, trace)
		done = true
		if parked then
			task.spawn(caller)
		end
	end)

	if not done then
		Log.Warn(TAG, `{name}.Init yielded, move waiting code to Start`)
		parked = true
		coroutine.yield()
	end

	initTimes[name] = elapsed(started)
	if not ok then
		failed[name] = true
		Log.Warn(TAG, `{name}.Init failed, module disabled:\n{err}`)
	end
end

local function start(name: string)
	local method = rawget(modules[name], "Start")
	if failed[name] or type(method) ~= "function" then
		return
	end

	task.spawn(function()
		local ok, err = xpcall(method, trace)
		if not ok then
			Log.Warn(TAG, `{name}.Start failed:\n{err}`)
		end
	end)
end

local function report(started: number)
	local failedCount = 0
	for _ in failed do
		failedCount += 1
	end

	local slowest, slowestTime = nil, 0
	for name, time in initTimes do
		if time > slowestTime then
			slowest, slowestTime = name, time
		end
	end

	local okCount = 0
	for _, name in order do
		if not failed[name] then
			okCount += 1
		end
	end

	local summary = string.format("Ready: %d ok, %d failed, %.1f ms", okCount, failedCount, elapsed(started))
	if slowest then
		summary ..= string.format(", slowest Init: %s %.1f ms", slowest, slowestTime)
	end

	if failedCount > 0 then
		Log.Warn(TAG, summary)
	else
		Log.Info(TAG, summary)
	end
end

local Loader = {}

function Loader.Start(roots: { Instance? })
	if phase ~= "Idle" then
		Log.Error(TAG, "Start can only be called once", 2)
	end

	local present: { Instance } = {}
	for _, root in roots do
		if root then
			table.insert(present, root)
		end
	end

	local started = os.clock()
	phase = "Loading"
	for _, moduleScript in collect(present) do
		load(moduleScript)
	end

	phase = "Init"
	for _, name in order do
		init(name)
	end

	phase = "Start"
	for _, name in order do
		start(name)
	end

	phase = "Ready"
	for _, thread in waiting do
		task.spawn(thread)
	end
	table.clear(waiting)
	report(started)
end

function Loader.IsReady(): boolean
	return phase == "Ready"
end

function Loader.IsHealthy(name: string): boolean
	return modules[name] ~= nil and not failed[name]
end

function Loader.WaitForReady()
	if phase ~= "Ready" then
		table.insert(waiting, coroutine.running())
		coroutine.yield()
	end
end

return table.freeze(Loader)
