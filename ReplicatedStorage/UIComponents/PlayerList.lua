--[[
	═══════════════════════════════════════════════════════════════
	PlayerList.lua - Lista de usuarios con scroll virtual
	═══════════════════════════════════════════════════════════════
	• Carga y muestra lista de jugadores (ej: sin un gamepass)
	• Buscador integrado
	• Scroll virtual para rendimiento
	• Diseño consistente con MembersList
	
	Uso:
		local list = PlayerList.new({
			parent = frame,
			title = "Usuarios sin VIP",
			emptyText = "Todos tienen este pase",
			accentColor = Color3.fromRGB(255, 140, 40),
			buttonText = "REGALAR",
			buttonIcon = "🎁",
			players = { {userId=1, username="user", displayName="User"}, ... },
			onAction = function(userId, username, displayName) ... end,
		})
		
		list:setPlayers(newPlayersArray)
		list:setLoading(true/false)
		list:destroy()
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local THEME = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("ThemeConfig"))
local PlayerListCard = require(script.Parent:WaitForChild("PlayerListCard"))
local ModernScrollbar = require(script.Parent:WaitForChild("ModernScrollbar"))
local SearchModern = require(script.Parent:WaitForChild("SearchModern"))

local PlayerList = {}
PlayerList.__index = PlayerList

-- ═══════════════════════════════════════════════════════════════
-- CONSTANTES
-- ═══════════════════════════════════════════════════════════════
local CARD_HEIGHT = 56
local CARD_PADDING = 6
local HEADER_HEIGHT = 44
local SEARCH_HEIGHT = 36
local VISIBLE_BUFFER = 3

local TWEEN_FAST = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

-- ═══════════════════════════════════════════════════════════════
-- CONSTRUCTOR
-- ═══════════════════════════════════════════════════════════════
function PlayerList.new(config)
	local self = setmetatable({}, PlayerList)
	
	self.parent = config.parent
	self.title = config.title or "Jugadores"
	self.emptyText = config.emptyText or "No hay jugadores"
	self.accentColor = config.accentColor or THEME.accent
	self.buttonText = config.buttonText or "REGALAR"
	self.buttonIcon = config.buttonIcon or "🎁"
	self.onAction = config.onAction
	self.showSearch = config.showSearch ~= false
	
	self.players = config.players or {}
	self.filteredPlayers = {}
	self.searchQuery = ""
	self.isLoading = false
	
	self.cards = {}
	self.connections = {}
	
	self:_build()
	self:_applyFilter()
	
	return self
end

-- ═══════════════════════════════════════════════════════════════
-- BUILD UI
-- ═══════════════════════════════════════════════════════════════
function PlayerList:_build()
	-- Root container
	self.root = Instance.new("Frame")
	self.root.Name = "PlayerListRoot"
	self.root.Size = UDim2.new(1, 0, 1, 0)
	self.root.BackgroundTransparency = 1
	self.root.BorderSizePixel = 0
	self.root.ClipsDescendants = true
	self.root.Parent = self.parent
	
	local contentY = 0
	
	-- Header con título y contador
	if self.title then
		local header = Instance.new("Frame")
		header.Name = "Header"
		header.Size = UDim2.new(1, -16, 0, HEADER_HEIGHT)
		header.Position = UDim2.new(0, 8, 0, 0)
		header.BackgroundTransparency = 1
		header.Parent = self.root
		
		local titleLabel = Instance.new("TextLabel")
		titleLabel.Name = "Title"
		titleLabel.Size = UDim2.new(0.7, 0, 1, 0)
		titleLabel.BackgroundTransparency = 1
		titleLabel.Font = Enum.Font.GothamBold
		titleLabel.TextSize = 14
		titleLabel.TextColor3 = THEME.text
		titleLabel.TextXAlignment = Enum.TextXAlignment.Left
		titleLabel.Text = self.title
		titleLabel.Parent = header
		
		self.countLabel = Instance.new("TextLabel")
		self.countLabel.Name = "Count"
		self.countLabel.Size = UDim2.new(0.3, 0, 1, 0)
		self.countLabel.Position = UDim2.new(0.7, 0, 0, 0)
		self.countLabel.BackgroundTransparency = 1
		self.countLabel.Font = Enum.Font.Gotham
		self.countLabel.TextSize = 12
		self.countLabel.TextColor3 = THEME.muted
		self.countLabel.TextXAlignment = Enum.TextXAlignment.Right
		self.countLabel.Text = "0 jugadores"
		self.countLabel.Parent = header
		
		contentY = HEADER_HEIGHT
	end
	
	-- Search bar
	if self.showSearch then
		local searchContainer, searchInput = SearchModern.new(self.root, {
			placeholder = "Buscar jugador...",
			size = UDim2.new(1, -16, 0, SEARCH_HEIGHT),
			bg = THEME.card,
			corner = 8,
			z = 105,
			inputName = "PlayerSearchInput",
		})
		searchContainer.Position = UDim2.new(0, 8, 0, contentY)
		
		self.searchInput = searchInput
		
		local searchDebounce = false
		local conn = searchInput:GetPropertyChangedSignal("Text"):Connect(function()
			if searchDebounce then return end
			searchDebounce = true
			task.delay(0.2, function()
				self.searchQuery = searchInput.Text:lower()
				self:_applyFilter()
				searchDebounce = false
			end)
		end)
		table.insert(self.connections, conn)
		
		contentY = contentY + SEARCH_HEIGHT + 8
	end
	
	-- Scroll container
	self.scroll = Instance.new("ScrollingFrame")
	self.scroll.Name = "PlayersScroll"
	self.scroll.Size = UDim2.new(1, -8, 1, -(contentY + 8))
	self.scroll.Position = UDim2.new(0, 4, 0, contentY + 4)
	self.scroll.BackgroundTransparency = 1
	self.scroll.BorderSizePixel = 0
	self.scroll.ScrollBarThickness = 0
	self.scroll.ScrollBarImageTransparency = 1
	self.scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	self.scroll.ClipsDescendants = true
	self.scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	self.scroll.Parent = self.root
	
	-- Layout
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, CARD_PADDING)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = self.scroll
	
	-- Padding
	local scrollPad = Instance.new("UIPadding")
	scrollPad.PaddingLeft = UDim.new(0, 4)
	scrollPad.PaddingRight = UDim.new(0, 4)
	scrollPad.PaddingTop = UDim.new(0, 4)
	scrollPad.PaddingBottom = UDim.new(0, 8)
	scrollPad.Parent = self.scroll
	
	-- Modern scrollbar
	ModernScrollbar.setup(self.scroll, self.root, THEME, {
		transparency = 0.3,
		offset = -4,
		zIndex = 110
	})
	
	-- Loading indicator
	self.loadingFrame = Instance.new("Frame")
	self.loadingFrame.Name = "LoadingFrame"
	self.loadingFrame.Size = UDim2.new(1, 0, 0, 60)
	self.loadingFrame.BackgroundTransparency = 1
	self.loadingFrame.Visible = false
	self.loadingFrame.Parent = self.scroll
	
	local loadingText = Instance.new("TextLabel")
	loadingText.Name = "LoadingText"
	loadingText.Size = UDim2.new(1, 0, 1, 0)
	loadingText.BackgroundTransparency = 1
	loadingText.Font = Enum.Font.Gotham
	loadingText.TextSize = 13
	loadingText.TextColor3 = THEME.muted
	loadingText.Text = "⏳ Cargando jugadores..."
	loadingText.Parent = self.loadingFrame
	
	-- Empty state
	self.emptyFrame = Instance.new("Frame")
	self.emptyFrame.Name = "EmptyFrame"
	self.emptyFrame.Size = UDim2.new(1, 0, 0, 80)
	self.emptyFrame.BackgroundTransparency = 1
	self.emptyFrame.Visible = false
	self.emptyFrame.Parent = self.scroll
	
	local emptyIcon = Instance.new("TextLabel")
	emptyIcon.Name = "EmptyIcon"
	emptyIcon.Size = UDim2.new(1, 0, 0, 30)
	emptyIcon.Position = UDim2.new(0, 0, 0, 10)
	emptyIcon.BackgroundTransparency = 1
	emptyIcon.Font = Enum.Font.Gotham
	emptyIcon.TextSize = 24
	emptyIcon.TextColor3 = THEME.muted
	emptyIcon.Text = "👥"
	emptyIcon.Parent = self.emptyFrame
	
	local emptyText = Instance.new("TextLabel")
	emptyText.Name = "EmptyText"
	emptyText.Size = UDim2.new(1, 0, 0, 20)
	emptyText.Position = UDim2.new(0, 0, 0, 45)
	emptyText.BackgroundTransparency = 1
	emptyText.Font = Enum.Font.Gotham
	emptyText.TextSize = 12
	emptyText.TextColor3 = THEME.muted
	emptyText.Text = self.emptyText
	emptyText.Parent = self.emptyFrame
end

-- ═══════════════════════════════════════════════════════════════
-- FILTERING
-- ═══════════════════════════════════════════════════════════════
function PlayerList:_applyFilter()
	-- Filter players by search query
	self.filteredPlayers = {}
	
	for _, p in ipairs(self.players) do
		local matchesSearch = self.searchQuery == "" 
			or (p.username and p.username:lower():find(self.searchQuery, 1, true))
			or (p.displayName and p.displayName:lower():find(self.searchQuery, 1, true))
		
		if matchesSearch then
			table.insert(self.filteredPlayers, p)
		end
	end
	
	self:_renderCards()
	self:_updateCount()
end

-- ═══════════════════════════════════════════════════════════════
-- RENDERING
-- ═══════════════════════════════════════════════════════════════
function PlayerList:_clearCards()
	for _, card in pairs(self.cards) do
		card:destroy()
	end
	self.cards = {}
end

function PlayerList:_renderCards()
	self:_clearCards()
	
	-- Hide loading/empty while rendering
	self.loadingFrame.Visible = false
	self.emptyFrame.Visible = false
	
	if self.isLoading then
		self.loadingFrame.Visible = true
		return
	end
	
	if #self.filteredPlayers == 0 then
		self.emptyFrame.Visible = true
		return
	end
	
	-- Create cards for filtered players
	for i, playerData in ipairs(self.filteredPlayers) do
		local card = PlayerListCard.new(self.scroll, {
			userId = playerData.userId,
			username = playerData.username,
			displayName = playerData.displayName,
			buttonText = self.buttonText,
			buttonIcon = self.buttonIcon,
			accentColor = self.accentColor,
			layoutOrder = i,
			onAction = function(userId, username, displayName)
				if self.onAction then
					self.onAction(userId, username, displayName, playerData)
				end
			end
		})
		
		table.insert(self.cards, card)
	end
end

function PlayerList:_updateCount()
	if self.countLabel then
		local total = #self.players
		local filtered = #self.filteredPlayers
		
		if self.searchQuery ~= "" then
			self.countLabel.Text = string.format("%d/%d encontrados", filtered, total)
		else
			self.countLabel.Text = string.format("%d jugador%s", total, total == 1 and "" or "es")
		end
	end
end

-- ═══════════════════════════════════════════════════════════════
-- PUBLIC METHODS
-- ═══════════════════════════════════════════════════════════════
function PlayerList:setPlayers(players)
	self.players = players or {}
	self:_applyFilter()
end

function PlayerList:addPlayer(playerData)
	table.insert(self.players, playerData)
	self:_applyFilter()
end

function PlayerList:removePlayer(userId)
	for i, p in ipairs(self.players) do
		if p.userId == userId then
			table.remove(self.players, i)
			break
		end
	end
	self:_applyFilter()
end

function PlayerList:setLoading(loading)
	self.isLoading = loading
	self:_renderCards()
end

function PlayerList:setTitle(title)
	self.title = title
	-- Update title label if exists
	local header = self.root:FindFirstChild("Header")
	if header then
		local titleLabel = header:FindFirstChild("Title")
		if titleLabel then
			titleLabel.Text = title
		end
	end
end

function PlayerList:setEmptyText(text)
	self.emptyText = text
	local emptyFrame = self.root:FindFirstChild("EmptyFrame")
	if emptyFrame then
		local emptyText = emptyFrame:FindFirstChild("EmptyText")
		if emptyText then
			emptyText.Text = text
		end
	end
end

function PlayerList:setAccentColor(color)
	self.accentColor = color
	for _, card in pairs(self.cards) do
		card:setAccentColor(color)
	end
end

function PlayerList:clearSearch()
	if self.searchInput then
		self.searchInput.Text = ""
	end
	self.searchQuery = ""
	self:_applyFilter()
end

function PlayerList:getRoot()
	return self.root
end

function PlayerList:destroy()
	for _, conn in ipairs(self.connections) do
		conn:Disconnect()
	end
	self.connections = {}
	
	self:_clearCards()
	
	if self.root then
		self.root:Destroy()
		self.root = nil
	end
end

return PlayerList
