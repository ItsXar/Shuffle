--!strict
--[[
	Owns everything that must stop when something closes: connections, key bindings, loops,
	delayed callbacks, instances, release functions. One Clean() undoes it all, newest first.

	    local scope = Scope.new()
	    scope:Connect(button.Activated, onClick)
	    scope:Add(Cursor.Unlock())
	    scope:Every(0.2, jitter)
	    scope:Clean()
]]

local ContextActionService = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")

local BIND_PRIORITY = Enum.ContextActionPriority.High.Value + 10

export type Task = Instance | RBXScriptConnection | thread | (() -> ()) | { Destroy: (any) -> () } | { Disconnect: (any) -> () }

export type Scope = {
	Alive: boolean,
	Add: <T>(self: Scope, item: T) -> T,
	Connect: (self: Scope, signal: RBXScriptSignal, callback: (...any) -> ()) -> RBXScriptConnection,
	Bind: (self: Scope, name: string, keys: { Enum.KeyCode }, onKey: (Enum.KeyCode, InputObject) -> (), priority: number?) -> (),
	Every: (self: Scope, interval: number, callback: () -> ()) -> (),
	Delay: (self: Scope, seconds: number, callback: () -> ()) -> (),
	Spawn: (self: Scope, callback: () -> ()) -> (),
	Clean: (self: Scope) -> (),
}

local Scope = {}

local function cleanup(item: any)
	local kind = typeof(item)
	if kind == "function" then
		item()
	elseif kind == "RBXScriptConnection" then
		item:Disconnect()
	elseif kind == "Instance" then
		item:Destroy()
	elseif kind == "thread" then
		-- A running thread (one that closed its own screen) ends on its own.
		if coroutine.status(item) == "suspended" then
			task.cancel(item)
		end
	elseif type(item) == "table" then
		if type(item.Destroy) == "function" then
			item:Destroy()
		elseif type(item.Disconnect) == "function" then
			item:Disconnect()
		end
	end
end

function Scope.new(): Scope
	local items: { any } = {}
	local self = { Alive = true } :: Scope

	function self.Add<T>(scope: Scope, item: T): T
		if scope.Alive then
			table.insert(items, item)
		else
			cleanup(item)
		end
		return item
	end

	function self.Connect(scope: Scope, signal: RBXScriptSignal, callback: (...any) -> ()): RBXScriptConnection
		return scope:Add(signal:Connect(callback))
	end

	-- Sinks the keys while the scope lives (above normal game input unless `priority` says
	-- otherwise); the handler gets key-down only.
	function self.Bind(scope: Scope, name: string, keys: { Enum.KeyCode }, onKey: (Enum.KeyCode, InputObject) -> (), priority: number?)
		ContextActionService:BindActionAtPriority(name, function(_: string, state: Enum.UserInputState, input: InputObject)
			if state == Enum.UserInputState.Begin then
				onKey(input.KeyCode, input)
			end
			return Enum.ContextActionResult.Sink
		end, false, priority or BIND_PRIORITY, table.unpack(keys))
		scope:Add(function()
			ContextActionService:UnbindAction(name)
		end)
	end

	-- Calls back every `interval` seconds of rendered time.
	function self.Every(scope: Scope, interval: number, callback: () -> ())
		local elapsed = 0
		scope:Connect(RunService.RenderStepped, function(deltaTime: number)
			elapsed += deltaTime
			if elapsed >= interval then
				elapsed = 0
				callback()
			end
		end)
	end

	function self.Delay(scope: Scope, seconds: number, callback: () -> ())
		scope:Add(task.delay(seconds, function()
			if scope.Alive then
				callback()
			end
		end))
	end

	function self.Spawn(scope: Scope, callback: () -> ())
		scope:Add(task.spawn(callback))
	end

	function self.Clean(scope: Scope)
		if not scope.Alive then
			return
		end
		scope.Alive = false
		for index = #items, 1, -1 do
			cleanup(items[index])
		end
		table.clear(items)
	end

	return self
end

return table.freeze(Scope)
