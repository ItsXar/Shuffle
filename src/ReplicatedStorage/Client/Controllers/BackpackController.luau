--!strict
--[[
	Owns the player's collection and deck on the client: loads them once ("Inventory"), adds every
	card won by a roll (and fills empty deck slots like the server does), edits the deck through
	the server ("SetDeck"), remembers which cards are new since the backpack was last opened (the
	red badge), and opens and closes the backpack window. Others listen with OnChanged.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Backpack = require(script.Parent.Parent.UI.Screens.Backpack)
local Battle = require(ReplicatedStorage.Shared.Config.Battle)
local Deck = require(ReplicatedStorage.Shared.Domain.Deck)
local Hud = require(script.Parent.Parent.UI.Screens.Hud)
local HudController = require(script.Parent.HudController)
local Log = require(ReplicatedStorage.Shared.Core.Log)
local Net = require(ReplicatedStorage.Shared.Net)
local Odds = require(ReplicatedStorage.Shared.Domain.Odds)
local Power = require(ReplicatedStorage.Shared.Domain.Power)

local TAG = "Backpack"

export type State = Backpack.State

local BackpackController = {}

local state: State = { Owned = {}, Deck = {}, Fresh = {} }
local window: Backpack.Backpack? = nil
local hud: Hud.Hud? = nil
local listeners: { (State) -> () } = {}

local function changed()
	if hud then
		local fresh = 0
		for _ in state.Fresh do
			fresh += 1
		end
		hud:SetBadge(fresh)
	end
	if window then
		window:Render(state)
	end
	for _, listener in listeners do
		task.spawn(listener, state)
	end
end

-- Sends the wanted deck; the server's answer (what it kept) becomes the deck.
local function setDeck(deck: { string })
	state.Deck = deck
	changed()
	task.spawn(function()
		local ok, kept = pcall(function(): { string }
			return Net.Function("SetDeck"):InvokeServer(deck)
		end)
		if ok and type(kept) == "table" then
			state.Deck = kept
			changed()
		else
			Log.Warn(TAG, `Could not change the deck: {kept}`)
		end
	end)
end

local function toggleCard(cardId: string)
	local deck = table.clone(state.Deck)
	local index = table.find(deck, cardId)
	if index then
		table.remove(deck, index)
	elseif #deck < Battle.DeckSize then
		table.insert(deck, cardId)
	else
		return
	end
	setDeck(deck)
end

local function removeSlot(index: number)
	local deck = table.clone(state.Deck)
	table.remove(deck, index)
	setDeck(deck)
end

function BackpackController.State(): State
	return state
end

function BackpackController.OnChanged(listener: (State) -> ())
	table.insert(listeners, listener)
	task.spawn(listener, state)
end

-- A roll ended: the kept card goes into the backpack.
function BackpackController.Collect(result: Odds.Result)
	local cardId = result.Hand[result.Best]
	local count = (state.Owned[cardId] or 0) + 1
	state.Owned[cardId] = count
	if count == 1 then
		state.Fresh[cardId] = true
	end
	Deck.Fill(state.Deck, state.Owned)
	changed()
end

function BackpackController.Toggle()
	local current = window
	if not current then
		return
	end
	if current:IsOpen() then
		current:Close()
	else
		current:Open(state)
		table.clear(state.Fresh)
		changed()
	end
end

function BackpackController.Start()
	hud = HudController.Get()
	hud.Actions.OnBackpack = BackpackController.Toggle
	window = Backpack.new({
		OnClose = function()
			local current = window
			if current then
				current:Close()
			end
		end,
		OnCard = toggleCard,
		OnSlot = removeSlot,
		OnEquipBest = function()
			setDeck(Power.Best(state.Owned, Battle.DeckSize))
		end,
	})
	local ok, result = pcall(function(): Odds.Collection
		return Net.Function("Inventory"):InvokeServer()
	end)
	if ok and type(result) == "table" and type(result.Owned) == "table" then
		-- The server's numbers are the truth (they already include any roll that finished meanwhile).
		state.Owned = table.clone(result.Owned)
		state.Deck = if type(result.Deck) == "table" then table.clone(result.Deck) else {}
	else
		Log.Warn(TAG, `Could not load the collection: {result}`)
	end
	changed()
end

return BackpackController
