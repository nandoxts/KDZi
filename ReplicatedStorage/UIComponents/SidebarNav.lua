--[[
	═══════════════════════════════════════════════════════════
	SidebarNav — Componente reutilizable de navegación lateral
	═══════════════════════════════════════════════════════════
	Patrón: columna izquierda fija con items de navegación
	Compatible con ThemeConfig + UI module
	by ignxts
]]

local TweenService     = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ModernScrollbar   = require(ReplicatedStorage:WaitForChild("UIComponents"):WaitForChild("ModernScrollbar"))

local TW_FAST = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TW_NORM = TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local SidebarNav = {}
SidebarNav.__index = SidebarNav

--[[
	SidebarNav.new(opts)
	opts = {
		parent    : Instance      — contenedor padre (CONTAINER / CanvasGroup)
		UI        : module        — módulo UI
		THEME     : module        — módulo ThemeConfig
		title     : string        — título del sidebar (ej. "CLANES")
		subtitle  : string?       — subtítulo opcional decorativo
		items     : array         — lista de { id, label, icon? }
		width     : number?       — ancho en px (default 130)
		isMobile  : bool?
		onSelect  : function(id)  — callback al seleccionar item
	}
]]
function SidebarNav.new(opts)
	local self = setmetatable({}, SidebarNav)

	local UI        = opts.UI
	local THEME     = opts.THEME
	local items     = opts.items     or {}
	local width     = opts.width     or 130
	local title     = opts.title     or ""
	local subtitle  = opts.subtitle
	local onSelect  = opts.onSelect  or function() end
	local parent    = opts.parent
	local isMobile  = opts.isMobile  or false

	self._THEME      = THEME
	self._selected   = nil
	self._buttons    = {}    -- [id] = Frame (clickable)
	self._labels     = {}    -- [id] = TextLabel
	self._iconFrames = {}    -- [id] = Frame circular
	self._iconImgs   = {}    -- [id] = ImageLabel
	self._iconStks   = {}    -- [id] = UIStroke

	-- ── Frame principal ──────────────────────────────────────────
	local sidebar = UI.frame({
		name = "Sidebar",
		size = UDim2.new(0, width, 1, 0),
		bg   = THEME.deep, bgT = THEME.lightAlpha,
		z    = 200, parent = parent, clips = true,
	})
	self.frame = sidebar

	-- Stroke borde
	local stroke = Instance.new("UIStroke")
	stroke.Color              = THEME.stroke
	stroke.Thickness          = 1
	stroke.Transparency       = THEME.mediumAlpha
	stroke.ApplyStrokeMode    = Enum.ApplyStrokeMode.Border
	stroke.Parent             = sidebar

	-- Separador vertical derecho
	local divider = Instance.new("Frame")
	divider.Name                    = "Divider"
	divider.Size                    = UDim2.new(0, 1, 1, -20)
	divider.Position                = UDim2.new(1, 0, 0, 10)
	divider.BackgroundColor3        = THEME.stroke
	divider.BackgroundTransparency  = THEME.mediumAlpha
	divider.BorderSizePixel         = 0
	divider.ZIndex                  = 201
	divider.Parent                  = sidebar

	-- ── Cabecera ─────────────────────────────────────────────────
	local headerHeight = 0

	if title ~= "" then
		UI.label({
			name      = "SidebarTitle",
			size      = UDim2.new(1, -16, 0, 34),
			pos       = UDim2.new(0, 8, 0, 18),
			text      = title,
			color     = THEME.text,
			font      = Enum.Font.GothamBlack,
			textSize  = 18,
			alignX    = Enum.TextXAlignment.Center,
			z         = 202, parent = sidebar,
		})
		headerHeight = headerHeight + 58

		-- Línea decorativa bajo el título
		local decoLine = Instance.new("Frame")
		decoLine.Name                   = "DecoLine"
		decoLine.Size                   = UDim2.new(0.55, 0, 0, 1)
		decoLine.Position               = UDim2.new(0.225, 0, 0, headerHeight)
		decoLine.BackgroundColor3       = THEME.accent
		decoLine.BackgroundTransparency = THEME.mediumAlpha
		decoLine.BorderSizePixel        = 0
		decoLine.ZIndex                 = 202
		decoLine.Parent                 = sidebar
		headerHeight = headerHeight + 8
	end

	if subtitle then
		UI.label({
			name      = "SidebarSubtitle",
			size      = UDim2.new(1, -16, 0, 20),
			pos       = UDim2.new(0, 8, 0, headerHeight + 2),
			text      = subtitle,
			color     = THEME.muted,
			font      = Enum.Font.GothamBold,
			textSize  = 10,
			alignX    = Enum.TextXAlignment.Center,
			z         = 202, parent = sidebar,
		})
		headerHeight = headerHeight + 22
	end

	-- ── Items de navegación — icono circular grande + label (patrón GamepassShop) ─
	local ICON_SIZE = isMobile and 48 or 56
	local ITEM_H    = ICON_SIZE + 30   -- círculo + label + padding
	local ITEM_GAP  = 10
	local ITEMS_PAD = 8

	-- ScrollingFrame que ocupa el espacio bajo el header
	local itemsScroll = Instance.new("ScrollingFrame")
	itemsScroll.Name                     = "ItemsScroll"
	itemsScroll.Size                     = UDim2.new(1, 0, 1, -(headerHeight + 4))
	itemsScroll.Position                 = UDim2.new(0, 0, 0, headerHeight + 4)
	itemsScroll.BackgroundTransparency   = 1
	itemsScroll.BorderSizePixel          = 0
	itemsScroll.ScrollBarThickness       = 0
	itemsScroll.ScrollBarImageTransparency = 1
	itemsScroll.ScrollingDirection       = Enum.ScrollingDirection.Y
	itemsScroll.CanvasSize               = UDim2.new(0, 0, 0, 0)
	itemsScroll.ZIndex                   = 201
	itemsScroll.Parent                   = sidebar

	ModernScrollbar.setup(itemsScroll, sidebar, THEME, {transparency = 0, offset = -6, zIndex = 210})

	for i, item in ipairs(items) do
		local posY = ITEMS_PAD + (i - 1) * (ITEM_H + ITEM_GAP)

		-- Frame invisible de ítem (solo para layout/click)
		local btn = Instance.new("Frame")
		btn.Name                  = "Nav_" .. item.id
		btn.Size                  = UDim2.new(1, 0, 0, ITEM_H)
		btn.Position              = UDim2.new(0, 0, 0, posY)
		btn.BackgroundTransparency = 1
		btn.BorderSizePixel       = 0
		btn.ZIndex                = 202
		btn.Parent                = itemsScroll
		self._buttons[item.id] = btn

		-- Círculo de icono — idéntico a decoIcon de GamepassShop
		local iconFrame = UI.frame({
			name   = "IconFrame",
			size   = UDim2.new(0, ICON_SIZE, 0, ICON_SIZE),
			pos    = UDim2.new(0.5, -ICON_SIZE / 2, 0, 0),
			bg     = THEME.card,
			bgT    = THEME.frameAlpha,
			z      = 203, parent = btn, corner = ICON_SIZE / 2,
		})
		self._iconFrames[item.id] = iconFrame

		local iconStroke = Instance.new("UIStroke")
		iconStroke.Color        = THEME.stroke
		iconStroke.Thickness    = 1.5
		iconStroke.Transparency = THEME.lightAlpha
		iconStroke.Parent       = iconFrame
		self._iconStks[item.id] = iconStroke

		local img = Instance.new("ImageLabel")
		img.Name                   = "Icon"
		img.Size                   = UDim2.new(1, 0, 1, 0)
		img.Position               = UDim2.new(0, 0, 0, 0)
		img.BackgroundTransparency = 1
		img.Image                  = "rbxassetid://" .. tostring(item.image or "79346090571461")
		img.ScaleType              = Enum.ScaleType.Crop
		img.ZIndex                 = 204
		img.Parent                 = iconFrame
		Instance.new("UICorner", img).CornerRadius = UDim.new(1, 0)
		self._iconImgs[item.id] = img

		-- Separador fino bajo el círculo (como decoLine2 de GamepassShop)
		local sep = Instance.new("Frame")
		sep.Size                   = UDim2.new(0.5, 0, 0, 1)
		sep.Position               = UDim2.new(0.25, 0, 0, ICON_SIZE + 6)
		sep.BackgroundColor3       = THEME.stroke
		sep.BackgroundTransparency = THEME.lightAlpha
		sep.BorderSizePixel        = 0
		sep.ZIndex                 = 202
		sep.Parent                 = btn

		-- Label bajo el icono — GothamBlack igual que "GAMEPASSES" en GamepassShop
		local lbl = UI.label({
			name      = "Label",
			size      = UDim2.new(1, -8, 0, 18),
			pos       = UDim2.new(0, 4, 0, ICON_SIZE + 10),
			text      = item.label,
			color     = THEME.muted,
			font      = Enum.Font.GothamBlack,
			textSize  = isMobile and 11 or 13,
			alignX    = Enum.TextXAlignment.Center,
			z         = 203, parent = btn,
		})
		self._labels[item.id] = lbl

		-- Botón invisible encima
		local clickBtn = Instance.new("TextButton")
		clickBtn.Size                   = UDim2.new(1, 0, 1, 0)
		clickBtn.BackgroundTransparency = 1
		clickBtn.Text                   = ""
		clickBtn.ZIndex                 = 205
		clickBtn.Parent                 = btn

		-- Actualizar canvas al final del loop (lo hacemos fuera)
		if i == #items then
			itemsScroll.CanvasSize = UDim2.new(0, 0, 0, posY + ITEM_H + ITEMS_PAD)
		end

		local capturedId = item.id
		clickBtn.MouseButton1Click:Connect(function()
			self:selectItem(capturedId)
			onSelect(capturedId)
		end)

		-- Hover: solo stroke accent + texto accent (sin fondo)
		clickBtn.MouseEnter:Connect(function()
			if self._selected ~= capturedId then
				TweenService:Create(iconStroke, TW_FAST, { Color = THEME.accentHover or THEME.accent, Transparency = THEME.mediumAlpha }):Play()
				TweenService:Create(lbl, TW_FAST, { TextColor3 = THEME.accentHover or THEME.accent }):Play()
			end
		end)
		clickBtn.MouseLeave:Connect(function()
			if self._selected ~= capturedId then
				TweenService:Create(iconStroke, TW_FAST, { Color = THEME.stroke, Transparency = THEME.lightAlpha }):Play()
				TweenService:Create(lbl, TW_FAST, { TextColor3 = THEME.muted }):Play()
			end
		end)
	end

	-- ── Footer decorativo ────────────────────────────────────────
	if opts.footerText then
		UI.label({
			name      = "FooterText",
			size      = UDim2.new(1, -12, 0, 28),
			pos       = UDim2.new(0, 6, 1, -38),
			text      = opts.footerText,
			color     = THEME.subtle or THEME.muted,
			font      = Enum.Font.GothamBold,
			textSize  = 11,
			alignX    = Enum.TextXAlignment.Center,
			z         = 202, parent = sidebar,
		})
	end

	return self
end

-- Selecciona un item por id (actualiza visual, sin llamar onSelect)
function SidebarNav:selectItem(id)
	local THEME = self._THEME

	-- Deseleccionar anterior
	if self._selected then
		local prev = self._selected
		if self._labels[prev] then
			TweenService:Create(self._labels[prev], TW_NORM, { TextColor3 = THEME.muted }):Play()
		end
		if self._iconStks[prev] then
			TweenService:Create(self._iconStks[prev], TW_NORM, { Color = THEME.stroke, Transparency = THEME.lightAlpha }):Play()
		end
	end

	self._selected = id

	-- Seleccionar nuevo
	if self._labels[id] then
		TweenService:Create(self._labels[id], TW_NORM, { TextColor3 = THEME.accent }):Play()
	end
	if self._iconStks[id] then
		TweenService:Create(self._iconStks[id], TW_NORM, { Color = THEME.accent, Transparency = 0 }):Play()
	end
end

-- Retorna el ancho del frame del sidebar
function SidebarNav:getWidth()
	return self.frame.AbsoluteSize.X
end

return SidebarNav
