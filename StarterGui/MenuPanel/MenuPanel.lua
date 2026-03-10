-- MenuPanel.lua v7.0 — Panel lateral FULL BLACK
-- by ignxts

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")
local TextService       = game:GetService("TextService")
local StarterGui        = game:GetService("StarterGui")

local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
local THEME     = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("ThemeConfig"))
local BlobIndicator = require(ReplicatedStorage:WaitForChild("UIComponents"):WaitForChild("BlobIndicator"))

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
local HEADER_H, TABBAR_H = 0, 45
local CONTENT_Y = HEADER_H + TABBAR_H
local ICON_SZ = 23
local TAB_PAD = 15
local ICON_GAP = 3
local BORDER_R = 14
local TOPBAR_H = 62 -- espacio libre para el topbar de MENU

local TW_SNAP   = TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local TW_SMOOTH = TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local TW_SLIDE  = TweenInfo.new(0.34, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

-- Panel empieza debajo del topbar, border radius visible en todas las esquinas
local POS_OPEN   = UDim2.new(1, 0, 0, TOPBAR_H)
local POS_CLOSED = UDim2.new(1, PANEL_W + 10, 0, TOPBAR_H)

local TABS = {
	{ id = "music",    label = "MUSICA",   icon = "rbxassetid://128030996841410" },
	{ id = "shop",     label = "TIENDA",   icon = "rbxassetid://83068902823364" },
	{ id = "settings", label = "AJUSTES",  icon = "rbxassetid://138336967142132" },
	{ id = "credits",  label = "CREDITOS", icon = "rbxassetid://107899112970032" },
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
overlay.Size = UDim2.fromScale(1, 1); overlay.BackgroundColor3 = THEME.bg
overlay.BackgroundTransparency = 1; overlay.Text = ""; overlay.BorderSizePixel = 0
overlay.ZIndex = 200; overlay.Visible = false; overlay.AutoButtonColor = false; overlay.Parent = screenGui

-- Panel
local panel = Instance.new("TextButton")
panel.Name = "MenuPanel"; panel.Size = UDim2.new(0, PANEL_W, 1, -TOPBAR_H)
panel.Position = POS_CLOSED; panel.AnchorPoint = Vector2.new(1, 0)
panel.BackgroundColor3 = THEME.bg; panel.BorderSizePixel = 0; panel.ZIndex = 201
panel.Active = true; panel.AutoButtonColor = false; panel.Text = ""
panel.ClipsDescendants = true
panel.Parent = screenGui
addCorner(panel, BORDER_R)
local panelStroke = Instance.new("UIStroke")
panelStroke.Color = THEME.stroke; panelStroke.Thickness = 1.5
panelStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
panelStroke.Parent = panel

local canvas = Instance.new("CanvasGroup")
canvas.Size = UDim2.fromScale(1, 1)
canvas.BackgroundTransparency = 1
canvas.BorderSizePixel = 0; canvas.ZIndex = 202; canvas.Parent = panel
addCorner(canvas, BORDER_R)

-- Inner edge vignette (left) — dark fade from edge inward
local edgeL = Instance.new("Frame")
edgeL.Name = "EdgeGlowL"; edgeL.Size = UDim2.new(0, 35, 1, 0)
edgeL.BackgroundColor3 = THEME.bg; edgeL.BorderSizePixel = 0
edgeL.ZIndex = 250; edgeL.Parent = canvas
local gL = Instance.new("UIGradient")
gL.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0.4),
	NumberSequenceKeypoint.new(0.6, 0.85),
	NumberSequenceKeypoint.new(1, 1),
})
gL.Parent = edgeL

-- Inner edge vignette (right)
local edgeR = Instance.new("Frame")
edgeR.Name = "EdgeGlowR"; edgeR.Size = UDim2.new(0, 35, 1, 0)
edgeR.Position = UDim2.new(1, -35, 0, 0)
edgeR.BackgroundColor3 = THEME.bg; edgeR.BorderSizePixel = 0
edgeR.ZIndex = 250; edgeR.Parent = canvas
local gR = Instance.new("UIGradient")
gR.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 1),
	NumberSequenceKeypoint.new(0.4, 0.85),
	NumberSequenceKeypoint.new(1, 0.4),
})
gR.Parent = edgeR

-- Header (hidden)
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, HEADER_H); header.BackgroundColor3 = THEME.bg
header.BorderSizePixel = 0; header.ZIndex = 203; header.Visible = false; header.Parent = canvas

local headerPill = Instance.new("Frame")
headerPill.Size = UDim2.new(0, 140, 0, 40)
headerPill.Position = UDim2.new(1, -152, 0.5, -20)
headerPill.BackgroundColor3 = THEME.elevated; headerPill.BorderSizePixel = 0
headerPill.ZIndex = 204; headerPill.Parent = header
addCorner(headerPill, UDim.new(0, 8))

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
tabBar.BackgroundColor3 = THEME.card; tabBar.BorderSizePixel = 0
tabBar.ZIndex = 203; tabBar.Parent = canvas

-- Blob indicator (reutilizable)
local TAB_COUNT = #TABS
local btnScale = 1 / TAB_COUNT

local blobIndicator = BlobIndicator.new(tabBar, {
	tabCount     = TAB_COUNT,
	bgColor      = THEME.subtle,
	padding      = 4,
	cornerRadius = 8,
	zIndex       = 204,
})

local pillContainer = Instance.new("Frame")
pillContainer.Size = UDim2.fromScale(1, 1)
pillContainer.BackgroundTransparency = 1; pillContainer.BorderSizePixel = 0
pillContainer.ZIndex = 205; pillContainer.Parent = tabBar

-- Content Area
local contentArea = Instance.new("Frame")
contentArea.Size = UDim2.new(1, 0, 1, -CONTENT_Y)
contentArea.Position = UDim2.new(0, 0, 0, CONTENT_Y)
contentArea.BackgroundColor3 = THEME.bg; contentArea.ClipsDescendants = true
contentArea.ZIndex = 202; contentArea.Parent = canvas

-- Estado
local isOpen, activeTabId = false, nil
local tabBtns, tabFrames, tabAPIs = {}, {}, {}
local tabLabels, tabIcons = {}, {} -- cache para evitar FindFirstChild repetido
local sharedState = { shopCards = {}, isMuted = false }
_G._MenuPanelShopCards = sharedState.shopCards
local _playerListWasOpen = false

-- Abrir / Cerrar
local function openPanel()
	if isOpen then return end
	isOpen = true
	_playerListWasOpen = StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.PlayerList)
	if _playerListWasOpen then
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
	end
	overlay.Visible = true; overlay.BackgroundTransparency = 1
	tween(overlay, TW_SMOOTH, {BackgroundTransparency = THEME.overlayAlpha})
	tween(panel, TW_SLIDE, {Position = POS_OPEN})
end

local function resetPills()
	for id, _ in pairs(tabBtns) do
		local lbl = tabLabels[id]
		local ico = tabIcons[id]
		if lbl then lbl.TextColor3 = THEME.muted end
		if ico then ico.ImageColor3 = THEME.muted end
	end
end

local _tabSwitching = false

local function closePanel()
	if not isOpen then return end
	isOpen = false
	if _playerListWasOpen then
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, true)
		_playerListWasOpen = false
	end
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

local function selectTab(tabId)
	if activeTabId == tabId or _tabSwitching then return end
	_tabSwitching = true

	local oldId = activeTabId
	if oldId and tabAPIs[oldId] and tabAPIs[oldId].onClose then
		pcall(tabAPIs[oldId].onClose)
	end

	for _, t in ipairs(TABS) do
		if t.id == tabId then
			headerPillLabel.Text = t.label
			if t.icon ~= "" then headerPillIcon.Image = t.icon end
			break
		end
	end

	-- ── BLOB ANIMATION (stretch → settle) ──
	local oldIdx = 0
	local newIdx = 0
	for i, t in ipairs(TABS) do
		if t.id == oldId then oldIdx = i end
		if t.id == tabId then newIdx = i end
	end

	if oldId and oldIdx > 0 then
		blobIndicator:animateTo(oldIdx, newIdx)
	else
		blobIndicator:jumpTo(newIdx)
	end

	-- Colorear textos/iconos
	activeTabId = tabId
	for id, b in pairs(tabBtns) do
		local active = (id == tabId)
		local lbl = tabLabels[id]
		local ico = tabIcons[id]
		if lbl then tween(lbl, TW_SNAP, {TextColor3 = active and THEME.text or THEME.muted}) end
		if ico then tween(ico, TW_SNAP, {ImageColor3 = active and THEME.text or THEME.muted}) end
	end

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

-- Construir tabs + frames
for idx, tabDef in ipairs(TABS) do
	local hasIcon = tabDef.icon ~= ""

	local b = Instance.new("TextButton")
	b.Name = tabDef.id
	b.Size = UDim2.new(btnScale, 0, 1, 0)
	b.Position = UDim2.new(btnScale * (idx - 1), 0, 0, 0)
	b.BackgroundTransparency = 1; b.Text = ""
	b.BorderSizePixel = 0; b.AutoButtonColor = false
	b.ZIndex = 206; b.Parent = pillContainer

	-- Contenedor interno con icon + label
	local inner = Instance.new("Frame")
	inner.Name = "Inner"; inner.BackgroundTransparency = 1
	inner.Size = UDim2.fromScale(1, 1)
	inner.ZIndex = 207; inner.Parent = b

	local innerLayout = Instance.new("UIListLayout")
	innerLayout.FillDirection = Enum.FillDirection.Horizontal
	innerLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	innerLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	innerLayout.Padding = UDim.new(0, ICON_GAP)
	innerLayout.SortOrder = Enum.SortOrder.LayoutOrder
	innerLayout.Parent = inner

	if hasIcon then
		local ico = Instance.new("ImageLabel")
		ico.Name = "Ico"; ico.Size = UDim2.new(0, ICON_SZ, 0, ICON_SZ)
		ico.BackgroundTransparency = 1; ico.ScaleType = Enum.ScaleType.Fit
		ico.ResampleMode = Enum.ResamplerMode.Default
		ico.Image = tabDef.icon; ico.ImageColor3 = THEME.muted
		ico.ZIndex = 208; ico.LayoutOrder = 1; ico.Parent = inner
	end

	local lbl = Instance.new("TextLabel")
	lbl.Name = "Lbl"
	lbl.Size = UDim2.new(0, 0, 0, ICON_SZ)
	lbl.AutomaticSize = Enum.AutomaticSize.X
	lbl.BackgroundTransparency = 1; lbl.Font = Enum.Font.GothamBold
	lbl.TextSize = 13; lbl.TextColor3 = THEME.muted
	lbl.Text = tabDef.label; lbl.ZIndex = 207; lbl.LayoutOrder = 2
	lbl.Parent = inner

	tabBtns[tabDef.id] = b
	tabLabels[tabDef.id] = lbl
	if hasIcon then tabIcons[tabDef.id] = inner:FindFirstChild("Ico") end

	local frame = Instance.new("Frame")
	frame.Name = tabDef.id .. "Frame"; frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundTransparency = 1; frame.Visible = false; frame.ZIndex = 203
	frame.Parent = contentArea
	tabFrames[tabDef.id] = frame

	b.MouseButton1Click:Connect(function() selectTab(tabDef.id) end)
	b.MouseEnter:Connect(function()
		if activeTabId ~= tabDef.id then
			local l = tabLabels[tabDef.id]
			local ic = tabIcons[tabDef.id]
			if l then tween(l, TW_SNAP, {TextColor3 = THEME.dim}) end
			if ic then tween(ic, TW_SNAP, {ImageColor3 = THEME.dim}) end
		end
	end)
	b.MouseLeave:Connect(function()
		if activeTabId ~= tabDef.id then
			local l = tabLabels[tabDef.id]
			local ic = tabIcons[tabDef.id]
			if l then tween(l, TW_SNAP, {TextColor3 = THEME.muted}) end
			if ic then tween(ic, TW_SNAP, {ImageColor3 = THEME.muted}) end
		end
	end)
end

-- Build tab modules
tabAPIs["music"] = MusicTab.build(tabFrames["music"], THEME, sharedState) or {}
ShopTab.build(tabFrames["shop"], THEME, sharedState); tabAPIs["shop"] = {}
SettingsTab.build(tabFrames["settings"], THEME); tabAPIs["settings"] = {}
CreditsTab.build(tabFrames["credits"], THEME); tabAPIs["credits"] = {}

-- (scrollToTab removed — tabs are fixed-width, no scrolling needed)

-- Dismiss
local function dismiss()
	closePanel()
	if _G.MenuIcon then pcall(function() _G.MenuIcon:deselect() end) end
end

overlay.MouseButton1Click:Connect(dismiss)
headerPillBtn.MouseButton1Click:Connect(dismiss)
headerPillBtn.MouseEnter:Connect(function() tween(headerPill, TW_SNAP, {BackgroundColor3 = THEME.stroke}) end)
headerPillBtn.MouseLeave:Connect(function() tween(headerPill, TW_SNAP, {BackgroundColor3 = THEME.elevated}) end)

-- API global
_G.OpenMenuPanel = function(tab) openPanel(); selectTab(tab or "music") end
_G.CloseMenuPanel = closePanel

_panelReady = true
if _pendingOpen then
	task.defer(function() _G.OpenMenuPanel(_pendingOpen); _pendingOpen = nil end)
end