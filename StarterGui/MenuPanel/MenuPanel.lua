--[[
	MenuPanel.lua — Controlador del panel lateral v5.0 BLACKOUT CLEAN
	Diseño basado en la foto de referencia:
	  ✦ SIN botón cerrar (se cierra con overlay o _G.CloseMenuPanel)
	  ✦ SIN bordes / UIStroke en ningún lado
	  ✦ SIN líneas divisoras
	  ✦ Tabs estilo PILL: icono + texto en la misma línea
	  ✦ Tab activa con fondo pill + texto naranja
	  ✦ Negro puro, naranja fuerte
	  ✦ Music tab se dibuja primero
]]

-- ════════════════════════════════════════════════════════
-- SERVICIOS
-- ════════════════════════════════════════════════════════
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ════════════════════════════════════════════════════════
-- MÓDULOS
-- ════════════════════════════════════════════════════════
local THEME = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("ThemeConfig"))

local Tabs       = script.Parent:WaitForChild("Tabs")
local MusicTab   = require(Tabs:WaitForChild("MusicTab"))
local ShopTab    = require(Tabs:WaitForChild("ShopTab"))
local CreditsTab = require(Tabs:WaitForChild("CreditsTab"))

-- ════════════════════════════════════════════════════════
-- STUBS GLOBALES TEMPRANOS
-- ════════════════════════════════════════════════════════
local _panelReady   = false
local _pendingOpen  = nil
_G.OpenMenuPanel = function(defaultTab)
	if _panelReady then
		_G.OpenMenuPanel(defaultTab)
	else
		_pendingOpen = defaultTab or "music"
	end
end
_G.CloseMenuPanel = function() end

-- ════════════════════════════════════════════════════════
-- CONSTANTES DE LAYOUT
-- ════════════════════════════════════════════════════════
local PANEL_W   = THEME.panelWidth or 390
local HEADER_H  = 50
local TABBAR_H  = 52
local CONTENT_Y = HEADER_H + TABBAR_H  -- 102

local TW_SNAP   = TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local TW_SMOOTH = TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local TW_SLIDE  = TweenInfo.new(0.34, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

local POS_OPEN   = UDim2.new(1, 0, 0, 0)
local POS_CLOSED = UDim2.new(1, PANEL_W + 10, 0, 0)

local TABS = {
	{ id = "music",   label = "MÚSICA",   icon = "♫" },
	{ id = "shop",    label = "TIENDA",   icon = "🛒" },
	{ id = "credits", label = "CRÉDITOS", icon = "★" },
}

print("[MenuPanel] v5.0 Blackout Clean — Tabs:", TABS[1].label, TABS[2].label, TABS[3].label)

-- ════════════════════════════════════════════════════════
-- HELPER
-- ════════════════════════════════════════════════════════
local function addCorner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = typeof(radius) == "UDim" and radius or UDim.new(0, radius or 8)
	c.Parent = parent
	return c
end

-- ════════════════════════════════════════════════════════
-- GUI ROOT
-- ════════════════════════════════════════════════════════
local screenGui = Instance.new("ScreenGui")
screenGui.Name           = "MenuPanelGui"
screenGui.ResetOnSpawn   = false
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent         = playerGui

-- ── Overlay (click fuera cierra) ────────────────────────
local overlay = Instance.new("TextButton")
overlay.Name                   = "Overlay"
overlay.Size                   = UDim2.fromScale(1, 1)
overlay.BackgroundColor3       = THEME.deep
overlay.BackgroundTransparency = 1
overlay.Text                   = ""
overlay.BorderSizePixel        = 0
overlay.ZIndex                 = 200
overlay.Visible                = false
overlay.Parent                 = screenGui

-- ── Panel principal ─────────────────────────────────────
local panel = Instance.new("Frame")
panel.Name                    = "MenuPanel"
panel.Size                    = UDim2.new(0, PANEL_W, 1, 0)
panel.Position                = POS_CLOSED
panel.AnchorPoint             = Vector2.new(1, 0)
panel.BackgroundColor3        = THEME.bg
panel.BackgroundTransparency  = 0
panel.BorderSizePixel         = 0
panel.ZIndex                  = 201
panel.Parent                  = screenGui
-- SIN UIStroke — cero bordes

-- Canvas
local canvas = Instance.new("CanvasGroup")
canvas.Size                   = UDim2.fromScale(1, 1)
canvas.BackgroundTransparency = 1
canvas.BorderSizePixel        = 0
canvas.ZIndex                 = 202
canvas.Parent                 = panel

-- ════════════════════════════════════════════════════════
-- HEADER — Limpio, solo título, SIN botón cerrar
-- ════════════════════════════════════════════════════════
local header = Instance.new("Frame")
header.Name                   = "Header"
header.Size                   = UDim2.new(1, 0, 0, HEADER_H)
header.BackgroundColor3       = THEME.head
header.BackgroundTransparency = 0
header.BorderSizePixel        = 0
header.ZIndex                 = 203
header.Parent                 = canvas
-- SIN línea inferior, SIN UIStroke

-- Pill del título en el header (estilo foto: "✕ MÚSICA" como pill)
local headerPill = Instance.new("Frame")
headerPill.Name                   = "TitlePill"
headerPill.Size                   = UDim2.new(0, 130, 0, 32)
headerPill.Position               = UDim2.new(1, -145, 0.5, -16)
headerPill.BackgroundColor3       = THEME.pillActive
headerPill.BackgroundTransparency = 0
headerPill.BorderSizePixel        = 0
headerPill.ZIndex                 = 204
headerPill.Parent                 = header
addCorner(headerPill, THEME.radiusPill)

-- Label dentro de la pill (muestra tab activa)
local headerPillLabel = Instance.new("TextLabel")
headerPillLabel.Name                   = "PillLabel"
headerPillLabel.Size                   = UDim2.fromScale(1, 1)
headerPillLabel.BackgroundTransparency = 1
headerPillLabel.Font                   = Enum.Font.GothamBold
headerPillLabel.TextSize               = 13
headerPillLabel.TextColor3             = THEME.text
headerPillLabel.Text                   = "✕  MÚSICA"
headerPillLabel.ZIndex                 = 205
headerPillLabel.Parent                 = headerPill

-- La pill del header cierra el panel al clickear
local headerPillBtn = Instance.new("TextButton")
headerPillBtn.Name                   = "PillBtn"
headerPillBtn.Size                   = UDim2.fromScale(1, 1)
headerPillBtn.BackgroundTransparency = 1
headerPillBtn.Text                   = ""
headerPillBtn.ZIndex                 = 206
headerPillBtn.Parent                 = headerPill

-- ════════════════════════════════════════════════════════
-- TAB BAR — Pills horizontales, SIN líneas, SIN bordes
-- ════════════════════════════════════════════════════════
local tabBar = Instance.new("Frame")
tabBar.Name                   = "TabBar"
tabBar.Size                   = UDim2.new(1, 0, 0, TABBAR_H)
tabBar.Position               = UDim2.new(0, 0, 0, HEADER_H)
tabBar.BackgroundColor3       = THEME.bg
tabBar.BackgroundTransparency = 0
tabBar.BorderSizePixel        = 0
tabBar.ZIndex                 = 203
tabBar.Parent                 = canvas
-- SIN UIStroke, SIN línea superior/inferior

-- Container de pills
local tabBtnContainer = Instance.new("Frame")
tabBtnContainer.Name                   = "PillContainer"
tabBtnContainer.Size                   = UDim2.new(1, -20, 0, 38)
tabBtnContainer.Position               = UDim2.new(0, 10, 0.5, -19)
tabBtnContainer.BackgroundTransparency = 1
tabBtnContainer.BorderSizePixel        = 0
tabBtnContainer.ZIndex                 = 204
tabBtnContainer.Parent                 = tabBar

do
	local l = Instance.new("UIListLayout")
	l.FillDirection       = Enum.FillDirection.Horizontal
	l.HorizontalAlignment = Enum.HorizontalAlignment.Left
	l.VerticalAlignment   = Enum.VerticalAlignment.Center
	l.Padding             = UDim.new(0, 8)
	l.Parent              = tabBtnContainer
end

-- ════════════════════════════════════════════════════════
-- ÁREA DE CONTENIDO
-- ════════════════════════════════════════════════════════
local contentArea = Instance.new("Frame")
contentArea.Name                   = "Content"
contentArea.Size                   = UDim2.new(1, 0, 1, -CONTENT_Y)
contentArea.Position               = UDim2.new(0, 0, 0, CONTENT_Y)
contentArea.BackgroundColor3       = THEME.bg
contentArea.BackgroundTransparency = 0
contentArea.ClipsDescendants       = true
contentArea.ZIndex                 = 202
contentArea.Parent                 = canvas
-- SIN bordes

-- ════════════════════════════════════════════════════════
-- ESTADO
-- ════════════════════════════════════════════════════════
local isOpen      = false
local activeTabId = nil
local tabBtns     = {}
local tabFrames   = {}
local tabAPIs     = {}

local sharedState = {
	shopCards = {},
	isMuted   = false,
}
_G._MenuPanelShopCards = sharedState.shopCards

-- ════════════════════════════════════════════════════════
-- ABRIR / CERRAR
-- ════════════════════════════════════════════════════════
local function openPanel()
	if isOpen then return end
	isOpen = true

	overlay.Visible = true
	overlay.BackgroundTransparency = 1
	TweenService:Create(overlay, TW_SMOOTH, {BackgroundTransparency = THEME.overlayAlpha}):Play()

	canvas.GroupTransparency = 0.1
	TweenService:Create(panel,  TW_SLIDE,  {Position = POS_OPEN}):Play()
	TweenService:Create(canvas, TW_SMOOTH, {GroupTransparency = 0}):Play()
end

local function closePanel()
	if not isOpen then return end
	isOpen = false

	TweenService:Create(overlay, TW_SNAP,  {BackgroundTransparency = 1}):Play()
	TweenService:Create(panel,   TW_SLIDE, {Position = POS_CLOSED}):Play()
	TweenService:Create(canvas,  TW_SNAP,  {GroupTransparency = 0.1}):Play()

	task.delay(0.40, function()
		if not isOpen then overlay.Visible = false end
	end)

	if activeTabId and tabAPIs[activeTabId] and tabAPIs[activeTabId].onClose then
		pcall(tabAPIs[activeTabId].onClose)
	end
	activeTabId = nil

	-- Reset pills
	for _, b in pairs(tabBtns) do
		local lbl = b:FindFirstChild("Lbl")
		TweenService:Create(b, TW_SNAP, {
			BackgroundColor3       = THEME.pillInactive,
			BackgroundTransparency = 0,
		}):Play()
		if lbl then
			TweenService:Create(lbl, TW_SNAP, {TextColor3 = THEME.tabInactive}):Play()
		end
	end
end

-- ════════════════════════════════════════════════════════
-- SWITCHER DE TABS
-- ════════════════════════════════════════════════════════
local function selectTab(tabId)
	if activeTabId == tabId then return end

	if activeTabId and tabAPIs[activeTabId] and tabAPIs[activeTabId].onClose then
		pcall(tabAPIs[activeTabId].onClose)
	end

	activeTabId = tabId

	-- Actualizar header pill con nombre del tab activo
	for _, t in ipairs(TABS) do
		if t.id == tabId then
			headerPillLabel.Text = "✕  " .. t.label
			break
		end
	end

	-- Actualizar pills
	for id, b in pairs(tabBtns) do
		local active = (id == tabId)
		local lbl    = b:FindFirstChild("Lbl")

		TweenService:Create(b, TW_SMOOTH, {
			BackgroundColor3       = active and THEME.pillActive or THEME.pillInactive,
			BackgroundTransparency = 0,
		}):Play()

		if lbl then
			TweenService:Create(lbl, TW_SMOOTH, {
				TextColor3 = active and THEME.accent or THEME.tabInactive,
			}):Play()
		end
	end

	-- Mostrar/ocultar contenido
	for id, f in pairs(tabFrames) do
		f.Visible = (id == tabId)
	end

	if tabAPIs[tabId] and tabAPIs[tabId].onOpen then
		pcall(tabAPIs[tabId].onOpen)
	end
end

-- ════════════════════════════════════════════════════════
-- CONSTRUIR PILLS DE TAB + FRAMES
-- Estilo foto: pill redondeada, icono + texto en la misma línea
-- ════════════════════════════════════════════════════════
for idx, tabDef in ipairs(TABS) do
	-- Medir ancho según texto (más largo = más ancho)
	local textLen  = string.len(tabDef.label)
	local pillW    = math.max(textLen * 10 + 42, 100)

	local b = Instance.new("TextButton")
	b.Name                   = tabDef.id
	b.Size                   = UDim2.new(0, pillW, 0, 34)
	b.BackgroundColor3       = THEME.pillInactive
	b.BackgroundTransparency = 0
	b.Text                   = ""
	b.BorderSizePixel        = 0
	b.ZIndex                 = 205
	b.LayoutOrder            = idx
	b.Parent                 = tabBtnContainer
	addCorner(b, THEME.radiusPill)   -- Pill redondeada
	-- SIN UIStroke — cero bordes

	-- Label: icono + texto en la misma línea
	local lbl = Instance.new("TextLabel")
	lbl.Name                   = "Lbl"
	lbl.Size                   = UDim2.fromScale(1, 1)
	lbl.BackgroundTransparency = 1
	lbl.Font                   = Enum.Font.GothamBold
	lbl.TextSize               = THEME.fontTab   -- 13px
	lbl.TextColor3             = THEME.tabInactive
	lbl.Text                   = tabDef.icon .. "  " .. tabDef.label
	lbl.ZIndex                 = 206
	lbl.Parent                 = b

	tabBtns[tabDef.id] = b

	-- Frame de contenido
	local content = Instance.new("Frame")
	content.Name                   = tabDef.id .. "Frame"
	content.Size                   = UDim2.fromScale(1, 1)
	content.BackgroundTransparency = 1
	content.Visible                = false
	content.ZIndex                 = 203
	content.Parent                 = contentArea
	tabFrames[tabDef.id] = content

	-- Click
	b.MouseButton1Click:Connect(function() selectTab(tabDef.id) end)

	-- Hover
	b.MouseEnter:Connect(function()
		if activeTabId ~= tabDef.id then
			TweenService:Create(b, TW_SNAP, {
				BackgroundColor3 = THEME.elevated,
			}):Play()
			local l = b:FindFirstChild("Lbl")
			if l then TweenService:Create(l, TW_SNAP, {TextColor3 = THEME.textSoft}):Play() end
		end
	end)
	b.MouseLeave:Connect(function()
		if activeTabId ~= tabDef.id then
			TweenService:Create(b, TW_SNAP, {
				BackgroundColor3 = THEME.pillInactive,
			}):Play()
			local l = b:FindFirstChild("Lbl")
			if l then TweenService:Create(l, TW_SNAP, {TextColor3 = THEME.tabInactive}):Play() end
		end
	end)
end

-- ════════════════════════════════════════════════════════
-- CONSTRUIR TABS (módulos) — MUSIC PRIMERO
-- ════════════════════════════════════════════════════════
print("[MenuPanel] Construyendo MusicTab primero...")
local musicApi = MusicTab.build(tabFrames["music"], THEME, sharedState)
tabAPIs["music"] = musicApi or {}

print("[MenuPanel] Construyendo ShopTab...")
ShopTab.build(tabFrames["shop"], THEME, sharedState)
tabAPIs["shop"] = {}

print("[MenuPanel] Construyendo CreditsTab...")
CreditsTab.build(tabFrames["credits"], THEME)
tabAPIs["credits"] = {}

-- ════════════════════════════════════════════════════════
-- EVENTOS: cerrar (overlay + header pill)
-- ════════════════════════════════════════════════════════
local function dismiss()
	closePanel()
	if _G.MenuIcon then
		pcall(function() _G.MenuIcon:deselect() end)
	end
end

overlay.MouseButton1Click:Connect(dismiss)
headerPillBtn.MouseButton1Click:Connect(dismiss)

-- Hover en la pill del header
headerPillBtn.MouseEnter:Connect(function()
	TweenService:Create(headerPill, TW_SNAP, {
		BackgroundColor3 = THEME.elevated,
	}):Play()
end)
headerPillBtn.MouseLeave:Connect(function()
	TweenService:Create(headerPill, TW_SNAP, {
		BackgroundColor3 = THEME.pillActive,
	}):Play()
end)

-- ════════════════════════════════════════════════════════
-- FUNCIONES GLOBALES
-- ════════════════════════════════════════════════════════
_G.OpenMenuPanel = function(defaultTab)
	openPanel()
	selectTab(defaultTab or "music")
end

_G.CloseMenuPanel = function()
	closePanel()
end

_panelReady = true
if _pendingOpen then
	task.defer(function()
		_G.OpenMenuPanel(_pendingOpen)
		_pendingOpen = nil
	end)
end

print("[MenuPanel] v5.0 Blackout Clean — Listo ✓")