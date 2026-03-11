--[[
--[[
	═══════════════════════════════════════════════════════════════
	GamepassTab.lua — Tab de Game Passes para la tienda
	Usa ShopItemList (Shared) para cards + slide + regalo.
	═══════════════════════════════════════════════════════════════
]]

local Players            = game:GetService("Players")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local Configuration     = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("Configuration"))
local AdminConfig       = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("AdminConfig"))
local ConfirmationModal = require(ReplicatedStorage:WaitForChild("Modal"):WaitForChild("ConfirmationModal"))
local Notify            = require(ReplicatedStorage:WaitForChild("Systems"):WaitForChild("NotificationSystem"):WaitForChild("NotificationSystem"))
local ShopItemList      = require(script.Parent.Parent:WaitForChild("Shared"):WaitForChild("ShopItemList"))

local player  = Players.LocalPlayer
local isAdmin = AdminConfig:IsAdmin(player)

local ROBUX_CHAR = utf8.char(0xE002)

local GamepassTab = {}

-- ═══════════════════════════════════════════════════════════════
-- DATA
-- ═══════════════════════════════════════════════════════════════
local GRAD_COLORS = {
	Color3.fromRGB(90,  40, 140), Color3.fromRGB(40,  80, 160),
	Color3.fromRGB(50, 130,  80), Color3.fromRGB(30,  80, 160),
	Color3.fromRGB(160, 50,  50), Color3.fromRGB(60, 100, 160),
	Color3.fromRGB(180, 90,  20), Color3.fromRGB(20, 140, 160),
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

	-- ── Remotes ──────────────────────────────────────────────────
	local GetPlayersWithoutItem, GiftingRemote, OwnershipUpdated
	local ownershipRemote

	task.spawn(function()
		pcall(function()
			ownershipRemote = ReplicatedStorage
				:WaitForChild("RemotesGlobal", 5)
				:WaitForChild("Gamepass Gifting")
				:WaitForChild("Remotes")
				:WaitForChild("Ownership")
		end)
		local rg = ReplicatedStorage:WaitForChild("RemotesGlobal", 5)
		if not rg then return end
		local shopFolder = rg:FindFirstChild("ShopGifting")
		if shopFolder then
			GetPlayersWithoutItem = shopFolder:FindFirstChild("GetPlayersWithoutItem")
			OwnershipUpdated      = shopFolder:FindFirstChild("OwnershipUpdated")
		end
		local giftFolder = rg:FindFirstChild("Gamepass Gifting")
		if giftFolder then
			local remotes = giftFolder:FindFirstChild("Remotes")
			if remotes then GiftingRemote = remotes:FindFirstChild("Gifting") end
		end
	end)

	-- ═══════════════════════════════════════════════════════════════
	-- VIEW 1: LISTA DE GAMEPASSES (diseño original con cards)
	-- ═══════════════════════════════════════════════════════════════
	-- Nota: todo el UI (cards, gradiente, slide, PlayerList) vive en ShopItemList
	-- ═══════════════════════════════════════════════════════════════
	-- ── Items ────────────────────────────────────────────────────
	local items = {}
	for i, gp in ipairs(GAMEPASSES) do
		table.insert(items, {
			id        = gp.gid,
			name      = gp.name,
			price     = gp.price,
			icon      = gp.icon,
			color     = gp.color,
			gradColor = GRAD_COLORS[i],
			desc      = gp.desc,
			productId = gp.productId,
		})
	end

	-- ── ShopItemList ─────────────────────────────────────────────
	local listApi = ShopItemList.build({
		parent = parent,
		theme  = THEME,
		state  = state,
		items  = items,

		onBuy = function(item)
			pcall(function() MarketplaceService:PromptGamePassPurchase(player, item.id) end)
		end,

		onGift = function(item, userId, username, displayName)
			local priceText = isAdmin and "GRATIS (Admin)" or (ROBUX_CHAR .. " " .. item.price)
			ConfirmationModal.show(screenGui, {
				title       = "Regalar " .. item.name,
				message     = "Regalar a " .. displayName .. "?\n\nCosto: " .. priceText,
				confirmText = "REGALAR",
				cancelText  = "CANCELAR",
				accentColor = item.color,
				onConfirm   = function()
					if GiftingRemote then
						GiftingRemote:FireServer({ item.id, item.productId }, userId, username, player.UserId)
						Notify:Info("Regalo", "Procesando regalo de " .. item.name .. " para " .. displayName, 3)
					else
						Notify:Error("Error", "Sistema de regalos no disponible", 3)
					end
				end,
			})
		end,

		loadPlayers = function(item, callback)
			task.spawn(function()
				if not GetPlayersWithoutItem then task.wait(1) end
				if GetPlayersWithoutItem then
					local result = GetPlayersWithoutItem:InvokeServer("gamepass", item.id)
					callback(result and result.success and result.players or {})
				else
					callback({})
				end
			end)
		end,
	})

	-- ── Ownership check al cargar ─────────────────────────────────
	for _, item in ipairs(items) do
		task.spawn(function()
			local owned = false
			if ownershipRemote then
				local ok, res = pcall(function() return ownershipRemote:InvokeServer(item.id) end)
				owned = ok and res or false
			else
				local ok, res = pcall(function()
					return MarketplaceService:UserOwnsGamePassAsync(player.UserId, item.id)
				end)
				owned = ok and res or false
			end
			if owned then listApi.markOwned(item.id) end
		end)
	end

	-- ── Purchase callback ─────────────────────────────────────────
	local mpConn = MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(plr, passId, bought)
		if plr ~= player or not bought then return end
		listApi.markOwned(passId)
	end)

	-- ── OwnershipUpdated ──────────────────────────────────────────
	task.spawn(function()
		task.wait(1)
		if OwnershipUpdated then
			OwnershipUpdated.OnClientEvent:Connect(function(data)
				if data.type == "gamepass" then
					listApi.handleOwnershipRemoved(data.itemId, data.userId)
					Notify:Success("Actualizado", data.username .. " ahora tiene este pase", 2)
				end
			end)
		end
	end)

	local function cleanup()
		mpConn:Disconnect()
		listApi.cleanup()
	end

	return { panel = listApi.panel, cleanup = cleanup }
end

return GamepassTab
