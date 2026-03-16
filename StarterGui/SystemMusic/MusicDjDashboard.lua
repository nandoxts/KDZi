--[[ Music Dashboard - Professional (Sidebar Layout)
	by ignxts- Nando
	Layout refactor: Sidebar + Main Area (LOCAL REGISTER FIX)
	NOTE: Forward-declared UI refs consolidated into _ui table
	      to stay under Luau's 200 local register limit.
]]

-- ════════════════════════════════════════════════════════════════
-- SERVICES
-- ════════════════════════════════════════════════════════════════
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local MarketplaceService = game:GetService("MarketplaceService")
local SoundService = game:GetService("SoundService")

-- ════════════════════════════════════════════════════════════════
-- MODULES
-- ════════════════════════════════════════════════════════════════
local ModalManager = require(ReplicatedStorage:WaitForChild("Modal"):WaitForChild("ModalManager"))
local GlobalModalManager = require(ReplicatedStorage:WaitForChild("Systems"):WaitForChild("GlobalModalManager"))
local Notify = require(ReplicatedStorage:WaitForChild("Systems"):WaitForChild("NotificationSystem"):WaitForChild("NotificationSystem"))
local UI = require(ReplicatedStorage:WaitForChild("Core"):WaitForChild("UI"))
local SearchModern = require(ReplicatedStorage:WaitForChild("UIComponents"):WaitForChild("SearchModern"))
local ModernScrollbar = require(ReplicatedStorage:WaitForChild("UIComponents"):WaitForChild("ModernScrollbar"))
local THEME = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("ThemeConfig"))

-- ════════════════════════════════════════════════════════════════
-- INSTANCE HELPER
-- ════════════════════════════════════════════════════════════════
local function make(className, props, children)
	local inst = Instance.new(className)
	for k, v in pairs(props) do
		if k ~= "Parent" then inst[k] = v end
	end
	if children then
		for _, child in ipairs(children) do child.Parent = inst end
	end
	if props.Parent then inst.Parent = props.Parent end
	return inst
end

local function makeLabel(props)
	return make("TextLabel", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Font = props.font or Enum.Font.Gotham,
		TextSize = props.size or 13,
		TextColor3 = props.color or THEME and THEME.text or Color3.new(1,1,1),
		TextXAlignment = props.alignX or Enum.TextXAlignment.Left,
		TextTruncate = props.truncate or Enum.TextTruncate.None,
		Text = props.text or "",
		Size = props.dim or UDim2.new(1, 0, 0, 20),
		Position = props.pos or UDim2.new(0, 0, 0, 0),
		ZIndex = props.z or 102,
		Visible = props.visible ~= false,
		Name = props.name or "Label",
		TextWrapped = props.wrap or false,
		Parent = props.parent,
	})
end

local function makeBtn(props)
	local btn = make("TextButton", {
		Size = props.dim or UDim2.new(0, 80, 0, 30),
		Position = props.pos or UDim2.new(0, 0, 0, 0),
		BackgroundColor3 = props.bg or Color3.fromRGB(60, 60, 68),
		Text = props.text or "",
		TextColor3 = props.textColor or Color3.new(1, 1, 1),
		Font = props.font or Enum.Font.GothamBold,
		TextSize = props.textSize or 13,
		BorderSizePixel = 0,
		ZIndex = props.z or 103,
		Name = props.name or "Button",
		Parent = props.parent,
	})
	if props.round then UI.rounded(btn, props.round) end
	return btn
end

local function makeFrame(props)
	return make("Frame", {
		Size = props.dim or UDim2.new(1, 0, 1, 0),
		Position = props.pos or UDim2.new(0, 0, 0, 0),
		BackgroundColor3 = props.bg or Color3.fromRGB(20, 20, 24),
		BackgroundTransparency = props.bgT or 1,
		BorderSizePixel = 0,
		ZIndex = props.z or 100,
		ClipsDescendants = props.clip or false,
		Name = props.name or "Frame",
		Parent = props.parent,
	})
end

local function makeImage(props)
	return make("ImageLabel", {
		Size = props.dim or UDim2.new(0, 40, 0, 40),
		Position = props.pos or UDim2.new(0, 0, 0, 0),
		BackgroundTransparency = props.bgT or 1,
		BackgroundColor3 = props.bg or Color3.fromRGB(30, 30, 35),
		Image = props.image or "",
		ImageColor3 = props.imageColor or Color3.new(1, 1, 1),
		ImageTransparency = props.imageT or 0,
		ScaleType = props.scale or Enum.ScaleType.Crop,
		BorderSizePixel = 0,
		ZIndex = props.z or 103,
		Visible = props.visible ~= false,
		Name = props.name or "Image",
		Parent = props.parent,
	})
end

local function makeScrollColumn(parent, offsetY, paddingOpts, theme)
	local scroll = make("ScrollingFrame", {
		Size = UDim2.new(1, paddingOpts.sizeXOff or -8, 1, -(offsetY + (paddingOpts.bottomOff or 8))),
		Position = UDim2.new(0, paddingOpts.posX or 4, 0, offsetY),
		BackgroundTransparency = 1, BorderSizePixel = 0,
		ScrollBarThickness = 0, ScrollBarImageTransparency = 1,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		ClipsDescendants = true, ZIndex = 101, Parent = parent,
	})
	ModernScrollbar.setup(scroll, parent, theme, {transparency = 0})
	if paddingOpts.padding then
		make("UIPadding", {
			PaddingLeft = UDim.new(0, paddingOpts.padding),
			PaddingRight = UDim.new(0, paddingOpts.padding),
			PaddingTop = UDim.new(0, paddingOpts.paddingTop or paddingOpts.padding),
			PaddingBottom = UDim.new(0, paddingOpts.padding),
			Parent = scroll,
		})
	end
	local layout = make("UIListLayout", {
		Padding = UDim.new(0, paddingOpts.gap or 4),
		SortOrder = Enum.SortOrder.LayoutOrder, Parent = scroll,
	})
	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 12)
	end)
	return scroll, layout
end

local function makeCanvas(parent, corner, z)
	local canvas = Instance.new("CanvasGroup")
	canvas.Name = "Canvas"
	canvas.Size = UDim2.new(1, 0, 1, 0)
	canvas.BackgroundTransparency = 1
	canvas.BorderSizePixel = 0
	canvas.GroupTransparency = 0
	canvas.ZIndex = z or 103
	canvas.Parent = parent
	Instance.new("UICorner", canvas).CornerRadius = UDim.new(0, corner or 8)
	return canvas
end

local function tween(obj, duration, props)
	TweenService:Create(obj, TweenInfo.new(duration), props):Play()
end

local function addHover(btn, hoverColor, defaultColor, defaultTransparency)
	btn.MouseEnter:Connect(function()
		tween(btn, 0.15, {BackgroundColor3 = hoverColor, BackgroundTransparency = 0})
	end)
	btn.MouseLeave:Connect(function()
		tween(btn, 0.15, {BackgroundColor3 = defaultColor, BackgroundTransparency = defaultTransparency or 0})
	end)
end

-- ════════════════════════════════════════════════════════════════
-- RESPONSE CODES
-- ════════════════════════════════════════════════════════════════
local ResponseCodes = {
	SUCCESS = "SUCCESS", ERROR_INVALID_ID = "ERROR_INVALID_ID",
	ERROR_BLACKLISTED = "ERROR_BLACKLISTED", ERROR_DUPLICATE = "ERROR_DUPLICATE",
	ERROR_NOT_FOUND = "ERROR_NOT_FOUND", ERROR_NOT_AUDIO = "ERROR_NOT_AUDIO",
	ERROR_NOT_AUTHORIZED = "ERROR_NOT_AUTHORIZED", ERROR_QUEUE_FULL = "ERROR_QUEUE_FULL",
	ERROR_PERMISSION = "ERROR_PERMISSION", ERROR_UNKNOWN = "ERROR_UNKNOWN",
}

local ResponseMessages = {
	[ResponseCodes.SUCCESS] = {type = "success", title = "Éxito"},
	[ResponseCodes.ERROR_INVALID_ID] = {type = "error", title = "ID Inválido"},
	[ResponseCodes.ERROR_BLACKLISTED] = {type = "error", title = "Audio Bloqueado"},
	[ResponseCodes.ERROR_DUPLICATE] = {type = "warning", title = "Duplicado"},
	[ResponseCodes.ERROR_NOT_FOUND] = {type = "error", title = "No Encontrado"},
	[ResponseCodes.ERROR_NOT_AUDIO] = {type = "error", title = "Tipo Incorrecto"},
	[ResponseCodes.ERROR_NOT_AUTHORIZED] = {type = "error", title = "No Autorizado"},
	[ResponseCodes.ERROR_QUEUE_FULL] = {type = "warning", title = "Cola Llena"},
	[ResponseCodes.ERROR_PERMISSION] = {type = "error", title = "Sin Permiso"},
	[ResponseCodes.ERROR_UNKNOWN] = {type = "error", title = "Error"},
}

-- ════════════════════════════════════════════════════════════════
-- CONFIG
-- ════════════════════════════════════════════════════════════════
local player = Players.LocalPlayer
local MusicSystemConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("MusicSystemConfig"))
local isAdmin = MusicSystemConfig:IsAdmin(player) and true

local CARD_HEIGHT, CARD_PADDING = 54, 6
local VISIBLE_BUFFER, MAX_POOL_SIZE = 3, 25
local MAX_QUEUE_POOL = 30

local ICONS = {
	PLAY_ADD = "rbxassetid://84692791859484",
	CHECK    = "rbxassetid://102926522001210",
	DELETE   = "rbxassetid://94904012825024",
	LOADING  = "rbxassetid://72909990569897",
	VOL_DOWN = "rbxassetid://118993192034241",
	VOL_UP   = "rbxassetid://114456072508401",
}

local VISUALIZER = {
	BAR_COUNT = 40, BAR_WIDTH = 8, BAR_GAP = 2,
	BAR_MIN_H = 2, BAR_MAX_H = 50,
	COLOR_LOW = Color3.fromRGB(100, 80, 180),
}

-- ════════════════════════════════════════════════════════════════
-- STATE — consolidated into tables to save local registers
-- ════════════════════════════════════════════════════════════════
local state = {
	playQueue = {}, currentSong = nil,
	allDJs = {}, selectedDJ = nil, selectedDJInfo = nil,
	currentSoundObject = nil, progressConnection = nil, visualizerConnection = nil,
	isAddingToQueue = false,
	loadingDotsThread = nil, loadingTween = nil,
	cardPool = {}, cardsIndex = {},
	selectedDJCard = nil, currentHeaderCover = "",
	pendingCardSongIds = {},
	queueCardPool = {}, activeQueueCards = {},
	activeEffectThreads = {},
	scrollDebounceThread = nil, scrollConnection = nil,
	currentView = "queue",
	queueEmptyLabel = nil,
	avatarCache = {},
	progressTween = nil, progressAccum = 0,
	searchDebounce = nil,
	lastUpdateTime = 0, pendingUpdate = nil,
	lastSkipTime = 0,
}

local virtualScrollState = {
	totalSongs = 0, songData = {}, visibleCards = {},
	firstVisibleIndex = 1, lastVisibleIndex = 1,
	isSearching = false, searchQuery = "", searchResults = {},
	pendingRequests = {},
}

-- UI refs — single table instead of ~30 individual locals
local _ui = {}

-- ════════════════════════════════════════════════════════════════
-- HELPERS
-- ════════════════════════════════════════════════════════════════
local function isValidAudioId(text)
	if not text or text == "" then return false end
	if not text:match("^%d+$") then return false end
	return #text >= 6 and #text <= 19
end

local function getRemote(name)
	local RemotesGlobal = ReplicatedStorage:WaitForChild("RemotesGlobal", 10)
	if not RemotesGlobal then return end
	local remoteMap = {
		NextSong = "MusicPlayback", PlaySong = "MusicPlayback", PauseSong = "MusicPlayback",
		StopSong = "MusicPlayback", ChangeVolume = "MusicPlayback",
		AddToQueue = "MusicQueue", AddToQueueResponse = "MusicQueue",
		RemoveFromQueue = "MusicQueue", RemoveFromQueueResponse = "MusicQueue",
		ClearQueue = "MusicQueue", ClearQueueResponse = "MusicQueue",
		UpdateUI = "UI", GetDJs = "MusicLibrary", GetSongsByDJ = "MusicLibrary",
		GetSongRange = "MusicLibrary", SearchSongs = "MusicLibrary",
		GetSongMetadata = "MusicLibrary",
	}
	local folder = RemotesGlobal:FindFirstChild(remoteMap[name] or "MusicLibrary")
	return folder and folder:FindFirstChild(name)
end

local function formatTime(s)
	return string.format("%d:%02d", math.floor(s / 60), math.floor(s % 60))
end

local function showNotification(response)
	local cfg = ResponseMessages[response.code] or ResponseMessages[ResponseCodes.ERROR_UNKNOWN]
	local msg = response.message or "Operación completada"
	if response.data and response.data.songName then msg = msg .. ": " .. response.data.songName end
	local fn = ({success = Notify.Success, warning = Notify.Warning, error = Notify.Error})[cfg.type] or Notify.Info
	fn(Notify, cfg.title, msg, cfg.type == "error" and 4 or 3)
end

local function isInQueue(songId)
	for _, song in ipairs(state.playQueue) do
		if song.id == songId then return true end
	end
	return false
end

local function isMusicMuted() return _G.MusicMutedState or false end

-- ════════════════════════════════════════════════════════════════
-- REMOTES
-- ════════════════════════════════════════════════════════════════
local R = {}
do
	local remoteNames = {
		"NextSong", "PlaySong", "StopSong", "AddToQueue", "AddToQueueResponse",
		"RemoveFromQueue", "RemoveFromQueueResponse", "ClearQueue", "ClearQueueResponse",
		"UpdateUI", "GetDJs", "GetSongsByDJ", "GetSongRange", "SearchSongs",
		"GetSongMetadata", "ChangeVolume",
	}
	local shortNames = {
		NextSong = "Next", PlaySong = "Play", StopSong = "Stop",
		AddToQueue = "Add", AddToQueueResponse = "AddResponse",
		RemoveFromQueue = "Remove", RemoveFromQueueResponse = "RemoveResponse",
		ClearQueue = "Clear", ClearQueueResponse = "ClearResponse",
		UpdateUI = "Update",
	}
	for _, name in ipairs(remoteNames) do
		R[shortNames[name] or name] = getRemote(name)
	end
end

-- ════════════════════════════════════════════════════════════════
-- ROOT GUI
-- ════════════════════════════════════════════════════════════════
local screenGui = make("ScreenGui", {
	Name = "MusicDashboardUI", ResetOnSpawn = false,
	IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	Parent = player:WaitForChild("PlayerGui"),
})

task.wait(0.5)
local mob = UserInputService.TouchEnabled

-- ════════════════════════════════════════════════════════════════
-- LAYOUT CONSTANTS
-- ════════════════════════════════════════════════════════════════
local PANEL_W = mob and THEME.panelWidth or math.max(THEME.panelWidth, 1100)
local PANEL_H = mob and THEME.panelHeight or math.max(THEME.panelHeight, 620)
local SIDEBAR_W = mob and 75 or 95  -- Reducido de 80/105
local BOTTOM_BAR_H = mob and 75 or 90  -- Reducido de 80/100
local MAIN_HEADER_H = mob and 110 or 150  -- Reducido de 120/170
local QUEUE_BTN_H = mob and 65 or 75  -- Reducido de 70/82
local DJ_THUMB_H = mob and 85 or 100  -- Reducido de 90/108

-- ════════════════════════════════════════════════════════════════
-- MODAL
-- ════════════════════════════════════════════════════════════════
local modal = ModalManager.new({
	screenGui = screenGui, panelName = "MusicDashboard",
	panelWidth = PANEL_W, panelHeight = PANEL_H,
	cornerRadius = 12, enableBlur = true, blurSize = 14,
	isMobile = mob,
	onClose = function()
		if state.progressConnection then state.progressConnection:Disconnect(); state.progressConnection = nil end
		if state.visualizerConnection then state.visualizerConnection:Disconnect(); state.visualizerConnection = nil end
	end,
})

local canvas = modal:getCanvas()

-- ════════════════════════════════════════════════════════════════
-- MAIN LAYOUT
-- ════════════════════════════════════════════════════════════════
local contentArea = makeFrame({
	dim = UDim2.new(1, -SIDEBAR_W, 1, 0),
	pos = UDim2.new(0, SIDEBAR_W, 0, 0),
	z = 100, clip = true, name = "ContentArea", parent = canvas,
})

-- ── Bottom Bar ──
do
	local bottomBar = makeFrame({
		dim = UDim2.new(1, 0, 0, BOTTOM_BAR_H),
		pos = UDim2.new(0, 0, 1, -BOTTOM_BAR_H),
		bg = Color3.fromRGB(14, 14, 18), bgT = 0,
		z = 110, name = "BottomBar", parent = contentArea,
	})
	make("UIGradient", {
		Color = ColorSequence.new{
			ColorSequenceKeypoint.new(0, Color3.fromRGB(22, 22, 28)),
			ColorSequenceKeypoint.new(0.15, Color3.fromRGB(14, 14, 18)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 10, 14)),
		},
		Rotation = 90, Parent = bottomBar,
	})
	make("UIStroke", {
		Color = THEME.stroke, Thickness = 1, Transparency = 0.6,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = bottomBar,
	})
	_ui.bottomBarBg = makeImage({
		dim = UDim2.new(1, 0, 1, 0), z = 110, imageT = 0.6,
		name = "BottomBarBg", parent = bottomBar,
	})
	_ui.bottomBar = bottomBar
end

-- ════════════════════════════════════════════════════════════════
-- SIDEBAR
-- ════════════════════════════════════════════════════════════════
do
	local sidebar = makeFrame({
		dim = UDim2.new(0, SIDEBAR_W, 1, 0),
		bg = THEME.deep, bgT = THEME.lightAlpha,
		z = 105, name = "Sidebar", parent = canvas,
	})

	-- Queue Toggle Button
	local queueBtnContainer = makeFrame({
		dim = UDim2.new(1, 0, 0, QUEUE_BTN_H),
		bg = THEME.card, bgT = THEME.frameAlpha,
		z = 102, name = "QueueBtnContainer", parent = sidebar,
	})

	-- Hamburger icon
	do
		local hf = makeFrame({
			dim = UDim2.new(0, 28, 0, 22),
			pos = UDim2.new(0.5, -14, 0, mob and 10 or 14),
			z = 103, parent = queueBtnContainer,
		})
		for li = 0, 2 do
			local line = Instance.new("Frame")
			line.Size = UDim2.new(1, 0, 0, 3)
			line.Position = UDim2.new(0, 0, 0, li * 9)
			line.BackgroundColor3 = Color3.new(1, 1, 1)
			line.BackgroundTransparency = 0
			line.BorderSizePixel = 0
			line.ZIndex = 104
			line.Parent = hf
		end
	end

	makeLabel({
		text = "Queue", font = Enum.Font.GothamBold, size = mob and 10 or 12,
		dim = UDim2.new(1, 0, 0, 16),
		pos = UDim2.new(0, 0, 1, mob and -20 or -22),
		color = THEME.text, alignX = Enum.TextXAlignment.Center,
		z = 103, parent = queueBtnContainer,
	})

	_ui.queueBtnStroke = make("UIStroke", {
		Color = THEME.accent, Thickness = 1.5, Transparency = 0.2,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Name = "QueueBtnStroke", Parent = queueBtnContainer,
	})

	_ui.queueClickBtn = makeBtn({
		dim = UDim2.new(1, 0, 1, 0), z = 110,
		name = "QueueClickBtn", parent = queueBtnContainer,
	})
	_ui.queueClickBtn.BackgroundTransparency = 1

	-- Divider
	makeFrame({
		dim = UDim2.new(1, -12, 0, 1),
		pos = UDim2.new(0, 6, 0, QUEUE_BTN_H),
		bg = THEME.stroke, bgT = 0.5, z = 102, parent = sidebar,
	})

	-- DJ Thumbnails Scroll
	_ui.djsScroll = make("ScrollingFrame", {
		Size = UDim2.new(1, 0, 1, -(QUEUE_BTN_H + 4)),
		Position = UDim2.new(0, 0, 0, QUEUE_BTN_H + 4),
		BackgroundTransparency = 1, BorderSizePixel = 0,
		ScrollBarThickness = 0, ScrollBarImageTransparency = 1,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		ClipsDescendants = true, ZIndex = 101, Parent = sidebar,
	})
	ModernScrollbar.setup(_ui.djsScroll, sidebar, THEME, {transparency = 0})

	local djsLayout = make("UIListLayout", {
		Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		Parent = _ui.djsScroll,
	})
	make("UIPadding", {
		PaddingLeft = UDim.new(0, 5), PaddingRight = UDim.new(0, 5),
		PaddingTop = UDim.new(0, 3), PaddingBottom = UDim.new(0, 3),
		Parent = _ui.djsScroll,
	})
	djsLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		_ui.djsScroll.CanvasSize = UDim2.new(0, 0, 0, djsLayout.AbsoluteContentSize.Y + 12)
	end)
end

-- ════════════════════════════════════════════════════════════════
-- MAIN PANEL
-- ════════════════════════════════════════════════════════════════
_ui.mainPanel = makeFrame({
	dim = UDim2.new(1, 0, 1, -BOTTOM_BAR_H),
	pos = UDim2.new(0, 0, 0, 0),
	z = 100, clip = true, name = "MainPanel", parent = contentArea,
})

-- Divider
makeFrame({
	dim = UDim2.new(0, 1, 1, -16), pos = UDim2.new(0, 0, 0, 8),
	bg = THEME.stroke, bgT = 0.5, z = 105, parent = _ui.mainPanel,
})

-- ── Main Header ──
_ui.mainHeader = makeFrame({
	dim = UDim2.new(1, 0, 0, MAIN_HEADER_H),
	bg = Color3.fromRGB(18, 18, 22), bgT = 0,
	z = 101, clip = true, name = "MainHeader", parent = _ui.mainPanel,
})

_ui.mainHeaderCoverImg = makeImage({
	dim = UDim2.new(1, 0, 1, 0), z = 102,
	imageT = 1, name = "HeaderCoverImg", parent = _ui.mainHeader,
})

_ui.headerGradientFrame = makeFrame({
	dim = UDim2.new(1, 0, 1, 0),
	bg = THEME.accent, bgT = 0.6,
	z = 103, name = "HeaderGradient", parent = _ui.mainHeader,
})

make("UIGradient", {
	Transparency = NumberSequence.new{
		NumberSequenceKeypoint.new(0, 0.15),
		NumberSequenceKeypoint.new(0.35, 0.45),
		NumberSequenceKeypoint.new(0.7, 0.85),
		NumberSequenceKeypoint.new(1, 0.98),
	},
	Parent = _ui.headerGradientFrame,
})

-- Vignette
do
	local hv = makeFrame({
		dim = UDim2.new(1, 0, 0.6, 0), pos = UDim2.new(0, 0, 0.4, 0),
		bg = Color3.new(0, 0, 0), bgT = 0.2,
		z = 104, parent = _ui.mainHeader,
	})
	make("UIGradient", {
		Transparency = NumberSequence.new{
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.6, 0.5),
			NumberSequenceKeypoint.new(1, 0.15),
		},
		Rotation = 90, Parent = hv,
	})
end

_ui.songsTitle = makeLabel({
	text = "PLAYLIST QUEUE", font = Enum.Font.GothamBlack,
	size = mob and 22 or 32,
	dim = UDim2.new(1, -32, 0, mob and 30 or 40),
	pos = UDim2.new(0, 16, 0, mob and 16 or 24),
	truncate = Enum.TextTruncate.AtEnd,
	z = 106, name = "MainHeaderTitle", parent = _ui.mainHeader,
})

_ui.songCountLabel = makeLabel({
	dim = UDim2.new(0, 120, 0, 22),
	pos = UDim2.new(0, 16, 0, mob and 48 or 68),
	color = THEME.accent, font = Enum.Font.GothamBold,
	size = mob and 11 or 13,
	z = 106, visible = false, parent = _ui.mainHeader,
})

do
	local sc
	sc, _ui.searchInput = SearchModern.new(_ui.mainHeader, {
		placeholder = "Buscar por ID o nombre...",
		size = UDim2.new(1, 0, 0, 28),
		bg = THEME.card, corner = 8, z = 106, inputName = "SearchInput",
	})
	sc.Position = UDim2.new(0, 16, 1, mob and -34 or -38)
	sc.Size = UDim2.new(1, -32, 0, mob and 26 or 30)
	sc.Visible = false
	_ui.searchContainer = sc
end

if isAdmin then
	_ui.clearB = makeBtn({
		dim = UDim2.new(0, 60, 0, 28),
		pos = UDim2.new(1, -76, 0, mob and 16 or 26),
		bg = Color3.fromRGB(161, 124, 72), text = "CLEAR", textSize = 11,
		z = 107, round = 6, parent = _ui.mainHeader,
	})
end

-- ── Songs View ──
_ui.songsView = makeFrame({
	dim = UDim2.new(1, 0, 1, -MAIN_HEADER_H),
	pos = UDim2.new(0, 0, 0, MAIN_HEADER_H),
	z = 101, clip = true, name = "SongsView", parent = _ui.mainPanel,
})
_ui.songsView.Visible = false

_ui.songsScroll = make("ScrollingFrame", {
	Size = UDim2.new(1, -16, 1, -8),
	Position = UDim2.new(0, 8, 0, 4),
	BackgroundTransparency = 1, BorderSizePixel = 0,
	ScrollBarThickness = 0, ScrollBarImageTransparency = 1,
	CanvasSize = UDim2.new(0, 0, 0, 0),
	ClipsDescendants = true, ZIndex = 101, Parent = _ui.songsView,
})
ModernScrollbar.setup(_ui.songsScroll, _ui.songsView, THEME, {transparency = 0})

_ui.songsContainer = makeFrame({name = "SongsContainer", dim = UDim2.new(1, 0, 0, 0), z = 101, parent = _ui.songsScroll})

_ui.loadingIndicator = makeLabel({
	dim = UDim2.new(1, 0, 0, 40), text = "Cargando...",
	color = THEME.muted, size = 15, z = 102, visible = false, parent = _ui.songsScroll,
})

_ui.songsPlaceholder = makeLabel({
	dim = UDim2.new(1, -40, 0, 80), pos = UDim2.new(0, 20, 0.35, 0),
	text = "Selecciona un DJ\npara ver sus canciones",
	color = THEME.muted, size = 16, wrap = true, z = 102,
	alignX = Enum.TextXAlignment.Center,
	name = "Placeholder", parent = _ui.songsView,
})

-- ── Queue View ──
_ui.queueView = makeFrame({
	dim = UDim2.new(1, 0, 1, -MAIN_HEADER_H),
	pos = UDim2.new(0, 0, 0, MAIN_HEADER_H),
	z = 101, clip = true, name = "QueueView", parent = _ui.mainPanel,
})

_ui.queueScroll = makeScrollColumn(_ui.queueView, 4, {
	sizeXOff = -12, posX = 6, bottomOff = 8, padding = 6, paddingTop = 6, gap = 6,
}, THEME)

-- ════════════════════════════════════════════════════════════════
-- VIEW SWITCHING
-- ════════════════════════════════════════════════════════════════
local function switchView(view)
	if state.currentView == view then return end
	state.currentView = view

	if view == "queue" then
		_ui.songsView.Visible = false
		_ui.queueView.Visible = true
		_ui.songsTitle.Text = "PLAYLIST QUEUE"
		_ui.songCountLabel.Visible = false
		_ui.searchContainer.Visible = false
		if _ui.clearB then _ui.clearB.Visible = true end
		tween(_ui.mainHeaderCoverImg, 0.3, {ImageTransparency = 1})
		_ui.headerGradientFrame.BackgroundColor3 = THEME.accent
		tween(_ui.headerGradientFrame, 0.3, {BackgroundTransparency = 0.6})
		tween(_ui.queueBtnStroke, 0.2, {Color = THEME.accent, Transparency = 0.2, Thickness = 1.5})
		if state.selectedDJCard then
			local ps = state.selectedDJCard:FindFirstChild("CardStroke")
			if ps then tween(ps, 0.2, {Color = THEME.stroke, Transparency = 0.7, Thickness = 1}) end
			local pn = state.selectedDJCard:FindFirstChild("DJNameLabel")
			if pn then tween(pn, 0.2, {TextColor3 = Color3.fromRGB(180, 180, 190)}) end
		end
	else
		_ui.songsView.Visible = true
		_ui.queueView.Visible = false
		if _ui.clearB then _ui.clearB.Visible = false end
		_ui.searchContainer.Visible = true
		tween(_ui.queueBtnStroke, 0.2, {Color = THEME.stroke, Transparency = 0.7, Thickness = 1})
	end
end

_ui.queueClickBtn.MouseButton1Click:Connect(function() switchView("queue") end)
_ui.queueClickBtn.MouseEnter:Connect(function()
	if state.currentView ~= "queue" then
		tween(_ui.queueBtnStroke, 0.15, {Color = THEME.accent, Transparency = 0.4, Thickness = 1.5})
	end
end)
_ui.queueClickBtn.MouseLeave:Connect(function()
	if state.currentView ~= "queue" then
		tween(_ui.queueBtnStroke, 0.15, {Color = THEME.stroke, Transparency = 0.7, Thickness = 1})
	end
end)

-- ════════════════════════════════════════════════════════════════
-- BOTTOM BAR CONTENT
-- ════════════════════════════════════════════════════════════════
do
	local bottomContent = makeFrame({
		dim = UDim2.new(1, -24, 1, 0), pos = UDim2.new(0, 12, 0, 0),
		z = 111, parent = _ui.bottomBar,
	})

	-- LEFT: Now Playing
	local nowPlaying = makeFrame({
		dim = UDim2.new(0.30, -10, 1, 0), z = 112, name = "NowPlaying", parent = bottomContent,
	})

	local MINI_COVER = mob and 45 or 64
	_ui.miniCover = makeImage({
		dim = UDim2.new(0, MINI_COVER, 0, MINI_COVER),
		pos = UDim2.new(0, 0, 0.5, -MINI_COVER/2),
		z = 113, name = "MiniCover", parent = nowPlaying,
	})
	_ui.miniCover.ClipsDescendants = true
	UI.rounded(_ui.miniCover, 6)
	make("UIStroke", {Color = THEME.accent, Thickness = 1.5, Transparency = 0.5, Parent = _ui.miniCover})

	local infoX = MINI_COVER + 10

	_ui.songTitle = makeLabel({
		dim = UDim2.new(1, -MINI_COVER - 12, 0, 18), pos = UDim2.new(0, infoX, 0, mob and 8 or 12),
		text = "No song playing", font = Enum.Font.GothamBold, size = mob and 13 or 15,
		truncate = Enum.TextTruncate.AtEnd, z = 113, parent = nowPlaying,
	})

	_ui.headerDJName = makeLabel({
		dim = UDim2.new(1, -MINI_COVER - 12, 0, 14),
		pos = UDim2.new(0, infoX, 0, mob and 26 or 32),
		color = THEME.muted, font = Enum.Font.GothamMedium, size = mob and 10 or 12,
		truncate = Enum.TextTruncate.AtEnd, z = 113, parent = nowPlaying,
	})

	_ui.headerSongID = makeLabel({
		dim = UDim2.new(1, -MINI_COVER - 12, 0, 16),
		pos = UDim2.new(0, infoX, 0, mob and 40 or 48),
		color = THEME.accent, font = Enum.Font.GothamBold, size = mob and 12 or 14,
		z = 113, parent = nowPlaying,
	})

	-- CENTER: Progress + Visualizer + Quick Add
	local centerSection = makeFrame({
		dim = UDim2.new(0.40, -20, 1, 0), pos = UDim2.new(0.30, 10, 0, 0),
		z = 112, clip = true, name = "CenterSection", parent = bottomContent,
	})

	-- Visualizer
	local vizContainer = makeFrame({
		dim = UDim2.new(1, 0, 0, mob and 48 or 70),
		pos = UDim2.new(0, 0, 1, -(mob and 48 or 70)),
		z = 111, clip = true, parent = centerSection,
	})

	_ui.visualizerBars = {}
	local totalVizW = VISUALIZER.BAR_COUNT * (VISUALIZER.BAR_WIDTH + VISUALIZER.BAR_GAP)
	for i = 1, VISUALIZER.BAR_COUNT do
		local barX = (i - 1) * (VISUALIZER.BAR_WIDTH + VISUALIZER.BAR_GAP)
		local bar = makeFrame({
			dim = UDim2.new(0, VISUALIZER.BAR_WIDTH, 0, VISUALIZER.BAR_MIN_H),
			pos = UDim2.new(0.5, barX - math.floor(totalVizW / 2), 1, -VISUALIZER.BAR_MIN_H),
			bg = VISUALIZER.COLOR_LOW, bgT = 0.5,
			z = 112, parent = vizContainer,
		})
		UI.rounded(bar, 1)
		_ui.visualizerBars[i] = {
			frame = bar, currentH = VISUALIZER.BAR_MIN_H, targetH = VISUALIZER.BAR_MIN_H,
			phase = math.random() * math.pi * 2,
			freqWeight = math.abs((i - VISUALIZER.BAR_COUNT / 2) / (VISUALIZER.BAR_COUNT / 2)),
		}
	end

	-- Progress
	local progContainer = makeFrame({
		dim = UDim2.new(1, 0, 0, 26), pos = UDim2.new(0, 0, 0, mob and 3 or 6),
		z = 113, parent = centerSection,
	})

	_ui.currentTimeLabel = makeLabel({
		dim = UDim2.new(0, 44, 1, 0), text = "0:00",
		color = THEME.muted, font = Enum.Font.GothamBold, size = mob and 13 or 15,
		alignX = Enum.TextXAlignment.Right, z = 114, parent = progContainer,
	})

	local progBar = makeFrame({
		dim = UDim2.new(1, -108, 0, mob and 6 or 10),
		pos = UDim2.new(0, 52, 0.5, mob and -3 or -5),
		bg = Color3.fromRGB(40, 40, 48), bgT = 0, z = 113, parent = progContainer,
	})
	UI.rounded(progBar, 5)

	_ui.progressFill = makeFrame({
		dim = UDim2.new(0, 0, 1, 0), bg = THEME.accent, bgT = 0, z = 114, parent = progBar,
	})
	UI.rounded(_ui.progressFill, 5)

	_ui.totalTimeLabel = makeLabel({
		dim = UDim2.new(0, 44, 1, 0), pos = UDim2.new(1, -44, 0, 0),
		text = "0:00", color = THEME.muted, font = Enum.Font.GothamBold,
		size = mob and 13 or 15, alignX = Enum.TextXAlignment.Left, z = 114,
		parent = progContainer,
	})

	-- Quick Add
	local qaFrame = makeFrame({
		dim = UDim2.new(1, 0, 0, 38),
		pos = UDim2.new(0, 0, 0, mob and 34 or 40),
		bg = THEME.card, bgT = THEME.frameAlpha or 0.3,
		z = 113, parent = centerSection,
	})
	UI.rounded(qaFrame, 8)
	_ui.qiStroke = UI.stroked(qaFrame, 0.4)

	_ui.quickInput = make("TextBox", {
		Size = UDim2.new(1, -50, 0, 34), Position = UDim2.new(0, 10, 0.5, -17),
		BackgroundTransparency = 1, Text = "", PlaceholderText = "Input ID",
		TextColor3 = THEME.text, PlaceholderColor3 = THEME.muted,
		Font = Enum.Font.GothamMedium, TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = false, ZIndex = 114, Parent = qaFrame,
	})
	_ui.quickInput:GetPropertyChangedSignal("Text"):Connect(function()
		if #_ui.quickInput.Text > 19 then _ui.quickInput.Text = string.sub(_ui.quickInput.Text, 1, 19) end
	end)

	_ui.quickAddBtn = makeBtn({
		dim = UDim2.new(0, 40, 0, 34), pos = UDim2.new(1, -44, 0.5, -17),
		bg = THEME.accent, z = 114, round = 6, parent = qaFrame,
	})
	_ui.quickAddBtnImg = makeImage({
		dim = UDim2.new(0.65, 0, 0.65, 0), pos = UDim2.new(0.175, 0, 0.175, 0),
		image = ICONS.PLAY_ADD, z = 115, parent = _ui.quickAddBtn,
	})
	_ui.quickAddBtnLoading = makeImage({
		dim = UDim2.new(0.65, 0, 0.65, 0), pos = UDim2.new(0.175, 0, 0.175, 0),
		image = ICONS.LOADING, z = 116, visible = false, parent = _ui.quickAddBtn,
	})

	_ui.songIdDisplay = makeLabel({
		dim = UDim2.new(1, 0, 0, 16), pos = UDim2.new(0, 0, 1, -18),
		color = THEME.muted, font = Enum.Font.GothamMedium, size = 12,
		z = 113, visible = false, parent = centerSection,
	})

	-- RIGHT: Skip + Volume
	local rightSection = makeFrame({
		dim = UDim2.new(0.30, -10, 1, 0), pos = UDim2.new(0.70, 10, 0, 0),
		z = 112, parent = bottomContent,
	})
	make("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = rightSection,
	})
	make("UIPadding", {PaddingRight = UDim.new(0, 4), Parent = rightSection})

	_ui.skipB = makeBtn({
		dim = UDim2.new(0, 70, 0, 34), bg = THEME.accent,
		text = "Skip", textSize = 13, z = 113,
		round = 8, parent = rightSection,
	})
	_ui.skipB.LayoutOrder = 2

	local volFrame = makeFrame({
		dim = UDim2.new(0, 150, 0, 36), z = 113, parent = rightSection,
	})
	volFrame.LayoutOrder = 1
	make("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = volFrame,
	})

	_ui.volDownBtn = makeBtn({
		dim = UDim2.new(0, 36, 0, 36), bg = THEME.elevated, z = 114,
		round = 8, parent = volFrame,
	})
	_ui.volDownBtn.LayoutOrder = 1
	if ICONS.VOL_DOWN ~= "" then
		makeImage({dim = UDim2.new(0.65,0,0.65,0), pos = UDim2.new(0.175,0,0.175,0), image = ICONS.VOL_DOWN, z = 115, parent = _ui.volDownBtn})
	end

	local volSlot = makeFrame({
		dim = UDim2.new(0, 60, 0, 36), bg = THEME.card, bgT = THEME.frameAlpha,
		z = 114, parent = volFrame,
	})
	volSlot.LayoutOrder = 2
	UI.rounded(volSlot, 6)

	_ui.volLabelText = makeLabel({
		dim = UDim2.new(1, 0, 1, 0), text = "100%",
		color = THEME.text, font = Enum.Font.GothamBold,
		size = 13, alignX = Enum.TextXAlignment.Center, z = 115, parent = volSlot,
	})

	_ui.volInput = make("TextBox", {
		Size = UDim2.new(1, 0, 1, 0), Position = UDim2.new(0, 0, 0, 0),
		BackgroundColor3 = THEME.elevated, Text = "",
		TextColor3 = THEME.text, Font = Enum.Font.GothamBold, TextSize = 13,
		BorderSizePixel = 0, ZIndex = 116, Visible = false,
		ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Center,
		Parent = volSlot,
	})
	UI.rounded(_ui.volInput, 6)

	_ui.volUpBtn = makeBtn({
		dim = UDim2.new(0, 36, 0, 36), bg = THEME.elevated, z = 114,
		round = 8, parent = volFrame,
	})
	_ui.volUpBtn.LayoutOrder = 3
	if ICONS.VOL_UP ~= "" then
		makeImage({dim = UDim2.new(0.65,0,0.65,0), pos = UDim2.new(0.175,0,0.175,0), image = ICONS.VOL_UP, z = 115, parent = _ui.volUpBtn})
	end
end

-- ════════════════════════════════════════════════════════════════
-- ADD BUTTON STATE MACHINE
-- ════════════════════════════════════════════════════════════════
local function setAddButtonState(st, customMessage)
	if not _ui.quickAddBtn or not _ui.quickInput or not _ui.qiStroke then return end
	if state.loadingDotsThread then task.cancel(state.loadingDotsThread); state.loadingDotsThread = nil end
	if state.loadingTween then state.loadingTween:Cancel(); state.loadingTween = nil end

	local states = {
		loading   = {adding = true,  bg = THEME.surface, stroke = THEME.accent, auto = false},
		success   = {adding = false, bg = Color3.fromRGB(72, 187, 120), stroke = Color3.fromRGB(72, 187, 120), clear = true, delay = 2},
		error     = {adding = false, bg = THEME.btnDanger, stroke = THEME.btnDanger, clear = true, placeholder = customMessage, delay = 3},
		duplicate = {adding = false, bg = THEME.warn, stroke = THEME.warn, clear = true, placeholder = customMessage or "La canción ya está en la cola", delay = 3},
		default   = {adding = false, bg = THEME.accent, stroke = THEME.stroke, auto = true, placeholder = "Input ID"},
	}

	local s = states[st] or states.default
	state.isAddingToQueue = s.adding
	_ui.quickAddBtn.BackgroundColor3 = s.bg
	_ui.qiStroke.Color = s.stroke
	_ui.quickAddBtn.AutoButtonColor = s.auto ~= false

	if st == "loading" then
		_ui.quickAddBtnImg.Visible = false
		_ui.quickAddBtnLoading.Visible = true
		state.loadingDotsThread = task.spawn(function()
			state.loadingTween = TweenService:Create(_ui.quickAddBtnLoading, TweenInfo.new(1.2, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1), {Rotation = 360})
			state.loadingTween:Play()
			while true do task.wait(0.1) end
		end)
	else
		_ui.quickAddBtnLoading.Visible = false
		_ui.quickAddBtnImg.Visible = true
	end

	if s.clear then _ui.quickInput.Text = "" end
	if s.placeholder then _ui.quickInput.PlaceholderText = s.placeholder end
	if s.delay then
		task.delay(s.delay, function()
			if _ui.quickAddBtn and _ui.qiStroke then setAddButtonState("default") end
		end)
	end
end

-- ════════════════════════════════════════════════════════════════
-- QUICK ADD + RESPONSE HANDLERS
-- ════════════════════════════════════════════════════════════════
_ui.quickAddBtn.MouseButton1Click:Connect(function()
	if state.isAddingToQueue then return end
	local aid = _ui.quickInput.Text:gsub("%s+", "")
	if not isValidAudioId(aid) then
		Notify:Warning("ID Inválido", "Ingresa un ID válido (6-19 dígitos)", 3)
		setAddButtonState("error", "Invalid Audio ID")
		return
	end
	setAddButtonState("loading")
	if R.Add then R.Add:FireServer(tonumber(aid)) end
end)

local function updatePendingCard(response, songId)
	task.defer(function()
		if not songId then return end
		state.pendingCardSongIds[songId] = nil
		for _, card in ipairs(state.cardPool) do
			if card.Visible and card:GetAttribute("SongID") == songId then
				local addBtn = card:FindFirstChild("AddButton", true)
				if not addBtn then break end
				local loadingIcon = addBtn:FindFirstChild("LoadingIcon")
				if loadingIcon then loadingIcon.Visible = false end
				local icon = addBtn:FindFirstChild("IconImage")
				if icon then icon.Visible = true end
				if response.success or response.code == ResponseCodes.ERROR_DUPLICATE then
					if icon then icon.Image = ICONS.CHECK; icon.ImageColor3 = Color3.new(1, 1, 1) end
					addBtn.BackgroundColor3 = THEME.success; addBtn.AutoButtonColor = false
				else
					if icon then icon.Image = ICONS.PLAY_ADD; icon.ImageColor3 = THEME.text end
					addBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 68); addBtn.AutoButtonColor = true
				end
				break
			end
		end
	end)
end

if R.AddResponse then
	R.AddResponse.OnClientEvent:Connect(function(response)
		if not response then return end
		showNotification(response)
		if response.success then setAddButtonState("success")
		elseif response.code == ResponseCodes.ERROR_DUPLICATE then setAddButtonState("duplicate", response.message)
		else setAddButtonState("error", response.message) end
		local resolvedIds = {}
		for songId in pairs(state.pendingCardSongIds) do table.insert(resolvedIds, songId) end
		if response.data and response.data.songId then
			updatePendingCard(response, response.data.songId)
		else
			for _, sid in ipairs(resolvedIds) do updatePendingCard(response, sid) end
		end
	end)
end

for _, remoteName in ipairs({"RemoveResponse", "ClearResponse"}) do
	if R[remoteName] then
		R[remoteName].OnClientEvent:Connect(function(response)
			if response then showNotification(response) end
		end)
	end
end

-- ════════════════════════════════════════════════════════════════
-- VOLUME LOGIC
-- ════════════════════════════════════════════════════════════════
local maxVolume = MusicSystemConfig.PLAYBACK.MaxVolume
local minVolume = MusicSystemConfig.PLAYBACK.MinVolume
local currentVolume = player:GetAttribute("MusicVolume") or MusicSystemConfig.PLAYBACK.DefaultVolume
local VOL_STEP = (maxVolume - minVolume) * 0.05

local function updateVolumeDisplay()
	if isMusicMuted() then
		_ui.volLabelText.Text = "MUTE"; _ui.volLabelText.TextColor3 = Color3.fromRGB(200, 80, 80)
	else
		_ui.volLabelText.Text = math.floor(currentVolume * 100) .. "%"; _ui.volLabelText.TextColor3 = THEME.text
	end
end

local function updateVolume(volume)
	currentVolume = math.clamp(volume, minVolume, maxVolume)
	updateVolumeDisplay()
	player:SetAttribute("MusicVolume", currentVolume)
	local sg = SoundService:FindFirstChild("MusicSoundGroup")
	if sg then sg.Volume = isMusicMuted() and 0 or currentVolume end
	if R.ChangeVolume then pcall(function() R.ChangeVolume:FireServer(currentVolume) end) end
end

do
	local musicSoundGroup = SoundService:FindFirstChild("MusicSoundGroup") or SoundService:WaitForChild("MusicSoundGroup", 10)
	local lastMuteState = isMusicMuted()
	local muteAccum = 0
	RunService.Heartbeat:Connect(function(dt)
		muteAccum = muteAccum + dt
		if muteAccum >= 0.5 then
			muteAccum = 0
			local muted = isMusicMuted()
			if muted ~= lastMuteState then
				lastMuteState = muted
				if musicSoundGroup then musicSoundGroup.Volume = muted and 0 or currentVolume end
				updateVolumeDisplay()
			end
		end
	end)
end

updateVolume(currentVolume)

local function handleMuteCheck()
	if isMusicMuted() then
		Notify:Info("Música Silenciada", "Desmutea el sonido en el topbar para cambiar el volumen", 2)
		return true
	end
	return false
end

_ui.volDownBtn.MouseButton1Click:Connect(function()
	if handleMuteCheck() then return end; updateVolume(currentVolume - VOL_STEP)
end)
_ui.volUpBtn.MouseButton1Click:Connect(function()
	if handleMuteCheck() then return end; updateVolume(currentVolume + VOL_STEP)
end)
addHover(_ui.volDownBtn, THEME.elevated, THEME.elevated, THEME.lightAlpha)
addHover(_ui.volUpBtn, THEME.elevated, THEME.elevated, THEME.lightAlpha)

_ui.volLabelText.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		if handleMuteCheck() then return end
		_ui.volInput.Text = tostring(math.floor(currentVolume * 100))
		_ui.volInput.Visible = true; _ui.volLabelText.Visible = false
		_ui.volInput:CaptureFocus()
	end
end)

_ui.volInput:GetPropertyChangedSignal("Text"):Connect(function()
	local text = _ui.volInput.Text:gsub("[^%d]", "")
	if #text > 3 then text = string.sub(text, 1, 3) end
	local v = tonumber(text)
	local maxP = math.floor(maxVolume * 100)
	if v and v > maxP then text = tostring(maxP) end
	_ui.volInput.Text = text
end)

local function applyVolumeInput()
	local parsed = tonumber(_ui.volInput.Text)
	updateVolume(parsed and math.clamp(parsed, 0, math.floor(maxVolume * 100)) / 100 or currentVolume)
	_ui.volInput.Visible = false; _ui.volLabelText.Visible = true
end

_ui.volInput.FocusLost:Connect(applyVolumeInput)

-- ════════════════════════════════════════════════════════════════
-- SKIP/CLEAR LOGIC
-- ════════════════════════════════════════════════════════════════
do
	local skipProductId = 3468988018
	local skipRemote = ReplicatedStorage:WaitForChild("RemotesGlobal"):WaitForChild("MusicQueue"):WaitForChild("PurchaseSkip")
	local skipCooldown = MusicSystemConfig.LIMITS.SkipCooldown or 3

	_ui.skipB.MouseButton1Click:Connect(function()
		local elapsed = tick() - state.lastSkipTime
		if not isAdmin and elapsed < skipCooldown then
			Notify:Info("Cooldown", "Espera " .. math.ceil(skipCooldown - elapsed) .. " segundos")
			return
		end
		state.lastSkipTime = tick()
		if isAdmin then
			if R.Next then R.Next:FireServer(); Notify:Success("Skip", "Canción saltada") end
		else
			MarketplaceService:PromptProductPurchase(player, skipProductId)
		end
	end)

	if _ui.clearB then
		_ui.clearB.MouseButton1Click:Connect(function()
			if R.Clear then R.Clear:FireServer() end
		end)
	end

	MarketplaceService.PromptProductPurchaseFinished:Connect(function(userId, productId, wasPurchased)
		if userId == player.UserId and productId == skipProductId and wasPurchased then
			pcall(function() skipRemote:FireServer() end)
		end
	end)

	skipRemote.OnClientEvent:Connect(function(ok, msg)
		if ok then Notify:Success("Skip", msg or "Canción saltada")
		else Notify:Error("Skip", msg or "No se pudo saltar") end
	end)
end

-- ════════════════════════════════════════════════════════════════
-- QUEUE CARD POOL
-- ════════════════════════════════════════════════════════════════
local function createQueueCard()
	local card = makeFrame({dim = UDim2.new(1, 0, 0, 54), bg = THEME.card, bgT = THEME.frameAlpha, z = 101})
	card.Visible = false
	UI.rounded(card, 8)
	make("UIStroke", {Color = THEME.stroke, Thickness = 1, Transparency = 0.3, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = card})
	make("UIPadding", {PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 8), Parent = card})
	local avatar = makeImage({dim = UDim2.new(0, 40, 0, 40), pos = UDim2.new(0, 4, 0.5, -20), z = 102, name = "Avatar", parent = card})
	UI.rounded(avatar, 20)
	make("UIStroke", {Color = Color3.fromRGB(100, 100, 110), Thickness = 1, Name = "AvatarStroke", Parent = avatar})
	local nameClip = makeFrame({dim = UDim2.new(1, -58, 0, 18), pos = UDim2.new(0, 50, 0, 8), z = 102, clip = true, name = "NameClip", parent = card})
	makeLabel({text = "", color = THEME.text, font = Enum.Font.GothamBold, size = 12, truncate = Enum.TextTruncate.AtEnd, z = 102, name = "NameLabel", parent = nameClip})
	makeLabel({dim = UDim2.new(1, -58, 0, 14), pos = UDim2.new(0, 50, 0, 28), text = "", color = THEME.muted, font = Enum.Font.GothamMedium, size = 11, truncate = Enum.TextTruncate.AtEnd, z = 102, name = "RequesterLabel", parent = card})
	if isAdmin then
		local removeBtn = makeBtn({dim = UDim2.new(0, 28, 0, 28), pos = UDim2.new(1, -32, 0.5, -14), bg = THEME.btnDanger, z = 103, round = 8, name = "RemoveBtn", parent = card})
		makeImage({dim = UDim2.new(0.7, 0, 0.7, 0), pos = UDim2.new(0.15, 0, 0.15, 0), image = ICONS.DELETE, z = 104, name = "IconImage", parent = removeBtn})
	end
	return card
end

local function getQueueCardFromPool()
	for _, card in ipairs(state.queueCardPool) do if not card.Visible then return card end end
	if #state.queueCardPool < MAX_QUEUE_POOL then
		local c = createQueueCard(); c.Parent = _ui.queueScroll; table.insert(state.queueCardPool, c); return c
	end
	return nil
end

local function releaseAllQueueCards()
	for _, card in ipairs(state.activeQueueCards) do card.Visible = false; card:SetAttribute("QueueIndex", nil) end
	state.activeQueueCards = {}
end

local function cleanupActiveEffects()
	for _, td in ipairs(state.activeEffectThreads) do if td.thread then task.cancel(td.thread) end end
	state.activeEffectThreads = {}
end

local function createActiveCardEffects(card)
	local stroke = card:FindFirstChildWhichIsA("UIStroke")
	if stroke then stroke.Color = THEME.avatarRingGlow or THEME.accent; stroke.Thickness = 1.2; stroke.Transparency = 0.3 end
	local t1 = task.spawn(function()
		while card.Parent and card.Visible do
			if stroke then tween(stroke, 1, {Transparency = 0, Thickness = 1.6}) end; task.wait(1)
			if stroke then tween(stroke, 1, {Transparency = 0.5, Thickness = 1.2}) end; task.wait(1)
		end
	end)
	table.insert(state.activeEffectThreads, {thread = t1, card = card})
	local grad = card:FindFirstChild("ActiveGradient")
	if not grad then
		grad = make("UIGradient", {
			Name = "ActiveGradient",
			Color = ColorSequence.new{
				ColorSequenceKeypoint.new(0, Color3.fromRGB(28, 28, 32)),
				ColorSequenceKeypoint.new(0.3, Color3.fromRGB(48, 52, 70)),
				ColorSequenceKeypoint.new(0.5, Color3.fromRGB(68, 72, 100)),
				ColorSequenceKeypoint.new(0.7, Color3.fromRGB(48, 52, 70)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(28, 28, 32)),
			},
			Transparency = NumberSequence.new(0.3), Offset = Vector2.new(-1, 0), Parent = card,
		})
	end
	grad.Offset = Vector2.new(-1, 0)
	local t2 = task.spawn(function()
		while card.Parent and card.Visible do
			tween(grad, 2.5, {Offset = Vector2.new(1, 0)}); task.wait(2.5)
			grad.Offset = Vector2.new(-1, 0); task.wait(0.5)
		end
	end)
	table.insert(state.activeEffectThreads, {thread = t2, card = card})
end

local function drawQueue()
	cleanupActiveEffects()
	releaseAllQueueCards()
	if not state.queueEmptyLabel then
		state.queueEmptyLabel = makeLabel({text = "Queue is empty", color = THEME.muted, size = 14, dim = UDim2.new(1, 0, 0, 60), wrap = true, alignX = Enum.TextXAlignment.Center, parent = _ui.queueScroll})
	end
	if #state.playQueue == 0 then state.queueEmptyLabel.Visible = true; return end
	state.queueEmptyLabel.Visible = false

	for i, song in ipairs(state.playQueue) do
		local isActive = state.currentSong and song.id == state.currentSong.id
		local userId = song.userId or song.requestedByUserId
		local card = getQueueCardFromPool()
		if not card then break end
		card.LayoutOrder = i; card:SetAttribute("QueueIndex", i)
		card.BackgroundColor3 = isActive and THEME.accent or THEME.card
		card.BackgroundTransparency = isActive and THEME.subtleAlpha or THEME.frameAlpha
		card.Visible = true
		table.insert(state.activeQueueCards, card)
		local stroke = card:FindFirstChildWhichIsA("UIStroke")
		if stroke then stroke.Color = isActive and THEME.accent or THEME.stroke; stroke.Transparency = isActive and 0.6 or 0.3 end
		if isActive then createActiveCardEffects(card) end
		local avatar = card:FindFirstChild("Avatar")
		if avatar then
			avatar.Visible = userId ~= nil
			if userId then
				local as = avatar:FindFirstChild("AvatarStroke")
				if as then as.Color = isActive and THEME.accent or Color3.fromRGB(100, 100, 110); as.Thickness = isActive and 2 or 1 end
				if state.avatarCache[userId] then avatar.Image = state.avatarCache[userId]
				else
					avatar.Image = ""
					task.spawn(function()
						local ok, thumb = pcall(Players.GetUserThumbnailAsync, Players, userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
						if ok then state.avatarCache[userId] = thumb; if avatar and avatar.Parent then avatar.Image = thumb end end
					end)
				end
			end
		end
		local nameClip = card:FindFirstChild("NameClip")
		if nameClip then
			nameClip.Size = UDim2.new(1, -(50 + (isAdmin and 40 or 8)), 0, 18)
			local nl = nameClip:FindFirstChild("NameLabel")
			if nl then nl.Text = song.name or "Unknown"; nl.TextColor3 = isActive and Color3.new(1,1,1) or THEME.text end
		end
		local rl = card:FindFirstChild("RequesterLabel")
		if rl then rl.Size = UDim2.new(1, -(50 + (isAdmin and 40 or 8)), 0, 14); rl.Text = song.requestedBy or "Unknown"; rl.TextColor3 = isActive and Color3.fromRGB(220, 220, 230) or THEME.muted end
	end
end

-- Pre-create queue card pool
for _ = 1, math.min(MAX_QUEUE_POOL, 15) do
	local card = createQueueCard(); card.Parent = _ui.queueScroll; table.insert(state.queueCardPool, card)
	if isAdmin then
		local rb = card:FindFirstChild("RemoveBtn")
		if rb then rb.MouseButton1Click:Connect(function()
				local idx = card:GetAttribute("QueueIndex")
				if idx and R.Remove then R.Remove:FireServer(idx) end
			end) end
	end
end

-- ════════════════════════════════════════════════════════════════
-- SONG CARD POOL
-- ════════════════════════════════════════════════════════════════
local function createSongCard()
	local card = makeCanvas(nil, 8, 102)
	card.Name = "SongCard"; card.Size = UDim2.new(1, -8, 0, CARD_HEIGHT)
	card.BackgroundColor3 = THEME.card; card.BackgroundTransparency = THEME.frameAlpha
	card.Visible = false
	UI.stroked(card, 0.3)
	local coverBg = makeFrame({dim = UDim2.new(0, CARD_HEIGHT, 1, 0), bg = Color3.fromRGB(30, 30, 35), bgT = 0, z = 103, name = "CoverBg", parent = card})
	make("ImageLabel", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Crop, BorderSizePixel = 0, ZIndex = 104, Name = "DJCover", Parent = coverBg})
	local textX = CARD_HEIGHT + 8
	makeLabel({dim = UDim2.new(1, -(textX + 44), 0, 18), pos = UDim2.new(0, textX, 0, 10), font = Enum.Font.GothamBold, size = 14, truncate = Enum.TextTruncate.AtEnd, z = 103, name = "NameLabel", parent = card})
	makeLabel({dim = UDim2.new(1, -(textX + 44), 0, 14), pos = UDim2.new(0, textX, 0, 30), color = THEME.muted, font = Enum.Font.GothamMedium, size = 12, truncate = Enum.TextTruncate.AtEnd, z = 103, name = "ArtistLabel", parent = card})
	local addBtn = makeBtn({dim = UDim2.new(0, 32, 0, 32), pos = UDim2.new(1, -36, 0.5, -16), z = 103, round = 16, name = "AddButton", parent = card})
	makeImage({dim = UDim2.new(0.75, 0, 0.75, 0), pos = UDim2.new(0.125, 0, 0.125, 0), image = ICONS.PLAY_ADD, imageColor = THEME.text, z = 104, name = "IconImage", parent = addBtn})
	makeImage({dim = UDim2.new(0.75, 0, 0.75, 0), pos = UDim2.new(0.125, 0, 0.125, 0), image = ICONS.LOADING, imageColor = THEME.text, z = 105, visible = false, name = "LoadingIcon", parent = addBtn})
	addBtn.MouseButton1Click:Connect(function()
		local songId = card:GetAttribute("SongID")
		if songId and not isInQueue(songId) and not state.pendingCardSongIds[songId] then
			state.pendingCardSongIds[songId] = true
			local iconImg = addBtn:FindFirstChild("IconImage")
			local loadingIcon = addBtn:FindFirstChild("LoadingIcon")
			if iconImg then iconImg.Visible = false end
			if loadingIcon then
				loadingIcon.Visible = true; loadingIcon.Rotation = 0
				task.spawn(function()
					local tw = TweenService:Create(loadingIcon, TweenInfo.new(1.2, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1), {Rotation = 360})
					tw:Play(); while loadingIcon.Visible do task.wait(0.1) end; if tw then tw:Cancel() end
				end)
			end
			addBtn.BackgroundColor3 = THEME.surface; addBtn.AutoButtonColor = false
			if R.Add then R.Add:FireServer(songId) end
		end
	end)
	return card
end

local function getCardFromPool()
	for _, card in ipairs(state.cardPool) do if not card.Visible then return card end end
	if #state.cardPool < MAX_POOL_SIZE then
		local c = createSongCard(); c.Parent = _ui.songsContainer; table.insert(state.cardPool, c); return c
	end
end

local function releaseCard(card)
	local idx = card:GetAttribute("SongIndex")
	if idx then state.cardsIndex[idx] = nil end
	card.Visible = false; card:SetAttribute("SongIndex", nil); card:SetAttribute("SongID", nil)
end

local function releaseAllCards()
	state.cardsIndex = {}
	for _, card in ipairs(state.cardPool) do card.Visible = false; card:SetAttribute("SongIndex", nil); card:SetAttribute("SongID", nil) end
end

-- ════════════════════════════════════════════════════════════════
-- VIRTUAL SCROLL
-- ════════════════════════════════════════════════════════════════
local function getSongData() return virtualScrollState.isSearching and virtualScrollState.searchResults or virtualScrollState.songData end
local function getTotalSongs() return virtualScrollState.isSearching and #virtualScrollState.searchResults or virtualScrollState.totalSongs end

local function updateSongCard(card, data, index, inQ)
	if not card or not data then return end
	card:SetAttribute("SongIndex", index); card:SetAttribute("SongID", data.id)
	state.cardsIndex[index] = card
	local djCover = card:FindFirstChild("DJCover", true)
	if djCover and state.selectedDJInfo and state.selectedDJInfo.cover then djCover.Image = state.selectedDJInfo.cover end
	local nl = card:FindFirstChild("NameLabel", true)
	if nl then nl.Text = data.name or "Cargando..."; nl.TextColor3 = data.loaded and THEME.text or THEME.muted end
	local al = card:FindFirstChild("ArtistLabel", true)
	if al then al.Text = data.artist or ("ID: " .. data.id) end
	local ab = card:FindFirstChild("AddButton", true)
	if ab then
		local icon = ab:FindFirstChild("IconImage"); local li = ab:FindFirstChild("LoadingIcon")
		local isPending = state.pendingCardSongIds[data.id]
		if isPending then ab.BackgroundColor3 = THEME.surface; ab.AutoButtonColor = false; if icon then icon.Visible = false end; if li then li.Visible = true end
		elseif inQ then ab.BackgroundColor3 = THEME.success; ab.AutoButtonColor = false; if icon then icon.Image = ICONS.CHECK; icon.ImageColor3 = Color3.new(1,1,1); icon.Visible = true end; if li then li.Visible = false end
		else ab.BackgroundColor3 = Color3.fromRGB(60, 60, 68); ab.AutoButtonColor = true; if icon then icon.Image = ICONS.PLAY_ADD; icon.ImageColor3 = THEME.text; icon.Visible = true end; if li then li.Visible = false end
		end
	end
	card.Position = UDim2.new(0, 4, 0, (index - 1) * (CARD_HEIGHT + CARD_PADDING)); card.Visible = true
end

local function updateVisibleCards()
	if not _ui.songsScroll or not _ui.songsScroll.Parent then return end
	local totalItems = getTotalSongs()
	if totalItems == 0 then releaseAllCards(); return end
	local scrollY, vpH = _ui.songsScroll.CanvasPosition.Y, _ui.songsScroll.AbsoluteSize.Y
	local step = CARD_HEIGHT + CARD_PADDING
	local first = math.max(1, math.floor(scrollY / step) + 1 - VISIBLE_BUFFER)
	local last = math.min(totalItems, math.ceil((scrollY + vpH) / step) + VISIBLE_BUFFER)
	local totalH = totalItems * step
	_ui.songsContainer.Size = UDim2.new(1, 0, 0, totalH)
	_ui.songsScroll.CanvasSize = UDim2.new(0, 0, 0, totalH + 20)
	for idx, card in pairs(state.cardsIndex) do
		if card and card.Visible and (idx < first or idx > last) then releaseCard(card) end
	end
	local dataSource = getSongData()
	local needsFetch = {}
	for i = first, last do
		local sd = dataSource[i]
		if sd then
			local c = state.cardsIndex[i] or getCardFromPool()
			if c then updateSongCard(c, sd, i, isInQueue(sd.id)) end
		elseif not virtualScrollState.isSearching then table.insert(needsFetch, i) end
	end
	if #needsFetch > 0 and not virtualScrollState.isSearching then
		local mn, mx = math.huge, 0
		for _, idx in ipairs(needsFetch) do mn = math.min(mn, idx); mx = math.max(mx, idx) end
		local key = mn .. "-" .. mx
		if not virtualScrollState.pendingRequests[key] then
			virtualScrollState.pendingRequests[key] = true
			if R.GetSongRange and state.selectedDJ then R.GetSongRange:FireServer(state.selectedDJ, mn, mx) end
		end
	end
	virtualScrollState.firstVisibleIndex = first; virtualScrollState.lastVisibleIndex = last
end

local function connectScrollListener()
	if state.scrollConnection then state.scrollConnection:Disconnect() end
	state.scrollConnection = _ui.songsScroll:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
		if state.scrollDebounceThread then return end
		state.scrollDebounceThread = task.delay(0.03, function()
			state.scrollDebounceThread = nil; updateVisibleCards()
		end)
	end)
end

-- ════════════════════════════════════════════════════════════════
-- SEARCH
-- ════════════════════════════════════════════════════════════════
local function performSearch(query)
	if query == "" then
		virtualScrollState.isSearching = false; virtualScrollState.searchQuery = ""; virtualScrollState.searchResults = {}
		_ui.songCountLabel.Text = virtualScrollState.totalSongs .. " songs"
		_ui.songsScroll.CanvasPosition = Vector2.new(0, 0); updateVisibleCards(); return
	end
	virtualScrollState.isSearching = true; virtualScrollState.searchQuery = query
	_ui.loadingIndicator.Visible = true; _ui.loadingIndicator.Text = "Buscando..."
	if R.SearchSongs and state.selectedDJ then R.SearchSongs:FireServer(state.selectedDJ, query) end
end

_ui.searchInput:GetPropertyChangedSignal("Text"):Connect(function()
	if not state.selectedDJ then return end
	if state.searchDebounce then task.cancel(state.searchDebounce) end
	state.searchDebounce = task.delay(0.3, function() performSearch(_ui.searchInput.Text) end)
end)

-- ════════════════════════════════════════════════════════════════
-- HEADER COVER UPDATE (bottom bar)
-- ════════════════════════════════════════════════════════════════
local function updateHeaderCover(song)
	if not song then
		if state.currentHeaderCover ~= "" then
			state.currentHeaderCover = ""
			TweenService:Create(_ui.bottomBarBg, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {ImageTransparency = 1}):Play()
			task.delay(0.3, function() _ui.miniCover.Image = ""; _ui.bottomBarBg.Image = ""; _ui.headerDJName.Text = "" end)
		end; return
	end
	local cover = song.djCover or ""
	if cover ~= state.currentHeaderCover then
		state.currentHeaderCover = cover
		TweenService:Create(_ui.bottomBarBg, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {ImageTransparency = 1}):Play()
		task.delay(0.25, function()
			_ui.miniCover.Image = cover; _ui.bottomBarBg.Image = cover
			TweenService:Create(_ui.bottomBarBg, TweenInfo.new(0.35, Enum.EasingStyle.Quad), {ImageTransparency = 0.6}):Play()
		end)
	end
	_ui.headerDJName.Text = song.dj or ""
	_ui.headerSongID.Text = song.id and tostring(song.id) or ""
	_ui.songIdDisplay.Text = song.id and tostring(song.id) or ""
end

-- ════════════════════════════════════════════════════════════════
-- DJ LIST — Sidebar Thumbnails
-- ════════════════════════════════════════════════════════════════
local function clearChildren(parent, keep)
	for _, child in pairs(parent:GetChildren()) do
		local skip = false
		for _, cls in ipairs(keep or {}) do if child:IsA(cls) then skip = true; break end end
		if not skip then child:Destroy() end
	end
end

local function selectDJ(djName, djData, card)
	if state.selectedDJ == djName and state.currentView == "songs" then return end
	if state.selectedDJCard and state.selectedDJCard ~= card then
		local ps = state.selectedDJCard:FindFirstChild("CardStroke")
		if ps then tween(ps, 0.25, {Color = THEME.stroke, Thickness = 1, Transparency = 0.7}) end
		local pn = state.selectedDJCard:FindFirstChild("DJNameLabel")
		if pn then tween(pn, 0.25, {TextColor3 = Color3.fromRGB(180, 180, 190)}) end
	end
	state.selectedDJ = djName; state.selectedDJInfo = djData; state.selectedDJCard = card
	local s = card:FindFirstChild("CardStroke")
	if s then tween(s, 0.25, {Color = THEME.accent, Thickness = 2, Transparency = 0.2}) end
	local dn = card:FindFirstChild("DJNameLabel")
	if dn then tween(dn, 0.25, {TextColor3 = Color3.new(1, 1, 1)}) end
	state.currentView = "queue"; switchView("songs")
	_ui.songsTitle.Text = djName; _ui.songCountLabel.Text = djData.songCount .. " songs"; _ui.songCountLabel.Visible = true
	_ui.songsPlaceholder.Visible = false
	if djData.cover and djData.cover ~= "" then
		_ui.mainHeaderCoverImg.Image = djData.cover
		tween(_ui.mainHeaderCoverImg, 0.35, {ImageTransparency = 0.45})
		_ui.headerGradientFrame.BackgroundColor3 = THEME.accent
		tween(_ui.headerGradientFrame, 0.35, {BackgroundTransparency = 0.3})
	else tween(_ui.mainHeaderCoverImg, 0.3, {ImageTransparency = 1}) end
	virtualScrollState.totalSongs = djData.songCount; virtualScrollState.songData = {}
	virtualScrollState.searchResults = {}; virtualScrollState.isSearching = false
	virtualScrollState.searchQuery = ""; virtualScrollState.pendingRequests = {}
	_ui.searchInput.Text = ""; releaseAllCards()
	_ui.songsScroll.CanvasPosition = Vector2.new(0, 0)
	_ui.loadingIndicator.Visible = true; _ui.loadingIndicator.Text = "Cargando canciones..."
	_ui.loadingIndicator.Position = UDim2.new(0, 0, 0, 4)
	local totalH = djData.songCount * (CARD_HEIGHT + CARD_PADDING)
	_ui.songsContainer.Size = UDim2.new(1, 0, 0, totalH)
	_ui.songsScroll.CanvasSize = UDim2.new(0, 0, 0, totalH + 20)
	connectScrollListener()
	if R.GetSongRange then R.GetSongRange:FireServer(djName, 1, math.min(djData.songCount, 25)) end
end

local function drawDJs()
	clearChildren(_ui.djsScroll, {"UIListLayout", "UIPadding"})
	state.selectedDJCard = nil
	if #state.allDJs == 0 then
		makeLabel({text = "No DJs", color = THEME.muted, size = 11, dim = UDim2.new(1, 0, 0, 40), wrap = true, alignX = Enum.TextXAlignment.Center, parent = _ui.djsScroll})
		return
	end
	local thumbSize = SIDEBAR_W - 24
	for _, dj in ipairs(state.allDJs) do
		local isSel = state.selectedDJ == dj.name
		local card = makeCanvas(_ui.djsScroll, 10, 102)
		card.Name = "DJThumb"; card.Size = UDim2.new(1, 0, 0, DJ_THUMB_H)
		card.BackgroundColor3 = THEME.card; card.BackgroundTransparency = THEME.frameAlpha
		local stroke = make("UIStroke", {
			Color = isSel and THEME.accent or THEME.stroke, Thickness = isSel and 2 or 1,
			Transparency = isSel and 0.2 or 0.7, ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Name = "CardStroke", Parent = card,
		})
		if isSel then state.selectedDJCard = card end
		local coverBg = makeFrame({dim = UDim2.new(0, thumbSize, 0, thumbSize), pos = UDim2.new(0.5, -thumbSize/2, 0, 4), bg = Color3.fromRGB(30, 30, 40), bgT = 0, z = 103, clip = true, name = "CoverBg", parent = card})
		makeLabel({dim = UDim2.new(1, 0, 1, 0), text = "♪", font = Enum.Font.GothamBold, size = 22, color = isSel and THEME.accent or THEME.muted, alignX = Enum.TextXAlignment.Center, z = 104, parent = coverBg})
		if dj.cover and dj.cover ~= "" then
			make("ImageLabel", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Image = dj.cover, ScaleType = Enum.ScaleType.Crop, BorderSizePixel = 0, ZIndex = 105, Parent = coverBg})
		end
		makeLabel({dim = UDim2.new(1, -4, 0, 16), pos = UDim2.new(0, 2, 1, -(mob and 16 or 18)), text = dj.name, font = Enum.Font.GothamBold, size = mob and 9 or 11, color = isSel and Color3.new(1,1,1) or Color3.fromRGB(180, 180, 190), alignX = Enum.TextXAlignment.Center, truncate = Enum.TextTruncate.AtEnd, z = 103, name = "DJNameLabel", parent = card})
		local clickBtn = makeBtn({dim = UDim2.new(1, 0, 1, 0), z = 110, parent = card})
		clickBtn.BackgroundTransparency = 1
		clickBtn.MouseEnter:Connect(function() if state.selectedDJCard ~= card then tween(stroke, 0.15, {Color = THEME.accent, Transparency = 0.35, Thickness = 1.5}) end end)
		clickBtn.MouseLeave:Connect(function() if state.selectedDJCard ~= card then tween(stroke, 0.2, {Color = THEME.stroke, Transparency = 0.7, Thickness = 1}) end end)
		clickBtn.MouseButton1Click:Connect(function() selectDJ(dj.name, dj, card) end)
	end
end

-- ════════════════════════════════════════════════════════════════
-- PROGRESS BAR + VISUALIZER
-- ════════════════════════════════════════════════════════════════
local function updateProgressBar(dt)
	if not state.currentSoundObject then state.currentSoundObject = workspace:FindFirstChild("QueueSound") end
	if not state.currentSoundObject or not state.currentSoundObject:IsA("Sound") or not state.currentSoundObject.Parent then
		if state.progressTween then state.progressTween:Cancel(); state.progressTween = nil end
		_ui.progressFill.Size = UDim2.new(0, 0, 1, 0)
		_ui.currentTimeLabel.Text = "0:00"; _ui.totalTimeLabel.Text = "0:00"; state.progressAccum = 0
		if not state.currentSong then _ui.songTitle.Text = "No song playing" end; return
	end
	local total = state.currentSoundObject.TimeLength
	if total <= 0 then _ui.progressFill.Size = UDim2.new(0, 0, 1, 0); _ui.currentTimeLabel.Text = "0:00"; _ui.totalTimeLabel.Text = "0:00"; return end
	state.progressAccum = state.progressAccum + dt
	if state.progressAccum < 0.1 then return end; state.progressAccum = 0
	local rawPos = state.currentSoundObject.TimePosition
	local frac = math.clamp(rawPos / total, 0, 1)
	if state.progressTween then state.progressTween:Cancel() end
	state.progressTween = TweenService:Create(_ui.progressFill, TweenInfo.new(0.12, Enum.EasingStyle.Linear), {Size = UDim2.new(frac, 0, 1, 0)})
	state.progressTween:Play()
	_ui.currentTimeLabel.Text = formatTime(rawPos); _ui.totalTimeLabel.Text = formatTime(total)
end

local function startVisualizer()
	if state.visualizerConnection then state.visualizerConnection:Disconnect() end
	local vizAccum = 0
	state.visualizerConnection = RunService.Heartbeat:Connect(function(dt)
		vizAccum = vizAccum + dt; if vizAccum < 0.033 then return end
		local elapsed = vizAccum; vizAccum = 0
		local loudness, hasAudio = 0, false
		if state.currentSoundObject and state.currentSoundObject:IsA("Sound") and state.currentSoundObject.IsPlaying then
			loudness = math.clamp(state.currentSoundObject.PlaybackLoudness / 300, 0, 1); hasAudio = loudness > 0.001
		end
		local time = tick()
		for i, bd in ipairs(_ui.visualizerBars) do
			local bar = bd.frame
			if bar and bar.Parent then
				local targetH, maxH = 0, VISUALIZER.BAR_MAX_H
				if hasAudio then
					targetH = math.clamp(loudness * maxH * (0.4 + 0.6 * (1 - bd.freqWeight)) * (math.sin(time * 8 + bd.phase * 3) * 0.3 + 0.7) * (1 - bd.freqWeight * 0.5), 2, maxH)
				else
					targetH = 2 + (math.floor(maxH * 0.35) - 2) * (math.sin(time * 1.8 + bd.phase) * 0.5 + 0.5) * (math.sin(time * 1.26 + bd.phase * 1.3) * 0.3 + 0.7)
				end
				bd.currentH = bd.currentH + (targetH - bd.currentH) * ((targetH > bd.currentH) and 12 or 8) * elapsed
				local h = math.floor(math.clamp(bd.currentH, 2, maxH))
				bar.Size = UDim2.new(0, VISUALIZER.BAR_WIDTH, 0, h)
				bar.Position = UDim2.new(bar.Position.X.Scale, bar.Position.X.Offset, 1, -h)
				local t = math.clamp((h - 2) / (maxH - 2), 0, 1)
				bar.BackgroundColor3 = Color3.fromRGB(100, 80, 180):Lerp(Color3.fromRGB(130, 100, 220), t)
				bar.BackgroundTransparency = hasAudio and (0.05 + (1 - t) * 0.15) or 0.35
			end
		end
	end)
end

-- ════════════════════════════════════════════════════════════════
-- UI OPEN/CLOSE
-- ════════════════════════════════════════════════════════════════
local function openUI()
	if modal:isModalOpen() then return end
	state.currentView = "queue"
	_ui.songsView.Visible = false; _ui.queueView.Visible = true
	_ui.songsTitle.Text = "PLAYLIST QUEUE"; _ui.songCountLabel.Visible = false
	_ui.searchContainer.Visible = false
	if _ui.clearB then _ui.clearB.Visible = true end
	_ui.mainHeaderCoverImg.ImageTransparency = 1
	_ui.headerGradientFrame.BackgroundColor3 = THEME.accent; _ui.headerGradientFrame.BackgroundTransparency = 0.6
	_ui.queueBtnStroke.Color = THEME.accent; _ui.queueBtnStroke.Transparency = 0.2; _ui.queueBtnStroke.Thickness = 1.5
	drawQueue()
	if #state.allDJs > 0 then drawDJs() end
	modal:open()
	if state.progressConnection then state.progressConnection:Disconnect() end
	state.progressConnection = RunService.Heartbeat:Connect(updateProgressBar)
	startVisualizer()
end

local function closeUI()
	if modal:isModalOpen() then modal:close() end
	if state.visualizerConnection then state.visualizerConnection:Disconnect(); state.visualizerConnection = nil end
end

-- ════════════════════════════════════════════════════════════════
-- EVENTS
-- ════════════════════════════════════════════════════════════════
UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.Escape and modal:isModalOpen() then GlobalModalManager:closeModal("Music")
	elseif input.KeyCode == Enum.KeyCode.Return and _ui.volInput.Visible then applyVolumeInput() end
end)

-- ════════════════════════════════════════════════════════════════
-- REMOTE UPDATES
-- ════════════════════════════════════════════════════════════════
local function updateNowPlayingInfo(song)
	if song then
		_ui.songTitle.Text = song.name; _ui.headerDJName.Text = song.artist or "Unknown"
		_ui.headerSongID.Text = song.id and tostring(song.id) or ""; _ui.songIdDisplay.Text = song.id and tostring(song.id) or ""
	else
		_ui.songTitle.Text = "No song playing"; _ui.headerDJName.Text = ""; _ui.headerSongID.Text = ""; _ui.songIdDisplay.Text = ""
	end
end

local function processUpdate(data)
	state.playQueue = data.queue or {}; state.currentSong = data.currentSong
	state.currentSoundObject = workspace:FindFirstChild("QueueSound")
	updateNowPlayingInfo(state.currentSong); updateHeaderCover(state.currentSong)
	drawQueue()
	if state.selectedDJ then updateVisibleCards() end
	local newDJs = data.djs or state.allDJs
	local djsChanged = #newDJs ~= #state.allDJs
	if not djsChanged then
		for i, dj in ipairs(newDJs) do
			if not state.allDJs[i] or state.allDJs[i].name ~= dj.name or state.allDJs[i].songCount ~= dj.songCount then djsChanged = true; break end
		end
	end
	if djsChanged then state.allDJs = newDJs; drawDJs() end
end

if R.Update then
	R.Update.OnClientEvent:Connect(function(data)
		local now = tick()
		if (now - state.lastUpdateTime) < 0.15 then
			state.pendingUpdate = data
			if not state.pendingUpdate._scheduled then
				state.pendingUpdate._scheduled = true
				task.delay(0.15, function()
					if state.pendingUpdate then state.lastUpdateTime = tick(); processUpdate(state.pendingUpdate); state.pendingUpdate = nil end
				end)
			end; return
		end
		state.lastUpdateTime = now; state.pendingUpdate = nil; processUpdate(data)
	end)
end

if R.GetDJs then R.GetDJs.OnClientEvent:Connect(function(d) state.allDJs = (d and (d.djs or d)) or state.allDJs; drawDJs() end) end

if R.GetSongRange then
	R.GetSongRange.OnClientEvent:Connect(function(data)
		if not data or data.djName ~= state.selectedDJ then return end
		_ui.loadingIndicator.Visible = false
		for _, song in ipairs(data.songs or {}) do virtualScrollState.songData[song.index] = song end
		virtualScrollState.pendingRequests[data.startIndex .. "-" .. data.endIndex] = nil
		updateVisibleCards()
	end)
end

if R.SearchSongs then
	R.SearchSongs.OnClientEvent:Connect(function(data)
		if not data or data.djName ~= state.selectedDJ then return end
		_ui.loadingIndicator.Visible = false
		virtualScrollState.searchResults = data.songs or {}
		local total = data.totalInDJ or virtualScrollState.totalSongs
		local ct = #virtualScrollState.searchResults .. " / " .. total .. " songs"
		if data.cachedCount and data.cachedCount < total then ct = ct .. " " .. math.floor(data.cachedCount / total * 100) .. "%" end
		_ui.songCountLabel.Text = ct; _ui.songsScroll.CanvasPosition = Vector2.new(0, 0); updateVisibleCards()
	end)
end

if R.GetSongsByDJ then
	R.GetSongsByDJ.OnClientEvent:Connect(function(data)
		if not data or data.djName ~= state.selectedDJ then return end
		virtualScrollState.totalSongs = data.total or 0; _ui.songCountLabel.Text = data.total .. " songs"
		local totalH = data.total * (CARD_HEIGHT + CARD_PADDING)
		_ui.songsContainer.Size = UDim2.new(1, 0, 0, totalH); _ui.songsScroll.CanvasSize = UDim2.new(0, 0, 0, totalH + 20)
	end)
end

-- ════════════════════════════════════════════════════════════════
-- INITIALIZATION
-- ════════════════════════════════════════════════════════════════
if R.GetDJs then R.GetDJs:FireServer() end
for _ = 1, MAX_POOL_SIZE do
	local card = createSongCard(); card.Parent = _ui.songsContainer; table.insert(state.cardPool, card)
end

print("[MusicDashboard] Sidebar layout v3 loaded OK")

_G.OpenMusicUI = openUI
_G.CloseMusicUI = closeUI