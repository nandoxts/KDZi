--[[
	SubTabs v2 — Blob/Pill sliding indicator
	El indicador se desliza entre tabs con efecto elástico (stretch + settle).
	Uso idéntico a v1: .new(), :register(), :select(), .onSwitch
]]

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BlobIndicator = require(ReplicatedStorage:WaitForChild("UIComponents"):WaitForChild("BlobIndicator"))

local SubTabs = {}
SubTabs.__index = SubTabs

function SubTabs.new(parent, THEME, config)
	local self = setmetatable({}, SubTabs)

	config = config or {}
	local tabs = config.tabs or {}
	local height = config.height or 38
	local defaultTab = config.default or (tabs[1] and tabs[1].id)
	local z = config.z or 215
	local tabCount = #tabs
	local btnScale = tabCount > 0 and (1 / tabCount) or 1

	self.THEME = THEME
	self.activeId = nil
	self.buttons = {}
	self.labels = {}
	self.panels = {}
	self.tabOrder = {}
	self.tabDefs = tabs
	self.origPositions = {}
	self.onSwitch = nil
	self._animating = false
	self._tabCount = tabCount
	self._btnScale = btnScale

	for idx, tabDef in ipairs(tabs) do
		self.tabOrder[tabDef.id] = idx
	end

	-- ── BAR (fondo sutil) ──
	local bar = Instance.new("Frame")
	bar.Name = "SubTabBar"
	bar.Size = UDim2.new(1, 0, 0, height)
	bar.BackgroundColor3 = THEME.card
	bar.BackgroundTransparency = 0
	bar.BorderSizePixel = 0
	bar.ZIndex = z
	bar.Parent = parent

	-- ── BLOB INDICATOR (reutilizable) ──
	self._blobIndicator = BlobIndicator.new(bar, {
		tabCount     = tabCount,
		bgColor      = THEME.subtle,
		padding      = 4,
		cornerRadius = 8,
		zIndex       = z + 1,
	})

	-- ── TAB BUTTONS (transparentes, solo texto) ──
	for idx, tabDef in ipairs(tabs) do
		local btn = Instance.new("TextButton")
		btn.Name = tabDef.id
		btn.Size = UDim2.new(btnScale, 0, 1, 0)
		btn.Position = UDim2.new(btnScale * (idx - 1), 0, 0, 0)
		btn.BackgroundTransparency = 1
		btn.Font = Enum.Font.GothamBold
		btn.TextSize = 13
		btn.TextColor3 = THEME.muted
		btn.Text = tabDef.label
		btn.BorderSizePixel = 0
		btn.AutoButtonColor = false
		btn.ZIndex = z + 2
		btn.Parent = bar

		self.buttons[tabDef.id] = btn
		self.labels[tabDef.id] = btn

		btn.MouseButton1Click:Connect(function()
			self:select(tabDef.id)
		end)
	end

	self.bar = bar
	self.height = height

	-- Seleccionar default sin animación
	if defaultTab then
		self:_setActive(defaultTab, true)
	end

	return self
end

function SubTabs:register(tabId, panel)
	self.panels[tabId] = panel
	self.origPositions[tabId] = panel.Position
	panel.Visible = (tabId == self.activeId)
end

function SubTabs:_setActive(tabId, instant)
	local THEME = self.THEME
	self.activeId = tabId

	local idx = self.tabOrder[tabId] or 1
	if instant then
		self._blobIndicator:jumpTo(idx)
	end

	-- Colorear textos
	local dur = instant and 0 or 0.2
	for id, btn in pairs(self.labels) do
		local targetColor = (id == tabId) and THEME.text or THEME.muted
		if instant then
			btn.TextColor3 = targetColor
		else
			TweenService:Create(btn, TweenInfo.new(dur), { TextColor3 = targetColor }):Play()
		end
	end
end

function SubTabs:select(tabId)
	if tabId == self.activeId then return end
	if self._animating then return end

	local oldId = self.activeId
	local oldPanel = self.panels[oldId]
	local newPanel = self.panels[tabId]

	local oldIdx = self.tabOrder[oldId] or 0
	local newIdx = self.tabOrder[tabId] or 0
	local forward = newIdx > oldIdx

	-- ── BLOB ANIMATION (stretch → settle) ──
	self._animating = true

	local oldBlobIdx = self.tabOrder[oldId] or 1
	local newBlobIdx = self.tabOrder[tabId] or 1
	self._blobIndicator:animateTo(oldBlobIdx, newBlobIdx)

	-- Actualizar textos inmediatamente
	self.activeId = tabId
	for id, btn in pairs(self.labels) do
		local targetColor = (id == tabId) and self.THEME.text or self.THEME.muted
		TweenService:Create(btn, TweenInfo.new(0.15), { TextColor3 = targetColor }):Play()
	end

	-- ── PANEL SLIDE ──
	local TW_PAGE = TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

	if oldPanel and newPanel and oldPanel ~= newPanel then
		local origOld = self.origPositions[oldId]
		local origNew = self.origPositions[tabId]

		local inDir = forward and 1 or -1
		newPanel.Position = UDim2.new(
			origNew.X.Scale + inDir, origNew.X.Offset,
			origNew.Y.Scale, origNew.Y.Offset
		)
		newPanel.Visible = true

		local outDir = forward and -1 or 1
		TweenService:Create(oldPanel, TW_PAGE, {
			Position = UDim2.new(
				origOld.X.Scale + outDir, origOld.X.Offset,
				origOld.Y.Scale, origOld.Y.Offset
			)
		}):Play()
		TweenService:Create(newPanel, TW_PAGE, { Position = origNew }):Play()

		task.delay(0.35, function()
			oldPanel.Visible = false
			oldPanel.Position = origOld
			self._animating = false
		end)
	elseif newPanel then
		if oldPanel then oldPanel.Visible = false end
		newPanel.Visible = true
		task.delay(0.35, function() self._animating = false end)
	else
		task.delay(0.35, function() self._animating = false end)
	end

	if self.onSwitch then
		task.defer(self.onSwitch, tabId)
	end
end

function SubTabs:getActiveId()
	return self.activeId
end

return SubTabs
