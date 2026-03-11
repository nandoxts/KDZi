--[[
	 Card.lua - Componente card reutilizable (CanvasGroup)
	 CanvasGroup + imagen full-height izq + labels + boton circular.
	 Base compartida para cards de jugadores, canciones DJ, etc.

	 Uso:
		local c = Card.new(parent, {
			height     = 58,
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

	local H       = opts.height     or 58
	local corner  = opts.corner     or 10
	local z       = opts.zIndex     or 1
	local btnSize = opts.buttonSize or 36

	-- CanvasGroup base
	local card = Instance.new("CanvasGroup")
	card.Name                   = opts.instanceName or "Card"
	card.Size                   = opts.size or UDim2.new(1, 0, 0, H)
	card.BackgroundColor3       = THEME.card
	card.BackgroundTransparency = 0
	card.BorderSizePixel        = 0
	card.GroupTransparency      = 0
	card.LayoutOrder            = opts.layoutOrder or 0
	card.Parent                 = parent

	Instance.new("UICorner", card).CornerRadius = UDim.new(0, corner)
	UI.stroked(card, 0.3)

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
	local tx       = H + 10
	local rightPad = btnSize + 16

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name                   = "NameLabel"
	nameLabel.Size                   = UDim2.new(1, -(tx + rightPad), 0, 20)
	nameLabel.Position               = UDim2.new(0, tx, 0, 10)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font                   = opts.nameFont or Enum.Font.GothamBold
	nameLabel.TextSize               = opts.nameSize or 14
	nameLabel.TextColor3             = opts.nameColor or THEME.text
	nameLabel.TextXAlignment         = Enum.TextXAlignment.Left
	nameLabel.TextTruncate           = Enum.TextTruncate.AtEnd
	nameLabel.Text                   = opts.name or ""
	nameLabel.ZIndex                 = z + 1
	nameLabel.Parent                 = card

	local subtitleLabel = Instance.new("TextLabel")
	subtitleLabel.Name                   = "SubtitleLabel"
	subtitleLabel.Size                   = UDim2.new(1, -(tx + rightPad), 0, 16)
	subtitleLabel.Position               = UDim2.new(0, tx, 0, 33)
	subtitleLabel.BackgroundTransparency = 1
	subtitleLabel.Font                   = opts.subtitleFont or Enum.Font.GothamMedium
	subtitleLabel.TextSize               = opts.subtitleSize or 12
	subtitleLabel.TextColor3             = opts.subtitleColor or THEME.muted
	subtitleLabel.TextXAlignment         = Enum.TextXAlignment.Left
	subtitleLabel.TextTruncate           = Enum.TextTruncate.AtEnd
	subtitleLabel.Text                   = opts.subtitle or ""
	subtitleLabel.ZIndex                 = z + 1
	subtitleLabel.Parent                 = card

	-- Boton circular outlined
	local iconStr = opts.buttonIcon
	if not iconStr or iconStr == "" then iconStr = UI.ICONS.PLAY_ADD end

	local actionBtn, actionIcon = UI.outlinedCircleBtn(card, {
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

	-- Refs
	self.card          = card
	self.imageFrame    = imgFrame
	self.imageLabel    = imgLabel
	self.nameLabel     = nameLabel
	self.subtitleLabel = subtitleLabel
	self.actionBtn     = actionBtn
	self.actionIcon    = actionIcon
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
	self.actionBtn.Visible      = enabled ~= false
	self.card.GroupTransparency = enabled ~= false and 0 or 0.4
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
