--!strict
--[[
	Server entry point: creates every remote, then loads every *Service. No game logic lives here.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Loader = require(ReplicatedStorage.Shared.Core.Loader)
local Net = require(ReplicatedStorage.Shared.Net)

Net.Setup()
Loader.Start({ ServerScriptService.Services })
