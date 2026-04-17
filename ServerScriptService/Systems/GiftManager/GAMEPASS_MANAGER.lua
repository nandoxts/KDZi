-- ═══════════════════════════════════════════════════════════════
--  GAMEPASS_MANAGER.lua  |  GiftManager
--  Sistema central de gamepasses: compras directas, regalos y ownership
-- ═══════════════════════════════════════════════════════════════

-- ── Services ─────────────────────────────────────────────────
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local Players            = game:GetService("Players")
local DataStoreService   = game:GetService("DataStoreService")

-- ── Modules ──────────────────────────────────────────────────
local Configuration      = require(ReplicatedStorage.Config.Configuration)
local ShopManager        = require(script.Parent.ShopManager)
local CentralPurchaseHandler = require(script.Parent.ManagerProcess)

local RemotesGlobal      = ReplicatedStorage:FindFirstChild("RemotesGlobal") or Instance.new("Folder")
RemotesGlobal.Name = "RemotesGlobal"
RemotesGlobal.Parent = ReplicatedStorage

local GiftingFolder      = RemotesGlobal:FindFirstChild("Gamepass Gifting") or Instance.new("Folder")
GiftingFolder.Name = "Gamepass Gifting"
GiftingFolder.Parent = RemotesGlobal
local GiftingConfig      = require(ReplicatedStorage.Config.GiftingConfig)

local CommandsFolder     = RemotesGlobal:FindFirstChild("Commands")
local EventMessage       = CommandsFolder and CommandsFolder:FindFirstChild("EventMessage") or nil

local GiftDataStore      = DataStoreService:GetDataStore("Gifting.1")

-- ── Remotes ──────────────────────────────────────────────────
local Remotes            = GiftingFolder:FindFirstChild("Remotes") or Instance.new("Folder")
Remotes.Name = "Remotes"
Remotes.Parent = GiftingFolder

local GiftingRemote      = Remotes:FindFirstChild("Gifting") or Instance.new("RemoteEvent")
GiftingRemote.Name = "Gifting"
GiftingRemote.Parent = Remotes

local OwnershipRemote    = Remotes:FindFirstChild("Ownership") or Instance.new("RemoteFunction")
OwnershipRemote.Name = "Ownership"
OwnershipRemote.Parent = Remotes


-- ── Constants ────────────────────────────────────────────────
local VIP_GAMEPASS   = Configuration.Gamepasses.VIP and Configuration.Gamepasses.VIP.id or nil
local CAMINO_GAMEPASS = ((Configuration.Gamepasses.CAMINO and Configuration.Gamepasses.CAMINO.id)
	or (Configuration.Gamepasses.CAMINO_AL_CIELO and Configuration.Gamepasses.CAMINO_AL_CIELO.id)) or nil
local TARIMA_GAMEPASS = Configuration.Gamepasses.TARIMA and Configuration.Gamepasses.TARIMA.id or nil
local GROUP_ID = tonumber(Configuration.GroupID) or 0
local HIGHEST_GROUP_RANK = 255

-- ── State ────────────────────────────────────────────────────
-- pendingGifts[donorUserId] = { recipientId, donorName, donorId, gamepassId }
-- Capa 1: memoria (rápido). Capa 2: DataStore (sobrevive restarts).
local pendingGifts = {}
local PendingGiftStore = DataStoreService:GetDataStore("PendingGifts.1")

-- Lista unificada de items regalables (se construye una sola vez desde GiftingConfig)
local ALL_ITEMS = {}
for _, gp in ipairs(GiftingConfig.Gamepasses) do table.insert(ALL_ITEMS, gp) end
for _, title in ipairs(GiftingConfig.Titles) do table.insert(ALL_ITEMS, title) end

-- ═══════════════════════════════════════════════════════════════
-- HELPERS
-- ═══════════════════════════════════════════════════════════════

local itemNameCache = {}

local function fireGiftFeed(message)
	if EventMessage then
		EventMessage:FireAllClients(message, "gift")
	end
end

local function getItemName(gamepassId)
	if itemNameCache[gamepassId] then
		return itemNameCache[gamepassId]
	end
	local ok, asset = pcall(function()
		return MarketplaceService:GetProductInfo(gamepassId, Enum.InfoType.GamePass)
	end)
	if ok and asset and asset.Name then
		itemNameCache[gamepassId] = asset.Name
		return asset.Name
	end
	return nil
end

local function ensureFolder(player)
	local folder = player:FindFirstChild("Gamepasses")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "Gamepasses"
		folder.Parent = player
	end
	return folder
end

local function setFolderValue(folder, name, value)
	local existing = folder:FindFirstChild(name)
	if not existing then
		local v = Instance.new("BoolValue")
		v.Name = name
		v.Value = value
		v.Parent = folder
	else
		existing.Value = value
	end
end

local function setOwnedAttribute(player, gamepassId, owns)
	if VIP_GAMEPASS and gamepassId == VIP_GAMEPASS then
		player:SetAttribute("HasVIP", owns)
	elseif CAMINO_GAMEPASS and gamepassId == CAMINO_GAMEPASS then
		player:SetAttribute("HasCAMINO", owns)
	elseif TARIMA_GAMEPASS and gamepassId == TARIMA_GAMEPASS then
		player:SetAttribute("HasTARIMA", owns)
	end
end

local function isHighestRank(player)
	if not player or GROUP_ID <= 0 then
		return false
	end

	local ok, rank = pcall(player.GetRankInGroup, player, GROUP_ID)
	return ok and rank == HIGHEST_GROUP_RANK
end

local function grantToOnlinePlayer(recipientUserId, gamepassId)
	local player = Players:GetPlayerByUserId(recipientUserId)
	if not player then return end

	local folder = ensureFolder(player)
	local name = getItemName(gamepassId)
	if name then
		setFolderValue(folder, name, true)
	end
	setOwnedAttribute(player, gamepassId, true)
end

-- ═══════════════════════════════════════════════════════════════
-- GIFT LOGIC
-- ═══════════════════════════════════════════════════════════════

local function giftFree(admin, gamepass, recipientUserId, recipientName)
	if not admin or not gamepass or not gamepass[1] or not recipientUserId or not recipientName then
		if admin then GiftingRemote:FireClient(admin, "Error", "Parámetros inválidos") end
		return
	end

	local gamepassId = gamepass[1]

	-- Verificar si ya lo tiene
	if ShopManager.HasGamepassByUserId(recipientUserId, gamepassId) then
		local name = getItemName(gamepassId) or "Unknown"
		GiftingRemote:FireClient(admin, "Error", recipientName .. " ya tiene " .. name)
		return
	end

	-- Guardar en DataStore SÍNCRONO (confirmar antes de notificar)
	local writeOk, writeErr = pcall(function()
		GiftDataStore:SetAsync(recipientUserId .. "-" .. gamepassId, true)
	end)
	if not writeOk then
		warn("[GIFT-FREE] Fallo DataStore write:", writeErr)
		GiftingRemote:FireClient(admin, "Error", "Error al guardar, intenta de nuevo")
		return
	end

	-- Conceder al jugador online
	grantToOnlinePlayer(recipientUserId, gamepassId)

	-- Notificar en el chat (color rosa = regalo)
	local gpName = getItemName(gamepassId) or "Item"
	fireGiftFeed(admin.Name .. " le regaló [" .. gpName .. "] a " .. recipientName .. "!")

	-- Notificar a ShopGifting
	if _G.ShopGifting_OnItemGifted then
		pcall(_G.ShopGifting_OnItemGifted, recipientUserId, "gamepass", gamepassId)
	end

	-- Confirmar al admin
	GiftingRemote:FireClient(admin, "Purchase")
end

-- ═══════════════════════════════════════════════════════════════
-- EVENT: SOLICITUD DE REGALO
-- ═══════════════════════════════════════════════════════════════

-- ── Rate limit por jugador (1 request cada 2s) ──────────────
local giftRateLimit = {}
local GIFT_RATE_COOLDOWN = 2

Players.PlayerRemoving:Connect(function(p)
	giftRateLimit[p.UserId] = nil
end)

GiftingRemote.OnServerEvent:Connect(function(player, gamepass, userId, username, identifier)
	-- Rate limit
	local now = tick()
	local last = giftRateLimit[player.UserId]
	if last and (now - last) < GIFT_RATE_COOLDOWN then
		return
	end
	giftRateLimit[player.UserId] = now

	if not gamepass or type(gamepass) ~= "table" or not gamepass[1] or not gamepass[2] then
		GiftingRemote:FireClient(player, "Error", "Datos inválidos")
		return
	end

	-- Validar tipos (protección anti-exploit)
	if type(gamepass[1]) ~= "number" or type(gamepass[2]) ~= "number" then
		GiftingRemote:FireClient(player, "Error", "Datos inválidos")
		return
	end
	if gamepass[1] <= 0 or gamepass[2] <= 0 then
		return
	end

	userId     = tonumber(userId)
	identifier = tonumber(identifier)
	if not userId or userId <= 0 then return end
	if not identifier or identifier == 0 then identifier = userId end

	local recipientName
	local ok = pcall(function() recipientName = Players:GetNameFromUserIdAsync(userId) end)
	if not ok or not recipientName then return end

	for _, item in ipairs(ALL_ITEMS) do
		if item[1] == gamepass[1] and item[2] == gamepass[2] then
			if player.UserId == userId then return end

			if isHighestRank(player) then
				giftFree(player, gamepass, userId, recipientName)
			else
				if not ShopManager.HasGamepassByUserId(userId, gamepass[1]) then
					local giftData = {
						recipientId = userId,
						donorName   = player.Name,
						donorId     = player.UserId,
						gamepassId  = gamepass[1],
					}

					-- Persistir en DataStore ANTES de cobrar (sobrevive server restart)
					local saveOk, saveErr = pcall(function()
						PendingGiftStore:SetAsync("pending-" .. player.UserId, giftData)
					end)
					if not saveOk then
						warn("[GIFT] No se pudo guardar pending gift:", saveErr)
						GiftingRemote:FireClient(player, "Error", "Error al preparar el regalo, intenta de nuevo")
						return
					end

					-- Guardar también en memoria (acceso rápido)
					pendingGifts[player.UserId] = giftData
					MarketplaceService:PromptProductPurchase(player, gamepass[2])
				else
					local name = getItemName(gamepass[1])
					if name then
						GiftingRemote:FireClient(player, "Error", recipientName .. " ya tiene " .. name)
					end
				end
			end
			return
		end
	end
end)

-- ═══════════════════════════════════════════════════════════════
-- EVENT: PLAYER ADDED (crear folder + sincronizar ownership)
-- ═══════════════════════════════════════════════════════════════

Players.PlayerAdded:Connect(function(player)
	local folder = ensureFolder(player)
	player:SetAttribute("HasVIP", false)
	player:SetAttribute("HasCAMINO", false)
	if TARIMA_GAMEPASS then
		player:SetAttribute("HasTARIMA", false)
	end

	local function syncOwnership()
		for _, item in ipairs(ALL_ITEMS) do
			local id = item[1]
			if id and type(id) == "number" then
				local owns = ShopManager.HasGamepassByUserId(player.UserId, id)
				local name = getItemName(id)
				if name then
					setFolderValue(folder, name, owns)
				end
				setOwnedAttribute(player, id, owns)
			end
		end
	end

	syncOwnership()
	player.CharacterAdded:Connect(syncOwnership)
end)

-- ═══════════════════════════════════════════════════════════════
-- EVENT: COMPRA DIRECTA DE GAMEPASS
-- ═══════════════════════════════════════════════════════════════

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamepassId, wasPurchased)
	if not wasPurchased or not player or not player.Parent then return end

	-- Siempre sincronizar atributos de zonas VIP/TARIMA/CAMINO en compra directa,
	-- ANTES del gate isOurs, para que el cliente reciba el cambio incluso si
	-- el gamepass no está en GiftingConfig.
	if VIP_GAMEPASS and gamepassId == VIP_GAMEPASS then
		setOwnedAttribute(player, gamepassId, true)
	elseif CAMINO_GAMEPASS and gamepassId == CAMINO_GAMEPASS then
		setOwnedAttribute(player, gamepassId, true)
	elseif TARIMA_GAMEPASS and gamepassId == TARIMA_GAMEPASS then
		setOwnedAttribute(player, gamepassId, true)
	end

	-- Verificar que es uno de nuestros items
	local isOurs = false
	for _, item in ipairs(ALL_ITEMS) do
		if item[1] == gamepassId then isOurs = true; break end
	end
	if not isOurs then return end

	grantToOnlinePlayer(player.UserId, gamepassId)

	-- Actualizar cache de ShopGifting (quitar de lista "sin pase")
	if _G.ShopGifting_OnItemGifted then
		pcall(_G.ShopGifting_OnItemGifted, player.UserId, "gamepass", gamepassId)
	end
end)

-- ═══════════════════════════════════════════════════════════════
-- PROCESS RECEIPT: Regalo pagado (no-admin)
-- ═══════════════════════════════════════════════════════════════

local function handleGiftPurchase(receiptInfo)
	for _, item in ipairs(ALL_ITEMS) do
		if receiptInfo.ProductId == item[2] then
			-- ── Recuperar info del regalo (memoria → DataStore fallback) ──
			local giftInfo = pendingGifts[receiptInfo.PlayerId]
			if not giftInfo then
				-- Server pudo reiniciarse: leer de DataStore
				local readOk, stored = pcall(function()
					return PendingGiftStore:GetAsync("pending-" .. receiptInfo.PlayerId)
				end)
				if readOk and stored and type(stored) == "table" and stored.recipientId then
					giftInfo = stored
				else
					-- No hay info en ningún lado → reintentar después
					warn("[GIFT] Sin pending gift para PlayerId:", receiptInfo.PlayerId, "- reintentando")
					return Enum.ProductPurchaseDecision.NotProcessedYet
				end
			end

			local recipientId = giftInfo.recipientId
			local donorName   = giftInfo.donorName
			local donorId     = giftInfo.donorId
			local gamepassId  = item[1]

			-- ── Validar: ¿el destinatario ya tiene el pase? ──
			local alreadyOwns = false
			pcall(function()
				alreadyOwns = ShopManager.HasGamepassByUserId(recipientId, gamepassId)
			end)

			if alreadyOwns then
				-- Ya lo tiene → no conceder de nuevo pero SÍ marcar como procesado
				-- (ya se cobró, no se puede reembolsar desde aquí)
				warn("[GIFT] Destinatario", recipientId, "ya tiene gamepass", gamepassId, "- cobrado pero duplicado evitado")
				pendingGifts[receiptInfo.PlayerId] = nil
				pcall(function() PendingGiftStore:RemoveAsync("pending-" .. receiptInfo.PlayerId) end)

				local donor = Players:GetPlayerByUserId(donorId)
				if donor then
					local gpName = getItemName(gamepassId) or "Item"
					GiftingRemote:FireClient(donor, "Error", "El jugador ya obtuvo " .. gpName .. " antes de completar tu compra.")
				end
				return Enum.ProductPurchaseDecision.PurchaseGranted
			end

			-- ── Escribir en DataStore SÍNCRONO (confirmar antes de PurchaseGranted) ──
			local writeOk, writeErr = pcall(function()
				GiftDataStore:SetAsync(recipientId .. "-" .. gamepassId, true)
			end)
			if not writeOk then
				warn("[GIFT] Fallo DataStore write:", writeErr, "- reintentando")
				-- NO retornar PurchaseGranted → Roblox reintentará
				return Enum.ProductPurchaseDecision.NotProcessedYet
			end

			-- ── Write confirmado → limpiar pending ──
			pendingGifts[receiptInfo.PlayerId] = nil
			pcall(function() PendingGiftStore:RemoveAsync("pending-" .. receiptInfo.PlayerId) end)

			-- Conceder al jugador online
			grantToOnlinePlayer(recipientId, gamepassId)

			-- Notificar en el chat (color rosa = regalo)
			pcall(function()
				local recipientName2 = Players:GetNameFromUserIdAsync(recipientId)
				local gpName = getItemName(gamepassId) or "Item"
				fireGiftFeed(donorName .. " le regaló [" .. gpName .. "] a " .. recipientName2 .. "!")
			end)

			-- Notificar al donante
			local donor = Players:GetPlayerByUserId(donorId)
			if donor then
				GiftingRemote:FireClient(donor, "Purchase")
			end

			-- Notificar a ShopGifting
			if _G.ShopGifting_OnItemGifted then
				pcall(_G.ShopGifting_OnItemGifted, recipientId, "gamepass", gamepassId)
			end

			return Enum.ProductPurchaseDecision.PurchaseGranted
		end
	end
	return Enum.ProductPurchaseDecision.NotProcessedYet
end

CentralPurchaseHandler.registerGiftHandler(handleGiftPurchase)

-- ═══════════════════════════════════════════════════════════════
-- REMOTE: Ownership check (usado por clientes)
-- ═══════════════════════════════════════════════════════════════

OwnershipRemote.OnServerInvoke = function(player, gamepassId)
	return ShopManager.HasGamepass(player, gamepassId)
end