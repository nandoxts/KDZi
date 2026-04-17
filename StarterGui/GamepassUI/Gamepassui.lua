--[[
GamePass UI — MamboKings
Dark theme · ModalManager · ThemeConfig · Mobile ready
]]

local Players            = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local TweenService       = game:GetService("TweenService")
local UserInputService   = game:GetService("UserInputService")

local player = Players.LocalPlayer

local Configuration    = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("Configuration"))
local THEME            = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("ThemeConfig"))
local Notify           = require(ReplicatedStorage:WaitForChild("Systems"):WaitForChild("NotificationSystem"):WaitForChild("NotificationSystem"))
local UI               = require(ReplicatedStorage:WaitForChild("Systems"):WaitForChild("UI"):WaitForChild("Helpers"))
local ModernScrollbar  = require(ReplicatedStorage:WaitForChild("Systems"):WaitForChild("UI"):WaitForChild("Components"):WaitForChild("ModernScrollbar"))
local SearchModern     = require(ReplicatedStorage:WaitForChild("Systems"):WaitForChild("UI"):WaitForChild("Components"):WaitForChild("SearchModern"))
local ModalManager     = require(ReplicatedStorage:WaitForChild("Systems"):WaitForChild("UI"):WaitForChild("Modal"):WaitForChild("ModalManager"))

local ROBUX    = utf8.char(0xE002)
local TW_FAST  = TweenInfo.new(0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local TW_SLIDE = TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

-- ══════════════════════════════════════
--  RESPONSIVE
-- ══════════════════════════════════════
local IS_MOBILE = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local CARD_H   = IS_MOBILE and 120 or 136
local ICON_S   = IS_MOBILE and 72 or 96
local TITLE_SZ = IS_MOBILE and 22 or 28
local BTN_H    = IS_MOBILE and 34 or 38
local BTN_W    = IS_MOBILE and 100 or 120
local PAD      = IS_MOBILE and 10 or 14
local CORNER   = 12

-- ══════════════════════════════════════
--  THEME
-- ══════════════════════════════════════
local T = {
	bg       = THEME.bg,
	card     = THEME.card,
	elevated = THEME.elevated,
	subtle   = THEME.subtle,
	text     = THEME.text,
	dim      = THEME.dim,
	muted    = THEME.muted,
	stroke   = THEME.stroke,
	accent   = THEME.accent,
	success  = THEME.success,
	danger   = THEME.danger,
}

local function stroked(parent, thickness, color, transparency)
	local s = Instance.new("UIStroke")
	s.Thickness = thickness or 1
	s.Color = color or T.stroke
	s.Transparency = transparency or 0.4
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = parent
	return s
end

local function rounded(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or CORNER)
	c.Parent = parent
	return c
end

-- ══════════════════════════════════════
--  GAMEPASSES DATA
-- ══════════════════════════════════════
local PASS_META = {
	VIP  = { color = Color3.fromRGB(255, 175, 25), order = 1, desc = "Acceso VIP exclusivo · Zonas premium · Etiqueta VIP" },
}

local DISPLAY_NAMES = {
	CAMINO = "Camino",
	CAMINO_AL_CIELO = "Camino",
	TARIMA = "Tarima",
}

local GAMEPASSES = {}
for name, data in pairs(Configuration.Gamepasses) do
	if data.state == false then
		continue
	end

	local meta = PASS_META[name] or {
		color = data.color or T.accent,
		order = data.order or 99,
		desc = data.desc or "",
	}
	table.insert(GAMEPASSES, {
		name = DISPLAY_NAMES[name] or name:gsub("_", " "), gid = data.id, devId = data.devId,
		color = meta.color, order = meta.order, desc = meta.desc,
		price = 0, icon = "", owned = false,
	})
end
table.sort(GAMEPASSES, function(a, b) return a.order < b.order end)

-- ══════════════════════════════════════
--  MODAL (CanvasGroup)
-- ══════════════════════════════════════
local screenGui = UI.make("ScreenGui", {
	Name              = "GamepassUI",
	ResetOnSpawn      = false,
	IgnoreGuiInset    = true,
	ZIndexBehavior    = Enum.ZIndexBehavior.Sibling,
	Parent            = player:WaitForChild("PlayerGui"),
})

local modal = ModalManager.new({
	screenGui   = screenGui,
	panelName   = "GamepassUI",
	panelWidth  = IS_MOBILE and 360 or 460,
	panelHeight = IS_MOBILE and 520 or 580,
	cornerRadius = 14,
	enableBlur  = true,
	blurSize    = 14,
	isMobile    = IS_MOBILE,
})

local canvas = modal:getCanvas()

-- ══════════════════════════════════════
--  HEADER
-- ══════════════════════════════════════
local HEADER_H = IS_MOBILE and 46 or 50

local header = UI.make("Frame", {
	Size             = UDim2.new(1, 0, 0, HEADER_H),
	BackgroundColor3 = T.card,
	BackgroundTransparency = 0,
	BorderSizePixel  = 0,
	ZIndex           = 110,
	Parent           = canvas,
})

UI.make("Frame", {
	Size             = UDim2.new(1, 0, 0, 1),
	Position         = UDim2.new(0, 0, 1, 0),
	BackgroundColor3 = T.stroke,
	BackgroundTransparency = 0.4,
	BorderSizePixel  = 0,
	ZIndex           = 111,
	Parent           = header,
})

UI.label({
	size     = UDim2.new(1, -20, 1, 0),
	pos      = UDim2.new(0, 18, 0, 0),
	text     = "ZONAS Y GAMEPASSES",
	color    = T.text,
	textSize = IS_MOBILE and 16 or 19,
	font     = Enum.Font.GothamBlack,
	z        = 111,
	parent   = header,
})

-- ══════════════════════════════════════
--  CARD SCROLL
-- ══════════════════════════════════════
local CONTENT_Y = HEADER_H + 6

local scroll = UI.make("ScrollingFrame", {
	Name                  = "CardScroll",
	Size                  = UDim2.new(1, -20, 1, -(CONTENT_Y + 6)),
	Position              = UDim2.new(0, 10, 0, CONTENT_Y),
	BackgroundTransparency = 1,
	BorderSizePixel       = 0,
	ScrollBarThickness    = 0,
	AutomaticCanvasSize   = Enum.AutomaticSize.Y,
	CanvasSize            = UDim2.new(0, 0, 0, 0),
	ZIndex                = 105,
	Parent                = canvas,
})
UI.make("UIListLayout", {
	Padding             = UDim.new(0, IS_MOBILE and 8 or 10),
	SortOrder           = Enum.SortOrder.LayoutOrder,
	HorizontalAlignment = Enum.HorizontalAlignment.Center,
	Parent              = scroll,
})
UI.make("UIPadding", {
	PaddingTop    = UDim.new(0, 6),
	PaddingBottom = UDim.new(0, 10),
	Parent        = scroll,
})

ModernScrollbar.setup(scroll, canvas, THEME, {
	transparency = 0.45, offset = 0, zIndex = 300,
})

-- ══════════════════════════════════════
--  GIFT OVERLAY
-- ══════════════════════════════════════
local renderGiftRows  -- forward declaration
local giftOverlay = UI.make("Frame", {
	Name             = "GiftOverlay",
	Size             = UDim2.new(1, 0, 1, 0),
	Position         = UDim2.new(1, 0, 0, 0),
	BackgroundTransparency = 1,
	BorderSizePixel  = 0,
	ClipsDescendants = true,
	ZIndex           = 120,
	Parent           = canvas,
})
rounded(giftOverlay, 14)
giftOverlay.Visible = false

local giftHeader = UI.make("Frame", {
	Size             = UDim2.new(1, 0, 0, HEADER_H),
	BackgroundColor3 = T.card,
	BackgroundTransparency = 0,
	BorderSizePixel  = 0,
	ZIndex           = 121,
	Parent           = giftOverlay,
})
UI.make("Frame", {
	Size             = UDim2.new(1, 0, 0, 1),
	Position         = UDim2.new(0, 0, 1, 0),
	BackgroundColor3 = T.stroke,
	BackgroundTransparency = 0.4,
	BorderSizePixel  = 0,
	ZIndex           = 122,
	Parent           = giftHeader,
})

local backBtn, _backIcon = UI.outlinedCircleBtn(giftHeader, {
	size     = IS_MOBILE and 30 or 34,
	icon     = UI.ICONS.BACK,
	theme    = { stroke = T.stroke, bg = T.bg, accent = T.accent },
	zIndex   = 122,
	position = UDim2.new(0, 10, 0.5, IS_MOBILE and -15 or -17),
	name     = "BackBtn",
})

local giftTitle = UI.label({
	size     = UDim2.new(1, -60, 1, 0),
	pos      = UDim2.new(0, 50, 0, 0),
	text     = "Regalar",
	color    = T.text,
	textSize = IS_MOBILE and 15 or 17,
	font     = Enum.Font.GothamBold,
	truncate = Enum.TextTruncate.AtEnd,
	z        = 122,
	parent   = giftHeader,
})

-- Search
local SEARCH_H = IS_MOBILE and 36 or 40
local searchContainer, searchInput = SearchModern.new(giftOverlay, {
	placeholder = "Buscar jugador...",
	onSearch    = function(txt) if renderGiftRows then renderGiftRows(txt) end end,
	size        = UDim2.new(1, -20, 0, SEARCH_H),
	bg          = T.elevated,
	corner      = 8,
	z           = 121,
	isMobile    = IS_MOBILE,
})
searchContainer.Position = UDim2.new(0, 10, 0, HEADER_H + 6)

local GIFT_CONTENT_Y = HEADER_H + SEARCH_H + 14
local giftScroll = UI.make("ScrollingFrame", {
	Name                  = "GiftScroll",
	Size                  = UDim2.new(1, -20, 1, -(GIFT_CONTENT_Y + 4)),
	Position              = UDim2.new(0, 10, 0, GIFT_CONTENT_Y),
	BackgroundTransparency = 1,
	BorderSizePixel       = 0,
	ScrollBarThickness    = 0,
	AutomaticCanvasSize   = Enum.AutomaticSize.Y,
	CanvasSize            = UDim2.new(0, 0, 0, 0),
	ZIndex                = 121,
	Parent                = giftOverlay,
})
UI.make("UIListLayout", {
	Padding   = UDim.new(0, 6),
	SortOrder = Enum.SortOrder.LayoutOrder,
	Parent    = giftScroll,
})
UI.make("UIPadding", {
	PaddingTop    = UDim.new(0, 4),
	PaddingBottom = UDim.new(0, 10),
	Parent        = giftScroll,
})

ModernScrollbar.setup(giftScroll, giftOverlay, THEME, {
	transparency = 0.45, offset = -4, zIndex = 300,
})

-- ══════════════════════════════════════
--  REMOTES
-- ══════════════════════════════════════
local GiftingRemote, GetPlayersWithoutItem, OwnershipRemote, OwnershipUpdated
local sliding = false
local slideToList    -- Forward declaration
local refreshGiftList -- Forward declaration
local currentGiftPlayers = {}

task.spawn(function()
	pcall(function()
		local rg = ReplicatedStorage:WaitForChild("RemotesGlobal", 5)
		local gf = rg:WaitForChild("Gamepass Gifting", 5)
		local remotes = gf:WaitForChild("Remotes", 5)
		GiftingRemote   = remotes:WaitForChild("Gifting", 5)
		OwnershipRemote = remotes:WaitForChild("Ownership", 5)
		if GiftingRemote then
			GiftingRemote.OnClientEvent:Connect(function(eventType, msg)
				if eventType == "Purchase" then
					refreshGiftList()
					Notify:Success("Regalo entregado", msg or "Pase otorgado correctamente", 3)
				elseif eventType == "Error" then
					Notify:Error("Error", msg or "No se pudo completar", 3)
				end
			end)
		end
	end)
	pcall(function()
		local rg = ReplicatedStorage:WaitForChild("RemotesGlobal", 5)
		local sf = rg:WaitForChild("ShopGifting", 10)
		if sf then
			GetPlayersWithoutItem = sf:WaitForChild("GetPlayersWithoutItem", 10)
			OwnershipUpdated      = sf:WaitForChild("OwnershipUpdated", 10)
		end
	end)
end)

-- ══════════════════════════════════════
--  GIFT SLIDE
-- ══════════════════════════════════════
local selectedGiftItem = nil
local currentGiftRef = nil

slideToList = function()
	if sliding then return end
	sliding = true
	scroll.Position = UDim2.new(1, 0, 0, CONTENT_Y)
	scroll.Visible  = true
	TweenService:Create(giftOverlay, TW_SLIDE, { Position = UDim2.new(1, 0, 0, 0) }):Play()
	TweenService:Create(scroll,      TW_SLIDE, { Position = UDim2.new(0, 10, 0, CONTENT_Y) }):Play()
	task.delay(0.28, function()
		giftOverlay.Visible  = false
		giftOverlay.Position = UDim2.new(1, 0, 0, 0)
		sliding              = false
	end)
end

refreshGiftList = function()
	if not selectedGiftItem or not giftOverlay.Visible then return end
	task.spawn(function()
		if not GetPlayersWithoutItem then return end
		local ok, result = pcall(function()
			return GetPlayersWithoutItem:InvokeServer("gamepass", selectedGiftItem.gid)
		end)
		if ok and result and result.success then
			currentGiftPlayers = result.players or {}
			renderGiftRows(searchInput and searchInput.Text or "")
		end
	end)
end

renderGiftRows = function(filter)
	for _, c in ipairs(giftScroll:GetChildren()) do
		if c:IsA("Frame") or c:IsA("TextLabel") then c:Destroy() end
	end

	local filterLower = (filter or ""):lower()
	local filtered = {}
	for _, pData in ipairs(currentGiftPlayers) do
		if filterLower == ""
			or (pData.displayName or ""):lower():find(filterLower, 1, true)
			or (pData.username or ""):lower():find(filterLower, 1, true)
		then
			table.insert(filtered, pData)
		end
	end

	if #filtered == 0 then
		UI.label({
			size = UDim2.new(1, 0, 0, 40),
			text = filterLower ~= "" and 'Sin resultados para "' .. filter .. '"' or "No hay jugadores disponibles",
			color = T.muted, textSize = 14, font = Enum.Font.GothamBold,
			alignX = Enum.TextXAlignment.Center, z = 122, parent = giftScroll,
		})
		return
	end

	local gp = currentGiftRef
	for i, pData in ipairs(filtered) do
		local row = UI.make("Frame", {
			Name             = "Player_" .. i,
			Size             = UDim2.new(1, 0, 0, IS_MOBILE and 54 or 60),
			BackgroundColor3 = T.card,
			BackgroundTransparency = 0,
			BorderSizePixel  = 0,
			LayoutOrder      = i,
			ZIndex           = 122,
			Parent           = giftScroll,
		})
		rounded(row, 10)
		stroked(row, 1, T.stroke, 0.5)

		local avSize = IS_MOBILE and 38 or 44
		local av = UI.make("ImageLabel", {
			Name             = "Avatar",
			Size             = UDim2.new(0, avSize, 0, avSize),
			Position         = UDim2.new(0, 10, 0.5, -avSize / 2),
			BackgroundColor3 = T.elevated,
			Image            = "rbxthumb://type=AvatarHeadShot&id=" .. pData.userId .. "&w=150&h=150",
			BorderSizePixel  = 0,
			ZIndex           = 123,
			Parent           = row,
		})
		rounded(av, avSize / 2)

		UI.label({
			size     = UDim2.new(1, -(avSize + 30 + (IS_MOBILE and 78 or 90)), 1, 0),
			pos      = UDim2.new(0, avSize + 18, 0, 0),
			text     = pData.displayName or pData.username,
			color    = T.text,
			textSize = IS_MOBILE and 13 or 15,
			font     = Enum.Font.GothamBold,
			truncate = Enum.TextTruncate.AtEnd,
			z        = 123,
			parent   = row,
		})

		local gBtnW = IS_MOBILE and 70 or 82
		local gBtnH = IS_MOBILE and 30 or 34
		local giftPlayerBtn = UI.make("TextButton", {
			Name             = "GiftBtn",
			Size             = UDim2.new(0, gBtnW, 0, gBtnH),
			Position         = UDim2.new(1, -(gBtnW + 10), 0.5, -gBtnH / 2),
			BackgroundColor3 = gp and gp.color or T.accent,
			BackgroundTransparency = 0,
			Text             = "REGALAR",
			TextColor3       = Color3.fromRGB(10, 10, 10),
			TextSize         = IS_MOBILE and 11 or 13,
			Font             = Enum.Font.GothamBold,
			AutoButtonColor  = false,
			BorderSizePixel  = 0,
			ZIndex           = 123,
			Parent           = row,
		})
		rounded(giftPlayerBtn, 8)

		local sent = false
		giftPlayerBtn.MouseButton1Click:Connect(function()
			if sent or not GiftingRemote or not selectedGiftItem then return end
			sent = true
			giftPlayerBtn.Text = "..."
			TweenService:Create(giftPlayerBtn, TW_FAST, { BackgroundTransparency = 0.4 }):Play()
			GiftingRemote:FireServer(
				{ selectedGiftItem.gid, selectedGiftItem.devId },
				pData.userId, pData.username, player.UserId
			)
			Notify:Info("Procesando regalo", "Completando transaccion...", 2)
		end)

		giftPlayerBtn.MouseEnter:Connect(function()
			if not sent then TweenService:Create(giftPlayerBtn, TW_FAST, { BackgroundTransparency = 0.2 }):Play() end
		end)
		giftPlayerBtn.MouseLeave:Connect(function()
			if not sent then TweenService:Create(giftPlayerBtn, TW_FAST, { BackgroundTransparency = 0 }):Play() end
		end)
		row.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
				TweenService:Create(row, TW_FAST, { BackgroundColor3 = T.elevated }):Play()
			end
		end)
		row.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
				TweenService:Create(row, TW_FAST, { BackgroundColor3 = T.card }):Play()
			end
		end)
	end
end

local function slideToGift(gp)
	if sliding then return end
	sliding = true
	selectedGiftItem = gp
	currentGiftRef = gp
	currentGiftPlayers = {}
	giftTitle.Text = "Regalar " .. gp.name
	searchInput.Text = ""

	for _, c in ipairs(giftScroll:GetChildren()) do
		if c:IsA("Frame") or c:IsA("TextLabel") then c:Destroy() end
	end
	UI.label({
		size = UDim2.new(1, 0, 0, 40), text = "Cargando jugadores...",
		color = T.muted, textSize = 14, font = Enum.Font.GothamBold,
		alignX = Enum.TextXAlignment.Center, z = 122, parent = giftScroll,
	})

	giftOverlay.Position = UDim2.new(1, 0, 0, 0)
	giftOverlay.Visible  = true
	TweenService:Create(scroll,       TW_SLIDE, { Position = UDim2.new(-1, 0, 0, CONTENT_Y) }):Play()
	TweenService:Create(giftOverlay,  TW_SLIDE, { Position = UDim2.new(0, 0, 0, 0) }):Play()
	task.delay(0.28, function()
		scroll.Visible  = false
		scroll.Position = UDim2.new(0, 10, 0, CONTENT_Y)
		sliding         = false
	end)

	task.spawn(function()
		if not GetPlayersWithoutItem then
			renderGiftRows("")
			return
		end
		local ok, result = pcall(function()
			return GetPlayersWithoutItem:InvokeServer("gamepass", gp.gid)
		end)
		if ok and result and result.success then
			currentGiftPlayers = result.players or {}
		end
		renderGiftRows("")
	end)
end

backBtn.MouseButton1Click:Connect(slideToList)

-- ══════════════════════════════════════
--  GAMEPASS CARDS
-- ══════════════════════════════════════
local cardRefs = {}

for i, gp in ipairs(GAMEPASSES) do
	task.spawn(function()
		local ok, info = pcall(function()
			return MarketplaceService:GetProductInfo(gp.gid, Enum.InfoType.GamePass)
		end)
		if ok and info then
			gp.price = info.PriceInRobux or 0
			if info.IconImageAssetId then gp.icon = "rbxassetid://" .. info.IconImageAssetId end
			local ref = cardRefs[gp.gid]
			if ref then
				if ref.priceLabel then ref.priceLabel.Text = ROBUX .. " " .. tostring(gp.price) end
				if ref.iconImage and gp.icon ~= "" then ref.iconImage.Image = gp.icon end
			end
		end
	end)

	local card = UI.make("Frame", {
		Name             = "Card_" .. gp.name,
		Size             = UDim2.new(1, 0, 0, CARD_H),
		BackgroundColor3 = T.card,
		BackgroundTransparency = 0,
		BorderSizePixel  = 0,
		LayoutOrder      = i,
		ZIndex           = 106,
		Parent           = scroll,
	})
	rounded(card, CORNER)
	stroked(card, 1, T.stroke, 0.4)

	-- Icono
	local iconFrame = UI.make("Frame", {
		Size             = UDim2.new(0, ICON_S, 0, ICON_S),
		Position         = UDim2.new(0, PAD + 8, 0.5, -ICON_S / 2),
		BackgroundColor3 = T.elevated,
		BackgroundTransparency = 0,
		BorderSizePixel  = 0,
		ZIndex           = 107,
		Parent           = card,
	})
	rounded(iconFrame, ICON_S / 2)
	stroked(iconFrame, 1, gp.color, 0.5)

	local iconImage = UI.make("ImageLabel", {
		Size                  = UDim2.new(1, -8, 1, -8),
		Position              = UDim2.new(0, 4, 0, 4),
		BackgroundTransparency = 1,
		Image                 = "",
		ScaleType             = Enum.ScaleType.Fit,
		ZIndex                = 108,
		Parent                = iconFrame,
	})
	rounded(iconImage, ICON_S / 2)

	-- Textos
	local TEXT_X = PAD + 8 + ICON_S + 12
	UI.label({
		size     = UDim2.new(1, -(TEXT_X + BTN_W + PAD * 2), 0, 26),
		pos      = UDim2.new(0, TEXT_X, 0, IS_MOBILE and 12 or 16),
		text     = gp.name,
		color    = gp.color,
		textSize = TITLE_SZ,
		font     = Enum.Font.GothamBlack,
		truncate = Enum.TextTruncate.AtEnd,
		z = 107, parent = card,
	})
	UI.label({
		size     = UDim2.new(1, -(TEXT_X + BTN_W + PAD * 2), 0, IS_MOBILE and 26 or 32),
		pos      = UDim2.new(0, TEXT_X, 0, IS_MOBILE and 40 or 46),
		text     = gp.desc,
		color    = T.muted,
		textSize = IS_MOBILE and 11 or 13,
		font     = Enum.Font.GothamMedium,
		wrap     = true,
		z = 107, parent = card,
	})
	local priceLabel = UI.label({
		size     = UDim2.new(0, 140, 0, 22),
		pos      = UDim2.new(0, TEXT_X, 0, IS_MOBILE and 68 or 84),
		text     = ROBUX .. " ...",
		color    = T.dim,
		textSize = IS_MOBILE and 17 or 20,
		font     = Enum.Font.GothamBold,
		z = 107, parent = card,
	})

	-- Botones
	local BTN_GAP = 6

	local buyBtn = UI.make("TextButton", {
		Name             = "BuyBtn",
		Size             = UDim2.new(0, BTN_W, 0, BTN_H),
		Position         = UDim2.new(1, -(BTN_W + PAD), 0.5, -(BTN_H + BTN_GAP / 2)),
		BackgroundColor3 = gp.color,
		BackgroundTransparency = 0,
		Text             = ROBUX .. " COMPRAR",
		TextColor3       = Color3.fromRGB(10, 10, 10),
		TextSize         = IS_MOBILE and 12 or 14,
		Font             = Enum.Font.GothamBold,
		AutoButtonColor  = false,
		BorderSizePixel  = 0,
		ZIndex           = 108,
		Parent           = card,
	})
	rounded(buyBtn, 8)

	local giftBtn = UI.make("TextButton", {
		Name             = "GiftBtn",
		Size             = UDim2.new(0, BTN_W, 0, BTN_H),
		Position         = UDim2.new(1, -(BTN_W + PAD), 0.5, BTN_GAP / 2),
		BackgroundColor3 = T.elevated,
		BackgroundTransparency = 0,
		Text             = "REGALAR",
		TextColor3       = T.text,
		TextSize         = IS_MOBILE and 12 or 14,
		Font             = Enum.Font.GothamBold,
		AutoButtonColor  = false,
		BorderSizePixel  = 0,
		ZIndex           = 108,
		Parent           = card,
	})
	rounded(giftBtn, 8)
	stroked(giftBtn, 1, T.stroke, 0.4)

	cardRefs[gp.gid] = {
		card = card, buyBtn = buyBtn, giftBtn = giftBtn,
		priceLabel = priceLabel, iconImage = iconImage,
	}

	buyBtn.MouseButton1Click:Connect(function()
		if gp.owned then Notify:Info("Game Pass", "Ya tienes este pase", 2); return end
		pcall(function() MarketplaceService:PromptGamePassPurchase(player, gp.gid) end)
	end)
	giftBtn.MouseButton1Click:Connect(function() slideToGift(gp) end)

	buyBtn.MouseEnter:Connect(function()
		if not gp.owned then TweenService:Create(buyBtn, TW_FAST, { BackgroundTransparency = 0.2 }):Play() end
	end)
	buyBtn.MouseLeave:Connect(function()
		if not gp.owned then TweenService:Create(buyBtn, TW_FAST, { BackgroundTransparency = 0 }):Play() end
	end)
	giftBtn.MouseEnter:Connect(function()
		TweenService:Create(giftBtn, TW_FAST, { BackgroundColor3 = T.subtle }):Play()
	end)
	giftBtn.MouseLeave:Connect(function()
		TweenService:Create(giftBtn, TW_FAST, { BackgroundColor3 = T.elevated }):Play()
	end)
	card.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			TweenService:Create(card, TW_FAST, { BackgroundColor3 = T.elevated }):Play()
		end
	end)
	card.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			TweenService:Create(card, TW_FAST, { BackgroundColor3 = T.card }):Play()
		end
	end)
end

-- ══════════════════════════════════════
--  MARK OWNED
-- ══════════════════════════════════════
local function markOwned(gid)
	for _, gp in ipairs(GAMEPASSES) do
		if gp.gid == gid then gp.owned = true end
	end
	local ref = cardRefs[gid]
	if ref then
		ref.buyBtn.Text       = "ADQUIRIDO"
		ref.buyBtn.TextColor3 = Color3.fromRGB(10, 10, 10)
		TweenService:Create(ref.buyBtn, TW_FAST, {
			BackgroundColor3       = T.success,
			BackgroundTransparency = 0,
		}):Play()
	end
end

task.spawn(function()
	task.wait(1.5)
	for _, gp in ipairs(GAMEPASSES) do
		task.spawn(function()
			local owned = false
			if OwnershipRemote then
				local ok, res = pcall(function() return OwnershipRemote:InvokeServer(gp.gid) end)
				owned = ok and res or false
			else
				local ok, res = pcall(function()
					return MarketplaceService:UserOwnsGamePassAsync(player.UserId, gp.gid)
				end)
				owned = ok and res or false
			end
			if owned then markOwned(gp.gid) end
		end)
	end
end)

local selfPurchased = {}

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(plr, passId, bought)
	if plr ~= player or not bought then return end
	selfPurchased[passId] = true
	markOwned(passId)
end)

task.spawn(function()
	task.wait(2)
	if OwnershipUpdated then
		OwnershipUpdated.OnClientEvent:Connect(function(data)
			if data.type == "gamepass" and data.userId == player.UserId then
				if selfPurchased[data.itemId] then
					selfPurchased[data.itemId] = nil
					return
				end
				markOwned(data.itemId)
				Notify:Success("Recibiste un pase", "Alguien te regalo un Game Pass", 3)
			elseif data.type == "gamepass" and giftOverlay.Visible
				and selectedGiftItem and data.itemId == selectedGiftItem.gid then
				refreshGiftList()
			end
		end)
	end
end)

-- ══════════════════════════════════════
--  EXPONER _G (para GlobalModalManager)
-- ══════════════════════════════════════
_G.OpenGamepassUI = function()
	if not modal:isModalOpen() then
		modal:open()
	end
end

_G.CloseGamepassUI = function()
	if modal:isModalOpen() then
		modal:close()
	end
end
