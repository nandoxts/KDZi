--[[
	═══════════════════════════════════════════════════════════════
	GamepassTab.lua - Tab de Game Passes para la tienda
	═══════════════════════════════════════════════════════════════
	• Muestra lista de gamepasses disponibles
	• Permite seleccionar un gamepass para ver usuarios sin él
	• Permite regalar gamepasses a otros jugadores
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local MarketplaceService = game:GetService("MarketplaceService")

local Configuration = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("Configuration"))
local AdminConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("AdminConfig"))
local THEME = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("ThemeConfig"))
local ModernScrollbar = require(ReplicatedStorage:WaitForChild("UIComponents"):WaitForChild("ModernScrollbar"))
local PlayerList = require(ReplicatedStorage:WaitForChild("UIComponents"):WaitForChild("PlayerList"))
local ConfirmationModal = require(ReplicatedStorage:WaitForChild("Modal"):WaitForChild("ConfirmationModal"))
local Notify = require(ReplicatedStorage:WaitForChild("Systems"):WaitForChild("NotificationSystem"):WaitForChild("NotificationSystem"))

local player = Players.LocalPlayer
local isAdmin = AdminConfig:IsAdmin(player)

local GamepassTab = {}

-- ═══════════════════════════════════════════════════════════════
-- CONFIG
-- ═══════════════════════════════════════════════════════════════
local ROBUX_CHAR = utf8.char(0xE002)
local TW_FAST = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local GAMEPASSES = {
	{ name = "VIP",        price = 200,  gid = Configuration.Gamepasses.VIP.id,        productId = Configuration.Gamepasses.VIP.devId,        icon = "76721656269888",  color = Color3.fromRGB(255, 215, 0) },
	{ name = "COMANDOS",   price = 1500, gid = Configuration.Gamepasses.COMMANDS.id,   productId = Configuration.Gamepasses.COMMANDS.devId,   icon = "128637341143304", color = Color3.fromRGB(100, 180, 255) },
	{ name = "COLORES",    price = 50,   gid = Configuration.Gamepasses.COLORS.id,     productId = Configuration.Gamepasses.COLORS.devId,     icon = "91877799240345",  color = Color3.fromRGB(255, 100, 180) },
	{ name = "POLICIA",    price = 135,  gid = Configuration.Gamepasses.TOMBO.id,      productId = Configuration.Gamepasses.TOMBO.devId,      icon = "139661313218787", color = Color3.fromRGB(50, 100, 200) },
	{ name = "LADRON",     price = 135,  gid = Configuration.Gamepasses.CHORO.id,      productId = Configuration.Gamepasses.CHORO.devId,      icon = "84699864716808",  color = Color3.fromRGB(200, 60, 60) },
	{ name = "SEGURIDAD",  price = 135,  gid = Configuration.Gamepasses.SERE.id,       productId = Configuration.Gamepasses.SERE.devId,       icon = "85734290151599",  color = Color3.fromRGB(80, 130, 200) },
	{ name = "ARMY BOOMS", price = 80,   gid = Configuration.Gamepasses.ARMYBOOMS.id,  productId = Configuration.Gamepasses.ARMYBOOMS.devId,  icon = "134501492548324", color = Color3.fromRGB(255, 150, 50) },
	{ name = "LIGHTSTICK", price = 80,   gid = Configuration.Gamepasses.LIGHTSTICK.id, productId = Configuration.Gamepasses.LIGHTSTICK.devId, icon = "86122436659328",  color = Color3.fromRGB(50, 200, 220) },
	{ name = "AURA PACK",  price = 2500, gid = Configuration.Gamepasses.AURA_PACK.id,  productId = Configuration.Gamepasses.AURA_PACK.devId,  icon = "129517460766852", color = Color3.fromRGB(160, 80, 255) },
}

-- ═══════════════════════════════════════════════════════════════
-- BUILD
-- ═══════════════════════════════════════════════════════════════
function GamepassTab.build(parent, THEME, state, screenGui)
	local root = Instance.new("Frame")
	root.Name = "GamepassTabRoot"
	root.Size = UDim2.new(1, 0, 1, -(state.subTabH or 38))
	root.Position = UDim2.new(0, 0, 0, state.subTabH or 38)
	root.BackgroundTransparency = 1
	root.Visible = true
	root.Parent = parent
	
	-- Estado local
	local selectedGamepass = nil
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
	-- LAYOUT: IZQUIERDA (lista de gamepasses) + DERECHA (usuarios)
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
	-- LEFT PANE: LISTA DE GAMEPASSES
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
	leftTitle.Text = "🎮 GAME PASSES"
	leftTitle.Parent = leftHeader
	
	local gpScroll = Instance.new("ScrollingFrame")
	gpScroll.Name = "GamepassScroll"
	gpScroll.Size = UDim2.new(1, -8, 1, -44)
	gpScroll.Position = UDim2.new(0, 4, 0, 40)
	gpScroll.BackgroundTransparency = 1
	gpScroll.BorderSizePixel = 0
	gpScroll.ScrollBarThickness = 0
	gpScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	gpScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	gpScroll.ClipsDescendants = true
	gpScroll.Parent = leftPane
	
	local gpLayout = Instance.new("UIListLayout")
	gpLayout.Padding = UDim.new(0, 4)
	gpLayout.SortOrder = Enum.SortOrder.LayoutOrder
	gpLayout.Parent = gpScroll
	
	local gpPad = Instance.new("UIPadding")
	gpPad.PaddingLeft = UDim.new(0, 4)
	gpPad.PaddingRight = UDim.new(0, 4)
	gpPad.PaddingTop = UDim.new(0, 4)
	gpPad.PaddingBottom = UDim.new(0, 8)
	gpPad.Parent = gpScroll
	
	ModernScrollbar.setup(gpScroll, leftPane, THEME, { transparency = 0.4, offset = -2, zIndex = 110 })
	
	local gpButtons = {}
	
	for i, gp in ipairs(GAMEPASSES) do
		local btn = Instance.new("TextButton")
		btn.Name = "GP_" .. gp.name
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
		btn.Parent = gpScroll
		
		local btnCorner = Instance.new("UICorner")
		btnCorner.CornerRadius = UDim.new(0, 8)
		btnCorner.Parent = btn
		
		-- Icon
		local icon = Instance.new("ImageLabel")
		icon.Size = UDim2.new(0, 32, 0, 32)
		icon.Position = UDim2.new(0, 6, 0.5, 0)
		icon.AnchorPoint = Vector2.new(0, 0.5)
		icon.BackgroundColor3 = gp.color
		icon.BackgroundTransparency = 0.7
		icon.Image = "rbxassetid://" .. gp.icon
		icon.ScaleType = Enum.ScaleType.Crop
		icon.Parent = btn
		
		local iconCorner = Instance.new("UICorner")
		iconCorner.CornerRadius = UDim.new(0, 6)
		iconCorner.Parent = icon
		
		-- Name
		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(1, -90, 0, 16)
		nameLabel.Position = UDim2.new(0, 44, 0, 6)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.TextSize = 12
		nameLabel.TextColor3 = THEME.text
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.Text = gp.name
		nameLabel.Parent = btn
		
		-- Price
		local priceLabel = Instance.new("TextLabel")
		priceLabel.Size = UDim2.new(1, -90, 0, 12)
		priceLabel.Position = UDim2.new(0, 44, 0, 24)
		priceLabel.BackgroundTransparency = 1
		priceLabel.Font = Enum.Font.Gotham
		priceLabel.TextSize = 10
		priceLabel.TextColor3 = THEME.accent
		priceLabel.TextXAlignment = Enum.TextXAlignment.Left
		priceLabel.Text = ROBUX_CHAR .. " " .. gp.price
		priceLabel.Parent = btn
		
		-- Selection indicator
		local selectIndicator = Instance.new("Frame")
		selectIndicator.Name = "SelectIndicator"
		selectIndicator.Size = UDim2.new(0, 3, 0.7, 0)
		selectIndicator.Position = UDim2.new(1, -1, 0.15, 0)
		selectIndicator.BackgroundColor3 = gp.color
		selectIndicator.BackgroundTransparency = 1
		selectIndicator.BorderSizePixel = 0
		selectIndicator.Parent = btn
		
		local indicatorCorner = Instance.new("UICorner")
		indicatorCorner.CornerRadius = UDim.new(0, 2)
		indicatorCorner.Parent = selectIndicator
		
		gpButtons[gp.gid] = { btn = btn, indicator = selectIndicator, data = gp }
		
		-- Hover
		btn.MouseEnter:Connect(function()
			if selectedGamepass ~= gp.gid then
				TweenService:Create(btn, TW_FAST, { BackgroundTransparency = 0 }):Play()
			end
		end)
		
		btn.MouseLeave:Connect(function()
			if selectedGamepass ~= gp.gid then
				TweenService:Create(btn, TW_FAST, { BackgroundTransparency = 0.2 }):Play()
			end
		end)
		
		-- Click
		btn.MouseButton1Click:Connect(function()
			-- Deseleccionar anterior
			if selectedGamepass and gpButtons[selectedGamepass] then
				local prev = gpButtons[selectedGamepass]
				TweenService:Create(prev.btn, TW_FAST, { BackgroundTransparency = 0.2 }):Play()
				TweenService:Create(prev.indicator, TW_FAST, { BackgroundTransparency = 1 }):Play()
			end
			
			selectedGamepass = gp.gid
			
			-- Seleccionar nuevo
			TweenService:Create(btn, TW_FAST, { BackgroundTransparency = 0 }):Play()
			TweenService:Create(selectIndicator, TW_FAST, { BackgroundTransparency = 0 }):Play()
			
			-- Cargar usuarios sin este gamepass
			if playerListInstance then
				playerListInstance:setLoading(true)
				playerListInstance:setTitle("🎁 Regalar " .. gp.name)
				playerListInstance:setAccentColor(gp.color)
			end
			
			task.spawn(function()
				if not GetPlayersWithoutItem then
					task.wait(1)
				end
				
				if GetPlayersWithoutItem then
					local result = GetPlayersWithoutItem:InvokeServer("gamepass", gp.gid)
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
		if not selectedGamepass then return end
		
		local gpData = nil
		for _, gp in ipairs(GAMEPASSES) do
			if gp.gid == selectedGamepass then
				gpData = gp
				break
			end
		end
		
		if not gpData then return end
		
		-- Mostrar modal de confirmación
		local priceText = isAdmin and "GRATIS (Admin)" or (ROBUX_CHAR .. " " .. gpData.price)
		
		ConfirmationModal.show(screenGui, {
			title = "🎁 Regalar " .. gpData.name,
			message = "¿Regalar a " .. displayName .. "?\n\nCosto: " .. priceText,
			confirmText = "REGALAR",
			cancelText = "CANCELAR",
			accentColor = gpData.color,
			onConfirm = function()
				-- Enviar regalo
				if GiftingRemote then
					GiftingRemote:FireServer(
						{ gpData.gid, gpData.productId },
						userId,
						username,
						player.UserId
					)
					
					Notify:Info("Regalo", "Procesando regalo de " .. gpData.name .. " para " .. displayName, 3)
				else
					Notify:Error("Error", "Sistema de regalos no disponible", 3)
				end
			end
		})
	end
	
	-- Crear PlayerList
	playerListInstance = PlayerList.new({
		parent = rightPane,
		title = "Selecciona un Game Pass",
		emptyText = "Selecciona un gamepass para ver jugadores",
		accentColor = THEME.accent,
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
				if data.type == "gamepass" and data.itemId == selectedGamepass then
					-- Remover al usuario de la lista
					if playerListInstance then
						playerListInstance:removePlayer(data.userId)
						Notify:Success("Actualizado", data.username .. " ahora tiene este pase", 2)
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

return GamepassTab
