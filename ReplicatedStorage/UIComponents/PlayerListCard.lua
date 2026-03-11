--[[
	═══════════════════════════════════════════════════════════════
	PlayerListCard.lua - Card reutilizable para mostrar usuarios
	═══════════════════════════════════════════════════════════════
	• Avatar circular + nombre + botón de acción
	• Diseño consistente con MemberCard del ClanSystem
	• Hover effects y animaciones suaves
	
	Uso:
		local card = PlayerListCard.new(parent, {
			userId = 12345,
			username = "Player",
			displayName = "Player",
			buttonText = "REGALAR",
			buttonIcon = "🎁",
			accentColor = Color3.fromRGB(255, 140, 40),
			onAction = function(userId, username) ... end,
		})
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local THEME = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("ThemeConfig"))
local UI = require(ReplicatedStorage:WaitForChild("Core"):WaitForChild("UI"))

local PlayerListCard = {}
PlayerListCard.__index = PlayerListCard

-- ═══════════════════════════════════════════════════════════════
-- CONSTANTES
-- ═══════════════════════════════════════════════════════════════
local CARD_HEIGHT = 56
local AVATAR_SIZE = 40
local TWEEN_FAST = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TWEEN_NORM = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

-- ═══════════════════════════════════════════════════════════════
-- HELPERS
-- ═══════════════════════════════════════════════════════════════
local function tween(obj, info, props)
	if not obj or not obj.Parent then return end
	local t = TweenService:Create(obj, info, props)
	t:Play()
	return t
end

local function getAvatarUrl(userId)
	return string.format(
		"https://www.roblox.com/headshot-thumbnail/image?userId=%d&width=150&height=150&format=png",
		userId
	)
end

-- ═══════════════════════════════════════════════════════════════
-- CONSTRUCTOR
-- ═══════════════════════════════════════════════════════════════
function PlayerListCard.new(parent, config)
	local self = setmetatable({}, PlayerListCard)
	
	self.userId = config.userId
	self.username = config.username or "Usuario"
	self.displayName = config.displayName or self.username
	self.buttonText = config.buttonText or "REGALAR"
	self.buttonIcon = config.buttonIcon or "🎁"
	self.accentColor = config.accentColor or THEME.accent
	self.onAction = config.onAction
	self.layoutOrder = config.layoutOrder or 1
	self.enabled = true
	
	self:_build(parent)
	
	return self
end

-- ═══════════════════════════════════════════════════════════════
-- BUILD UI
-- ═══════════════════════════════════════════════════════════════
function PlayerListCard:_build(parent)
	-- Card container
	self.card = Instance.new("Frame")
	self.card.Name = "PlayerCard_" .. self.userId
	self.card.Size = UDim2.new(1, 0, 0, CARD_HEIGHT)
	self.card.BackgroundColor3 = THEME.card
	self.card.BackgroundTransparency = 0
	self.card.BorderSizePixel = 0
	self.card.LayoutOrder = self.layoutOrder
	self.card.Parent = parent
	
	local cardCorner = Instance.new("UICorner")
	cardCorner.CornerRadius = UDim.new(0, 10)
	cardCorner.Parent = self.card
	
	-- Padding interno
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 10)
	padding.PaddingRight = UDim.new(0, 10)
	padding.PaddingTop = UDim.new(0, 8)
	padding.PaddingBottom = UDim.new(0, 8)
	padding.Parent = self.card
	
	-- Avatar frame
	local avatarFrame = Instance.new("Frame")
	avatarFrame.Name = "AvatarFrame"
	avatarFrame.Size = UDim2.new(0, AVATAR_SIZE, 0, AVATAR_SIZE)
	avatarFrame.Position = UDim2.new(0, 0, 0.5, 0)
	avatarFrame.AnchorPoint = Vector2.new(0, 0.5)
	avatarFrame.BackgroundColor3 = THEME.elevated
	avatarFrame.BorderSizePixel = 0
	avatarFrame.Parent = self.card
	
	local avatarCorner = Instance.new("UICorner")
	avatarCorner.CornerRadius = UDim.new(1, 0)
	avatarCorner.Parent = avatarFrame
	
	-- Avatar image
	local avatarImg = Instance.new("ImageLabel")
	avatarImg.Name = "Avatar"
	avatarImg.Size = UDim2.new(1, 0, 1, 0)
	avatarImg.BackgroundTransparency = 1
	avatarImg.Image = getAvatarUrl(self.userId)
	avatarImg.ScaleType = Enum.ScaleType.Crop
	avatarImg.Parent = avatarFrame
	
	local avatarImgCorner = Instance.new("UICorner")
	avatarImgCorner.CornerRadius = UDim.new(1, 0)
	avatarImgCorner.Parent = avatarImg
	
	-- Online indicator
	local isOnline = Players:GetPlayerByUserId(self.userId) ~= nil
	if isOnline then
		local onlineIndicator = Instance.new("Frame")
		onlineIndicator.Name = "OnlineIndicator"
		onlineIndicator.Size = UDim2.new(0, 10, 0, 10)
		onlineIndicator.Position = UDim2.new(1, -2, 1, -2)
		onlineIndicator.AnchorPoint = Vector2.new(1, 1)
		onlineIndicator.BackgroundColor3 = Color3.fromRGB(40, 200, 80)
		onlineIndicator.BorderSizePixel = 0
		onlineIndicator.ZIndex = 2
		onlineIndicator.Parent = avatarFrame
		
		local onlineCorner = Instance.new("UICorner")
		onlineCorner.CornerRadius = UDim.new(1, 0)
		onlineCorner.Parent = onlineIndicator
		
		local onlineStroke = Instance.new("UIStroke")
		onlineStroke.Color = THEME.card
		onlineStroke.Thickness = 2
		onlineStroke.Parent = onlineIndicator
	end
	
	-- Info container (nombre)
	local infoContainer = Instance.new("Frame")
	infoContainer.Name = "InfoContainer"
	infoContainer.Size = UDim2.new(1, -(AVATAR_SIZE + 90), 0, AVATAR_SIZE)
	infoContainer.Position = UDim2.new(0, AVATAR_SIZE + 10, 0.5, 0)
	infoContainer.AnchorPoint = Vector2.new(0, 0.5)
	infoContainer.BackgroundTransparency = 1
	infoContainer.Parent = self.card
	
	-- Display name (principal)
	local displayLabel = Instance.new("TextLabel")
	displayLabel.Name = "DisplayName"
	displayLabel.Size = UDim2.new(1, 0, 0, 18)
	displayLabel.Position = UDim2.new(0, 0, 0, 2)
	displayLabel.BackgroundTransparency = 1
	displayLabel.Font = Enum.Font.GothamBold
	displayLabel.TextSize = 14
	displayLabel.TextColor3 = THEME.text
	displayLabel.TextXAlignment = Enum.TextXAlignment.Left
	displayLabel.TextTruncate = Enum.TextTruncate.AtEnd
	displayLabel.Text = self.displayName
	displayLabel.Parent = infoContainer
	
	-- Username (secundario)
	local usernameLabel = Instance.new("TextLabel")
	usernameLabel.Name = "Username"
	usernameLabel.Size = UDim2.new(1, 0, 0, 14)
	usernameLabel.Position = UDim2.new(0, 0, 0, 20)
	usernameLabel.BackgroundTransparency = 1
	usernameLabel.Font = Enum.Font.Gotham
	usernameLabel.TextSize = 11
	usernameLabel.TextColor3 = THEME.muted
	usernameLabel.TextXAlignment = Enum.TextXAlignment.Left
	usernameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	usernameLabel.Text = "@" .. self.username
	usernameLabel.Parent = infoContainer
	
	-- Botón de acción
	self.actionBtn = Instance.new("TextButton")
	self.actionBtn.Name = "ActionBtn"
	self.actionBtn.Size = UDim2.new(0, 70, 0, 32)
	self.actionBtn.Position = UDim2.new(1, 0, 0.5, 0)
	self.actionBtn.AnchorPoint = Vector2.new(1, 0.5)
	self.actionBtn.BackgroundColor3 = self.accentColor
	self.actionBtn.BackgroundTransparency = 0.1
	self.actionBtn.Font = Enum.Font.GothamBold
	self.actionBtn.TextSize = 10
	self.actionBtn.TextColor3 = THEME.text
	self.actionBtn.Text = self.buttonIcon .. " " .. self.buttonText
	self.actionBtn.BorderSizePixel = 0
	self.actionBtn.AutoButtonColor = false
	self.actionBtn.Parent = self.card
	
	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 8)
	btnCorner.Parent = self.actionBtn
	
	-- Hover effects
	self:_setupInteractions()
end

-- ═══════════════════════════════════════════════════════════════
-- INTERACTIONS
-- ═══════════════════════════════════════════════════════════════
function PlayerListCard:_setupInteractions()
	-- Card hover
	self.card.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			tween(self.card, TWEEN_FAST, { BackgroundColor3 = THEME.elevated })
		end
	end)
	
	self.card.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			tween(self.card, TWEEN_FAST, { BackgroundColor3 = THEME.card })
		end
	end)
	
	-- Button hover
	self.actionBtn.MouseEnter:Connect(function()
		if not self.enabled then return end
		tween(self.actionBtn, TWEEN_FAST, { 
			BackgroundTransparency = 0,
			Size = UDim2.new(0, 74, 0, 34)
		})
	end)
	
	self.actionBtn.MouseLeave:Connect(function()
		if not self.enabled then return end
		tween(self.actionBtn, TWEEN_FAST, { 
			BackgroundTransparency = 0.1,
			Size = UDim2.new(0, 70, 0, 32)
		})
	end)
	
	-- Button click
	self.actionBtn.MouseButton1Click:Connect(function()
		if not self.enabled then return end
		if self.onAction then
			self.onAction(self.userId, self.username, self.displayName)
		end
	end)
end

-- ═══════════════════════════════════════════════════════════════
-- PUBLIC METHODS
-- ═══════════════════════════════════════════════════════════════
function PlayerListCard:setEnabled(enabled)
	self.enabled = enabled
	if enabled then
		self.actionBtn.BackgroundTransparency = 0.1
		self.actionBtn.TextTransparency = 0
	else
		self.actionBtn.BackgroundTransparency = 0.5
		self.actionBtn.TextTransparency = 0.5
	end
end

function PlayerListCard:setButtonText(text, icon)
	self.buttonText = text or self.buttonText
	self.buttonIcon = icon or self.buttonIcon
	self.actionBtn.Text = self.buttonIcon .. " " .. self.buttonText
end

function PlayerListCard:setAccentColor(color)
	self.accentColor = color
	self.actionBtn.BackgroundColor3 = color
end

function PlayerListCard:destroy()
	if self.card then
		self.card:Destroy()
		self.card = nil
	end
end

function PlayerListCard:getCard()
	return self.card
end

return PlayerListCard
