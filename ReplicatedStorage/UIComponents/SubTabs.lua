--[[
	SubTabs - Componente reutilizable de sub-tabs con animación suave
	Uso:
		local SubTabs = require(...)
		local subTabs = SubTabs.new(parent, THEME, {
			tabs = { {id = "actual", label = "ACTUAL"}, {id = "dj", label = "DJ"} },
			height = 38,
			default = "actual",
			z = 215,
		})

		-- Obtener contenedor de contenido para cada tab
		subTabs:getContentParent()  --> Frame debajo de la barra

		-- Registrar panel de cada tab
		subTabs:register("actual", panel)
		subTabs:register("dj", panel)

		-- Cambiar tab (con animación)
		subTabs:select("dj")

		-- Callback
		subTabs.onSwitch = function(tabId) ... end
]]

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UI = require(ReplicatedStorage:WaitForChild("Core"):WaitForChild("UI"))

local SubTabs = {}
SubTabs.__index = SubTabs

function SubTabs.new(parent, THEME, config)
	local self = setmetatable({}, SubTabs)

	config = config or {}
	local tabs = config.tabs or {}
	local height = config.height or 38
	local defaultTab = config.default or (tabs[1] and tabs[1].id)
	local z = config.z or 215

	self.THEME = THEME
	self.activeId = nil
	self.buttons = {}
	self.panels = {}
	self.tabOrder = {}
	self.origPositions = {}
	self.onSwitch = nil
	self._animating = false

	-- Guardar orden de tabs para dirección de slide
	for idx, tabDef in ipairs(tabs) do
		self.tabOrder[tabDef.id] = idx
	end

	-- Barra
	local bar = Instance.new("Frame")
	bar.Name = "SubTabBar"
	bar.Size = UDim2.new(1, 0, 0, height)
	bar.BackgroundColor3 = THEME.bg
	bar.BorderSizePixel = 0
	bar.ZIndex = z
	bar.Parent = parent

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 4)
	layout.Parent = bar

	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 6)
	pad.PaddingRight = UDim.new(0, 6)
	pad.Parent = bar

	-- Separador
	local sep = Instance.new("Frame")
	sep.Size = UDim2.new(1, 0, 0, 1)
	sep.Position = UDim2.new(0, 0, 0, height)
	sep.BackgroundColor3 = THEME.stroke or Color3.fromRGB(45, 45, 45)
	sep.BackgroundTransparency = 0.6
	sep.ZIndex = z
	sep.Parent = parent

	-- Crear botones
	local tabCount = #tabs
	local btnWidth = tabCount > 0 and (1 / tabCount) or 1

	for idx, tabDef in ipairs(tabs) do
		local btn = Instance.new("TextButton")
		btn.Name = tabDef.id
		btn.Size = UDim2.new(btnWidth, -4, 0, 30)
		btn.BackgroundColor3 = THEME.card or Color3.fromRGB(35, 35, 35)
		btn.BackgroundTransparency = 0.2
		btn.Font = Enum.Font.GothamBold
		btn.TextSize = 13
		btn.TextColor3 = THEME.muted
		btn.Text = tabDef.label
		btn.BorderSizePixel = 0
		btn.AutoButtonColor = false
		btn.ZIndex = z + 1
		btn.LayoutOrder = idx
		btn.Parent = bar
		UI.rounded(btn, 8)

		self.buttons[tabDef.id] = btn

		btn.MouseButton1Click:Connect(function()
			self:select(tabDef.id)
		end)

		btn.MouseEnter:Connect(function()
			if self.activeId ~= tabDef.id then
				TweenService:Create(btn, TweenInfo.new(0.12), { BackgroundTransparency = 0.15 }):Play()
			end
		end)
		btn.MouseLeave:Connect(function()
			if self.activeId ~= tabDef.id then
				TweenService:Create(btn, TweenInfo.new(0.12), { BackgroundTransparency = 0.2 }):Play()
			end
		end)
	end

	self.bar = bar
	self.height = height

	-- Seleccionar default sin animación
	if defaultTab then
		self:_setActive(defaultTab)
	end

	return self
end

function SubTabs:register(tabId, panel)
	self.panels[tabId] = panel
	self.origPositions[tabId] = panel.Position
	panel.Visible = (tabId == self.activeId)
end

function SubTabs:_setActive(tabId)
	local THEME = self.THEME
	self.activeId = tabId

	for id, btn in pairs(self.buttons) do
		if id == tabId then
			TweenService:Create(btn, TweenInfo.new(0.18), {
				BackgroundColor3 = THEME.accent,
				BackgroundTransparency = 0.1,
				TextColor3 = THEME.text,
			}):Play()
		else
			TweenService:Create(btn, TweenInfo.new(0.18), {
				BackgroundColor3 = THEME.card or Color3.fromRGB(35, 35, 35),
				BackgroundTransparency = 0.2,
				TextColor3 = THEME.muted,
			}):Play()
		end
	end
end

function SubTabs:select(tabId)
	if tabId == self.activeId then return end
	if self._animating then return end

	local oldId = self.activeId
	local oldPanel = self.panels[oldId]
	local newPanel = self.panels[tabId]

	self:_setActive(tabId)

	-- Dirección: forward = slide izquierda, backward = slide derecha
	local oldIdx = self.tabOrder[oldId] or 0
	local newIdx = self.tabOrder[tabId] or 0
	local forward = newIdx > oldIdx

	local TW_PAGE = TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

	if oldPanel and newPanel and oldPanel ~= newPanel then
		self._animating = true

		local origOld = self.origPositions[oldId]
		local origNew = self.origPositions[tabId]

		-- Posicionar nuevo fuera de pantalla
		local inDir = forward and 1 or -1
		newPanel.Position = UDim2.new(
			origNew.X.Scale + inDir, origNew.X.Offset,
			origNew.Y.Scale, origNew.Y.Offset
		)
		newPanel.Visible = true

		-- Slide: viejo sale, nuevo entra
		local outDir = forward and -1 or 1
		TweenService:Create(oldPanel, TW_PAGE, {
			Position = UDim2.new(
				origOld.X.Scale + outDir, origOld.X.Offset,
				origOld.Y.Scale, origOld.Y.Offset
			)
		}):Play()
		TweenService:Create(newPanel, TW_PAGE, { Position = origNew }):Play()

		task.delay(0.28, function()
			oldPanel.Visible = false
			oldPanel.Position = origOld
			self._animating = false
		end)
	elseif newPanel then
		if oldPanel then oldPanel.Visible = false end
		newPanel.Visible = true
	end

	if self.onSwitch then
		task.defer(self.onSwitch, tabId)
	end
end

function SubTabs:getActiveId()
	return self.activeId
end

return SubTabs
