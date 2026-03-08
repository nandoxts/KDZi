--[[
	MusicTab.lua — ModuleScript v7.0 PRO DESIGN
	2 Sub-tabs: ACTUAL | DJ
	
	ACTUAL:
	  ✦ Cover GRANDE con gradiente negro + nombre encima con sombra
	  ✦ Barra de progreso + tiempos
	  ✦ REPRODUCCIÓN: input grande + círculo cooldown
	  ✦ LISTA: cola de canciones actual
	
	DJ:
	  ✦ Lista de DJs con covers + gradiente
	  ✦ Click en DJ → vista interna con sus canciones + búsqueda
	  ✦ Botón volver a lista de DJs
	
	Toda la lógica de remotes mantenida
]]

local MusicTab = {}

function MusicTab.build(parent, THEME, sharedState)
	-- ═══════════════════════════════════════
	-- SERVICIOS
	-- ═══════════════════════════════════════
	local Players            = game:GetService("Players")
	local ReplicatedStorage  = game:GetService("ReplicatedStorage")
	local TweenService       = game:GetService("TweenService")
	local RunService         = game:GetService("RunService")
	local MarketplaceService = game:GetService("MarketplaceService")
	local SoundService       = game:GetService("SoundService")

	local player = Players.LocalPlayer

	-- ═══════════════════════════════════════
	-- MÓDULOS
	-- ═══════════════════════════════════════
	local UI = require(ReplicatedStorage:WaitForChild("Core"):WaitForChild("UI"))
	local ModernScrollbar = require(ReplicatedStorage:WaitForChild("UIComponents"):WaitForChild("ModernScrollbar"))

	local MusicConfig = nil
	pcall(function()
		MusicConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("MusicSystemConfig"))
	end)
	local isAdmin = MusicConfig and MusicConfig.IsAdmin and MusicConfig.IsAdmin(player) or false

	-- ═══════════════════════════════════════
	-- REMOTES
	-- ═══════════════════════════════════════
	local R = {}
	task.spawn(function()
		local rg = ReplicatedStorage:WaitForChild("RemotesGlobal", 8)
		if not rg then return end
		local UI_F = rg:FindFirstChild("UI")
		local PB   = rg:FindFirstChild("MusicPlayback")
		local MQ   = rg:FindFirstChild("MusicQueue")
		local ML   = rg:FindFirstChild("MusicLibrary")
		if UI_F then R.Update     = UI_F:FindFirstChild("UpdateUI") end
		if PB   then R.Next       = PB:FindFirstChild("NextSong"); R.ChangeVol = PB:FindFirstChild("ChangeVolume") end
		if MQ   then
			R.Add            = MQ:FindFirstChild("AddToQueue")
			R.AddResponse    = MQ:FindFirstChild("AddToQueueResponse")
			R.Remove         = MQ:FindFirstChild("RemoveFromQueue")
			R.RemoveResponse = MQ:FindFirstChild("RemoveFromQueueResponse")
			R.Clear          = MQ:FindFirstChild("ClearQueue")
			R.ClearResponse  = MQ:FindFirstChild("ClearQueueResponse")
		end
		if ML then
			R.GetDJs       = ML:FindFirstChild("GetDJs")
			R.GetSongsByDJ = ML:FindFirstChild("GetSongsByDJ")
			R.GetSongRange = ML:FindFirstChild("GetSongRange")
			R.SearchSongs  = ML:FindFirstChild("SearchSongs")
		end
		if R.GetDJs then R.GetDJs:FireServer() end
	end)

	-- ═══════════════════════════════════════
	-- CONSTANTES
	-- ═══════════════════════════════════════
	local TW          = TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	local CARD_H      = 58
	local CARD_PAD    = 2
	local VISIBLE_BUF = 3
	local MAX_POOL    = 30
	local SCROLL_DEB  = 0.05
	local SKIP_PRODUCT = 3468988018
	local SKIP_CD     = 3
	local VOL_STEP    = 0.05
	local MAX_VOL     = (MusicConfig and MusicConfig.PLAYBACK and MusicConfig.PLAYBACK.MaxVolume) or 1
	local MIN_VOL     = (MusicConfig and MusicConfig.PLAYBACK and MusicConfig.PLAYBACK.MinVolume) or 0
	local DEF_VOL     = (MusicConfig and MusicConfig.PLAYBACK and MusicConfig.PLAYBACK.DefaultVolume) or 0.5
	local UPDATE_THROTTLE = 0.15

	-- ═══════════════════════════════════════
	-- ESTADO
	-- ═══════════════════════════════════════
	local playQueue       = {}
	local currentSong     = nil
	local currentSoundObj = nil
	local allDJs          = {}
	local selectedDJ      = nil
	local selectedDJInfo  = nil
	local currentVolume   = DEF_VOL
	local lastSkipTime    = -math.huge
	local lastUpdateTime  = 0
	local pendingUpdate   = nil
	local pendingCardSongIds = {}
	local avatarCache     = {}

	-- DJ song pools
	local djCardPool      = {}
	local djCardsIndex    = {}
	local djScrollDebThread = nil
	local djScrollConn    = nil

	local progressConn    = nil
	local cooldownActive  = false

	local virtualScrollState = {
		totalSongs      = 0,
		songData        = {},
		searchResults   = {},
		isSearching     = false,
		searchQuery     = "",
		pendingRequests = {},
	}

	-- ═══════════════════════════════════════
	-- HELPERS
	-- ═══════════════════════════════════════
	local function tween(obj, t, props)
		TweenService:Create(obj, TweenInfo.new(t, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), props):Play()
	end

	local function make(class, props)
		local i = Instance.new(class)
		for k, v in pairs(props) do
			if k ~= "Parent" then i[k] = v end
		end
		if props.Parent then i.Parent = props.Parent end
		return i
	end

	local function rounded(obj, r)
		make("UICorner", { CornerRadius = UDim.new(0, r), Parent = obj })
	end

	local function formatTime(s)
		return string.format("%d:%02d", math.floor(s / 60), math.floor(s % 60))
	end

	local function isInQueue(id)
		for _, s in ipairs(playQueue) do
			if s.id == id then return true end
		end
		return false
	end

	-- ═══════════════════════════════════════════════════════
	-- SUB-TAB BAR (ACTUAL | DJ)
	-- ═══════════════════════════════════════════════════════
	local SUB_TAB_H = 38

	local subTabBar = make("Frame", {
		Size                   = UDim2.new(1, 0, 0, SUB_TAB_H),
		BackgroundColor3       = THEME.bg,
		BackgroundTransparency = 0,
		BorderSizePixel        = 0,
		ZIndex                 = 215,
		Name                   = "SubTabBar",
		Parent                 = parent,
	})

	make("UIListLayout", {
		FillDirection       = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Left,
		VerticalAlignment   = Enum.VerticalAlignment.Center,
		Padding             = UDim.new(0, 4),
		Parent              = subTabBar,
	})
	make("UIPadding", {
		PaddingLeft  = UDim.new(0, 10),
		PaddingRight = UDim.new(0, 10),
		Parent       = subTabBar,
	})

	local activeSubTab = "actual"

	local subTabActualBtn = make("TextButton", {
		Size                   = UDim2.new(0, 90, 0, 30),
		BackgroundColor3       = THEME.accent,
		BackgroundTransparency = 0.1,
		Font                   = Enum.Font.GothamBold,
		TextSize               = 12,
		TextColor3             = THEME.text,
		Text                   = "ACTUAL",
		BorderSizePixel        = 0,
		AutoButtonColor        = false,
		ZIndex                 = 216,
		LayoutOrder            = 1,
		Parent                 = subTabBar,
	})
	rounded(subTabActualBtn, 8)

	local subTabDJBtn = make("TextButton", {
		Size                   = UDim2.new(0, 90, 0, 30),
		BackgroundColor3       = THEME.card or Color3.fromRGB(35, 35, 35),
		BackgroundTransparency = 0.2,
		Font                   = Enum.Font.GothamBold,
		TextSize               = 12,
		TextColor3             = THEME.muted,
		Text                   = "DJ",
		BorderSizePixel        = 0,
		AutoButtonColor        = false,
		ZIndex                 = 216,
		LayoutOrder            = 2,
		Parent                 = subTabBar,
	})
	rounded(subTabDJBtn, 8)

	-- Línea sutil
	make("Frame", {
		Size                   = UDim2.new(1, 0, 0, 1),
		Position               = UDim2.new(0, 0, 0, SUB_TAB_H),
		BackgroundColor3       = THEME.stroke or Color3.fromRGB(45, 45, 45),
		BackgroundTransparency = 0.6,
		ZIndex                 = 215,
		Parent                 = parent,
	})

	-- ═══════════════════════════════════════════════════════
	-- CONTENT AREA
	-- ═══════════════════════════════════════════════════════
	local CONTENT_TOP = SUB_TAB_H + 1

	-- ═══════════════════════════════════════════════════════
	-- ████ TAB: ACTUAL ████
	-- ═══════════════════════════════════════════════════════
	local actualPanel = make("ScrollingFrame", {
		Size                   = UDim2.new(1, 0, 1, -CONTENT_TOP),
		Position               = UDim2.new(0, 0, 0, CONTENT_TOP),
		BackgroundTransparency = 1,
		BorderSizePixel        = 0,
		ScrollBarThickness     = 0,
		ClipsDescendants       = true,
		CanvasSize             = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize    = Enum.AutomaticSize.Y,
		ZIndex                 = 210,
		Name                   = "ActualPanel",
		Visible                = true,
		Parent                 = parent,
	})
	ModernScrollbar.setup(actualPanel, parent, THEME, { transparency = 0.45, offset = -4 })

	make("UIListLayout", {
		Padding   = UDim.new(0, 0),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent    = actualPanel,
	})

	-- ── 1) COVER GRANDE con gradiente + nombre encima ──
	local COVER_H = 230
	local coverSection = make("Frame", {
		Size                   = UDim2.new(1, 0, 0, COVER_H),
		BackgroundColor3       = Color3.fromRGB(18, 18, 18),
		BackgroundTransparency = 0,
		ClipsDescendants       = true,
		LayoutOrder            = 1,
		ZIndex                 = 211,
		Name                   = "CoverSection",
		Parent                 = actualPanel,
	})

	local coverImage = make("ImageLabel", {
		Size                   = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ScaleType              = Enum.ScaleType.Crop,
		Image                  = "",
		ImageTransparency      = 0,
		ZIndex                 = 212,
		Name                   = "CoverImage",
		Parent                 = coverSection,
	})

	local coverPlaceholder = make("TextLabel", {
		Size                   = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Font                   = Enum.Font.GothamBold,
		TextSize               = 52,
		TextColor3             = THEME.accent,
		Text                   = "♪",
		ZIndex                 = 211,
		Name                   = "Placeholder",
		Parent                 = coverSection,
	})

	-- Gradiente negro desde abajo
	local gradientOverlay = make("Frame", {
		Size                   = UDim2.new(1, 0, 0.55, 0),
		Position               = UDim2.new(0, 0, 0.45, 0),
		BackgroundColor3       = Color3.new(0, 0, 0),
		BackgroundTransparency = 0,
		ZIndex                 = 213,
		Parent                 = coverSection,
	})
	make("UIGradient", {
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.35, 0.6),
			NumberSequenceKeypoint.new(0.7, 0.15),
			NumberSequenceKeypoint.new(1, 0),
		}),
		Rotation = 90,
		Parent   = gradientOverlay,
	})

	-- Título encima del cover
	local coverTitle = make("TextLabel", {
		Size                   = UDim2.new(1, -24, 0, 28),
		Position               = UDim2.new(0, 12, 1, -52),
		BackgroundTransparency = 1,
		Font                   = Enum.Font.GothamBold,
		TextSize               = 20,
		TextColor3             = Color3.new(1, 1, 1),
		Text                   = "Sin reproducción",
		TextXAlignment         = Enum.TextXAlignment.Left,
		TextTruncate           = Enum.TextTruncate.AtEnd,
		ZIndex                 = 214,
		Parent                 = coverSection,
	})

	local coverArtist = make("TextLabel", {
		Size                   = UDim2.new(1, -24, 0, 18),
		Position               = UDim2.new(0, 12, 1, -26),
		BackgroundTransparency = 1,
		Font                   = Enum.Font.GothamMedium,
		TextSize               = 13,
		TextColor3             = Color3.fromRGB(200, 200, 200),
		Text                   = "",
		TextXAlignment         = Enum.TextXAlignment.Left,
		TextTruncate           = Enum.TextTruncate.AtEnd,
		ZIndex                 = 214,
		Parent                 = coverSection,
	})

	-- ── 2) PROGRESO ──
	local progressSection = make("Frame", {
		Size                   = UDim2.new(1, 0, 0, 38),
		BackgroundTransparency = 1,
		LayoutOrder            = 2,
		ZIndex                 = 211,
		Parent                 = actualPanel,
	})

	local progressBar = make("Frame", {
		Size                   = UDim2.new(1, -24, 0, 4),
		Position               = UDim2.new(0, 12, 0, 10),
		BackgroundColor3       = Color3.fromRGB(55, 55, 55),
		BackgroundTransparency = 0,
		ZIndex                 = 212,
		Parent                 = progressSection,
	})
	rounded(progressBar, 2)

	local progressFill = make("Frame", {
		Size                   = UDim2.new(0, 0, 1, 0),
		BackgroundColor3       = THEME.accent,
		BackgroundTransparency = 0,
		ZIndex                 = 213,
		Parent                 = progressBar,
	})
	rounded(progressFill, 2)

	local timeLeft = make("TextLabel", {
		Size = UDim2.new(0.5, -12, 0, 16),
		Position = UDim2.new(0, 12, 0, 18),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold, TextSize = 12,
		TextColor3 = Color3.fromRGB(170, 170, 170),
		Text = "0:00", TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 212, Parent = progressSection,
	})

	local timeRight = make("TextLabel", {
		Size = UDim2.new(0.5, -12, 0, 16),
		Position = UDim2.new(0.5, 0, 0, 18),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold, TextSize = 12,
		TextColor3 = Color3.fromRGB(170, 170, 170),
		Text = "0:00", TextXAlignment = Enum.TextXAlignment.Right,
		ZIndex = 212, Parent = progressSection,
	})

	-- ── 3) REPRODUCCIÓN ──
	local reproSection = make("Frame", {
		Size                   = UDim2.new(1, 0, 0, 78),
		BackgroundTransparency = 1,
		LayoutOrder            = 3,
		ZIndex                 = 211,
		Parent                 = actualPanel,
	})

	make("TextLabel", {
		Size = UDim2.new(1, -24, 0, 18),
		Position = UDim2.new(0, 12, 0, 4),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold, TextSize = 11,
		TextColor3 = Color3.fromRGB(140, 140, 140),
		Text = "REPRODUCCIÓN",
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 212, Parent = reproSection,
	})

	local reproRow = make("Frame", {
		Size = UDim2.new(1, -24, 0, 42),
		Position = UDim2.new(0, 12, 0, 28),
		BackgroundTransparency = 1,
		ZIndex = 212, Parent = reproSection,
	})

	local reproInput = make("TextBox", {
		Size                   = UDim2.new(1, -52, 1, 0),
		BackgroundColor3       = Color3.fromRGB(30, 30, 30),
		BackgroundTransparency = 0,
		Font                   = Enum.Font.GothamBold,
		TextSize               = 15,
		TextColor3             = THEME.text,
		PlaceholderText        = "ID de canción...",
		PlaceholderColor3      = Color3.fromRGB(100, 100, 100),
		ClearTextOnFocus       = false,
		Text                   = "",
		ZIndex                 = 213,
		Parent                 = reproRow,
	})
	rounded(reproInput, 10)
	make("UIPadding", { PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14), Parent = reproInput })

	-- Cooldown circle
	local cooldownBtn = make("TextButton", {
		Size                   = UDim2.new(0, 42, 0, 42),
		Position               = UDim2.new(1, -42, 0, 0),
		BackgroundColor3       = Color3.fromRGB(55, 55, 55),
		BackgroundTransparency = 0,
		Font                   = Enum.Font.GothamBold,
		TextSize               = 16,
		TextColor3             = Color3.fromRGB(180, 180, 180),
		Text                   = tostring(SKIP_CD),
		BorderSizePixel        = 0,
		AutoButtonColor        = false,
		ZIndex                 = 214,
		Parent                 = reproRow,
	})
	rounded(cooldownBtn, 21)
	local cdStroke = make("UIStroke", {
		Color = Color3.fromRGB(90, 90, 90), Thickness = 2, Transparency = 0.3,
		Parent = cooldownBtn,
	})

	-- ── 4) LISTA (cola) ──
	local listaSection = make("Frame", {
		Size                   = UDim2.new(1, 0, 0, 500),
		BackgroundTransparency = 1,
		LayoutOrder            = 4,
		ZIndex                 = 211,
		Parent                 = actualPanel,
	})

	local listaLabel = make("TextLabel", {
		Size = UDim2.new(1, -24, 0, 20),
		Position = UDim2.new(0, 12, 0, 2),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold, TextSize = 11,
		TextColor3 = Color3.fromRGB(140, 140, 140),
		Text = "LISTA · 0",
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 212, Parent = listaSection,
	})

	local queueContainer = make("Frame", {
		Size = UDim2.new(1, -24, 0, 0),
		Position = UDim2.new(0, 12, 0, 28),
		BackgroundTransparency = 1,
		ZIndex = 212, Parent = listaSection,
	})
	make("UIListLayout", { Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder, Parent = queueContainer })

	local queueEmptyLbl = make("TextLabel", {
		Size = UDim2.new(1, 0, 0, 40),
		BackgroundTransparency = 1,
		Font = Enum.Font.Gotham, TextSize = 13,
		TextColor3 = Color3.fromRGB(90, 90, 90),
		Text = "La cola está vacía",
		ZIndex = 212, Visible = true, Parent = queueContainer,
	})

	-- ═══════════════════════════════════════════════════════
	-- ████ TAB: DJ ████
	-- ═══════════════════════════════════════════════════════
	local djPanel = make("Frame", {
		Size = UDim2.new(1, 0, 1, -CONTENT_TOP),
		Position = UDim2.new(0, 0, 0, CONTENT_TOP),
		BackgroundTransparency = 1, ClipsDescendants = true,
		ZIndex = 210, Visible = false, Parent = parent,
	})

	-- DJ LIST VIEW
	local djListView = make("ScrollingFrame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1, BorderSizePixel = 0,
		ScrollBarThickness = 0, ClipsDescendants = true,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ZIndex = 211, Visible = true, Parent = djPanel,
	})
	ModernScrollbar.setup(djListView, djPanel, THEME, { transparency = 0.45, offset = -4 })

	make("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = djListView })
	make("UIPadding", {
		PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10),
		PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 12),
		Parent = djListView,
	})

	-- DJ SONGS VIEW (interno)
	local djSongsView = make("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1, ClipsDescendants = true,
		ZIndex = 211, Visible = false, Parent = djPanel,
	})

	-- DJ Header
	local djHeaderH = 56
	local djHeader = make("Frame", {
		Size = UDim2.new(1, 0, 0, djHeaderH),
		BackgroundColor3 = Color3.fromRGB(22, 22, 22),
		BackgroundTransparency = 0, ZIndex = 213, Parent = djSongsView,
	})

	local djBackBtn = make("TextButton", {
		Size = UDim2.new(0, 36, 0, 36),
		Position = UDim2.new(0, 8, 0.5, -18),
		BackgroundColor3 = Color3.fromRGB(40, 40, 40),
		BackgroundTransparency = 0,
		Font = Enum.Font.GothamBold, TextSize = 16,
		TextColor3 = THEME.text, Text = "←",
		BorderSizePixel = 0, AutoButtonColor = false,
		ZIndex = 214, Parent = djHeader,
	})
	rounded(djBackBtn, 8)

	local djHeaderCover = make("ImageLabel", {
		Size = UDim2.new(0, 36, 0, 36),
		Position = UDim2.new(0, 52, 0.5, -18),
		BackgroundColor3 = Color3.fromRGB(35, 35, 35),
		BackgroundTransparency = 0,
		ScaleType = Enum.ScaleType.Crop, Image = "",
		ZIndex = 214, Parent = djHeader,
	})
	rounded(djHeaderCover, 8)

	local djHeaderName = make("TextLabel", {
		Size = UDim2.new(1, -110, 0, 20),
		Position = UDim2.new(0, 96, 0, 8),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold, TextSize = 15,
		TextColor3 = THEME.text, Text = "",
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 214, Parent = djHeader,
	})

	local djHeaderCount = make("TextLabel", {
		Size = UDim2.new(1, -110, 0, 14),
		Position = UDim2.new(0, 96, 0, 30),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamMedium, TextSize = 11,
		TextColor3 = THEME.accent, Text = "0 canciones",
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 214, Parent = djHeader,
	})

	-- Search DJ
	local djSearchBar = make("Frame", {
		Size = UDim2.new(1, -20, 0, 36),
		Position = UDim2.new(0, 10, 0, djHeaderH + 6),
		BackgroundColor3 = Color3.fromRGB(30, 30, 30),
		BackgroundTransparency = 0, ZIndex = 213, Parent = djSongsView,
	})
	rounded(djSearchBar, 10)

	make("TextLabel", {
		Size = UDim2.new(0, 28, 1, 0),
		Position = UDim2.new(0, 6, 0, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold, TextSize = 14,
		TextColor3 = Color3.fromRGB(100, 100, 100), Text = "🔍",
		ZIndex = 214, Parent = djSearchBar,
	})

	local djSearchInput = make("TextBox", {
		Size = UDim2.new(1, -38, 1, 0),
		Position = UDim2.new(0, 34, 0, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.Gotham, TextSize = 13,
		TextColor3 = THEME.text,
		PlaceholderText = "Buscar Canción",
		PlaceholderColor3 = Color3.fromRGB(100, 100, 100),
		ClearTextOnFocus = false, Text = "",
		ZIndex = 214, Parent = djSearchBar,
	})

	local djSongListTop = djHeaderH + 48
	local djSongListScroll = make("ScrollingFrame", {
		Size = UDim2.new(1, 0, 1, -djSongListTop),
		Position = UDim2.new(0, 0, 0, djSongListTop),
		BackgroundTransparency = 1, BorderSizePixel = 0,
		ScrollBarThickness = 0, ClipsDescendants = true,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		ZIndex = 212, Parent = djSongsView,
	})
	ModernScrollbar.setup(djSongListScroll, djSongsView, THEME, { transparency = 0.45, offset = -2 })

	local djSongsContainer = make("Frame", {
		Size = UDim2.fromScale(1, 0),
		BackgroundTransparency = 1, ZIndex = 213,
		Parent = djSongListScroll,
	})

	-- ═══════════════════════════════════════════════════════
	-- SUB-TAB SWITCHING
	-- ═══════════════════════════════════════════════════════
	local function switchSubTab(tab)
		activeSubTab = tab
		actualPanel.Visible = (tab == "actual")
		djPanel.Visible     = (tab == "dj")

		if tab == "actual" then
			tween(subTabActualBtn, 0.18, { BackgroundColor3 = THEME.accent, BackgroundTransparency = 0.1, TextColor3 = THEME.text })
			tween(subTabDJBtn, 0.18, { BackgroundColor3 = THEME.card or Color3.fromRGB(35,35,35), BackgroundTransparency = 0.2, TextColor3 = THEME.muted })
		else
			tween(subTabDJBtn, 0.18, { BackgroundColor3 = THEME.accent, BackgroundTransparency = 0.1, TextColor3 = THEME.text })
			tween(subTabActualBtn, 0.18, { BackgroundColor3 = THEME.card or Color3.fromRGB(35,35,35), BackgroundTransparency = 0.2, TextColor3 = THEME.muted })
		end
	end

	subTabActualBtn.MouseButton1Click:Connect(function() switchSubTab("actual") end)
	subTabDJBtn.MouseButton1Click:Connect(function() switchSubTab("dj") end)

	for _, b in ipairs({subTabActualBtn, subTabDJBtn}) do
		b.MouseEnter:Connect(function()
			if (b == subTabActualBtn and activeSubTab ~= "actual") or (b == subTabDJBtn and activeSubTab ~= "dj") then
				tween(b, 0.12, { BackgroundTransparency = 0.15 })
			end
		end)
		b.MouseLeave:Connect(function()
			if (b == subTabActualBtn and activeSubTab ~= "actual") or (b == subTabDJBtn and activeSubTab ~= "dj") then
				tween(b, 0.12, { BackgroundTransparency = 0.2 })
			end
		end)
	end

	-- ═══════════════════════════════════════════════════════
	-- VOLUMEN
	-- ═══════════════════════════════════════════════════════
	local musicGroup = SoundService:FindFirstChild("MusicSoundGroup")
	if musicGroup then currentVolume = musicGroup.Volume end

	local function applyVolume(vol)
		currentVolume = math.clamp(vol, MIN_VOL, MAX_VOL)
		if musicGroup then musicGroup.Volume = currentVolume end
		if R.ChangeVol then pcall(function() R.ChangeVol:FireServer(currentVolume) end) end
	end

	local volCheckAccum = 0
	RunService.Heartbeat:Connect(function(dt)
		volCheckAccum += dt
		if volCheckAccum < 2 then return end
		volCheckAccum = 0
		if musicGroup and sharedState then
			if sharedState.isMuted then musicGroup.Volume = 0
			elseif musicGroup.Volume ~= currentVolume then musicGroup.Volume = currentVolume end
		end
	end)

	-- ═══════════════════════════════════════════════════════
	-- REPRODUCCIÓN + COOLDOWN
	-- ═══════════════════════════════════════════════════════
	reproInput:GetPropertyChangedSignal("Text"):Connect(function()
		reproInput.Text = reproInput.Text:gsub("[^%d]", ""):sub(1, 15)
	end)

	local function startCooldownUI(seconds)
		if cooldownActive then return end
		cooldownActive = true
		local remaining = seconds
		cooldownBtn.Text = tostring(remaining)
		tween(cooldownBtn, 0.2, { BackgroundColor3 = THEME.accent })
		tween(cdStroke, 0.2, { Color = THEME.accent, Transparency = 0.1 })

		task.spawn(function()
			while remaining > 0 do
				task.wait(1)
				remaining -= 1
				if cooldownBtn and cooldownBtn.Parent then
					cooldownBtn.Text = tostring(remaining)
				end
			end
			cooldownActive = false
			if cooldownBtn and cooldownBtn.Parent then
				cooldownBtn.Text = tostring(SKIP_CD)
				tween(cooldownBtn, 0.3, { BackgroundColor3 = Color3.fromRGB(55, 55, 55) })
				tween(cdStroke, 0.3, { Color = Color3.fromRGB(90, 90, 90), Transparency = 0.3 })
			end
		end)
	end

	local function doQuickAdd()
		local songId = tonumber(reproInput.Text)
		if not songId then return end
		if cooldownActive then return end
		if R.Add then
			pcall(function() R.Add:FireServer(songId) end)
			reproInput.Text = ""
			startCooldownUI(SKIP_CD)
		end
	end

	cooldownBtn.MouseButton1Click:Connect(doQuickAdd)
	cooldownBtn.MouseEnter:Connect(function()
		if not cooldownActive then tween(cooldownBtn, 0.12, { BackgroundColor3 = Color3.fromRGB(75, 75, 75) }) end
	end)
	cooldownBtn.MouseLeave:Connect(function()
		if not cooldownActive then tween(cooldownBtn, 0.12, { BackgroundColor3 = Color3.fromRGB(55, 55, 55) }) end
	end)

	-- ═══════════════════════════════════════════════════════
	-- QUEUE CARDS (LISTA en tab ACTUAL)
	-- ═══════════════════════════════════════════════════════
	local queueCardPool = {}
	local activeQueueCards = {}

	local function createQueueCard()
		local card = make("Frame", {
			Size = UDim2.new(1, 0, 0, 58),
			BackgroundColor3 = Color3.fromRGB(26, 26, 26),
			BackgroundTransparency = 0,
			ZIndex = 213, Visible = false, Parent = queueContainer,
		})
		rounded(card, 10)

		make("ImageLabel", {
			Size = UDim2.new(0, 42, 0, 42),
			Position = UDim2.new(0, 8, 0.5, -21),
			BackgroundColor3 = Color3.fromRGB(40, 40, 40),
			BackgroundTransparency = 0,
			ScaleType = Enum.ScaleType.Crop, Image = "",
			ZIndex = 214, Name = "Cover", Parent = card,
		})
		rounded(card:FindFirstChild("Cover"), 8)

		make("TextLabel", {
			Size = UDim2.new(1, -100, 0, 20),
			Position = UDim2.new(0, 58, 0, 10),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold, TextSize = 14,
			TextColor3 = THEME.text, Text = "",
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			ZIndex = 214, Name = "NameLabel", Parent = card,
		})

		make("TextLabel", {
			Size = UDim2.new(1, -100, 0, 15),
			Position = UDim2.new(0, 58, 0, 31),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamMedium, TextSize = 11,
			TextColor3 = Color3.fromRGB(130, 130, 130), Text = "",
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			ZIndex = 214, Name = "ArtistLabel", Parent = card,
		})

		make("TextLabel", {
			Size = UDim2.new(0, 28, 0, 28),
			Position = UDim2.new(1, -36, 0.5, -14),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold, TextSize = 18,
			TextColor3 = Color3.fromRGB(180, 180, 180), Text = "▶",
			ZIndex = 214, Name = "PlayIcon", Parent = card,
		})

		if isAdmin then
			local rmBtn = make("TextButton", {
				Size = UDim2.new(0, 24, 0, 24),
				Position = UDim2.new(1, -64, 0.5, -12),
				BackgroundColor3 = Color3.fromRGB(180, 50, 50),
				BackgroundTransparency = 0.6,
				Font = Enum.Font.GothamBold, TextSize = 10,
				TextColor3 = Color3.new(1, 1, 1), Text = "✕",
				BorderSizePixel = 0, ZIndex = 215,
				Name = "RemoveBtn", Parent = card,
			})
			rounded(rmBtn, 6)
			rmBtn.MouseButton1Click:Connect(function()
				local idx = card:GetAttribute("QueueIndex")
				if idx and R.Remove then pcall(function() R.Remove:FireServer(idx) end) end
			end)
		end

		return card
	end

	local function releaseAllQueueCards()
		for _, c in ipairs(activeQueueCards) do
			c.Visible = false; c:SetAttribute("QueueIndex", nil)
		end
		activeQueueCards = {}
	end

	local function getQueueCard()
		for _, c in ipairs(queueCardPool) do if not c.Visible then return c end end
		if #queueCardPool < 20 then
			local c = createQueueCard()
			table.insert(queueCardPool, c)
			return c
		end
	end

	for _ = 1, 6 do table.insert(queueCardPool, createQueueCard()) end

	local function drawQueue()
		releaseAllQueueCards()
		local count = #playQueue
		listaLabel.Text = "LISTA · " .. count

		if count == 0 then
			queueEmptyLbl.Visible = true
			listaSection.Size = UDim2.new(1, 0, 0, 80)
			return
		end
		queueEmptyLbl.Visible = false

		for i, song in ipairs(playQueue) do
			local isActive = currentSong and song.id == currentSong.id
			local card = getQueueCard()
			if not card then break end

			card.LayoutOrder = i
			card:SetAttribute("QueueIndex", i)
			card.Visible = true
			table.insert(activeQueueCards, card)

			card.BackgroundColor3 = isActive and Color3.fromRGB(35, 30, 20) or Color3.fromRGB(26, 26, 26)

			local nl = card:FindFirstChild("NameLabel")
			if nl then nl.Text = song.name or "Desconocida"; nl.TextColor3 = isActive and THEME.accent or THEME.text end

			local al = card:FindFirstChild("ArtistLabel")
			if al then al.Text = song.artist or song.requestedBy or "" end

			local cov = card:FindFirstChild("Cover")
			if cov then cov.Image = song.djCover or "" end

			local pi = card:FindFirstChild("PlayIcon")
			if pi then pi.TextColor3 = isActive and THEME.accent or Color3.fromRGB(180, 180, 180) end
		end

		local totalH = count * (58 + 3) + 32
		listaSection.Size = UDim2.new(1, 0, 0, totalH)
	end

	-- ═══════════════════════════════════════════════════════
	-- DJ SONG CARDS (virtual scroll)
	-- ═══════════════════════════════════════════════════════
	local function createSongCard()
		local card = make("Frame", {
			Size = UDim2.new(1, -12, 0, CARD_H),
			BackgroundColor3 = Color3.fromRGB(26, 26, 26),
			BackgroundTransparency = 0,
			ZIndex = 214, Visible = false,
			Parent = djSongsContainer,
		})
		rounded(card, 10)

		local coverBg = make("ImageLabel", {
			Size = UDim2.new(0, 42, 0, 42),
			Position = UDim2.new(0, 8, 0.5, -21),
			BackgroundColor3 = Color3.fromRGB(40, 40, 40),
			BackgroundTransparency = 0,
			ScaleType = Enum.ScaleType.Crop, Image = "",
			ZIndex = 215, Name = "DJCover", Parent = card,
		})
		rounded(coverBg, 8)

		local tx = 58
		make("TextLabel", {
			Size = UDim2.new(1, -(tx + 40), 0, 20),
			Position = UDim2.new(0, tx, 0, 10),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold, TextSize = 14,
			TextColor3 = THEME.text, Text = "",
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			ZIndex = 215, Name = "NameLabel", Parent = card,
		})
		make("TextLabel", {
			Size = UDim2.new(1, -(tx + 40), 0, 14),
			Position = UDim2.new(0, tx, 0, 32),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamMedium, TextSize = 11,
			TextColor3 = Color3.fromRGB(130, 130, 130), Text = "",
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			ZIndex = 215, Name = "ArtistLabel", Parent = card,
		})

		local addBtn = make("TextButton", {
			Size = UDim2.new(0, 30, 0, 30),
			Position = UDim2.new(1, -36, 0.5, -15),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold, TextSize = 18,
			TextColor3 = Color3.fromRGB(180, 180, 180), Text = "▶",
			BorderSizePixel = 0, AutoButtonColor = false,
			ZIndex = 216, Name = "AddButton", Parent = card,
		})

		addBtn.MouseButton1Click:Connect(function()
			local songId = card:GetAttribute("SongID")
			if songId and not isInQueue(songId) and not pendingCardSongIds[songId] then
				pendingCardSongIds[songId] = true
				addBtn.Text = "…"; addBtn.TextColor3 = THEME.accent
				if R.Add then pcall(function() R.Add:FireServer(songId) end) end
			end
		end)

		card.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseMovement then
				tween(card, 0.1, { BackgroundColor3 = Color3.fromRGB(36, 36, 36) })
			end
		end)
		card.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseMovement then
				tween(card, 0.1, { BackgroundColor3 = Color3.fromRGB(26, 26, 26) })
			end
		end)

		return card
	end

	local function getCardFromPool()
		for _, c in ipairs(djCardPool) do if not c.Visible then return c end end
		if #djCardPool < MAX_POOL then
			local c = createSongCard()
			table.insert(djCardPool, c)
			return c
		end
	end

	local function releaseCard(card)
		local idx = card:GetAttribute("SongIndex")
		if idx then djCardsIndex[idx] = nil end
		card.Visible = false
		card:SetAttribute("SongIndex", nil); card:SetAttribute("SongID", nil)
	end

	local function releaseAllCards()
		djCardsIndex = {}
		for _, c in ipairs(djCardPool) do
			c.Visible = false; c:SetAttribute("SongIndex", nil); c:SetAttribute("SongID", nil)
		end
	end

	local function updateSongCard(card, data, index)
		if not card or not data then return end
		card:SetAttribute("SongIndex", index); card:SetAttribute("SongID", data.id)
		djCardsIndex[index] = card

		local cov = card:FindFirstChild("DJCover", true)
		if cov and selectedDJInfo and selectedDJInfo.cover then cov.Image = selectedDJInfo.cover end

		local nl = card:FindFirstChild("NameLabel", true)
		if nl then nl.Text = data.name or "Cargando..."; nl.TextColor3 = data.loaded and THEME.text or THEME.muted end

		local al = card:FindFirstChild("ArtistLabel", true)
		if al then al.Text = data.artist or ("ID: " .. tostring(data.id)) end

		local ab = card:FindFirstChild("AddButton", true)
		if ab then
			local inQ = isInQueue(data.id)
			local pending = pendingCardSongIds[data.id]
			if pending then ab.Text = "…"; ab.TextColor3 = THEME.accent
			elseif inQ then ab.Text = "✓"; ab.TextColor3 = THEME.success or Color3.fromRGB(40, 180, 80)
			else ab.Text = "▶"; ab.TextColor3 = Color3.fromRGB(180, 180, 180) end
		end

		card.Position = UDim2.new(0, 6, 0, (index - 1) * (CARD_H + CARD_PAD))
		card.Visible = true
	end

	local function updateVisibleCards()
		if not djSongListScroll or not djSongListScroll.Parent then return end
		local total = virtualScrollState.isSearching and #virtualScrollState.searchResults or virtualScrollState.totalSongs
		if total == 0 then releaseAllCards(); return end

		local scrollY = djSongListScroll.CanvasPosition.Y
		local vpH     = djSongListScroll.AbsoluteSize.Y
		local step    = CARD_H + CARD_PAD
		local first   = math.max(1, math.floor(scrollY / step) + 1 - VISIBLE_BUF)
		local last    = math.min(total, math.ceil((scrollY + vpH) / step) + VISIBLE_BUF)

		local totalH = total * step
		djSongsContainer.Size       = UDim2.new(1, 0, 0, totalH)
		djSongListScroll.CanvasSize = UDim2.new(0, 0, 0, totalH + 16)

		for idx, card in pairs(djCardsIndex) do
			if card and card.Visible and (idx < first or idx > last) then releaseCard(card) end
		end

		local dataSource = virtualScrollState.isSearching and virtualScrollState.searchResults or virtualScrollState.songData
		local needsFetch = {}

		for i = first, last do
			local sd = dataSource[i]
			if sd then
				local c = djCardsIndex[i] or getCardFromPool()
				if c then updateSongCard(c, sd, i) end
			elseif not virtualScrollState.isSearching then
				table.insert(needsFetch, i)
			end
		end

		if #needsFetch > 0 and not virtualScrollState.isSearching and selectedDJ then
			local mn, mx = math.huge, 0
			for _, idx in ipairs(needsFetch) do mn = math.min(mn, idx); mx = math.max(mx, idx) end
			local key = mn .. "-" .. mx
			if not virtualScrollState.pendingRequests[key] then
				virtualScrollState.pendingRequests[key] = true
				if R.GetSongRange then pcall(function() R.GetSongRange:FireServer(selectedDJ, mn, mx) end) end
			end
		end
	end

	local function connectDJScrollListener()
		if djScrollConn then djScrollConn:Disconnect() end
		djScrollConn = djSongListScroll:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
			if djScrollDebThread then return end
			djScrollDebThread = task.delay(SCROLL_DEB, function()
				djScrollDebThread = nil
				updateVisibleCards()
			end)
		end)
	end

	for _ = 1, 8 do table.insert(djCardPool, createSongCard()) end

	-- ═══════════════════════════════════════════════════════
	-- DJ LIST + SELECTION
	-- ═══════════════════════════════════════════════════════
	local function selectDJ(djName, djData)
		selectedDJ = djName; selectedDJInfo = djData
		djListView.Visible = false; djSongsView.Visible = true

		djHeaderName.Text   = djName
		djHeaderCount.Text  = (djData.songCount or 0) .. " canciones"
		djHeaderCover.Image = djData.cover or ""

		virtualScrollState.totalSongs      = djData.songCount or 0
		virtualScrollState.songData        = {}
		virtualScrollState.searchResults   = {}
		virtualScrollState.isSearching     = false
		virtualScrollState.searchQuery     = ""
		virtualScrollState.pendingRequests = {}

		djSearchInput.Text = ""
		releaseAllCards()
		djSongListScroll.CanvasPosition = Vector2.new(0, 0)

		local totalH = virtualScrollState.totalSongs * (CARD_H + CARD_PAD)
		djSongsContainer.Size       = UDim2.new(1, 0, 0, totalH)
		djSongListScroll.CanvasSize = UDim2.new(0, 0, 0, totalH + 16)

		connectDJScrollListener()
		local limit = math.min(virtualScrollState.totalSongs, 20)
		if limit > 0 and R.GetSongRange then
			pcall(function() R.GetSongRange:FireServer(djName, 1, limit) end)
		end
	end

	djBackBtn.MouseButton1Click:Connect(function()
		djSongsView.Visible = false; djListView.Visible = true
		selectedDJ = nil; selectedDJInfo = nil
	end)
	djBackBtn.MouseEnter:Connect(function() tween(djBackBtn, 0.1, { BackgroundColor3 = Color3.fromRGB(55, 55, 55) }) end)
	djBackBtn.MouseLeave:Connect(function() tween(djBackBtn, 0.1, { BackgroundColor3 = Color3.fromRGB(40, 40, 40) }) end)

	local function drawDJs()
		for _, child in pairs(djListView:GetChildren()) do
			if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then child:Destroy() end
		end

		if #allDJs == 0 then
			make("TextLabel", {
				Size = UDim2.new(1, 0, 0, 60),
				BackgroundTransparency = 1,
				Font = Enum.Font.Gotham, TextSize = 14,
				TextColor3 = Color3.fromRGB(100, 100, 100),
				Text = "Sin DJs disponibles",
				ZIndex = 213, Parent = djListView,
			})
			return
		end

		for idx, dj in ipairs(allDJs) do
			local DJ_CARD_H = 100
			local djCard = make("Frame", {
				Size = UDim2.new(1, 0, 0, DJ_CARD_H),
				BackgroundColor3 = Color3.fromRGB(25, 25, 25),
				BackgroundTransparency = 0, ClipsDescendants = true,
				ZIndex = 213, LayoutOrder = idx, Parent = djListView,
			})
			rounded(djCard, 12)

			if dj.cover and dj.cover ~= "" then
				make("ImageLabel", {
					Size = UDim2.fromScale(1, 1),
					BackgroundTransparency = 1,
					ScaleType = Enum.ScaleType.Crop,
					Image = dj.cover, ImageTransparency = 0.25,
					ZIndex = 214, Parent = djCard,
				})
			end

			local djGrad = make("Frame", {
				Size = UDim2.new(1, 0, 0.6, 0),
				Position = UDim2.new(0, 0, 0.4, 0),
				BackgroundColor3 = Color3.new(0, 0, 0),
				ZIndex = 215, Parent = djCard,
			})
			make("UIGradient", {
				Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 1),
					NumberSequenceKeypoint.new(0.4, 0.5),
					NumberSequenceKeypoint.new(1, 0.1),
				}),
				Rotation = 90, Parent = djGrad,
			})

			make("TextLabel", {
				Size = UDim2.new(1, -20, 0, 24),
				Position = UDim2.new(0, 10, 1, -46),
				BackgroundTransparency = 1,
				Font = Enum.Font.GothamBold, TextSize = 17,
				TextColor3 = Color3.new(1, 1, 1), Text = dj.name,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 216, Parent = djCard,
			})

			make("TextLabel", {
				Size = UDim2.new(1, -20, 0, 16),
				Position = UDim2.new(0, 10, 1, -22),
				BackgroundTransparency = 1,
				Font = Enum.Font.GothamMedium, TextSize = 12,
				TextColor3 = THEME.accent,
				Text = (dj.songCount or 0) .. " canciones",
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 216, Parent = djCard,
			})

			local clickBtn = make("TextButton", {
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1, Text = "",
				ZIndex = 217, Parent = djCard,
			})
			clickBtn.MouseButton1Click:Connect(function() selectDJ(dj.name, dj) end)
			clickBtn.MouseEnter:Connect(function() tween(djCard, 0.15, { BackgroundColor3 = Color3.fromRGB(35, 35, 35) }) end)
			clickBtn.MouseLeave:Connect(function() tween(djCard, 0.15, { BackgroundColor3 = Color3.fromRGB(25, 25, 25) }) end)
		end
	end

	-- ═══════════════════════════════════════════════════════
	-- DJ SEARCH
	-- ═══════════════════════════════════════════════════════
	local djSearchDeb = nil
	djSearchInput:GetPropertyChangedSignal("Text"):Connect(function()
		if not selectedDJ then return end
		if djSearchDeb then task.cancel(djSearchDeb) end
		djSearchDeb = task.delay(0.3, function()
			local query = djSearchInput.Text
			if query == "" then
				virtualScrollState.isSearching = false; virtualScrollState.searchQuery = ""; virtualScrollState.searchResults = {}
				djHeaderCount.Text = virtualScrollState.totalSongs .. " canciones"
				djSongListScroll.CanvasPosition = Vector2.new(0, 0)
				updateVisibleCards()
			else
				virtualScrollState.isSearching = true; virtualScrollState.searchQuery = query
				if R.SearchSongs then pcall(function() R.SearchSongs:FireServer(selectedDJ, query) end) end
			end
		end)
	end)

	-- ═══════════════════════════════════════════════════════
	-- PROGRESS
	-- ═══════════════════════════════════════════════════════
	local function updateProgress()
		if not currentSoundObj then currentSoundObj = workspace:FindFirstChild("QueueSound") end
		if not currentSoundObj or not currentSoundObj:IsA("Sound") then
			progressFill.Size = UDim2.new(0, 0, 1, 0)
			timeLeft.Text = "0:00"; timeRight.Text = "0:00"; return
		end
		local cur, total = currentSoundObj.TimePosition, currentSoundObj.TimeLength
		if total > 0 then
			progressFill.Size = UDim2.new(math.clamp(cur / total, 0, 1), 0, 1, 0)
			timeLeft.Text = formatTime(cur); timeRight.Text = formatTime(total)
		else
			progressFill.Size = UDim2.new(0, 0, 1, 0)
			timeLeft.Text = "0:00"; timeRight.Text = "0:00"
		end
	end

	-- ═══════════════════════════════════════════════════════
	-- COVER UPDATE
	-- ═══════════════════════════════════════════════════════
	local currentCover = ""
	local function updateCover(song)
		local cover = song and (song.djCover or "") or ""
		if cover == currentCover then return end
		currentCover = cover
		if cover == "" then
			tween(coverImage, 0.25, { ImageTransparency = 1 })
			coverPlaceholder.Visible = true
		else
			coverPlaceholder.Visible = false
			tween(coverImage, 0.15, { ImageTransparency = 1 })
			task.delay(0.15, function()
				if coverImage and coverImage.Parent then
					coverImage.Image = cover
					tween(coverImage, 0.3, { ImageTransparency = 0 })
				end
			end)
		end
	end

	-- ═══════════════════════════════════════════════════════
	-- PROCESS UPDATE
	-- ═══════════════════════════════════════════════════════
	local function processUpdate(data)
		playQueue = data.queue or {}
		currentSong = data.currentSong
		currentSoundObj = workspace:FindFirstChild("QueueSound")

		if currentSong then
			coverTitle.Text  = currentSong.name or "Sin reproducción"
			coverArtist.Text = currentSong.artist or ""
		else
			coverTitle.Text  = "Sin reproducción"
			coverArtist.Text = ""
		end

		updateCover(currentSong)
		drawQueue()
		if selectedDJ then updateVisibleCards() end

		local newDJs = data.djs or allDJs
		local changed = #newDJs ~= #allDJs
		if not changed then
			for i, dj in ipairs(newDJs) do
				if not allDJs[i] or allDJs[i].name ~= dj.name then changed = true; break end
			end
		end
		if changed then allDJs = newDJs; drawDJs() end
	end

	-- ═══════════════════════════════════════════════════════
	-- REMOTE HANDLERS
	-- ═══════════════════════════════════════════════════════
	task.spawn(function()
		local rg = ReplicatedStorage:WaitForChild("RemotesGlobal", 10)
		if not rg then return end

		local function scheduleRemote(remote)
			remote.OnClientEvent:Connect(function(data)
				local now = tick()
				if (now - lastUpdateTime) < UPDATE_THROTTLE then
					pendingUpdate = data
					if not (pendingUpdate and pendingUpdate._sched) then
						if pendingUpdate then pendingUpdate._sched = true end
						task.delay(UPDATE_THROTTLE, function()
							if pendingUpdate then
								lastUpdateTime = tick()
								processUpdate(pendingUpdate)
								pendingUpdate = nil
							end
						end)
					end
					return
				end
				lastUpdateTime = now; pendingUpdate = nil
				processUpdate(data)
			end)
		end

		repeat task.wait(0.5) until R.Update
		scheduleRemote(R.Update)

		if R.GetDJs then
			R.GetDJs.OnClientEvent:Connect(function(d)
				allDJs = (d and (d.djs or d)) or allDJs
				drawDJs()
			end)
		end

		if R.GetSongRange then
			R.GetSongRange.OnClientEvent:Connect(function(data)
				if not data or data.djName ~= selectedDJ then return end
				for _, song in ipairs(data.songs or {}) do
					virtualScrollState.songData[song.index] = song
				end
				virtualScrollState.pendingRequests[(data.startIndex or 0) .. "-" .. (data.endIndex or 0)] = nil
				djHeaderCount.Text = virtualScrollState.totalSongs .. " canciones"
				updateVisibleCards()
			end)
		end

		if R.SearchSongs then
			R.SearchSongs.OnClientEvent:Connect(function(data)
				if not data or data.djName ~= selectedDJ then return end
				virtualScrollState.searchResults = data.songs or {}
				local total = data.totalInDJ or virtualScrollState.totalSongs
				djHeaderCount.Text = #virtualScrollState.searchResults .. "/" .. total .. " canciones"
				djSongListScroll.CanvasPosition = Vector2.new(0, 0)
				updateVisibleCards()
			end)
		end

		if R.AddResponse then
			R.AddResponse.OnClientEvent:Connect(function(ok, songId, msg)
				if songId then pendingCardSongIds[songId] = nil end
				updateVisibleCards(); drawQueue()
			end)
		end

		if R.RemoveResponse then R.RemoveResponse.OnClientEvent:Connect(function() drawQueue() end) end

		if R.ClearResponse then
			R.ClearResponse.OnClientEvent:Connect(function()
				playQueue = {}; drawQueue()
			end)
		end
	end)

	-- Skip (MarketplaceService)
	MarketplaceService.PromptProductPurchaseFinished:Connect(function(uid, pid, bought)
		if uid == player.UserId and pid == SKIP_PRODUCT and bought then
			if R.Next then pcall(function() R.Next:FireServer() end) end
		end
	end)

	-- ═══════════════════════════════════════════════════════
	-- onOpen / onClose
	-- ═══════════════════════════════════════════════════════
	local function onOpen()
		if progressConn then progressConn:Disconnect() end
		progressConn = RunService.Heartbeat:Connect(updateProgress)
		drawQueue()
		if R.GetDJs then pcall(function() R.GetDJs:FireServer() end) end
		if #allDJs > 0 then drawDJs() end
	end

	local function onClose()
		if progressConn then progressConn:Disconnect(); progressConn = nil end
	end

	switchSubTab("actual")
	connectDJScrollListener()

	return { onOpen = onOpen, onClose = onClose }
end

return MusicTab