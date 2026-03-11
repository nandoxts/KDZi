--[[
	 Card.lua - Componente card reutilizable (CanvasGroup)
	 CanvasGroup + imagen full-height izq + labels + boton circular.
	 Base compartida para cards de jugadores, canciones DJ, etc.
	 Diseño unificado: height=62, title=15 Bold, subtitle=13 Bold, btn=38.

	 Uso:
		local c = Card.new(parent, {
			image      = "rbxassetid://...",
			name       = "Titulo",
			subtitle   = "Subtitulo",
			buttonIcon = UI.ICONS.PLAY_ADD,
			onAction   = function() end,
		})
		c.card, c.imageLabel, c.nameLabel, c.subtitleLabel, c.actionBtn
]]

local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local THEME = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("ThemeConfig"))
local UI    = require(ReplicatedStorage:WaitForChild("Core"):WaitForChild("UI"))

local Card = {}
Card.__index = Card

local TWEEN_HOVER = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

function Card.new(parent, opts)
	opts = opts or {}
	local self = setmetatable({}, Card)

	local H       = 62
	local corner  = 10
	local z       = opts.zIndex     or 1
	local btnSize = 38

	-- CanvasGroup base
	local card = Instance.new("CanvasGroup")
	card.Name                   = opts.instanceName or "Card"
	card.Size                   = opts.size or UDim2.new(1, 0, 0, H)
	card.BackgroundColor3       = THEME.card
	card.BackgroundTransparency = 0
	card.BorderSizePixel        = 0
	card.GroupTransparency      = 0
	card.LayoutOrder            = opts.layoutOrder or 0
	card.ZIndex                 = z
	card.Parent                 = parent

	Instance.new("UICorner", card).CornerRadius = UDim.new(0, corner)
	local stroke = UI.stroked(card, 0.3)

	-- Imagen full-height izquierda
	local imgFrame = Instance.new("Frame")
	imgFrame.Name                   = "CoverBg"
	imgFrame.Size                   = UDim2.new(0, H, 1, 0)
	imgFrame.BackgroundColor3       = opts.imageBg or THEME.elevated
	imgFrame.BackgroundTransparency = 0
	imgFrame.BorderSizePixel        = 0
	imgFrame.ZIndex                 = z + 1
	imgFrame.Parent                 = card

	local imgLabel = Instance.new("ImageLabel")
	imgLabel.Name                   = "Cover"
	imgLabel.Size                   = UDim2.new(1, 0, 1, 0)
	imgLabel.BackgroundTransparency = 1
	imgLabel.Image                  = opts.image or ""
	imgLabel.ScaleType              = Enum.ScaleType.Crop
	imgLabel.BorderSizePixel        = 0
	imgLabel.ZIndex                 = z + 2
	imgLabel.Parent                 = imgFrame

	-- Labels
	local showBtn  = opts.showButton ~= false
	local tx       = H + 10
	local rightPad = showBtn and (btnSize + 16) or 8

	-- Contenedor de labels centrado verticalmente
	local labelsContainer = Instance.new("Frame")
	labelsContainer.Name                   = "Labels"
	labelsContainer.Size                   = UDim2.new(1, -(tx + rightPad), 0, 40)
	labelsContainer.Position               = UDim2.new(0, tx, 0.5, -20)
	labelsContainer.BackgroundTransparency = 1
	labelsContainer.BorderSizePixel        = 0
	labelsContainer.ZIndex                 = z + 1
	labelsContainer.Parent                 = card

	local labelsLayout = Instance.new("UIListLayout")
	labelsLayout.Padding       = UDim.new(0, 0)
	labelsLayout.SortOrder     = Enum.SortOrder.LayoutOrder
	labelsLayout.Parent        = labelsContainer

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name                   = "NameLabel"
	nameLabel.Size                   = UDim2.new(1, 0, 0, 22)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font                   = Enum.Font.GothamBold
	nameLabel.TextSize               = 17
	nameLabel.TextColor3             = THEME.text
	nameLabel.TextXAlignment         = Enum.TextXAlignment.Left
	nameLabel.TextTruncate           = Enum.TextTruncate.AtEnd
	nameLabel.Text                   = opts.name or ""
	nameLabel.LayoutOrder            = 1
	nameLabel.ZIndex                 = z + 1
	nameLabel.Parent                 = labelsContainer

	local subtitleLabel = Instance.new("TextLabel")
	subtitleLabel.Name                   = "SubtitleLabel"
	subtitleLabel.Size                   = UDim2.new(1, 0, 0, 18)
	subtitleLabel.BackgroundTransparency = 1
	subtitleLabel.Font                   = Enum.Font.GothamBold
	subtitleLabel.TextSize               = 15
	subtitleLabel.TextColor3             = THEME.muted
	subtitleLabel.TextXAlignment         = Enum.TextXAlignment.Left
	subtitleLabel.TextTruncate           = Enum.TextTruncate.AtEnd
	subtitleLabel.Text                   = opts.subtitle or ""
	subtitleLabel.LayoutOrder            = 2
	subtitleLabel.ZIndex                 = z + 1
	subtitleLabel.Parent                 = labelsContainer

	-- Boton circular outlined
	local actionBtn, actionIcon
	if showBtn then
		local iconStr = opts.buttonIcon
		if not iconStr or iconStr == "" then iconStr = UI.ICONS.PLAY_ADD end

		actionBtn, actionIcon = UI.outlinedCircleBtn(card, {
			size     = btnSize,
			icon     = iconStr,
			theme    = THEME,
			position = UDim2.new(1, -(btnSize + 8), 0.5, -(btnSize / 2)),
			zIndex   = z + 2,
			name     = "ActionBtn",
		})

		if opts.onAction then
			actionBtn.MouseButton1Click:Connect(opts.onAction)
		end
	end

	-- Hover
	card.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			TweenService:Create(card, TWEEN_HOVER, { BackgroundColor3 = THEME.elevated }):Play()
		end
	end)
	card.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			TweenService:Create(card, TWEEN_HOVER, { BackgroundColor3 = THEME.card }):Play()
		end
	end)

	-- Visible
	if opts.visible == false then card.Visible = false end

	-- Refs
	self.card          = card
	self.imageFrame    = imgFrame
	self.imageLabel    = imgLabel
	self.nameLabel     = nameLabel
	self.subtitleLabel = subtitleLabel
	self.actionBtn     = actionBtn
	self.actionIcon    = actionIcon
	self.stroke        = stroke
	self.height        = H

	return self
end

function Card:setImage(url)
	self.imageLabel.Image = url or ""
end

function Card:setName(text)
	self.nameLabel.Text = text or ""
end

function Card:setSubtitle(text)
	self.subtitleLabel.Text = text or ""
end

function Card:setEnabled(enabled)
	if self.actionBtn then self.actionBtn.Visible = enabled ~= false end
	self.card.GroupTransparency = enabled ~= false and 0 or 0.4
end

function Card:setVisible(bool)
	self.card.Visible = bool ~= false
end

function Card:destroy()
	if self.card then
		self.card:Destroy()
		self.card = nil
	end
end

function Card:getCard()
	return self.card
end

return Card
