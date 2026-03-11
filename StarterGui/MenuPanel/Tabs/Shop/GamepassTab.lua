--[[
	═══════════════════════════════════════════════════════════════
	GamepassTab.lua - Tab de Game Passes para la tienda
	═══════════════════════════════════════════════════════════════
	• Diseño limpio tipo cards con gradiente lateral (estilo original)
	• Botón de compra + botón de regalar en cada card
	• Al presionar "Regalar" navega con slide a lista de jugadores
	• Header con botón de regresar (estilo DJTab)
	• Usa UI helpers centralizados (UI.frame, UI.label, UI.button, etc.)
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local MarketplaceService = game:GetService("MarketplaceService")

local Configuration = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("Configuration"))
local AdminConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("AdminConfig"))
local THEME = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("ThemeConfig"))
local UI = require(ReplicatedStorage:WaitForChild("Core"):WaitForChild("UI"))
local ModernScrollbar = require(ReplicatedStorage:WaitForChild("UIComponents"):WaitForChild("ModernScrollbar"))
local PlayerList = require(ReplicatedStorage:WaitForChild("UIComponents"):WaitForChild("PlayerList"))
local ConfirmationModal = require(ReplicatedStorage:WaitForChild("Modal"):WaitForChild("ConfirmationModal"))
local Notify = require(ReplicatedStorage:WaitForChild("Systems"):WaitForChild("NotificationSystem"):WaitForChild("NotificationSystem"))
local SlideHeader = require(script.Parent.Parent:WaitForChild("Shared"):WaitForChild("SlideHeader"))

local player = Players.LocalPlayer
local isAdmin = AdminConfig:IsAdmin(player)

local GamepassTab = {}

-- ═══════════════════════════════════════════════════════════════
-- CONFIG
-- ═══════════════════════════════════════════════════════════════
local ROBUX_CHAR = utf8.char(0xE002)
local TW = TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local TW_PAGE = TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

local GRAD_COLORS = {
	Color3.fromRGB(90,  40, 140),
	Color3.fromRGB(40,  80, 160),
	Color3.fromRGB(50, 130,  80),
	Color3.fromRGB(30,  80, 160),
	Color3.fromRGB(160, 50,  50),
	Color3.fromRGB(60, 100, 160),
	Color3.fromRGB(180, 90,  20),
	Color3.fromRGB(20, 140, 160),
	Color3.fromRGB(120, 40, 180),
}

local GAMEPASSES = {
	{ name = "VIP",        price = 200,  gid = Configuration.Gamepasses.VIP.id,        productId = Configuration.Gamepasses.VIP.devId,        icon = "76721656269888",  color = Color3.fromRGB(255, 215, 0),
		desc = "[ + ] Acceso VIP exclusivo!\n[ + ] Las mejores vistas y zonas!\n[ + ] Etiqueta VIP!" },
	{ name = "COMANDOS",   price = 1500, gid = Configuration.Gamepasses.COMMANDS.id,   productId = Configuration.Gamepasses.COMMANDS.devId,   icon = "128637341143304", color = Color3.fromRGB(100, 180, 255),
		desc = "[ + ] Acceso ilimitado a una\nemocionante variedad de\ncomandos de chat!" },
	{ name = "COLORES",    price = 50,   gid = Configuration.Gamepasses.COLORS.id,     productId = Configuration.Gamepasses.COLORS.devId,     icon = "91877799240345",  color = Color3.fromRGB(255, 100, 180),
		desc = "[ + ] Personaliza tu nombre!\n[ + ] Usa ;cl [color] en el chat!\n[ + ] Múltiples colores!" },
	{ name = "POLICIA",    price = 135,  gid = Configuration.Gamepasses.TOMBO.id,      productId = Configuration.Gamepasses.TOMBO.devId,      icon = "139661313218787", color = Color3.fromRGB(50, 100, 200),
		desc = "[ + ] Traje de policía!\n[ + ] Usa ;tombo en el chat!\n[ + ] Look exclusivo!" },
	{ name = "LADRON",     price = 135,  gid = Configuration.Gamepasses.CHORO.id,      productId = Configuration.Gamepasses.CHORO.devId,      icon = "84699864716808",  color = Color3.fromRGB(200, 60, 60),
		desc = "[ + ] Traje de ladrón!\n[ + ] Usa ;choro en el chat!\n[ + ] Look exclusivo!" },
	{ name = "SEGURIDAD",  price = 135,  gid = Configuration.Gamepasses.SERE.id,       productId = Configuration.Gamepasses.SERE.devId,       icon = "85734290151599",  color = Color3.fromRGB(80, 130, 200),
		desc = "[ + ] Traje de seguridad!\n[ + ] Usa ;sere en el chat!\n[ + ] Look exclusivo!" },
	{ name = "ARMY BOOMS", price = 80,   gid = Configuration.Gamepasses.ARMYBOOMS.id,  productId = Configuration.Gamepasses.ARMYBOOMS.devId,  icon = "134501492548324", color = Color3.fromRGB(255, 150, 50),
		desc = "[ + ] Efectos Army Booms!\n[ + ] Actívalo en el chat!\n[ + ] Efecto exclusivo!" },
	{ name = "LIGHTSTICK", price = 80,   gid = Configuration.Gamepasses.LIGHTSTICK.id, productId = Configuration.Gamepasses.LIGHTSTICK.devId, icon = "86122436659328",  color = Color3.fromRGB(50, 200, 220),
		desc = "[ + ] ¡Lightstick brillante!\n[ + ] Actívalo en el chat!\n[ + ] Efecto exclusivo!" },
	{ name = "AURA PACK",  price = 2500, gid = Configuration.Gamepasses.AURA_PACK.id,  productId = Configuration.Gamepasses.AURA_PACK.devId,  icon = "129517460766852", color = Color3.fromRGB(160, 80, 255),
		desc = "[ + ] Pack de 6 auras únicas!\n[ + ] Dragon, Atomic, Blazing...\n[ + ] Usa ;aura [nombre]!" },
}

-- ═══════════════════════════════════════════════════════════════
-- BUILD
-- ═══════════════════════════════════════════════════════════════
function GamepassTab.build(parent, THEME, state, screenGui)
	local root = UI.frame({
		name = "GamepassTabRoot",
		size = UDim2.new(1, 0, 1, -(state.subTabH or 38)),
		pos = UDim2.new(0, 0, 0, state.subTabH or 38),
		bg = THEME.bg, clips = true, z = 100, parent = parent,
	})

	-- Estado local
	local selectedGamepass = nil
	local selectedGpData = nil
	local playerListInstance = nil
	local connections = {}
	local _sliding = false

	-- Ownership cache
	local gpCache = {}
	local ownershipRemote = nil
	pcall(function()
		ownershipRemote = ReplicatedStorage
			:WaitForChild("RemotesGlobal", 5)
			:WaitForChild("Gamepass Gifting")
			:WaitForChild("Remotes")
			:WaitForChild("Ownership")
	end)

	local function fetchOwnership(gid, cb)
		if gpCache[gid] ~= nil then cb(gpCache[gid]); return end
		task.spawn(function()
			local owned = false
			if ownershipRemote then
				local ok, res = pcall(function() return ownershipRemote:InvokeServer(gid) end)
				owned = ok and res or false
			else
				local ok, res = pcall(function()
					return MarketplaceService:UserOwnsGamePassAsync(player.UserId, gid)
				end)
				owned = ok and res or false
			end
			gpCache[gid] = owned
			cb(owned)
		end)
	end

	-- Remotes para gifting
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
	-- VIEW 1: LISTA DE GAMEPASSES (diseño original con cards)
	-- ═══════════════════════════════════════════════════════════════
	local listView = Instance.new("ScrollingFrame")
	listView.Name = "GamepassListView"
	listView.Size = UDim2.fromScale(1, 1)
	listView.BackgroundTransparency = 1
	listView.BorderSizePixel = 0
	listView.ScrollBarThickness = 0
	listView.CanvasSize = UDim2.new(0, 0, 0, 0)
	listView.AutomaticCanvasSize = Enum.AutomaticSize.Y
	listView.ClipsDescendants = true
	listView.ZIndex = 204
	listView.Parent = root
	ModernScrollbar.setup(listView, root, THEME, { transparency = 0.4, offset = -4, zIndex = 220 })

	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = UDim.new(0, 0)
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	listLayout.Parent = listView

	Instance.new("UIPadding").Parent = listView

	local shopCards = {}

	-- Forward declarations (se construyen después del loop)
	local giftView, giftHdr

	for i, gp in ipairs(GAMEPASSES) do
		local gradColor = GRAD_COLORS[i] or Color3.fromRGB(60, 40, 120)

		-- Card (CanvasGroup para clip de gradiente)
		local card = Instance.new("CanvasGroup")
		card.Name = "Card_" .. i
		card.Size = UDim2.new(1, 0, 0, 0)
		card.AutomaticSize = Enum.AutomaticSize.Y
		card.BackgroundColor3 = THEME.card
		card.BorderSizePixel = 0
		card.ZIndex = 205
		card.LayoutOrder = i
		card.Parent = listView

		-- Separador inferior
		UI.frame({ name = "Sep", size = UDim2.new(1, 0, 0, 1), pos = UDim2.new(0, 0, 1, -1), bg = THEME.stroke, bgT = 0.5, z = 215, parent = card })

		-- Gradiente lateral
		local gradOverlay = UI.frame({ size = UDim2.new(0.45, 0, 1, 0), bg = gradColor, z = 206, parent = card })
		local gd = Instance.new("UIGradient")
		gd.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.55),
			NumberSequenceKeypoint.new(0.6, 0.85),
			NumberSequenceKeypoint.new(1, 1),
		})
		gd.Parent = gradOverlay

		-- Contenido con padding
		local content = UI.frame({ size = UDim2.new(1, 0, 0, 0), bgT = 1, z = 210, parent = card })
		content.AutomaticSize = Enum.AutomaticSize.Y
		local cPad = Instance.new("UIPadding")
		cPad.PaddingLeft = UDim.new(0, 14); cPad.PaddingRight = UDim.new(0, 12)
		cPad.PaddingTop = UDim.new(0, 14); cPad.PaddingBottom = UDim.new(0, 14)
		cPad.Parent = content

		local innerLay = Instance.new("UIListLayout")
		innerLay.Padding = UDim.new(0, 10)
		innerLay.SortOrder = Enum.SortOrder.LayoutOrder
		innerLay.Parent = content

		-- ═══ Top row: avatar + title + desc ═══
		local topRow = UI.frame({ size = UDim2.new(1, 0, 0, 76), bgT = 1, z = 210, parent = content })
		topRow.LayoutOrder = 1

		local AVATAR_S = 76
		local avatarFrame = UI.frame({ size = UDim2.new(0, AVATAR_S, 0, AVATAR_S), bg = THEME.elevated, z = 211, parent = topRow, corner = AVATAR_S })

		local avatarImg = Instance.new("ImageLabel")
		avatarImg.Size = UDim2.fromScale(1, 1)
		avatarImg.BackgroundTransparency = 1
		avatarImg.Image = "rbxassetid://" .. gp.icon
		avatarImg.ScaleType = Enum.ScaleType.Crop
		avatarImg.ZIndex = 212
		avatarImg.Parent = avatarFrame
		UI.rounded(avatarImg, AVATAR_S)

		local TEXT_X = AVATAR_S + 12
		local titleLbl = UI.label({
			size = UDim2.new(1, -TEXT_X, 0, 28), pos = UDim2.new(0, TEXT_X, 0, 0),
			text = gp.name, color = THEME.accent, font = Enum.Font.GothamBlack,
			textSize = 20, truncate = Enum.TextTruncate.AtEnd, z = 211, parent = topRow,
		})

		local descLbl = UI.label({
			size = UDim2.new(1, -TEXT_X, 0, 0), pos = UDim2.new(0, TEXT_X, 0, 30),
			text = gp.desc or "", color = THEME.dim, textSize = 13,
			wrap = true, z = 211, parent = topRow,
		})
		descLbl.AutomaticSize = Enum.AutomaticSize.Y
		descLbl.RichText = true

		task.defer(function()
			if descLbl.Parent then
				task.wait()
				local descH = descLbl.TextBounds.Y
				local totalH = math.max(AVATAR_S, 30 + descH + 4)
				topRow.Size = UDim2.new(1, 0, 0, totalH)
			end
		end)

		-- ═══ Bottom row: buy button + gift button ═══
		local bottomRow = UI.frame({ size = UDim2.new(1, 0, 0, 44), bgT = 1, z = 210, parent = content })
		bottomRow.LayoutOrder = 2

		-- Buy pill
		local buyBtn = UI.button({
			name = "BuyBtn", size = UDim2.new(0, 150, 0, 40),
			bg = THEME.elevated, text = ROBUX_CHAR .. " " .. gp.price,
			textSize = 15, z = 212, parent = bottomRow, corner = 20,
		})

		-- Gift pill
		local giftBtn = UI.button({
			name = "GiftBtn", size = UDim2.new(0, 130, 0, 40), pos = UDim2.new(0, 158, 0, 0),
			bg = gp.color, text = "REGALAR",
			textSize = 14, z = 212, parent = bottomRow, corner = 20,
		})
		giftBtn.BackgroundTransparency = 0.3

		shopCards[gp.gid] = buyBtn

		fetchOwnership(gp.gid, function(owned)
			if owned then
				buyBtn.Text = "TIENES"
				buyBtn.BackgroundColor3 = Color3.fromRGB(40, 180, 80)
			end
		end)

		-- Hover card
		card.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseMovement then
				TweenService:Create(card, TW, { BackgroundColor3 = THEME.elevated }):Play()
			end
		end)
		card.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseMovement then
				TweenService:Create(card, TW, { BackgroundColor3 = THEME.card }):Play()
			end
		end)

		-- Buy click + hover
		buyBtn.MouseButton1Click:Connect(function()
			if gpCache[gp.gid] then return end
			pcall(function() MarketplaceService:PromptGamePassPurchase(player, gp.gid) end)
		end)
		buyBtn.MouseEnter:Connect(function()
			if not gpCache[gp.gid] then
				TweenService:Create(buyBtn, TW, { BackgroundColor3 = THEME.subtle }):Play()
			end
		end)
		buyBtn.MouseLeave:Connect(function()
			if not gpCache[gp.gid] then
				TweenService:Create(buyBtn, TW, { BackgroundColor3 = THEME.elevated }):Play()
			end
		end)

		-- Gift hover
		giftBtn.MouseEnter:Connect(function()
			TweenService:Create(giftBtn, TW, { BackgroundTransparency = 0 }):Play()
		end)
		giftBtn.MouseLeave:Connect(function()
			TweenService:Create(giftBtn, TW, { BackgroundTransparency = 0.3 }):Play()
		end)

		-- Gift click → slide a la vista de jugadores
		giftBtn.MouseButton1Click:Connect(function()
			if _sliding then return end
			selectedGamepass = gp.gid
			selectedGpData = gp

			giftHdr.title.Text = "Regalar " .. gp.name
			giftHdr.subtitle.Text = ROBUX_CHAR .. " " .. gp.price
			giftHdr.bg.BackgroundColor3 = gp.color

			_sliding = true
			giftView.Position = UDim2.fromScale(1, 0)
			giftView.Visible = true
			TweenService:Create(listView, TW_PAGE, { Position = UDim2.fromScale(-1, 0) }):Play()
			TweenService:Create(giftView, TW_PAGE, { Position = UDim2.fromScale(0, 0) }):Play()
			task.delay(0.28, function()
				listView.Visible = false
				listView.Position = UDim2.fromScale(0, 0)
				_sliding = false
			end)

			if playerListInstance then
				playerListInstance:setLoading(true)
				playerListInstance:setTitle("Regalar " .. gp.name)
				playerListInstance:setAccentColor(gp.color)
			end

			task.spawn(function()
				if not GetPlayersWithoutItem then task.wait(1) end
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

	-- Purchase callback
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(plr, passId, bought)
		if plr ~= player or not bought then return end
		gpCache[passId] = true
		local btn = shopCards[passId]
		if btn and btn.Parent then
			btn.Text = "TIENES"
			btn.BackgroundColor3 = Color3.fromRGB(40, 180, 80)
		end
	end)

	-- ═══════════════════════════════════════════════════════════════
	-- VIEW 2: GIFT VIEW (lista de jugadores con header + back)
	-- ═══════════════════════════════════════════════════════════════
	local HEADER_H = 60

	giftView = UI.frame({ name = "GiftView", bgT = 1, clips = true, z = 211, parent = root })
	giftView.Visible = false

	giftHdr = SlideHeader.new({ parent = giftView, theme = THEME, bgMode = "color" })

	-- Player list container
	local playerListContainer = UI.frame({
		name = "PlayerListContainer",
		size = UDim2.new(1, 0, 1, -HEADER_H), pos = UDim2.new(0, 0, 0, HEADER_H),
		bgT = 1, z = 212, parent = giftView,
	})

	-- Back button interacción
	giftHdr.backBtn.MouseButton1Click:Connect(function()
		if _sliding then return end
		_sliding = true
		listView.Position = UDim2.fromScale(-1, 0)
		listView.Visible = true
		TweenService:Create(giftView, TW_PAGE, { Position = UDim2.fromScale(1, 0) }):Play()
		TweenService:Create(listView, TW_PAGE, { Position = UDim2.fromScale(0, 0) }):Play()
		task.delay(0.28, function()
			giftView.Visible = false
			giftView.Position = UDim2.fromScale(0, 0)
			listView.Visible = true
			_sliding = false
		end)
		selectedGamepass = nil
		selectedGpData = nil
	end)

	-- ═══════════════════════════════════════════════════════════════
	-- PLAYER LIST + GIFTING LOGIC
	-- ═══════════════════════════════════════════════════════════════
	local function onGiftPlayer(userId, username, displayName, playerData)
		if not selectedGamepass or not selectedGpData then return end

		local gpData = selectedGpData
		local priceText = isAdmin and "GRATIS (Admin)" or (ROBUX_CHAR .. " " .. gpData.price)

		ConfirmationModal.show(screenGui, {
			title = "Regalar " .. gpData.name,
			message = "Regalar a " .. displayName .. "?\n\nCosto: " .. priceText,
			confirmText = "REGALAR",
			cancelText = "CANCELAR",
			accentColor = gpData.color,
			onConfirm = function()
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

	playerListInstance = PlayerList.new({
		parent = playerListContainer,
		title = "Selecciona un jugador",
		emptyText = "No hay jugadores sin este pase",
		accentColor = THEME.accent,
		buttonText = "REGALAR",
		buttonIcon = "",
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
