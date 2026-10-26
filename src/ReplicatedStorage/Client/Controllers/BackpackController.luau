--!strict
--[[
	Owns the player's collection on the client: loads it from the server once ("Inventory"), adds
	every card won by a roll, remembers which cards are new since the backpack was last opened
	(the red badge), and opens and closes the backpack window.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Backpack = require(script.Parent.Parent.UI.Screens.Backpack)
local Hud = require(script.Parent.Parent.UI.Screens.Hud)
local Log = require(ReplicatedStorage.Shared.Core.Log)
local Net = require(ReplicatedStorage.Shared.Net)
local Odds = require(ReplicatedStorage.Shared.Domain.Odds)

local TAG = "Backpack"

local BackpackController = {}

local owned: { [string]: number } = {}
local fresh: { [string]: boolean } = {}
local window: Backpack.Backpack? = nil
local hud: Hud.Hud? = nil

local function freshCount(): number
	local count = 0
	for _ in fresh do
		count += 1
	end
	return count
end

local function refreshBadge()
	if hud then
		hud:SetBadge(freshCount())
	end
end

-- The Hud that shows the badge (given by RollController, which builds it).
function BackpackController.Attach(target: Hud.Hud)
	hud = target
	refreshBadge()
end

-- A roll ended: the kept card goes into the backpack.
function BackpackController.Collect(result: Odds.Result)
	local cardId = result.Hand[result.Best]
	local count = (owned[cardId] or 0) + 1
	owned[cardId] = count
	if count == 1 then
		fresh[cardId] = true
	end
	refreshBadge()
end

function BackpackController.Toggle()
	local current = window
	if not current then
		return
	end
	if current:IsOpen() then
		current:Close()
	else
		current:Open(owned, fresh)
		table.clear(fresh)
		refreshBadge()
	end
end

function BackpackController.Start()
	window = Backpack.new(function()
		local current = window
		if current then
			current:Close()
		end
	end)
	local ok, result = pcall(function(): Odds.Collection
		return Net.Function("Inventory"):InvokeServer()
	end)
	if ok and type(result) == "table" and type(result.Owned) == "table" then
		-- The server's count is the truth (it already includes any roll that finished meanwhile).
		owned = table.clone(result.Owned)
	else
		Log.Warn(TAG, `Could not load the collection: {result}`)
	end
end

return BackpackController
