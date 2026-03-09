--[[
	═══════════════════════════════════════════════════════════
	CLAN SYSTEM UI - Rediseño v3 (Sidebar Pattern)
	═══════════════════════════════════════════════════════════
	Layout: SidebarNav + ContentArea (mismo patrón que GamepassShop)
	by ignxts
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

-- Módulos externos
local UI = require(ReplicatedStorage:WaitForChild("Core"):WaitForChild("UI"))
local THEME = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("ThemeConfig"))
local AdminConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("AdminConfig"))
local ClanSystemConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("ClanSystemConfig"))
local ClanClient = require(ReplicatedStorage:WaitForChild("Systems"):WaitForChild("ClanSystem"):WaitForChild("ClanClient"))
local GlobalModalManager = require(ReplicatedStorage:WaitForChild("Systems"):WaitForChild("GlobalModalManager"))
local ModalManager = require(ReplicatedStorage:WaitForChild("Modal"):WaitForChild("ModalManager"))
local SearchModern = require(ReplicatedStorage:WaitForChild("UIComponents"):WaitForChild("SearchModern"))
local SidebarNav = require(ReplicatedStorage:WaitForChild("UIComponents"):WaitForChild("SidebarNav"))

-- Módulos internos del sistema de clanes
local ClanConstants = require(script.Parent.ClanConstants)
local ClanHelpers = require(script.Parent.ClanHelpers)
local ClanNetworking = require(script.Parent.ClanNetworking)

-- Referencias locales
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local CONFIG = ClanConstants.CONFIG
local State = ClanConstants.State
local Memory = ClanConstants.Memory
local isAdmin = AdminConfig:IsAdmin(player)

-- Configurar el tracking de UI
UI.setTrack(function(conn) return Memory:track(conn) end)

-- ════════════════════════════════════════════════════════════════
-- ROOT GUI
-- ════════════════════════════════════════════════════════════════
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ClanSystemGui"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

task.wait(0.5)
local isMobileDevice = UserInputService.TouchEnabled

-- ════════════════════════════════════════════════════════════════
-- MODAL MANAGER
-- ════════════════════════════════════════════════════════════════
local modal = ModalManager.new({
	screenGui = screenGui,
	panelName = "ClanPanel",
	panelWidth = THEME.panelWidth,
	panelHeight = THEME.panelHeight,
	cornerRadius = CONFIG.panel.corner,
	enableBlur = CONFIG.blur.enabled,
	blurSize = CONFIG.blur.size,
	isMobile = isMobileDevice,
	onClose = function() end
})

local panel = modal:getPanel()
panel.BackgroundColor3 = THEME.bg
panel.BackgroundTransparency = THEME.mediumAlpha

local CONTAINER = modal:getCanvas()  -- recorta hijos respetando UICorner

local tabPages = {}
local switchTab     -- forward declaration
local contentTitle  -- label del header, actualizado en switchTab

-- ════════════════════════════════════════════════════════════════
-- SIDEBAR — NAVEGACIÓN LATERAL
-- ════════════════════════════════════════════════════════════════
local SIDEBAR_W = isMobileDevice and 100 or 130
local HEADER_H  = 52

local CLAN_NAV_ITEMS = {
	{ id = "TuClan",      label = "Tu Clan"   ,image="79638260789908"},  -- reemplaza 0 con tu asset id
	{ id = "Disponibles", label = "Disponibles",image="75350864255657"}, -- reemplaza 0 con tu asset id
}
if isAdmin then
	table.insert(CLAN_NAV_ITEMS, { id = "Admin", label = "Admin",image="81010877025533"})  -- reemplaza 0 con tu asset id
end

local sidebarNavInstance = SidebarNav.new({
	parent      = CONTAINER,
	UI          = UI,
	THEME       = THEME,
	title       = "CLANES",
	items       = CLAN_NAV_ITEMS,
	width       = SIDEBAR_W,
	isMobile    = isMobileDevice,
	onSelect    = function(id)
		switchTab(id)
	end,
})

-- ════════════════════════════════════════════════════════════════
-- CONTENT AREA
-- ════════════════════════════════════════════════════════════════
local contentArea = UI.frame({
	name   = "ContentArea",
	size   = UDim2.new(1, -SIDEBAR_W, 1, 0),
	pos    = UDim2.new(0, SIDEBAR_W, 0, 0),
	bgT    = 1, z = 100,
	parent = CONTAINER, clips = true,
})

-- Header superior del content area (mismo patrón que GamepassShop)
local contentHeader = UI.frame({
	name   = "ContentHeader",
	size   = UDim2.new(1, 0, 0, HEADER_H),
	bg     = THEME.bg, bgT = THEME.lightAlpha,
	z      = 150, parent = contentArea,
})

contentTitle = UI.label({
	name      = "Title",
	size      = UDim2.new(1, -20, 0, HEADER_H),
	pos       = UDim2.new(0, 18, 0, 0),
	text      = "TU CLAN",
	color     = THEME.text,
	font      = Enum.Font.GothamBlack, textSize = 18,
	alignX    = Enum.TextXAlignment.Left,
	z         = 152, parent = contentHeader,
})

local headerLine = Instance.new("Frame")
headerLine.Size                   = UDim2.new(1, -20, 0, 1)
headerLine.Position               = UDim2.new(0, 10, 1, -1)
headerLine.BackgroundColor3       = THEME.stroke
headerLine.BackgroundTransparency = THEME.mediumAlpha
headerLine.BorderSizePixel        = 0
headerLine.ZIndex                 = 152
headerLine.Parent                 = contentHeader

-- Área de páginas (debajo del header)
local pagesContainer = UI.frame({
	name   = "PagesContainer",
	size   = UDim2.new(1, 0, 1, -HEADER_H),
	pos    = UDim2.new(0, 0, 0, HEADER_H),
	bgT    = 1, z = 101,
	parent = contentArea, clips = true,
})

local pageLayout = Instance.new("UIPageLayout")
pageLayout.FillDirection          = Enum.FillDirection.Vertical
pageLayout.SortOrder              = Enum.SortOrder.LayoutOrder
pageLayout.HorizontalAlignment    = Enum.HorizontalAlignment.Center
pageLayout.EasingStyle            = Enum.EasingStyle.Sine
pageLayout.EasingDirection        = Enum.EasingDirection.InOut
pageLayout.TweenTime              = 0.35
pageLayout.ScrollWheelInputEnabled = false
pageLayout.TouchInputEnabled      = false
pageLayout.Parent                 = pagesContainer

-- ════════════════════════════════════════════════════════════════
-- PAGE: TU CLAN
-- ════════════════════════════════════════════════════════════════
local pageTuClan = UI.frame({name = "TuClan", size = UDim2.fromScale(1, 1), bgT = 1, z = 102, parent = pagesContainer})
pageTuClan.LayoutOrder = 1
local tuClanContainer = UI.frame({name = "Container", size = UDim2.new(1, -20, 1, -20), pos = UDim2.new(0, 10, 0, 10), bgT = 1, z = 102, parent = pageTuClan})
tabPages["TuClan"] = pageTuClan

-- ════════════════════════════════════════════════════════════════
-- PAGE: DISPONIBLES
-- ════════════════════════════════════════════════════════════════
local pageDisponibles = UI.frame({name = "Disponibles", size = UDim2.fromScale(1, 1), bgT = 1, z = 102, parent = pagesContainer})
pageDisponibles.LayoutOrder = 2

local searchContainer, searchInput, searchCleanup = SearchModern.new(pageDisponibles, {placeholder = "Buscar clanes...", size = UDim2.new(1, -20, 0, 36), z = 104, name = "BuscarClanes"})
searchContainer.Position = UDim2.new(0, 10, 0, 10)
Memory:track({Disconnect = searchCleanup})

local clansScroll = ClanHelpers.setupScroll(pageDisponibles, {size = UDim2.new(1, -20, 1, -56), pos = UDim2.new(0, 10, 0, 52), padding = 8, z = 103})

local searchDebounce = false
searchInput:GetPropertyChangedSignal("Text"):Connect(function()
	if searchDebounce then return end
	searchDebounce = true
	task.delay(0.4, function()
		if State.currentPage == "Disponibles" and State.isOpen then 
			ClanNetworking.loadClansFromServer(clansScroll, State, CONFIG, searchInput.Text)
		end
		searchDebounce = false
	end)
end)

tabPages["Disponibles"] = pageDisponibles

-- ════════════════════════════════════════════════════════════════
-- PAGE: ADMIN
-- ════════════════════════════════════════════════════════════════
local pageAdmin, adminClansScroll

if isAdmin then
	pageAdmin = UI.frame({name = "Admin", size = UDim2.fromScale(1, 1), bgT = 1, z = 102, parent = pagesContainer})
	pageAdmin.LayoutOrder = 3

	local adminHeader = UI.frame({size = UDim2.new(1, -20, 0, 40), pos = UDim2.new(0, 10, 0, 10), bg = THEME.warnMuted, z = 103, parent = pageAdmin, corner = 8, stroke = true, strokeA = 0.5, strokeC = THEME.btnDanger})
	UI.label({size = UDim2.new(1, -16, 1, 0), pos = UDim2.new(0, 8, 0, 0), text = "⚠ Panel de Administrador - Acciones irreversibles", color = THEME.warn, textSize = 11, font = Enum.Font.GothamMedium, z = 104, parent = adminHeader})

	adminClansScroll = ClanHelpers.setupScroll(pageAdmin, {z = 103})
	tabPages["Admin"] = pageAdmin
end

-- ════════════════════════════════════════════════════════════════
-- TAB SWITCHING
-- ════════════════════════════════════════════════════════════════
switchTab = function(tabName, forceLoad)
	if State.currentPage == tabName and not forceLoad then return end

	State.loadingId = State.loadingId + 1
	UI.cleanupLoading()

	State.currentPage = tabName
	State.currentView = "main"

	-- Actualizar título del header
	local TAB_TITLES = { TuClan = "TU CLAN", Disponibles = "DISPONIBLES", Admin = "ADMINISTRADOR" }
	if contentTitle then contentTitle.Text = TAB_TITLES[tabName] or tabName end

	local pageFrame = pagesContainer:FindFirstChild(tabName)
	if pageFrame then pageLayout:JumpTo(pageFrame) end

	task.delay(0.05, function()
		if State.currentPage ~= tabName then return end
		if not State.isOpen then return end

		local reloadFunc = function(v) ClanNetworking.reloadAndKeepView(tuClanContainer, screenGui, State, v) end

		if tabName == "TuClan" then 
			ClanNetworking.loadPlayerClan(tuClanContainer, screenGui, State, reloadFunc)
		elseif tabName == "Disponibles" then 
			ClanNetworking.loadClansFromServer(clansScroll, State, CONFIG)
		elseif tabName == "Admin" and isAdmin then 
			ClanNetworking.loadAdminClans(adminClansScroll, screenGui, State, CONFIG)
		end
	end)
end

-- ════════════════════════════════════════════════════════════════
-- OPEN/CLOSE FUNCTIONS
-- ════════════════════════════════════════════════════════════════
local function openUI()
	State.isOpen = true
	State.currentPage = nil

	modal:open()

	if not ClanClient.initialized then 
		task.spawn(function() ClanClient:Initialize() end) 
	end

	sidebarNavInstance:selectItem("TuClan")
	switchTab("TuClan", true)
end

local function closeUI()
	State.isOpen = false
	State.isUpdating = false
	State.loadingId = State.loadingId + 1

	Memory:cleanup()
	UI.cleanupLoading()

	if State.membersList then State.membersList:destroy() State.membersList = nil end
	if State.pendingList then State.pendingList:destroy() State.pendingList = nil end

	State.views = {}
	State.viewFactories = {}
	State.currentView = "main"
	State.currentPage = nil
	State.clanData = nil
	State.playerRole = nil

	modal:close()
end

-- ════════════════════════════════════════════════════════════════
-- LISTENER DEL SERVIDOR
-- ════════════════════════════════════════════════════════════════
local listenerLastTime = 0

-- Registrar callback para actualizar la UI cuando hay cambios
ClanClient:OnClansUpdated(function(changedClanId)
	if not State.isOpen then return end
	if not screenGui or not screenGui.Parent then return end

	local now = tick()
	if (now - listenerLastTime) < CONFIG.listenerCooldown then return end
	listenerLastTime = now

	-- ✅ Incrementar loadingId INMEDIATAMENTE para cancelar refreshes anteriores pendientes
	State.loadingId = State.loadingId + 1

	-- ✅ NO usar task.defer - las funciones ya usan task.spawn internamente
	if State.currentPage == "TuClan" then 
		ClanNetworking.reloadAndKeepView(tuClanContainer, screenGui, State, State.currentView)
	elseif State.currentPage == "Disponibles" then 
		ClanNetworking.loadClansFromServer(clansScroll, State, CONFIG, "", false)  -- Sin clansFromEvent, siempre hace fetch
	elseif State.currentPage == "Admin" and isAdmin then 
		ClanNetworking.loadAdminClans(adminClansScroll, screenGui, State, CONFIG)
	end
end)

-- Pre-cargar datos del cliente
task.spawn(function() 
	ClanClient:Initialize()
end)

-- ════════════════════════════════════════════════════════════════
-- EXPORT GLOBAL API
-- ════════════════════════════════════════════════════════════════
_G.OpenClanUI = openUI
_G.CloseClanUI = closeUI
