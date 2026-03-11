--[[
	═══════════════════════════════════════════════════════════════
	TitlesTab.lua - Tab de Títulos para la tienda
	═══════════════════════════════════════════════════════════════
	• Muestra lista de títulos disponibles
	• Permite seleccionar un título para ver usuarios sin él
	• Permite regalar títulos a otros jugadores
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local MarketplaceService = game:GetService("MarketplaceService")

local TitleConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("TitleConfig"))
local AdminConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("AdminConfig"))
local THEME = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("ThemeConfig"))
local ModernScrollbar = require(ReplicatedStorage:WaitForChild("UIComponents"):WaitForChild("ModernScrollbar"))
local PlayerList = require(ReplicatedStorage:WaitForChild("UIComponents"):WaitForChild("PlayerList"))
local ConfirmationModal = require(ReplicatedStorage:WaitForChild("Modal"):WaitForChild("ConfirmationModal"))
local Notify = require(ReplicatedStorage:WaitForChild("Systems"):WaitForChild("NotificationSystem"):WaitForChild("NotificationSystem"))

local player = Players.LocalPlayer
local isAdmin = AdminConfig:IsAdmin(player)

local TitlesTab = {}

-- ═══════════════════════════════════════════════════════════════
-- CONFIG
-- ═══════════════════════════════════════════════════════════════
local ROBUX_CHAR = utf8.char(0xE002)
local TW_FAST = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

-- Convertir TitleConfig a formato usable
local function getTitles()
	local titles = {}
	for _, titleData in ipairs(TitleConfig) do
		if titleData.gamepassId and titleData.name then
			-- Parsear color del hex
			local color = THEME.accent
			if titleData.color then
				local hex = titleData.color:gsub("#", "")
				local r = tonumber(hex:sub(1, 2), 16) or 255
				local g = tonumber(hex:sub(3, 4), 16) or 255
				local b = tonumber(hex:sub(5, 6), 16) or 255
				color = Color3.fromRGB(r, g, b)
			end
			
			table.insert(titles, {
				id = titleData.id,
				name = titleData.name,
				gamepassId = titleData.gamepassId,
				price = titleData.price or 500,
				icon = titleData.icon or "",
				color = color,
			})
		end
	end
	return titles
end

-- ═══════════════════════════════════════════════════════════════
-- BUILD
-- ═══════════════════════════════════════════════════════════════
function TitlesTab.build(parent, THEME, state, screenGui)
	local root = Instance.new("Frame")
	root.Name = "TitlesTabRoot"
	root.Size = UDim2.new(1, 0, 1, -(state.subTabH or 38))
	root.Position = UDim2.new(0, 0, 0, state.subTabH or 38)
	root.BackgroundTransparency = 1
	root.Visible = false
	root.Parent = parent
	
	local TITLES = getTitles()
	
	-- Estado local
	local selectedTitle = nil
	local playerListInstance = nil
	local connections = {}
	
	-- Remotes
	local GetPlayersWithoutItem = nil
	local GiftingRemote = nil
	local OwnershipUpdated = nil
	
	task.spawn(function()
		local rg = ReplicatedStorage:WaitForChild("RemotesGlobal", 5)
		if rg then
			local shopFolder = rg:FindFirstChild("ShopGifting")
			if shopFolder then
				GetPlayersWithoutItem = shopFolder:FindFirstChild("GetPlayersWithoutItem")
				OwnershipUpdated = shopFolder:FindFirstChild("OwnershipUpdated")
			end
			
			local giftFolder = rg:FindFirstChild("Gamepass Gifting")
			if giftFolder then
				local remotes = giftFolder:FindFirstChild("Remotes")
				if remotes then
					GiftingRemote = remotes:FindFirstChild("Gifting")
				end
			end
		end
	end)
	
	-- ═══════════════════════════════════════════════════════════════
	-- LAYOUT: IZQUIERDA (lista de títulos) + DERECHA (usuarios)
	-- ═══════════════════════════════════════════════════════════════
	local leftPane = Instance.new("Frame")
	leftPane.Name = "LeftPane"
	leftPane.Size = UDim2.new(0.45, -6, 1, -8)
	leftPane.Position = UDim2.new(0, 4, 0, 4)
	leftPane.BackgroundColor3 = THEME.card
	leftPane.BackgroundTransparency = 0.3
	leftPane.BorderSizePixel = 0
	leftPane.Parent = root
	
	local leftCorner = Instance.new("UICorner")
	leftCorner.CornerRadius = UDim.new(0, 10)
	leftCorner.Parent = leftPane
	
	local rightPane = Instance.new("Frame")
	rightPane.Name = "RightPane"
	rightPane.Size = UDim2.new(0.55, -6, 1, -8)
	rightPane.Position = UDim2.new(0.45, 2, 0, 4)
	rightPane.BackgroundColor3 = THEME.card
	rightPane.BackgroundTransparency = 0.3
	rightPane.BorderSizePixel = 0
	rightPane.Parent = root
	
	local rightCorner = Instance.new("UICorner")
	rightCorner.CornerRadius = UDim.new(0, 10)
	rightCorner.Parent = rightPane
	
	-- ═══════════════════════════════════════════════════════════════
	-- LEFT PANE: LISTA DE TÍTULOS
	-- ═══════════════════════════════════════════════════════════════
	local leftHeader = Instance.new("Frame")
	leftHeader.Name = "Header"
	leftHeader.Size = UDim2.new(1, 0, 0, 36)
	leftHeader.BackgroundTransparency = 1
	leftHeader.Parent = leftPane
	
	local leftTitle = Instance.new("TextLabel")
	leftTitle.Size = UDim2.new(1, -16, 1, 0)
	leftTitle.Position = UDim2.new(0, 8, 0, 0)
	leftTitle.BackgroundTransparency = 1
	leftTitle.Font = Enum.Font.GothamBold
	leftTitle.TextSize = 13
	leftTitle.TextColor3 = THEME.text
	leftTitle.TextXAlignment = Enum.TextXAlignment.Left
	leftTitle.Text = "✨ TÍTULOS"
	leftTitle.Parent = leftHeader
	
	local titleScroll = Instance.new("ScrollingFrame")
	titleScroll.Name = "TitleScroll"
	titleScroll.Size = UDim2.new(1, -8, 1, -44)
	titleScroll.Position = UDim2.new(0, 4, 0, 40)
	titleScroll.BackgroundTransparency = 1
	titleScroll.BorderSizePixel = 0
	titleScroll.ScrollBarThickness = 0
	titleScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	titleScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	titleScroll.ClipsDescendants = true
	titleScroll.Parent = leftPane
	
	local titleLayout = Instance.new("UIListLayout")
	titleLayout.Padding = UDim.new(0, 4)
	titleLayout.SortOrder = Enum.SortOrder.LayoutOrder
	titleLayout.Parent = titleScroll
	
	local titlePad = Instance.new("UIPadding")
	titlePad.PaddingLeft = UDim.new(0, 4)
	titlePad.PaddingRight = UDim.new(0, 4)
	titlePad.PaddingTop = UDim.new(0, 4)
	titlePad.PaddingBottom = UDim.new(0, 8)
	titlePad.Parent = titleScroll
	
	ModernScrollbar.setup(titleScroll, leftPane, THEME, { transparency = 0.4, offset = -2, zIndex = 110 })
	
	local titleButtons = {}
	
	for i, title in ipairs(TITLES) do
		local btn = Instance.new("TextButton")
		btn.Name = "Title_" .. title.id
		btn.Size = UDim2.new(1, 0, 0, 44)
		btn.BackgroundColor3 = THEME.elevated
		btn.BackgroundTransparency = 0.2
		btn.Font = Enum.Font.GothamBold
		btn.TextSize = 12
		btn.TextColor3 = THEME.text
		btn.Text = ""
		btn.AutoButtonColor = false
		btn.BorderSizePixel = 0
		btn.LayoutOrder = i
		btn.Parent = titleScroll
		
		local btnCorner = Instance.new("UICorner")
		btnCorner.CornerRadius = UDim.new(0, 8)
		btnCorner.Parent = btn
		
		-- Color bar
		local colorBar = Instance.new("Frame")
		colorBar.Size = UDim2.new(0, 4, 0.6, 0)
		colorBar.Position = UDim2.new(0, 6, 0.2, 0)
		colorBar.BackgroundColor3 = title.color
		colorBar.BorderSizePixel = 0
		colorBar.Parent = btn
		
		local colorCorner = Instance.new("UICorner")
		colorCorner.CornerRadius = UDim.new(0, 2)
		colorCorner.Parent = colorBar
		
		-- Name (con estilo del título)
		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(1, -80, 0, 16)
		nameLabel.Position = UDim2.new(0, 18, 0, 6)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.TextSize = 12
		nameLabel.TextColor3 = title.color
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.Text = title.name
		nameLabel.Parent = btn
		
		-- Price
		local priceLabel = Instance.new("TextLabel")
		priceLabel.Size = UDim2.new(1, -80, 0, 12)
		priceLabel.Position = UDim2.new(0, 18, 0, 24)
		priceLabel.BackgroundTransparency = 1
		priceLabel.Font = Enum.Font.Gotham
		priceLabel.TextSize = 10
		priceLabel.TextColor3 = THEME.accent
		priceLabel.TextXAlignment = Enum.TextXAlignment.Left
		priceLabel.Text = ROBUX_CHAR .. " " .. title.price
		priceLabel.Parent = btn
		
		-- Selection indicator
		local selectIndicator = Instance.new("Frame")
		selectIndicator.Name = "SelectIndicator"
		selectIndicator.Size = UDim2.new(0, 3, 0.7, 0)
		selectIndicator.Position = UDim2.new(1, -1, 0.15, 0)
		selectIndicator.BackgroundColor3 = title.color
		selectIndicator.BackgroundTransparency = 1
		selectIndicator.BorderSizePixel = 0
		selectIndicator.Parent = btn
		
		local indicatorCorner = Instance.new("UICorner")
		indicatorCorner.CornerRadius = UDim.new(0, 2)
		indicatorCorner.Parent = selectIndicator
		
		titleButtons[title.gamepassId] = { btn = btn, indicator = selectIndicator, data = title }
		
		-- Hover
		btn.MouseEnter:Connect(function()
			if selectedTitle ~= title.gamepassId then
				TweenService:Create(btn, TW_FAST, { BackgroundTransparency = 0 }):Play()
			end
		end)
		
		btn.MouseLeave:Connect(function()
			if selectedTitle ~= title.gamepassId then
				TweenService:Create(btn, TW_FAST, { BackgroundTransparency = 0.2 }):Play()
			end
		end)
		
		-- Click
		btn.MouseButton1Click:Connect(function()
			-- Deseleccionar anterior
			if selectedTitle and titleButtons[selectedTitle] then
				local prev = titleButtons[selectedTitle]
				TweenService:Create(prev.btn, TW_FAST, { BackgroundTransparency = 0.2 }):Play()
				TweenService:Create(prev.indicator, TW_FAST, { BackgroundTransparency = 1 }):Play()
			end
			
			selectedTitle = title.gamepassId
			
			-- Seleccionar nuevo
			TweenService:Create(btn, TW_FAST, { BackgroundTransparency = 0 }):Play()
			TweenService:Create(selectIndicator, TW_FAST, { BackgroundTransparency = 0 }):Play()
			
			-- Cargar usuarios sin este título
			if playerListInstance then
				playerListInstance:setLoading(true)
				playerListInstance:setTitle("🎁 Regalar " .. title.name)
				playerListInstance:setAccentColor(title.color)
			end
			
			task.spawn(function()
				if not GetPlayersWithoutItem then
					task.wait(1)
				end
				
				if GetPlayersWithoutItem then
					local result = GetPlayersWithoutItem:InvokeServer("title", title.gamepassId)
					if result and result.success and playerListInstance then
						playerListInstance:setPlayers(result.players)
						playerListInstance:setLoading(false)
					elseif playerListInstance then
						playerListInstance:setPlayers({})
						playerListInstance:setLoading(false)
					end
				end
			end)
		end)
	end
	
	-- ═══════════════════════════════════════════════════════════════
	-- RIGHT PANE: LISTA DE USUARIOS
	-- ═══════════════════════════════════════════════════════════════
	local function onGiftPlayer(userId, username, displayName, playerData)
		if not selectedTitle then return end
		
		local titleData = nil
		for _, t in ipairs(TITLES) do
			if t.gamepassId == selectedTitle then
				titleData = t
				break
			end
		end
		
		if not titleData then return end
		
		-- Mostrar modal de confirmación
		local priceText = isAdmin and "GRATIS (Admin)" or (ROBUX_CHAR .. " " .. titleData.price)
		
		ConfirmationModal.show(screenGui, {
			title = "🎁 Regalar " .. titleData.name,
			message = "¿Regalar a " .. displayName .. "?\n\nCosto: " .. priceText,
			confirmText = "REGALAR",
			cancelText = "CANCELAR",
			accentColor = titleData.color,
			onConfirm = function()
				-- Los títulos son gamepasses, usar el mismo sistema
				if GiftingRemote then
					-- Para títulos, el productId puede ser diferente
					-- Necesitamos usar MarketplaceService directamente o tener productId configurado
					GiftingRemote:FireServer(
						{ titleData.gamepassId, titleData.gamepassId }, -- gamepassId, productId (pueden ser iguales si no hay developer product separado)
						userId,
						username,
						player.UserId
					)
					
					Notify:Info("Regalo", "Procesando regalo de " .. titleData.name .. " para " .. displayName, 3)
				else
					Notify:Error("Error", "Sistema de regalos no disponible", 3)
				end
			end
		})
	end
	
	-- Crear PlayerList
	playerListInstance = PlayerList.new({
		parent = rightPane,
		title = "Selecciona un Título",
		emptyText = "Selecciona un título para ver jugadores",
		accentColor = Color3.fromRGB(60, 180, 220),
		buttonText = "REGALAR",
		buttonIcon = "🎁",
		showSearch = true,
		onAction = onGiftPlayer
	})
	
	-- ═══════════════════════════════════════════════════════════════
	-- ESCUCHAR ACTUALIZACIONES DE OWNERSHIP
	-- ═══════════════════════════════════════════════════════════════
	task.spawn(function()
		task.wait(1)
		if OwnershipUpdated then
			local conn = OwnershipUpdated.OnClientEvent:Connect(function(data)
				if data.type == "title" and data.itemId == selectedTitle then
					-- Remover al usuario de la lista
					if playerListInstance then
						playerListInstance:removePlayer(data.userId)
						Notify:Success("Actualizado", data.username .. " ahora tiene este título", 2)
					end
				end
			end)
			table.insert(connections, conn)
		end
	end)
	
	-- ═══════════════════════════════════════════════════════════════
	-- CLEANUP
	-- ═══════════════════════════════════════════════════════════════
	local function cleanup()
		for _, conn in ipairs(connections) do
			conn:Disconnect()
		end
		connections = {}
		
		if playerListInstance then
			playerListInstance:destroy()
			playerListInstance = nil
		end
	end
	
	return {
		panel = root,
		cleanup = cleanup
	}
end

return TitlesTab
