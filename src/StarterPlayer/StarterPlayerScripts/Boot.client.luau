--!strict
--[[
	Client entry point: loads every *Controller. No game logic lives here.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Client = ReplicatedStorage:WaitForChild("Client")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Loader = require(Shared:WaitForChild("Core"):WaitForChild("Loader"))

Loader.Start({ Client:WaitForChild("Controllers") })
