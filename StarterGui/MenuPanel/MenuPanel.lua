-- MenuPanel.lua v6.0 — Panel lateral BLACKOUT ORANGE
-- by ignxts + George Bellota

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")
local TextService       = game:GetService("TextService")

local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
local THEME     = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("ThemeConfig"))

local Tabs        = script.Parent:WaitForChild("Tabs")
local MusicTab    = require(Tabs:WaitForChild("Music"):WaitForChild("Music"))
local ShopTab     = require(Tabs:WaitForChild("Shop"):WaitForChild("Shop"))
local CreditsTab  = require(Tabs:WaitForChild("Credits"):WaitForChild("Credits"))
local SettingsTab = require(Tabs:WaitForChild("Settings"):WaitForChild("Settings"))

-- Stubs globales tempranos
local _panelReady, _pendingOpen = false, nil
_G.OpenMenuPanel = function(tab)
	if _panelReady then _G.OpenMenuPanel(tab) else _pendingOpen = tab or "music" end
end
_G.CloseMenuPanel = function() end

-- Layout
local PANEL_W   = THEME.panelWidth or 390
local HEADER_H, TABBAR_H = 50, 48
local CONTENT_Y = HEADER_H + TABBAR_H

local TW_SNAP   = TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local TW_SMOOTH = TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local TW_SLIDE  = TweenInfo.new(0.34, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

local POS_OPEN   = UDim2.new(1, 0, 0, 0)
local POS_CLOSED = UDim2.new(1, PANEL_W + 10, 0, 0)

local TABS = {
	{ id = "music",    label = "MUSICA",   icon = "rbxassetid://100807726055929" },
	{ id = "shop",     label = "TIENDA",   icon = "rbxassetid://80411403902609" },
	{ id = "settings", label = "AJUSTES",  icon = "rbxassetid://89050709715008" },
	{ id = "credits",  label = "CREDITOS", icon = "rbxassetid://118960630802353" },
}

-- Helpers
local function addCorner(obj, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = typeof(r) == "UDim" and r or UDim.new(0, r or 8)
	c.Parent = obj
end

local function tween(obj, info, props)
	TweenService:Create(obj, info, props):Play()
end

-- GUI Root
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MenuPanelGui"; screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true; screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

-- Overlay
local overlay = Instance.new("TextButton")
overlay.Size = UDim2.fromScale(1, 1); overlay.BackgroundColor3 = THEME.deep
overlay.BackgroundTransparency = 1; overlay.Text = ""; overlay.BorderSizePixel = 0
overlay.ZIndex = 200; overlay.Visible = false; overlay.AutoButtonColor = false; overlay.Parent = screenGui

-- Panel
local panel = Instance.new("TextButton")
panel.Name = "MenuPanel"; panel.Size = UDim2.new(0, PANEL_W, 1, 0)
panel.Position = POS_CLOSED; panel.AnchorPoint = Vector2.new(1, 0)
panel.BackgroundColor3 = THEME.bg; panel.BorderSizePixel = 0; panel.ZIndex = 201
panel.Active = true; panel.AutoButtonColor = false; panel.Text = ""
panel.Parent = screenGui

local canvas = Instance.new("CanvasGroup")
canvas.Size = UDim2.fromScale(1, 1); canvas.BackgroundTransparency = 1
canvas.BorderSizePixel = 0; canvas.ZIndex = 202; canvas.Parent = panel

-- Header
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, HEADER_H); header.BackgroundColor3 = THEME.head
header.BorderSizePixel = 0; header.ZIndex = 203; header.Parent = canvas

local headerPill = Instance.new("Frame")
headerPill.Size = UDim2.new(0, 140, 0, 40)
headerPill.Position = UDim2.new(1, -152, 0.5, -20)
headerPill.BackgroundColor3 = THEME.pillActive; headerPill.BorderSizePixel = 0
headerPill.ZIndex = 204; headerPill.Parent = header
addCorner(headerPill, THEME.radiusPill)

local headerPillIcon = Instance.new("ImageLabel")
headerPillIcon.Name = "Icon"; headerPillIcon.Size = UDim2.new(0, 32, 0, 32)
headerPillIcon.Position = UDim2.new(0, 8, 0.5, -16)
headerPillIcon.BackgroundTransparency = 1; headerPillIcon.ScaleType = Enum.ScaleType.Fit
headerPillIcon.ResampleMode = Enum.ResamplerMode.Default
headerPillIcon.ImageColor3 = THEME.text; headerPillIcon.Image = ""
headerPillIcon.ZIndex = 205; headerPillIcon.Parent = headerPill

local headerPillLabel = Instance.new("TextLabel")
headerPillLabel.Size = UDim2.new(1, -46, 1, 0); headerPillLabel.Position = UDim2.new(0, 46, 0, 0)
headerPillLabel.BackgroundTransparency = 1
headerPillLabel.Font = Enum.Font.GothamBold; headerPillLabel.TextSize = 13
headerPillLabel.TextColor3 = THEME.text; headerPillLabel.Text = "MUSICA"
headerPillLabel.TextXAlignment = Enum.TextXAlignment.Left
headerPillLabel.ZIndex = 205; headerPillLabel.Parent = headerPill

local headerPillBtn = Instance.new("TextButton")
headerPillBtn.Size = UDim2.fromScale(1, 1); headerPillBtn.BackgroundTransparency = 1
headerPillBtn.Text = ""; headerPillBtn.ZIndex = 206; headerPillBtn.Parent = headerPill

-- Tab Bar
local tabBar = Instance.new("Frame")
tabBar.Size = UDim2.new(1, 0, 0, TABBAR_H)
tabBar.Position = UDim2.new(0, 0, 0, HEADER_H)
tabBar.BackgroundColor3 = THEME.bg; tabBar.BorderSizePixel = 0
tabBar.ZIndex = 203; tabBar.Parent = canvas

local pillContainer = Instance.new("ScrollingFrame")
pillContainer.Size = UDim2.new(1, 0, 0, 38)
pillContainer.Position = UDim2.new(0, 0, 0.5, -19)
pillContainer.BackgroundTransparency = 1; pillContainer.BorderSizePixel = 0
pillContainer.ScrollBarThickness = 0
pillContainer.ScrollingDirection = Enum.ScrollingDirection.X
pillContainer.AutomaticCanvasSize = Enum.AutomaticSize.X
pillContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
pillContainer.ClipsDescendants = true
pillContainer.ZIndex = 204; pillContainer.Parent = tabBar

do
	local l = Instance.new("UIListLayout")
	l.FillDirection = Enum.FillDirection.Horizontal
	l.HorizontalAlignment = Enum.HorizontalAlignment.Left
	l.VerticalAlignment = Enum.VerticalAlignment.Center
	l.Padding = UDim.new(0, 8)
	l.SortOrder = Enum.SortOrder.LayoutOrder
	l.Parent = pillContainer
end

-- Content Area
local contentArea = Instance.new("Frame")
contentArea.Size = UDim2.new(1, 0, 1, -CONTENT_Y)
contentArea.Position = UDim2.new(0, 0, 0, CONTENT_Y)
contentArea.BackgroundColor3 = THEME.bg; contentArea.ClipsDescendants = true
contentArea.ZIndex = 202; contentArea.Parent = canvas

-- Estado
local isOpen, activeTabId = false, nil
local tabBtns, tabFrames, tabAPIs = {}, {}, {}
local sharedState = { shopCards = {}, isMuted = false }
_G._MenuPanelShopCards = sharedState.shopCards

-- Abrir / Cerrar
local function openPanel()
	if isOpen then return end
	isOpen = true
	overlay.Visible = true; overlay.BackgroundTransparency = 1
	tween(overlay, TW_SMOOTH, {BackgroundTransparency = THEME.overlayAlpha})
	tween(panel, TW_SLIDE, {Position = POS_OPEN})
end

local function resetPills()
	for _, b in pairs(tabBtns) do
		tween(b, TW_SNAP, {BackgroundColor3 = THEME.pillInactive})
		local lbl = b:FindFirstChild("Lbl")
		local ico = b:FindFirstChild("Ico")
		if lbl then tween(lbl, TW_SNAP, {TextColor3 = THEME.tabInactive}) end
		if ico then tween(ico, TW_SNAP, {ImageColor3 = THEME.tabInactive}) end
	end
end

local _tabSwitching = false

local function closePanel()
	if not isOpen then return end
	isOpen = false
	tween(overlay, TW_SNAP, {BackgroundTransparency = 1})
	tween(panel, TW_SLIDE, {Position = POS_CLOSED})
	task.delay(0.40, function()
		if not isOpen then overlay.Visible = false end
	end)
	if activeTabId and tabAPIs[activeTabId] and tabAPIs[activeTabId].onClose then
		pcall(tabAPIs[activeTabId].onClose)
	end
	-- Reset ALL tab frames para evitar páginas combinadas al reabrir
	for _, frame in pairs(tabFrames) do
		frame.Visible = false
		frame.Position = UDim2.fromScale(0, 0)
	end
	activeTabId = nil
	_tabSwitching = false
	resetPills()
end

-- Lookup de índice para dirección de slide
local tabIndexOf = {}
for i, t in ipairs(TABS) do tabIndexOf[t.id] = i end

local TW_PAGE = TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

local scrollToTab -- forward declaration

local function selectTab(tabId)
	if activeTabId == tabId or _tabSwitching then return end
	_tabSwitching = true

	local oldId = activeTabId
	if oldId and tabAPIs[oldId] and tabAPIs[oldId].onClose then
		pcall(tabAPIs[oldId].onClose)
	end
	activeTabId = tabId

	for _, t in ipairs(TABS) do
		if t.id == tabId then
			headerPillLabel.Text = t.label
			if t.icon ~= "" then headerPillIcon.Image = t.icon end
			break
		end
	end

	for id, b in pairs(tabBtns) do
		local active = (id == tabId)
		local lbl = b:FindFirstChild("Lbl")
		local ico = b:FindFirstChild("Ico")
		tween(b, TW_SMOOTH, {BackgroundColor3 = active and THEME.pillActive or THEME.pillInactive})
		if lbl then
			tween(lbl, TW_SMOOTH, {TextColor3 = active and THEME.accent or THEME.tabInactive})
		end
		if ico then
			tween(ico, TW_SMOOTH, {ImageColor3 = active and THEME.accent or THEME.tabInactive})
		end
	end
	scrollToTab(tabId)

	-- Animación slide horizontal
	local oldFrame = oldId and tabFrames[oldId]
	local newFrame = tabFrames[tabId]

	if oldFrame and newFrame and oldFrame ~= newFrame then
		local oldIdx = tabIndexOf[oldId] or 0
		local newIdx = tabIndexOf[tabId] or 0
		local forward = newIdx > oldIdx

		-- Posicionar nuevo fuera de pantalla
		newFrame.Position = UDim2.fromScale(forward and 1 or -1, 0)
		newFrame.Visible = true

		-- Slide: viejo sale, nuevo entra
		TweenService:Create(oldFrame, TW_PAGE, {
			Position = UDim2.fromScale(forward and -1 or 1, 0)
		}):Play()
		TweenService:Create(newFrame, TW_PAGE, {
			Position = UDim2.fromScale(0, 0)
		}):Play()

		task.delay(0.28, function()
			oldFrame.Visible = false
			oldFrame.Position = UDim2.fromScale(0, 0)
			_tabSwitching = false
		end)
	else
		if oldFrame then oldFrame.Visible = false end
		if newFrame then newFrame.Visible = true end
		_tabSwitching = false
	end

	if tabAPIs[tabId] and tabAPIs[tabId].onOpen then
		pcall(tabAPIs[tabId].onOpen)
	end
end

-- Construir pills + frames
local ICON_SZ = 22
local PAD_L, PAD_R, GAP = 8, 10, 4
for idx, tabDef in ipairs(TABS) do
	local hasIcon = tabDef.icon ~= ""
	local textW = TextService:GetTextSize(tabDef.label, THEME.fontTab, Enum.Font.GothamBold, Vector2.new(400, 36)).X
	local pillW = (hasIcon and (PAD_L + ICON_SZ + GAP) or PAD_L) + textW + PAD_R

	local b = Instance.new("TextButton")
	b.Name = tabDef.id; b.Size = UDim2.new(0, pillW, 0, 36)
	b.BackgroundColor3 = THEME.pillInactive; b.Text = ""
	b.BorderSizePixel = 0; b.ZIndex = 205; b.LayoutOrder = idx
	addCorner(b, THEME.radiusPill)

	if hasIcon then
		local ico = Instance.new("ImageLabel")
		ico.Name = "Ico"; ico.Size = UDim2.new(0, ICON_SZ, 0, ICON_SZ)
		ico.Position = UDim2.new(0, PAD_L, 0.5, -ICON_SZ / 2)
		ico.BackgroundTransparency = 1; ico.ScaleType = Enum.ScaleType.Fit
		ico.ResampleMode = Enum.ResamplerMode.Default
		ico.Image = tabDef.icon; ico.ImageColor3 = THEME.tabInactive
		ico.ZIndex = 207; ico.Parent = b
	end

	local lblX = hasIcon and (PAD_L + ICON_SZ + GAP) or PAD_L
	local lbl = Instance.new("TextLabel")
	lbl.Name = "Lbl"
	lbl.Size = UDim2.new(1, -lblX, 1, 0)
	lbl.Position = UDim2.new(0, lblX, 0, 0)
	lbl.BackgroundTransparency = 1; lbl.Font = Enum.Font.GothamBold
	lbl.TextSize = THEME.fontTab; lbl.TextColor3 = THEME.tabInactive
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Text = tabDef.label; lbl.ZIndex = 206
	lbl.Parent = b

	tabBtns[tabDef.id] = b
	b.Parent = pillContainer

	local frame = Instance.new("Frame")
	frame.Name = tabDef.id .. "Frame"; frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundTransparency = 1; frame.Visible = false; frame.ZIndex = 203
	frame.Parent = contentArea
	tabFrames[tabDef.id] = frame

	b.MouseButton1Click:Connect(function() selectTab(tabDef.id) end)
	b.MouseEnter:Connect(function()
		if activeTabId ~= tabDef.id then
			tween(b, TW_SNAP, {BackgroundColor3 = THEME.elevated})
			local l = b:FindFirstChild("Lbl")
			local ic = b:FindFirstChild("Ico")
			if l then tween(l, TW_SNAP, {TextColor3 = THEME.textSoft}) end
			if ic then tween(ic, TW_SNAP, {ImageColor3 = THEME.textSoft}) end
		end
	end)
	b.MouseLeave:Connect(function()
		if activeTabId ~= tabDef.id then
			tween(b, TW_SNAP, {BackgroundColor3 = THEME.pillInactive})
			local l = b:FindFirstChild("Lbl")
			local ic = b:FindFirstChild("Ico")
			if l then tween(l, TW_SNAP, {TextColor3 = THEME.tabInactive}) end
			if ic then tween(ic, TW_SNAP, {ImageColor3 = THEME.tabInactive}) end
		end
	end)
end

-- Build tab modules
tabAPIs["music"] = MusicTab.build(tabFrames["music"], THEME, sharedState) or {}
ShopTab.build(tabFrames["shop"], THEME, sharedState); tabAPIs["shop"] = {}
SettingsTab.build(tabFrames["settings"], THEME); tabAPIs["settings"] = {}
CreditsTab.build(tabFrames["credits"], THEME); tabAPIs["credits"] = {}

-- Auto-scroll pills al tab activo
scrollToTab = function(tabId)
	local btn = tabBtns[tabId]
	if not btn then return end
	local cW = pillContainer.AbsoluteSize.X
	local bX = btn.AbsolutePosition.X - pillContainer.AbsolutePosition.X + pillContainer.CanvasPosition.X
	local bW = btn.AbsoluteSize.X
	local target = bX - (cW / 2) + (bW / 2)
	local maxS = math.max(0, pillContainer.AbsoluteCanvasSize.X - cW)
	target = math.clamp(target, 0, maxS)
	TweenService:Create(pillContainer, TW_SMOOTH, { CanvasPosition = Vector2.new(target, 0) }):Play()
end

-- Dismiss
local function dismiss()
	closePanel()
	if _G.MenuIcon then pcall(function() _G.MenuIcon:deselect() end) end
end

overlay.MouseButton1Click:Connect(dismiss)
headerPillBtn.MouseButton1Click:Connect(dismiss)
headerPillBtn.MouseEnter:Connect(function() tween(headerPill, TW_SNAP, {BackgroundColor3 = THEME.elevated}) end)
headerPillBtn.MouseLeave:Connect(function() tween(headerPill, TW_SNAP, {BackgroundColor3 = THEME.pillActive}) end)

-- API global
_G.OpenMenuPanel = function(tab) openPanel(); selectTab(tab or "music") end
_G.CloseMenuPanel = closePanel

_panelReady = true
if _pendingOpen then
	task.defer(function() _G.OpenMenuPanel(_pendingOpen); _pendingOpen = nil end)
end