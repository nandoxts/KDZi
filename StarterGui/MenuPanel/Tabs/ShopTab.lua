--[[
	ShopTab.lua — ModuleScript
	Tab de TIENDA para el MenuPanel.
	Grid 2 columnas de gamepasses con check de propiedad y botón de compra.
]]

local ShopTab = {}

function ShopTab.build(parent, THEME, sharedState)
	local Players            = game:GetService("Players")
	local ReplicatedStorage  = game:GetService("ReplicatedStorage")
	local TweenService       = game:GetService("TweenService")
	local MarketplaceService = game:GetService("MarketplaceService")

	local player = Players.LocalPlayer

	local Configuration = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("Configuration"))
	local ModernScrollbar = require(ReplicatedStorage:WaitForChild("UIComponents"):WaitForChild("ModernScrollbar"))

	local TW = TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	local ROBUX_CHAR = utf8.char(0xE002)

	local GAMEPASSES = {
		{ name = "VIP",        price = 200,  gid = Configuration.VIP,        icon = "76721656269888"  },
		{ name = "COMANDOS",   price = 1500, gid = Configuration.COMMANDS,   icon = "128637341143304" },
		{ name = "COLORES",    price = 50,   gid = Configuration.COLORS,     icon = "91877799240345"  },
		{ name = "POLICIA",    price = 135,  gid = Configuration.TOMBO,      icon = "139661313218787" },
		{ name = "LADRON",     price = 135,  gid = Configuration.CHORO,      icon = "84699864716808"  },
		{ name = "SEGURIDAD",  price = 135,  gid = Configuration.SERE,       icon = "85734290151599"  },
		{ name = "ARMY BOOMS", price = 80,   gid = Configuration.ARMYBOOMS,  icon = "134501492548324" },
		{ name = "LIGHTSTICK", price = 80,   gid = Configuration.LIGHTSTICK, icon = "86122436659328"  },
	}

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

	-- Header
	local headerLbl = Instance.new("TextLabel")
	headerLbl.Size                   = UDim2.new(1, -24, 0, 30)
	headerLbl.Position               = UDim2.new(0, 12, 0, 8)
	headerLbl.BackgroundTransparency = 1
	headerLbl.Font                   = Enum.Font.GothamBold
	headerLbl.TextSize               = 13
	headerLbl.TextColor3             = THEME.text
	headerLbl.TextXAlignment         = Enum.TextXAlignment.Left
	headerLbl.Text                   = "GAMEPASSES"
	headerLbl.ZIndex                 = 204
	headerLbl.Parent                 = parent

	-- Scroll
	local scroll = Instance.new("ScrollingFrame")
	scroll.Size                   = UDim2.new(1, -16, 1, -44)
	scroll.Position               = UDim2.new(0, 8, 0, 44)
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel        = 0
	scroll.ScrollBarThickness     = 0
	scroll.CanvasSize             = UDim2.new(0, 0, 0, 0)
	scroll.ClipsDescendants       = true
	scroll.ZIndex                 = 204
	scroll.Parent                 = parent
	ModernScrollbar.setup(scroll, parent, THEME, {transparency = 0.4, offset = 0})

	-- Grid 2 columnas
	local grid = Instance.new("UIGridLayout")
	grid.CellSize            = UDim2.new(0.5, -6, 0, 176)
	grid.CellPadding         = UDim2.new(0, 8, 0, 8)
	grid.HorizontalAlignment = Enum.HorizontalAlignment.Center
	grid.SortOrder           = Enum.SortOrder.LayoutOrder
	grid.Parent              = scroll

	local gPad = Instance.new("UIPadding")
	gPad.PaddingLeft   = UDim.new(0, 4)
	gPad.PaddingRight  = UDim.new(0, 4)
	gPad.PaddingTop    = UDim.new(0, 6)
	gPad.PaddingBottom = UDim.new(0, 16)
	gPad.Parent        = scroll

	-- Guardar referencias de buy buttons (para actualizar tras compra)
	sharedState.shopCards = sharedState.shopCards or {}

	for i, gp in ipairs(GAMEPASSES) do
		local card = Instance.new("Frame")
		card.Name                   = "Card_" .. i
		card.BackgroundColor3       = THEME.card
		card.BackgroundTransparency = 0.05
		card.BorderSizePixel        = 0
		card.ZIndex                 = 205
		card.LayoutOrder            = i
		card.Parent                 = scroll

		local cc = Instance.new("UICorner"); cc.CornerRadius = UDim.new(0, 12); cc.Parent = card
		local cs = Instance.new("UIStroke"); cs.Color = THEME.stroke; cs.Thickness = 1; cs.Transparency = 0.5; cs.Parent = card

		-- Fondo decorativo superior
		local bgDeco = Instance.new("Frame")
		bgDeco.Size                   = UDim2.new(1, 0, 0.55, 0)
		bgDeco.BackgroundColor3       = THEME.elevated
		bgDeco.BackgroundTransparency = 0.1
		bgDeco.BorderSizePixel        = 0
		bgDeco.ZIndex                 = 205
		bgDeco.Parent                 = card
		local bgc = Instance.new("UICorner"); bgc.CornerRadius = UDim.new(0, 12); bgc.Parent = bgDeco

		-- Icono
		local img = Instance.new("ImageLabel")
		img.Size                   = UDim2.new(0.75, 0, 0, 72)
		img.Position               = UDim2.new(0.125, 0, 0, 8)
		img.BackgroundTransparency = 1
		img.Image                  = "rbxassetid://" .. gp.icon
		img.ScaleType              = Enum.ScaleType.Fit
		img.ZIndex                 = 206
		img.Parent                 = card

		-- Nombre
		local nameLbl = Instance.new("TextLabel")
		nameLbl.Size                   = UDim2.new(1, -8, 0, 18)
		nameLbl.Position               = UDim2.new(0, 4, 0, 90)
		nameLbl.BackgroundTransparency = 1
		nameLbl.Font                   = Enum.Font.GothamBold
		nameLbl.TextSize               = 11
		nameLbl.TextColor3             = THEME.text
		nameLbl.TextXAlignment         = Enum.TextXAlignment.Center
		nameLbl.Text                   = gp.name
		nameLbl.ZIndex                 = 206
		nameLbl.Parent                 = card

		-- Precio
		local priceLbl = Instance.new("TextLabel")
		priceLbl.Size                   = UDim2.new(1, -8, 0, 16)
		priceLbl.Position               = UDim2.new(0, 4, 0, 108)
		priceLbl.BackgroundTransparency = 1
		priceLbl.Font                   = Enum.Font.GothamBold
		priceLbl.TextSize               = 12
		priceLbl.TextColor3             = THEME.accent
		priceLbl.TextXAlignment         = Enum.TextXAlignment.Center
		priceLbl.Text                   = ROBUX_CHAR .. " " .. gp.price
		priceLbl.ZIndex                 = 206
		priceLbl.Parent                 = card

		-- Botón comprar
		local buyBtn = Instance.new("TextButton")
		buyBtn.Name                  = "BuyBtn"
		buyBtn.Size                  = UDim2.new(1, -16, 0, 26)
		buyBtn.Position              = UDim2.new(0, 8, 1, -32)
		buyBtn.BackgroundColor3      = Color3.fromRGB(50, 50, 50)
		buyBtn.BackgroundTransparency = 0
		buyBtn.Font                  = Enum.Font.GothamBold
		buyBtn.TextSize              = 11
		buyBtn.TextColor3            = Color3.new(1, 1, 1)
		buyBtn.Text                  = "COMPRAR"
		buyBtn.BorderSizePixel       = 0
		buyBtn.ZIndex                = 207
		buyBtn.Parent                = card
		local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0, 7); bc.Parent = buyBtn

		-- Guardar referencia para actualizar tras compra
		sharedState.shopCards[gp.gid] = buyBtn
		-- Compatibilidad con código anterior
		if _G._MenuPanelShopCards then
			_G._MenuPanelShopCards[gp.gid] = buyBtn
		end

		-- Check ownership
		fetchOwnership(gp.gid, function(owned)
			if owned then
				buyBtn.Text                  = "ACTIVADO"
				buyBtn.BackgroundColor3      = Color3.fromRGB(220, 220, 220)
				buyBtn.BackgroundTransparency = 0
				buyBtn.TextColor3            = Color3.fromRGB(20, 20, 20)
			end
		end)

		-- Hover effect
		card.MouseEnter:Connect(function()
			TweenService:Create(card, TW, {BackgroundTransparency = 0}):Play()
		end)
		card.MouseLeave:Connect(function()
			TweenService:Create(card, TW, {BackgroundTransparency = 0.05}):Play()
		end)

		-- Comprar
		buyBtn.MouseButton1Click:Connect(function()
			if gpCache[gp.gid] then return end
			pcall(function()
				MarketplaceService:PromptGamePassPurchase(player, gp.gid)
			end)
		end)
	end

	-- Auto canvas size
	grid:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		scroll.CanvasSize = UDim2.new(0, 0, 0, grid.AbsoluteContentSize.Y + 24)
	end)

	-- Listener de compra completada
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(plr, passId, bought)
		if plr ~= player or not bought then return end
		gpCache[passId] = true
		local btn = sharedState.shopCards and sharedState.shopCards[passId]
		if btn and btn.Parent then
			btn.Text                  = "ACTIVADO"
			btn.BackgroundColor3      = Color3.fromRGB(220, 220, 220)
			btn.BackgroundTransparency = 0
			btn.TextColor3            = Color3.fromRGB(20, 20, 20)
		end
	end)
end

return ShopTab
