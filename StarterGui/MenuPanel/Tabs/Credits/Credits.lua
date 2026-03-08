--[[
	Credits/Credits.lua — Tab de CREDITOS para el MenuPanel.
	Diseño moderno: avatares reales, sin lineas decorativas, cards con gradiente.
]]

local Credits = {}

function Credits.build(parent, THEME)
	local Players = game:GetService("Players")
	local TweenService = game:GetService("TweenService")
	local ModernScrollbar = require(
		game:GetService("ReplicatedStorage"):WaitForChild("UIComponents"):WaitForChild("ModernScrollbar")
	)

	local TW = TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

	local CREDITS = {
		message = "Gracias por ser parte de Mambo Kings! A cada persona que entra, participa, baila y comparte buena vibra: gracias de corazon. Su apoyo, sus ideas y su energia han sido clave para que este servidor crezca y se sienta como casa.",
		team = {
			{ name = "ignxts",        role = "DEV EXPERT", userId = nil, grad = Color3.fromRGB(90, 40, 140) },
			{ name = "xlm_brem",      role = "DEVELOPER",  userId = nil, grad = Color3.fromRGB(40, 80, 160) },
			{ name = "AngeloGarciia", role = "CREADOR",    userId = nil, grad = Color3.fromRGB(140, 60, 30) },
		},
	}

	-- Resolver userIds por nombre
	task.spawn(function()
		for _, m in ipairs(CREDITS.team) do
			local ok, id = pcall(function()
				return Players:GetUserIdFromNameAsync(m.name)
			end)
			if ok and id then
				m.userId = id
			end
		end
	end)

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
	pad.PaddingLeft   = UDim.new(0, 12)
	pad.PaddingRight  = UDim.new(0, 12)
	pad.PaddingTop    = UDim.new(0, 16)
	pad.PaddingBottom = UDim.new(0, 20)
	pad.Parent        = scroll

	-- Titulo
	local titleLbl = Instance.new("TextLabel")
	titleLbl.Size                   = UDim2.new(1, 0, 0, 32)
	titleLbl.BackgroundTransparency = 1
	titleLbl.Font                   = Enum.Font.GothamBlack
	titleLbl.TextSize               = 22
	titleLbl.TextColor3             = THEME.accent
	titleLbl.TextXAlignment         = Enum.TextXAlignment.Center
	titleLbl.Text                   = "CREDITOS"
	titleLbl.LayoutOrder            = 1
	titleLbl.ZIndex                 = 205
	titleLbl.Parent                 = scroll

	-- Mensaje card
	local msgCard = Instance.new("CanvasGroup")
	msgCard.Size                   = UDim2.new(1, 0, 0, 0)
	msgCard.AutomaticSize          = Enum.AutomaticSize.Y
	msgCard.BackgroundColor3       = THEME.card
	msgCard.BorderSizePixel        = 0
	msgCard.ZIndex                 = 205
	msgCard.LayoutOrder            = 2
	msgCard.Parent                 = scroll
	local mcc = Instance.new("UICorner"); mcc.CornerRadius = UDim.new(0, 12); mcc.Parent = msgCard

	local msgPad = Instance.new("UIPadding")
	msgPad.PaddingLeft   = UDim.new(0, 16)
	msgPad.PaddingRight  = UDim.new(0, 16)
	msgPad.PaddingTop    = UDim.new(0, 14)
	msgPad.PaddingBottom = UDim.new(0, 14)
	msgPad.Parent        = msgCard

	local msgLbl = Instance.new("TextLabel")
	msgLbl.Size                   = UDim2.new(1, 0, 0, 0)
	msgLbl.AutomaticSize          = Enum.AutomaticSize.Y
	msgLbl.BackgroundTransparency = 1
	msgLbl.Font                   = Enum.Font.Gotham
	msgLbl.TextSize               = 13
	msgLbl.TextColor3             = THEME.textSoft
	msgLbl.TextWrapped            = true
	msgLbl.TextXAlignment         = Enum.TextXAlignment.Center
	msgLbl.Text                   = CREDITS.message
	msgLbl.ZIndex                 = 206
	msgLbl.Parent                 = msgCard

	-- Header equipo
	local teamHeader = Instance.new("TextLabel")
	teamHeader.Size                   = UDim2.new(1, 0, 0, 24)
	teamHeader.BackgroundTransparency = 1
	teamHeader.Font                   = Enum.Font.GothamBold
	teamHeader.TextSize               = 12
	teamHeader.TextColor3             = THEME.accent
	teamHeader.TextXAlignment         = Enum.TextXAlignment.Center
	teamHeader.Text                   = "EQUIPO"
	teamHeader.ZIndex                 = 205
	teamHeader.LayoutOrder            = 3
	teamHeader.Parent                 = scroll

	-- Team cards
	for i, member in ipairs(CREDITS.team) do
		local CARD_H = 70

		local devCard = Instance.new("CanvasGroup")
		devCard.Size                   = UDim2.new(1, 0, 0, CARD_H)
		devCard.BackgroundColor3       = THEME.card
		devCard.BorderSizePixel        = 0
		devCard.ZIndex                 = 205
		devCard.LayoutOrder            = 3 + i
		devCard.Parent                 = scroll
		local dcc = Instance.new("UICorner"); dcc.CornerRadius = UDim.new(0, 12); dcc.Parent = devCard

		-- Gradiente lateral
		local gradOverlay = Instance.new("Frame")
		gradOverlay.Size = UDim2.new(0.4, 0, 1, 0)
		gradOverlay.BackgroundColor3 = member.grad
		gradOverlay.BackgroundTransparency = 0
		gradOverlay.BorderSizePixel = 0
		gradOverlay.ZIndex = 206
		gradOverlay.Parent = devCard
		local gd = Instance.new("UIGradient")
		gd.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.5),
			NumberSequenceKeypoint.new(0.6, 0.85),
			NumberSequenceKeypoint.new(1, 1),
		})
		gd.Parent = gradOverlay

		-- Avatar real (circular, 48x48)
		local AVATAR_S = 48
		local avatarFrame = Instance.new("Frame")
		avatarFrame.Size             = UDim2.new(0, AVATAR_S, 0, AVATAR_S)
		avatarFrame.Position         = UDim2.new(0, 14, 0.5, -AVATAR_S / 2)
		avatarFrame.BackgroundColor3 = THEME.elevated
		avatarFrame.BorderSizePixel  = 0
		avatarFrame.ZIndex           = 208
		avatarFrame.Parent           = devCard
		local afc = Instance.new("UICorner"); afc.CornerRadius = UDim.new(1, 0); afc.Parent = avatarFrame

		local avatarImg = Instance.new("ImageLabel")
		avatarImg.Size                   = UDim2.fromScale(1, 1)
		avatarImg.BackgroundTransparency = 1
		avatarImg.ScaleType              = Enum.ScaleType.Crop
		avatarImg.ZIndex                 = 209
		avatarImg.Image                  = ""
		avatarImg.Parent                 = avatarFrame
		local aiC = Instance.new("UICorner"); aiC.CornerRadius = UDim.new(1, 0); aiC.Parent = avatarImg

		-- Fallback letter
		local avatarLetter = Instance.new("TextLabel")
		avatarLetter.Size                   = UDim2.fromScale(1, 1)
		avatarLetter.BackgroundTransparency = 1
		avatarLetter.Font                   = Enum.Font.GothamBold
		avatarLetter.TextSize               = 18
		avatarLetter.TextColor3             = THEME.accent
		avatarLetter.Text                   = string.upper(string.sub(member.name, 1, 1))
		avatarLetter.ZIndex                 = 209
		avatarLetter.Parent                 = avatarFrame

		-- Cargar avatar real async
		task.spawn(function()
			-- Esperar a que se resuelva userId
			local tries = 0
			while not member.userId and tries < 40 do
				task.wait(0.25)
				tries = tries + 1
			end
			if member.userId then
				local ok, thumb = pcall(function()
					return Players:GetUserThumbnailAsync(
						member.userId,
						Enum.ThumbnailType.HeadShot,
						Enum.ThumbnailSize.Size100x100
					)
				end)
				if ok and thumb and avatarImg.Parent then
					avatarImg.Image = thumb
					avatarLetter.Visible = false
				end
			end
		end)

		-- Nombre
		local TEXT_X = 14 + AVATAR_S + 14
		local mName = Instance.new("TextLabel")
		mName.Size                   = UDim2.new(1, -TEXT_X - 10, 0, 22)
		mName.Position               = UDim2.new(0, TEXT_X, 0, 12)
		mName.BackgroundTransparency = 1
		mName.Font                   = Enum.Font.GothamBold
		mName.TextSize               = 15
		mName.TextColor3             = THEME.text
		mName.TextXAlignment         = Enum.TextXAlignment.Left
		mName.TextTruncate           = Enum.TextTruncate.AtEnd
		mName.Text                   = member.name
		mName.ZIndex                 = 208
		mName.Parent                 = devCard

		local mRole = Instance.new("TextLabel")
		mRole.Size                   = UDim2.new(1, -TEXT_X - 10, 0, 16)
		mRole.Position               = UDim2.new(0, TEXT_X, 0, 36)
		mRole.BackgroundTransparency = 1
		mRole.Font                   = Enum.Font.GothamBold
		mRole.TextSize               = 11
		mRole.TextColor3             = THEME.accent
		mRole.TextXAlignment         = Enum.TextXAlignment.Left
		mRole.Text                   = member.role
		mRole.ZIndex                 = 208
		mRole.Parent                 = devCard

		-- Hover
		devCard.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseMovement then
				TweenService:Create(devCard, TW, {BackgroundColor3 = THEME.elevated}):Play()
			end
		end)
		devCard.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseMovement then
				TweenService:Create(devCard, TW, {BackgroundColor3 = THEME.card}):Play()
			end
		end)
	end

	-- Footer
	local footer = Instance.new("TextLabel")
	footer.Size                   = UDim2.new(1, 0, 0, 30)
	footer.BackgroundTransparency = 1
	footer.Font                   = Enum.Font.Gotham
	footer.TextSize               = 10
	footer.TextColor3             = THEME.textSoft
	footer.TextTransparency       = 0.4
	footer.TextXAlignment         = Enum.TextXAlignment.Center
	footer.Text                   = "Mambo Kings " .. utf8.char(0x2764) .. " 2026"
	footer.ZIndex                 = 205
	footer.LayoutOrder            = 100
	footer.Parent                 = scroll
end

return Credits
