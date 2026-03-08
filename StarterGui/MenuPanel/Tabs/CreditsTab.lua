--[[
	CreditsTab.lua — ModuleScript
	Tab de CRÉDITOS para el MenuPanel.
	Muestra mensaje de agradecimiento + tarjetas del equipo.
]]

local CreditsTab = {}

function CreditsTab.build(parent, THEME)
	local ModernScrollbar = require(
		game:GetService("ReplicatedStorage"):WaitForChild("UIComponents"):WaitForChild("ModernScrollbar")
	)

	local CREDITS = {
		message = "Gracias por ser parte de Ritmo Latino! A cada persona que entra, participa, baila y comparte buena vibra: gracias de corazon. Su apoyo, sus ideas y su energia han sido clave para que este servidor crezca y se sienta como casa.",
		team = {
			{ name = "ignxts",        role = "DEV EXPERT" },
			{ name = "xlm_brem",      role = "DEVELOPER"  },
			{ name = "AngeloGarciia", role = "CREADOR"     },
		},
	}

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

	local layout = Instance.new("UIListLayout")
	layout.Padding             = UDim.new(0, 12)
	layout.SortOrder           = Enum.SortOrder.LayoutOrder
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Parent              = scroll

	local pad = Instance.new("UIPadding")
	pad.PaddingLeft   = UDim.new(0, 14)
	pad.PaddingRight  = UDim.new(0, 14)
	pad.PaddingTop    = UDim.new(0, 18)
	pad.PaddingBottom = UDim.new(0, 20)
	pad.Parent        = scroll

	-- Barra decorativa superior
	local topLine = Instance.new("Frame")
	topLine.Size                   = UDim2.new(0.3, 0, 0, 3)
	topLine.BackgroundColor3       = THEME.accent
	topLine.BackgroundTransparency = 0.15
	topLine.BorderSizePixel        = 0
	topLine.ZIndex                 = 205
	topLine.LayoutOrder            = 1
	topLine.Parent                 = scroll
	local tlc = Instance.new("UICorner"); tlc.CornerRadius = UDim.new(1, 0); tlc.Parent = topLine

	-- Título
	local titleLbl = Instance.new("TextLabel")
	titleLbl.Size                   = UDim2.new(1, 0, 0, 36)
	titleLbl.BackgroundTransparency = 1
	titleLbl.Font                   = Enum.Font.GothamBold
	titleLbl.TextSize               = 22
	titleLbl.TextColor3             = THEME.accent
	titleLbl.TextXAlignment         = Enum.TextXAlignment.Center
	titleLbl.Text                   = "Créditos"
	titleLbl.LayoutOrder            = 2
	titleLbl.ZIndex                 = 205
	titleLbl.Parent                 = scroll

	-- Divider
	local divider = Instance.new("Frame")
	divider.Size                   = UDim2.new(0.12, 0, 0, 2)
	divider.BackgroundColor3       = THEME.accent
	divider.BackgroundTransparency = 0.2
	divider.BorderSizePixel        = 0
	divider.ZIndex                 = 205
	divider.LayoutOrder            = 3
	divider.Parent                 = scroll
	local dc = Instance.new("UICorner"); dc.CornerRadius = UDim.new(1, 0); dc.Parent = divider

	-- Card de mensaje
	local msgCard = Instance.new("Frame")
	msgCard.Size                   = UDim2.new(1, 0, 0, 0)
	msgCard.AutomaticSize          = Enum.AutomaticSize.Y
	msgCard.BackgroundColor3       = THEME.card
	msgCard.BackgroundTransparency = THEME.frameAlpha
	msgCard.BorderSizePixel        = 0
	msgCard.ZIndex                 = 205
	msgCard.LayoutOrder            = 4
	msgCard.Parent                 = scroll
	local mcc = Instance.new("UICorner"); mcc.CornerRadius = UDim.new(0, 10); mcc.Parent = msgCard
	local mcs = Instance.new("UIStroke"); mcs.Color = THEME.stroke; mcs.Thickness = 1; mcs.Transparency = 0.5; mcs.Parent = msgCard

	local msgPad = Instance.new("UIPadding")
	msgPad.PaddingLeft   = UDim.new(0, 14)
	msgPad.PaddingRight  = UDim.new(0, 14)
	msgPad.PaddingTop    = UDim.new(0, 12)
	msgPad.PaddingBottom = UDim.new(0, 12)
	msgPad.Parent        = msgCard

	local msgLbl = Instance.new("TextLabel")
	msgLbl.Size                   = UDim2.new(1, 0, 0, 0)
	msgLbl.AutomaticSize          = Enum.AutomaticSize.Y
	msgLbl.BackgroundTransparency = 1
	msgLbl.Font                   = Enum.Font.Gotham
	msgLbl.TextSize               = 13
	msgLbl.TextColor3             = THEME.text
	msgLbl.TextWrapped            = true
	msgLbl.TextXAlignment         = Enum.TextXAlignment.Center
	msgLbl.Text                   = CREDITS.message
	msgLbl.ZIndex                 = 206
	msgLbl.Parent                 = msgCard

	-- Sección equipo
	local teamHeader = Instance.new("TextLabel")
	teamHeader.Size                   = UDim2.new(1, 0, 0, 20)
	teamHeader.BackgroundTransparency = 1
	teamHeader.Font                   = Enum.Font.GothamBold
	teamHeader.TextSize               = 11
	teamHeader.TextColor3             = THEME.accent
	teamHeader.TextXAlignment         = Enum.TextXAlignment.Center
	teamHeader.Text                   = "— EQUIPO —"
	teamHeader.ZIndex                 = 205
	teamHeader.LayoutOrder            = 5
	teamHeader.Parent                 = scroll

	-- Cards del equipo
	for i, member in ipairs(CREDITS.team) do
		local devCard = Instance.new("Frame")
		devCard.Size                   = UDim2.new(1, 0, 0, 58)
		devCard.BackgroundColor3       = THEME.card
		devCard.BackgroundTransparency = THEME.frameAlpha
		devCard.BorderSizePixel        = 0
		devCard.ZIndex                 = 205
		devCard.LayoutOrder            = 5 + i
		devCard.Parent                 = scroll
		local dcc = Instance.new("UICorner"); dcc.CornerRadius = UDim.new(0, 10); dcc.Parent = devCard
		local dcs = Instance.new("UIStroke"); dcs.Color = THEME.stroke; dcs.Thickness = 1; dcs.Transparency = 0.5; dcs.Parent = devCard

		-- Barra acento izquierda
		local accentBar = Instance.new("Frame")
		accentBar.Size                   = UDim2.new(0, 4, 0.65, 0)
		accentBar.Position               = UDim2.new(0, 10, 0.175, 0)
		accentBar.BackgroundColor3       = THEME.accent
		accentBar.BorderSizePixel        = 0
		accentBar.ZIndex                 = 206
		accentBar.Parent                 = devCard
		local abc = Instance.new("UICorner"); abc.CornerRadius = UDim.new(1, 0); abc.Parent = accentBar

		-- Avatar placeholder
		local avatarFrame = Instance.new("Frame")
		avatarFrame.Size                   = UDim2.new(0, 36, 0, 36)
		avatarFrame.Position               = UDim2.new(0, 22, 0.5, -18)
		avatarFrame.BackgroundColor3       = THEME.elevated
		avatarFrame.BorderSizePixel        = 0
		avatarFrame.ZIndex                 = 206
		avatarFrame.Parent                 = devCard
		local afc = Instance.new("UICorner"); afc.CornerRadius = UDim.new(0, 10); afc.Parent = avatarFrame

		local avatarLbl = Instance.new("TextLabel")
		avatarLbl.Size                   = UDim2.fromScale(1, 1)
		avatarLbl.BackgroundTransparency = 1
		avatarLbl.Font                   = Enum.Font.GothamBold
		avatarLbl.TextSize               = 14
		avatarLbl.TextColor3             = THEME.accent
		avatarLbl.Text                   = string.upper(string.sub(member.name, 1, 1))
		avatarLbl.ZIndex                 = 207
		avatarLbl.Parent                 = avatarFrame

		-- Nombre
		local mName = Instance.new("TextLabel")
		mName.Size                   = UDim2.new(1, -72, 0, 20)
		mName.Position               = UDim2.new(0, 66, 0, 8)
		mName.BackgroundTransparency = 1
		mName.Font                   = Enum.Font.GothamBold
		mName.TextSize               = 13
		mName.TextColor3             = THEME.text
		mName.TextXAlignment         = Enum.TextXAlignment.Left
		mName.Text                   = member.name
		mName.ZIndex                 = 206
		mName.Parent                 = devCard

		-- Rol
		local mRole = Instance.new("TextLabel")
		mRole.Size                   = UDim2.new(1, -72, 0, 16)
		mRole.Position               = UDim2.new(0, 66, 0, 30)
		mRole.BackgroundTransparency = 1
		mRole.Font                   = Enum.Font.Gotham
		mRole.TextSize               = 10
		mRole.TextColor3             = THEME.accent
		mRole.TextXAlignment         = Enum.TextXAlignment.Left
		mRole.Text                   = member.role
		mRole.ZIndex                 = 206
		mRole.Parent                 = devCard
	end
end

return CreditsTab
