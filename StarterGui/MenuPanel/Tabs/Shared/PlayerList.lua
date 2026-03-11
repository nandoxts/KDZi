--[[
	PlayerList.lua - Lista de usuarios con scroll virtual
	Usa Card.lua directamente (sin PlayerListCard intermedio).
	Decorations: avatar, premium badge, online indicator.
]]

local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local THEME          = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("ThemeConfig"))
local UI             = require(ReplicatedStorage:WaitForChild("Core"):WaitForChild("UI"))
local Card           = require(script.Parent:WaitForChild("Card"))
local ModernScrollbar = require(ReplicatedStorage:WaitForChild("UIComponents"):WaitForChild("ModernScrollbar"))
local SearchModern   = require(ReplicatedStorage:WaitForChild("UIComponents"):WaitForChild("SearchModern"))

local PlayerList = {}
PlayerList.__index = PlayerList

-- ═══════════════════════  CONSTANTES  ═══════════════════════
local CARD_HEIGHT    = 62
local CARD_PADDING   = 6
local HEADER_HEIGHT  = 44
local SEARCH_HEIGHT  = 36
local PREMIUM_ICON   = "rbxassetid://13600832988"

local TWEEN_FAST = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

-- ═══════════════════════  HELPERS  ═══════════════════════════
local function getAvatarUrl(userId)
	return string.format(
		"https://www.roblox.com/headshot-thumbnail/image?userId=%d&width=150&height=150&format=png",
		userId
	)
end

local function addOnlineIndicator(cardObj)
	local dot = Instance.new("Frame")
	dot.Name             = "OnlineIndicator"
	dot.Size             = UDim2.new(0, 10, 0, 10)
	dot.Position         = UDim2.new(1, -4, 1, -4)
	dot.AnchorPoint      = Vector2.new(1, 1)
	dot.BackgroundColor3 = Color3.fromRGB(40, 200, 80)
	dot.BorderSizePixel  = 0
	dot.ZIndex           = 4
	dot.Parent           = cardObj.imageFrame

	Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
	local s = Instance.new("UIStroke")
	s.Color     = THEME.card
	s.Thickness = 2
	s.Parent    = dot
end

local function addPremiumBadge(cardObj)
	local nameLabel = cardObj.nameLabel
	local tx = CARD_HEIGHT + 10

	local badge = Instance.new("ImageLabel")
	badge.Name                   = "PremiumBadge"
	badge.Size                   = UDim2.new(0, 14, 0, 14)
	badge.BackgroundTransparency = 1
	badge.Image                  = PREMIUM_ICON
	badge.ScaleType              = Enum.ScaleType.Fit
	badge.ZIndex                 = 3
	badge.Parent                 = cardObj.card

	local function updatePos()
		local tw = nameLabel.TextBounds.X
		local mx = nameLabel.AbsoluteSize.X
		badge.Position = UDim2.new(0, tx + math.min(tw + 5, mx), 0, 14)
	end
	nameLabel:GetPropertyChangedSignal("TextBounds"):Connect(updatePos)
	task.defer(updatePos)
end

-- ═══════════════════════  CONSTRUCTOR  ═══════════════════════
function PlayerList.new(config)
	local self = setmetatable({}, PlayerList)

	self.parent        = config.parent
	self.title         = config.title
	self.emptyText     = config.emptyText or "No hay jugadores"
	self.accentColor   = config.accentColor or THEME.accent
	self.buttonText    = config.buttonText or "REGALAR"
	self.buttonIcon    = config.buttonIcon
	self.onAction      = config.onAction
	self.showSearch    = config.showSearch ~= false
	self.showTitle     = config.showTitle
	if self.showTitle == nil then self.showTitle = self.title ~= nil end
	self.showCount     = config.showCount
	if self.showCount == nil then self.showCount = self.showTitle end
	self.headerHeight  = config.headerHeight or HEADER_HEIGHT
	self.searchGap     = config.searchGap
	self.searchOptions = config.searchOptions or {}
	if self.searchGap == nil then self.searchGap = 8 end

	self.players         = config.players or {}
	self.filteredPlayers  = {}
	self.searchQuery      = ""
	self.isLoading        = false

	self.cards       = {}
	self.connections  = {}

	self:_build()
	self:_applyFilter()

	return self
end

-- ═══════════════════════  BUILD UI  ══════════════════════════
function PlayerList:_build()
	self.root = Instance.new("Frame")
	self.root.Name                   = "PlayerListRoot"
	self.root.Size                   = UDim2.new(1, 0, 1, 0)
	self.root.BackgroundTransparency = 1
	self.root.BorderSizePixel        = 0
	self.root.ClipsDescendants       = true
	self.root.Parent                 = self.parent

	local contentY = 0

	-- Header
	if self.showTitle or self.showCount then
		local header = Instance.new("Frame")
		header.Name                   = "Header"
		header.Size                   = UDim2.new(1, 0, 0, self.headerHeight)
		header.BackgroundTransparency = 1
		header.Parent                 = self.root

		if self.showTitle then
			local tl = Instance.new("TextLabel")
			tl.Name                   = "Title"
			tl.Size                   = UDim2.new(self.showCount and 0.7 or 1, self.showCount and -8 or -12, 1, 0)
			tl.Position               = UDim2.new(0, 8, 0, 0)
			tl.BackgroundTransparency = 1
			tl.Font                   = Enum.Font.GothamBold
			tl.TextSize               = 14
			tl.TextColor3             = THEME.text
			tl.TextXAlignment         = Enum.TextXAlignment.Left
			tl.Text                   = self.title
			tl.Parent                 = header
			self.titleLabel = tl
		end

		if self.showCount then
			self.countLabel = Instance.new("TextLabel")
			self.countLabel.Name                   = "Count"
			self.countLabel.Size                   = self.showTitle and UDim2.new(0.3, -8, 1, 0) or UDim2.new(1, -8, 1, 0)
			self.countLabel.Position               = self.showTitle and UDim2.new(0.7, 0, 0, 0) or UDim2.new(0, 0, 0, 0)
			self.countLabel.BackgroundTransparency = 1
			self.countLabel.Font                   = Enum.Font.Gotham
			self.countLabel.TextSize               = 12
			self.countLabel.TextColor3             = THEME.muted
			self.countLabel.TextXAlignment         = Enum.TextXAlignment.Right
			self.countLabel.Text                   = "0 jugadores"
			self.countLabel.Parent                 = header
		end

		contentY = self.headerHeight
	end

	-- Search
	if self.showSearch then
		local so = self.searchOptions
		local searchSize   = so.size or UDim2.new(1, -16, 0, SEARCH_HEIGHT)
		local searchHeight = searchSize.Y.Offset ~= 0 and searchSize.Y.Offset or SEARCH_HEIGHT

		local searchContainer, searchInput = SearchModern.new(self.root, {
			placeholder = so.placeholder or "Buscar jugador...",
			size        = searchSize,
			bg          = so.bg or THEME.card,
			corner      = so.corner,
			z           = so.z or 105,
			inputName   = so.inputName or "PlayerSearchInput",
			textSize    = so.textSize,
			isMobile    = so.isMobile,
		})
		searchContainer.Position = so.position or UDim2.new(0, 8, 0, contentY)
		self.searchInput = searchInput

		local debounce = false
		local conn = searchInput:GetPropertyChangedSignal("Text"):Connect(function()
			if debounce then return end
			debounce = true
			task.delay(0.2, function()
				self.searchQuery = searchInput.Text:lower()
				self:_applyFilter()
				debounce = false
			end)
		end)
		table.insert(self.connections, conn)

		contentY = contentY + searchHeight + self.searchGap
	end

	-- Scroll
	self.scroll = Instance.new("ScrollingFrame")
	self.scroll.Name                      = "PlayersScroll"
	self.scroll.Size                      = UDim2.new(1, -8, 1, -(contentY + 8))
	self.scroll.Position                  = UDim2.new(0, 4, 0, contentY + 4)
	self.scroll.BackgroundTransparency    = 1
	self.scroll.BorderSizePixel           = 0
	self.scroll.ScrollBarThickness        = 0
	self.scroll.ScrollBarImageTransparency = 1
	self.scroll.CanvasSize                = UDim2.new(0, 0, 0, 0)
	self.scroll.ClipsDescendants          = true
	self.scroll.AutomaticCanvasSize       = Enum.AutomaticSize.Y
	self.scroll.Parent                    = self.root

	Instance.new("UIListLayout", self.scroll).Padding   = UDim.new(0, CARD_PADDING)
	self.scroll:FindFirstChildOfClass("UIListLayout").SortOrder = Enum.SortOrder.LayoutOrder

	local pad = Instance.new("UIPadding")
	pad.PaddingLeft   = UDim.new(0, 4)
	pad.PaddingRight  = UDim.new(0, 4)
	pad.PaddingTop    = UDim.new(0, 4)
	pad.PaddingBottom = UDim.new(0, 8)
	pad.Parent        = self.scroll

	ModernScrollbar.setup(self.scroll, self.root, THEME, {
		transparency = 0.3, offset = -4, zIndex = 110,
	})

	-- Loading
	self.loadingFrame = Instance.new("Frame")
	self.loadingFrame.Name                   = "LoadingFrame"
	self.loadingFrame.Size                   = UDim2.new(1, 0, 0, 60)
	self.loadingFrame.BackgroundTransparency = 1
	self.loadingFrame.Visible                = false
	self.loadingFrame.Parent                 = self.scroll

	local lt = Instance.new("TextLabel")
	lt.Size = UDim2.new(1, 0, 1, 0); lt.BackgroundTransparency = 1
	lt.Font = Enum.Font.Gotham; lt.TextSize = 15; lt.TextColor3 = THEME.muted
	lt.Text = "Cargando jugadores..."; lt.Parent = self.loadingFrame

	-- Empty
	self.emptyFrame = Instance.new("Frame")
	self.emptyFrame.Name                   = "EmptyFrame"
	self.emptyFrame.Size                   = UDim2.new(1, 0, 0, 80)
	self.emptyFrame.BackgroundTransparency = 1
	self.emptyFrame.Visible                = false
	self.emptyFrame.Parent                 = self.scroll

	local et = Instance.new("TextLabel")
	et.Name = "EmptyText"
	et.Size = UDim2.new(1, -16, 0, 24); et.Position = UDim2.new(0, 8, 0, 26)
	et.BackgroundTransparency = 1; et.Font = Enum.Font.GothamBold
	et.TextSize = 15; et.TextColor3 = THEME.muted
	et.TextXAlignment = Enum.TextXAlignment.Center
	et.Text = self.emptyText; et.Parent = self.emptyFrame
end

-- ═══════════════════════  FILTER  ════════════════════════════
function PlayerList:_applyFilter()
	self.filteredPlayers = {}
	for _, p in ipairs(self.players) do
		if self.searchQuery == ""
			or (p.username    and p.username:lower():find(self.searchQuery, 1, true))
			or (p.displayName and p.displayName:lower():find(self.searchQuery, 1, true))
		then
			table.insert(self.filteredPlayers, p)
		end
	end
	self:_renderCards()
	self:_updateCount()
end

-- ═══════════════════════  RENDER  ════════════════════════════
function PlayerList:_clearCards()
	for _, c in pairs(self.cards) do c:destroy() end
	self.cards = {}
end

function PlayerList:_renderCards()
	self:_clearCards()
	self.loadingFrame.Visible = false
	self.emptyFrame.Visible   = false

	if self.isLoading then
		self.loadingFrame.Visible = true
		return
	end
	if #self.filteredPlayers == 0 then
		self.emptyFrame.Visible = true
		return
	end

	for i, pd in ipairs(self.filteredPlayers) do
		local displayName = pd.displayName or pd.username or ""
		local username    = pd.username or ""

		local cardObj = Card.new(self.scroll, {
			instanceName = "PlayerCard_" .. pd.userId,
			image        = getAvatarUrl(pd.userId),
			name         = displayName,
			subtitle     = "@" .. username,
			buttonIcon   = self.buttonIcon,
			
			layoutOrder  = i,
			onAction     = function()
				if self.onAction then
					self.onAction(pd.userId, username, displayName, pd)
				end
			end,
		})

		-- Online indicator
		if Players:GetPlayerByUserId(pd.userId) then
			addOnlineIndicator(cardObj)
		end

		-- Premium badge
		if pd.isPremium then
			addPremiumBadge(cardObj)
		end

		table.insert(self.cards, cardObj)
	end
end

function PlayerList:_updateCount()
	if not self.countLabel then return end
	local total    = #self.players
	local filtered = #self.filteredPlayers
	if self.searchQuery ~= "" then
		self.countLabel.Text = string.format("%d/%d encontrados", filtered, total)
	else
		self.countLabel.Text = string.format("%d jugador%s", total, total == 1 and "" or "es")
	end
end

-- ═══════════════════════  PUBLIC  ════════════════════════════
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
	if self.titleLabel then self.titleLabel.Text = title end
end

function PlayerList:setEmptyText(text)
	self.emptyText = text
	local ef = self.root and self.root:FindFirstChild("EmptyFrame")
	if ef then
		local et = ef:FindFirstChild("EmptyText")
		if et then et.Text = text end
	end
end

function PlayerList:setAccentColor(color)
	self.accentColor = color
end

function PlayerList:clearSearch()
	if self.searchInput then self.searchInput.Text = "" end
	self.searchQuery = ""
	self:_applyFilter()
end

function PlayerList:getRoot()
	return self.root
end

function PlayerList:destroy()
	for _, conn in ipairs(self.connections) do conn:Disconnect() end
	self.connections = {}
	self:_clearCards()
	if self.root then self.root:Destroy(); self.root = nil end
end

return PlayerList
