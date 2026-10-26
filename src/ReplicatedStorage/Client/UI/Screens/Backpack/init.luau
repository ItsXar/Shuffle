--!strict
--[[
	The backpack window: the deck on top (DeckRow) and every card in the game below
	(Collection), with the collection progress in the title bar. Opens over a blurred world with
	the tiles popping in; the dark backdrop or ✕ closes it. Shows state only: every click goes to
	the actions given by the owner (BackpackController), which answers with Render.
]]

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Catalog = require(ReplicatedStorage.Shared.Domain.Catalog)
local Collection = require(script.Collection)
local DeckRow = require(script.DeckRow)
local Fit = require(script.Parent.Parent.Fit)
local Make = require(script.Parent.Parent.Make)
local Motion = require(script.Parent.Parent.Motion)
local Parts = require(script.Parts)
local Root = require(script.Parent.Parent.Root)
local Theme = require(ReplicatedStorage.Shared.Config.Theme)

local BLUR = 14
local BACKDROP = 0.35
local OPEN_SECONDS = 0.3
local DECK_Y = 64
local CARDS_Y = 268

export type State = Collection.State

export type Actions = {
	OnClose: () -> (),
	OnCard: (cardId: string) -> (),
	OnSlot: (index: number) -> (),
	OnEquipBest: () -> (),
}

export type Backpack = {
	Open: (self: Backpack, state: State) -> (),
	Render: (self: Backpack, state: State) -> (),
	Close: (self: Backpack) -> (),
	IsOpen: (self: Backpack) -> boolean,
}

local Backpack = {}

local function titleBar(window: Frame, onClose: () -> ()): (TextLabel, Frame)
	local colors = Theme.Colors
	Parts.Label(window, {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.fromOffset(26, 34),
		Size = UDim2.fromOffset(300, 28),
		Text = "BACKPACK",
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	local count = Parts.Label(window, {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -82, 0, 26),
		Size = UDim2.fromOffset(200, 14),
		Text = "",
		TextColor3 = colors.Muted,
		TextXAlignment = Enum.TextXAlignment.Right,
	})
	local track: Frame = Make("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -82, 0, 44),
		Size = UDim2.fromOffset(200, 8),
		BackgroundColor3 = colors.Ink,
		Parent = window,
	}, {
		Make("UICorner", { CornerRadius = UDim.new(1, 0) }),
	})
	local fill: Frame = Make("Frame", {
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = colors.Gold,
		Parent = track,
	}, {
		Make("UICorner", { CornerRadius = UDim.new(1, 0) }),
	})
	local close: TextButton = Make("TextButton", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(1, -38, 0, 34),
		Size = UDim2.fromOffset(38, 38),
		BackgroundColor3 = colors.Section,
		AutoButtonColor = false,
		Text = "",
		Parent = window,
	}, {
		Make("UICorner", { CornerRadius = UDim.new(0, 10) }),
		Make("UIStroke", { Thickness = 1, Color = colors.Edge }),
	})
	Parts.Label(close, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.45, 0.45),
		Text = "✕",
		TextColor3 = colors.Muted,
	})
	close.Activated:Connect(onClose)
	return count, fill
end

function Backpack.new(actions: Actions): Backpack
	local colors = Theme.Colors
	local layer = Root.Layer("Menu")
	local backdrop: TextButton = Make("TextButton", {
		Name = "Backdrop",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = colors.Ink,
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Text = "",
		Visible = false,
		Parent = layer,
	})
	backdrop.Activated:Connect(actions.OnClose)

	local design = Theme.Backpack.Design
	-- Canvas carries Fit's UIScale; the panel inside carries the open/close pop.
	local canvas: Frame = Make("Frame", {
		Name = "Window",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(design.X, design.Y),
		BackgroundTransparency = 1,
		Visible = false,
		ZIndex = 2,
		Parent = layer,
	})
	Fit.Attach(canvas, design, Theme.Backpack.HeightShare)
	local window: Frame = Make("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = colors.Panel,
		Parent = canvas,
	}, {
		Make("UICorner", { CornerRadius = UDim.new(0, 22) }),
		Make("UIStroke", { Thickness = 2, Color = colors.Edge }),
	})
	local pop: UIScale = Make("UIScale", { Parent = window })
	local count, fill = titleBar(window, actions.OnClose)
	local deckRow = DeckRow.new(window, DECK_Y, { OnSlot = actions.OnSlot, OnEquipBest = actions.OnEquipBest })

	local cardsBox = Parts.Section(window, CARDS_Y, design.Y - CARDS_Y - 20, "CARDS")
	local list: ScrollingFrame = Make("ScrollingFrame", {
		Position = UDim2.fromOffset(12, 40),
		Size = UDim2.new(1, -24, 1, -48),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 5,
		ScrollBarImageColor3 = colors.Edge,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		ScrollingDirection = Enum.ScrollingDirection.Y,
		Parent = cardsBox,
	})
	local collection = Collection.new(list, actions.OnCard)
	local blur: BlurEffect = Make("BlurEffect", { Size = 0, Enabled = false, Parent = Lighting })

	local open = false
	local self = {} :: Backpack

	local function render(state: State, animate: boolean)
		local total = #Catalog.All()
		local have = 0
		for _, card in Catalog.All() do
			if (state.Owned[card.Id] or 0) > 0 then
				have += 1
			end
		end
		count.Text = `COLLECTION {have}/{total}`
		Motion.Tween(fill, 0.4, { Size = UDim2.fromScale(have / math.max(total, 1), 1) })
		deckRow:Render(state.Deck, state.Owned)
		collection:Render(state, animate)
	end

	function self.Open(_: Backpack, state: State)
		render(state, true)
		list.CanvasPosition = Vector2.zero
		open = true
		backdrop.Visible = true
		canvas.Visible = true
		blur.Enabled = true
		Motion.Tween(backdrop, OPEN_SECONDS, { BackgroundTransparency = BACKDROP })
		Motion.Tween(blur, OPEN_SECONDS, { Size = BLUR })
		Motion.Pop(pop, 0.88, 1, OPEN_SECONDS + 0.1)
	end

	function self.Render(_: Backpack, state: State)
		if open then
			render(state, false)
		end
	end

	function self.Close(_: Backpack)
		if not open then
			return
		end
		open = false
		Motion.Tween(backdrop, 0.2, { BackgroundTransparency = 1 })
		Motion.Tween(blur, 0.2, { Size = 0 })
		Motion.Tween(pop, 0.2, { Scale = 0.88 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In).Completed:Once(function()
			if not open then
				backdrop.Visible = false
				canvas.Visible = false
				blur.Enabled = false
			end
		end)
	end

	function self.IsOpen(_: Backpack): boolean
		return open
	end

	return self
end

return table.freeze(Backpack)
