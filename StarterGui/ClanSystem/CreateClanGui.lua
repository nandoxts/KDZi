--[[
	═══════════════════════════════════════════════════════════
	CLAN SYSTEM UI - Rediseño v4 (SubTabs Pattern)
	═══════════════════════════════════════════════════════════
	Layout: SubTabs + ContentArea full-width (mismo patrón que MenuPanel)
	by ignxts
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

-- Módulos externos
local UI = require(ReplicatedStorage:WaitForChild("Core"):WaitForChild("UI"))
local THEME = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("ThemeConfig"))
local AdminConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("AdminConfig"))
local ClanClient = require(ReplicatedStorage:WaitForChild("Systems"):WaitForChild("ClanSystem"):WaitForChild("ClanClient"))
local ModalManager = require(ReplicatedStorage:WaitForChild("Modal"):WaitForChild("ModalManager"))
local SearchModern = require(ReplicatedStorage:WaitForChild("UIComponents"):WaitForChild("SearchModern"))
local SubTabs = require(ReplicatedStorage:WaitForChild("UIComponents"):WaitForChild("SubTabs"))

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
	panelWidth = 650,
	panelHeight = 500,
	cornerRadius = CONFIG.panel.corner,
	enableBlur = CONFIG.blur.enabled,
	blurSize = CONFIG.blur.size,
	isMobile = isMobileDevice,
	onClose = function() end
})

local panel = modal:getPanel()

local CONTAINER = modal:getCanvas()  -- recorta hijos respetando UICorner

local tabPages = {}
local switchTab     -- forward declaration

-- ════════════════════════════════════════════════════════════════
-- SUBTABS — NAVEGACIÓN SUPERIOR (patrón MenuPanel)
-- ════════════════════════════════════════════════════════════════
local TABBAR_H = 42

local CLAN_TABS = {
	{ id = "TuClan",      label = "TU CLAN" },
	{ id = "Disponibles", label = "DISPONIBLES" },
}
if isAdmin then
	table.insert(CLAN_TABS, { id = "Admin", label = "ADMIN" })
end

local subTabs = SubTabs.new(CONTAINER, THEME, {
	tabs    = CLAN_TABS,
	height  = TABBAR_H,
	z       = 215,
	textSize = 13,
	default = "TuClan",
})

-- ════════════════════════════════════════════════════════════════
-- CONTENT AREA (full-width debajo del tab bar)
-- ════════════════════════════════════════════════════════════════
local contentArea = UI.frame({
	name   = "ContentArea",
	size   = UDim2.new(1, 0, 1, -TABBAR_H),
	pos    = UDim2.new(0, 0, 0, TABBAR_H),
	bgT    = 1, z = 100,
	parent = CONTAINER, clips = true,
})

-- ════════════════════════════════════════════════════════════════
-- PAGE: TU CLAN
-- ════════════════════════════════════════════════════════════════
local pageTuClan = UI.frame({name = "TuClan", size = UDim2.fromScale(1, 1), bgT = 1, z = 102, parent = contentArea})
local tuClanContainer = UI.frame({name = "Container", size = UDim2.new(1, -20, 1, -20), pos = UDim2.new(0, 10, 0, 10), bgT = 1, z = 102, parent = pageTuClan})
tabPages["TuClan"] = pageTuClan

-- ════════════════════════════════════════════════════════════════
-- PAGE: DISPONIBLES
-- ════════════════════════════════════════════════════════════════
local pageDisponibles = UI.frame({name = "Disponibles", size = UDim2.fromScale(1, 1), bgT = 1, z = 102, parent = contentArea})

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
	pageAdmin = UI.frame({name = "Admin", size = UDim2.fromScale(1, 1), bgT = 1, z = 102, parent = contentArea})

	local adminHeader = UI.frame({size = UDim2.new(1, -20, 0, 40), pos = UDim2.new(0, 10, 0, 10), bg = THEME.elevated, z = 103, parent = pageAdmin, corner = 8, stroke = true, strokeA = 0.5, strokeC = THEME.danger})
	UI.label({size = UDim2.new(1, -16, 1, 0), pos = UDim2.new(0, 8, 0, 0), text = "⚠ Panel de Administrador - Acciones irreversibles", color = THEME.warn, textSize = 11, font = Enum.Font.GothamMedium, z = 104, parent = adminHeader})

	adminClansScroll = ClanHelpers.setupScroll(pageAdmin, {z = 103})
	tabPages["Admin"] = pageAdmin
end

-- ════════════════════════════════════════════════════════════════
-- REGISTRAR PÁGINAS EN SUBTABS (slide automático)
-- ════════════════════════════════════════════════════════════════
subTabs:register("TuClan", pageTuClan)
subTabs:register("Disponibles", pageDisponibles)
if isAdmin and pageAdmin then subTabs:register("Admin", pageAdmin) end

-- ════════════════════════════════════════════════════════════════
-- TAB SWITCHING (solo carga de datos, SubTabs maneja la UI)
-- ════════════════════════════════════════════════════════════════
switchTab = function(tabName, forceLoad)
	if State.currentPage == tabName and not forceLoad then return end

	State.loadingId = State.loadingId + 1
	UI.cleanupLoading()

	State.currentPage = tabName
	State.currentView = "main"

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

subTabs.onSwitch = function(tabId)
	switchTab(tabId)
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

	-- Reset y seleccionar TuClan (SubTabs maneja slide + blob)
	for id, p in pairs(subTabs.panels) do p.Visible = false end
	subTabs.activeId = nil
	subTabs:select("TuClan")
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

	subTabs.activeId = nil

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
