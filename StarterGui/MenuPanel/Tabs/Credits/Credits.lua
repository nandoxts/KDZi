--[[
	Credits/Credits.lua — Tab de CREDITOS para el MenuPanel.
	Secciones centradas, todo configurable.
]]

local Credits = {}

function Credits.build(parent, THEME)
	local ModernScrollbar = require(
		game:GetService("ReplicatedStorage"):WaitForChild("UIComponents"):WaitForChild("ModernScrollbar")
	)

	-- ══════════════════════════════════════════════════════════
	-- ══ CONFIGURACIÓN DE CRÉDITOS  (edita aquí fácilmente) ══
	-- ══════════════════════════════════════════════════════════
	--  • names = {"a","b"}          → nombres centrados, uno por línea
	--  • pairs = {{"a","b"}, …}     → dos columnas por fila
	local SECTIONS = {
		{ title = "Desarrollo",             names = {"Mambo Kingz Studios"} },
		{ title = "Creadores",              pairs = {{"itzjheiner", "VALLEIDS"}} },
		{ title = "Programador",            names = {"ignxts"} },
		{ title = "Diseño del mapa",        names = {"suetzmn"} },
		{ title = "Moderación",             pairs = {{"Leviz", "Zummer"}, {"Seigm", ""}} },
		{ title = "DJs",                    names = {} },
	}
	-- ══════════════════════════════════════════════════════════

	-- Scroll
	local scroll = Instance.new("ScrollingFrame")
	scroll.Size                   = UDim2.fromScale(1, 1)
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel        = 0
	scroll.ScrollBarThickness     = 0
	scroll.CanvasSize             = UDim2.new(0, 0, 0, 0)
	scroll.AutomaticCanvasSize    = Enum.AutomaticSize.Y
	scroll.ClipsDescendants       = true
	scroll.ZIndex                 = 204
	scroll.Parent                 = parent
	ModernScrollbar.setup(scroll, parent, THEME, {transparency = 0.4, offset = -4})

	local mainLayout = Instance.new("UIListLayout")
	mainLayout.Padding             = UDim.new(0, 6)
	mainLayout.SortOrder           = Enum.SortOrder.LayoutOrder
	mainLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	mainLayout.Parent              = scroll

	local mainPad = Instance.new("UIPadding")
	mainPad.PaddingLeft   = UDim.new(0, 16)
	mainPad.PaddingRight  = UDim.new(0, 16)
	mainPad.PaddingTop    = UDim.new(0, 10)
	mainPad.PaddingBottom = UDim.new(0, 24)
	mainPad.Parent        = scroll

	-- Render secciones
	for i, section in ipairs(SECTIONS) do
		-- Contenedor de sección
		local sectionFrame = Instance.new("Frame")
		sectionFrame.Size                   = UDim2.new(1, 0, 0, 0)
		sectionFrame.AutomaticSize          = Enum.AutomaticSize.Y
		sectionFrame.BackgroundTransparency = 1
		sectionFrame.BorderSizePixel        = 0
		sectionFrame.LayoutOrder            = i
		sectionFrame.ZIndex                 = 205
		sectionFrame.Parent                 = scroll

		local secLayout = Instance.new("UIListLayout")
		secLayout.Padding             = UDim.new(0, 2)
		secLayout.SortOrder           = Enum.SortOrder.LayoutOrder
		secLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		secLayout.Parent              = sectionFrame

		local secPad = Instance.new("UIPadding")
		secPad.PaddingTop    = UDim.new(0, 8)
		secPad.PaddingBottom = UDim.new(0, 4)
		secPad.Parent        = sectionFrame

		-- Titulo de sección
		local header = Instance.new("TextLabel")
		header.Size                   = UDim2.new(1, 0, 0, 20)
		header.BackgroundTransparency = 1
		header.Font                   = Enum.Font.Gotham
		header.TextSize               = 13
		header.TextColor3             = THEME.muted
		header.TextXAlignment         = Enum.TextXAlignment.Center
		header.Text                   = section.title
		header.LayoutOrder            = 0
		header.ZIndex                 = 206
		header.Parent                 = sectionFrame

		if section.names then
			-- Nombres centrados uno por línea
			for j, name in ipairs(section.names) do
				local lbl = Instance.new("TextLabel")
				lbl.Size                   = UDim2.new(1, 0, 0, 20)
				lbl.BackgroundTransparency = 1
				lbl.Font                   = Enum.Font.GothamBold
				lbl.TextSize               = 14
				lbl.TextColor3             = THEME.text
				lbl.TextXAlignment         = Enum.TextXAlignment.Center
				lbl.Text                   = name
				lbl.LayoutOrder            = j
				lbl.ZIndex                 = 206
				lbl.Parent                 = sectionFrame
			end
		elseif section.pairs then
			-- Dos columnas por fila
			for j, pair in ipairs(section.pairs) do
				local row = Instance.new("Frame")
				row.Size                   = UDim2.new(1, 0, 0, 20)
				row.BackgroundTransparency = 1
				row.BorderSizePixel        = 0
				row.LayoutOrder            = j
				row.ZIndex                 = 206
				row.Parent                 = sectionFrame

				local left = Instance.new("TextLabel")
				left.Size                   = UDim2.new(0.5, -4, 1, 0)
				left.Position               = UDim2.new(0, 0, 0, 0)
				left.BackgroundTransparency = 1
				left.Font                   = Enum.Font.GothamBold
				left.TextSize               = 14
				left.TextColor3             = THEME.text
				left.TextXAlignment         = Enum.TextXAlignment.Right
				left.TextTruncate           = Enum.TextTruncate.AtEnd
				left.Text                   = pair[1]
				left.ZIndex                 = 206
				left.Parent                 = row

				local right = Instance.new("TextLabel")
				right.Size                   = UDim2.new(0.5, -4, 1, 0)
				right.Position               = UDim2.new(0.5, 4, 0, 0)
				right.BackgroundTransparency = 1
				right.Font                   = Enum.Font.GothamBold
				right.TextSize               = 14
				right.TextColor3             = THEME.text
				right.TextXAlignment         = Enum.TextXAlignment.Left
				right.TextTruncate           = Enum.TextTruncate.AtEnd
				right.Text                   = pair[2]
				right.ZIndex                 = 206
				right.Parent                 = row
			end
		end
	end
end

return Credits
