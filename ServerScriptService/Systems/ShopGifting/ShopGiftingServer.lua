--[[
	═══════════════════════════════════════════════════════════════
	ShopGiftingServer.lua - Backend para sistema de regalos en Shop
	═══════════════════════════════════════════════════════════════
	• Maneja consultas de jugadores sin gamepass/título
	• Se integra con sistema existente de Gamepass Gifting
	• Cache inteligente para evitar throttling
	• Actualización en tiempo real cuando alguien obtiene algo
	
	Remotes creados:
	  - GetPlayersWithoutItem (RemoteFunction)
	  - OwnershipUpdated (RemoteEvent)
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local DataStoreService = game:GetService("DataStoreService")

-- ═══════════════════════════════════════════════════════════════
-- SETUP
-- ═══════════════════════════════════════════════════════════════
local GiftedGamepassesData = DataStoreService:GetDataStore("Gifting.1")
local Configuration = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("Configuration"))
local TitleConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("TitleConfig"))
local AdminConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("AdminConfig"))

-- Importar GamepassManager existente
local GamepassManager = require(game.ServerScriptService.Systems["Gamepass Gifting"]["GamepassManager"])

-- ═══════════════════════════════════════════════════════════════
-- CREAR REMOTES
-- ═══════════════════════════════════════════════════════════════
local RemotesGlobal = ReplicatedStorage:FindFirstChild("RemotesGlobal") or Instance.new("Folder", ReplicatedStorage)
RemotesGlobal.Name = "RemotesGlobal"

local ShopGiftingFolder = RemotesGlobal:FindFirstChild("ShopGifting") or Instance.new("Folder", RemotesGlobal)
ShopGiftingFolder.Name = "ShopGifting"

-- RemoteFunction para obtener jugadores sin item
local GetPlayersWithoutItem = ShopGiftingFolder:FindFirstChild("GetPlayersWithoutItem") 
	or Instance.new("RemoteFunction", ShopGiftingFolder)
GetPlayersWithoutItem.Name = "GetPlayersWithoutItem"

-- RemoteEvent para notificar actualizaciones de ownership
local OwnershipUpdated = ShopGiftingFolder:FindFirstChild("OwnershipUpdated") 
	or Instance.new("RemoteEvent", ShopGiftingFolder)
OwnershipUpdated.Name = "OwnershipUpdated"

-- ═══════════════════════════════════════════════════════════════
-- CACHE
-- ═══════════════════════════════════════════════════════════════
local ownershipCache = {} -- [userId-itemId] = {owns = bool, timestamp = tick()}
local CACHE_DURATION = 30 -- segundos

local function getCacheKey(userId, itemId)
	return userId .. "-" .. itemId
end

local function getCachedOwnership(userId, itemId)
	local key = getCacheKey(userId, itemId)
	local cached = ownershipCache[key]
	if cached and (tick() - cached.timestamp) < CACHE_DURATION then
		return cached.owns, true -- valor, esCache
	end
	return nil, false
end

local function setCachedOwnership(userId, itemId, owns)
	local key = getCacheKey(userId, itemId)
	ownershipCache[key] = {
		owns = owns,
		timestamp = tick()
	}
end

local function invalidateCache(userId, itemId)
	local key = getCacheKey(userId, itemId)
	ownershipCache[key] = nil
end

-- ═══════════════════════════════════════════════════════════════
-- OWNERSHIP CHECK
-- ═══════════════════════════════════════════════════════════════
local function checkGamepassOwnership(userId, gamepassId)
	-- Revisar cache primero
	local cachedValue, isCached = getCachedOwnership(userId, gamepassId)
	if isCached then
		return cachedValue
	end
	
	local owns = false
	
	-- 1. Verificar compra directa
	local success, result = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(userId, gamepassId)
	end)
	
	if success and result then
		owns = true
	else
		-- 2. Verificar en DataStore (regalado)
		success, result = pcall(function()
			return GiftedGamepassesData:GetAsync(userId .. "-" .. gamepassId)
		end)
		owns = success and result or false
	end
	
	-- Guardar en cache
	setCachedOwnership(userId, gamepassId, owns)
	
	return owns
end

local function checkTitleOwnership(userId, titleGamepassId)
	-- Los títulos también son gamepasses
	return checkGamepassOwnership(userId, titleGamepassId)
end

-- ═══════════════════════════════════════════════════════════════
-- GET PLAYERS WITHOUT ITEM
-- ═══════════════════════════════════════════════════════════════
local function getPlayersWithoutItem(requestingPlayer, itemType, itemId)
	if not requestingPlayer or not itemType or not itemId then
		return { success = false, error = "Parámetros inválidos" }
	end
	
	local playersWithout = {}
	local allPlayers = Players:GetPlayers()
	
	for _, targetPlayer in ipairs(allPlayers) do
		-- No incluir al jugador que solicita (no se puede regalar a sí mismo)
		if targetPlayer.UserId ~= requestingPlayer.UserId then
			local owns = false
			
			if itemType == "gamepass" then
				owns = checkGamepassOwnership(targetPlayer.UserId, itemId)
			elseif itemType == "title" then
				owns = checkTitleOwnership(targetPlayer.UserId, itemId)
			end
			
			if not owns then
				table.insert(playersWithout, {
					userId = targetPlayer.UserId,
					username = targetPlayer.Name,
					displayName = targetPlayer.DisplayName or targetPlayer.Name,
				})
			end
		end
	end
	
	-- Ordenar alfabéticamente por displayName
	table.sort(playersWithout, function(a, b)
		return (a.displayName or ""):lower() < (b.displayName or ""):lower()
	end)
	
	return {
		success = true,
		players = playersWithout,
		total = #playersWithout
	}
end

-- ═══════════════════════════════════════════════════════════════
-- REMOTE HANDLERS
-- ═══════════════════════════════════════════════════════════════
GetPlayersWithoutItem.OnServerInvoke = function(player, itemType, itemId)
	-- Rate limiting básico
	local rateLimitKey = player.UserId .. "_shopGifting"
	if not _G.shopGiftingRateLimit then _G.shopGiftingRateLimit = {} end
	
	local lastRequest = _G.shopGiftingRateLimit[rateLimitKey]
	if lastRequest and (tick() - lastRequest) < 0.5 then
		return { success = false, error = "Demasiadas solicitudes" }
	end
	_G.shopGiftingRateLimit[rateLimitKey] = tick()
	
	return getPlayersWithoutItem(player, itemType, itemId)
end

-- ═══════════════════════════════════════════════════════════════
-- ESCUCHAR COMPRAS/REGALOS PARA ACTUALIZAR CLIENTES
-- ═══════════════════════════════════════════════════════════════

-- Cuando alguien compra un gamepass directamente
MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamepassId, wasPurchased)
	if not wasPurchased then return end
	
	-- Invalidar cache
	invalidateCache(player.UserId, gamepassId)
	
	-- Notificar a todos los clientes
	OwnershipUpdated:FireAllClients({
		type = "gamepass",
		itemId = gamepassId,
		userId = player.UserId,
		username = player.Name,
	})
end)

-- Hook para cuando se regala un gamepass (llamado desde GiftGamepass.lua)
_G.ShopGifting_OnItemGifted = function(recipientUserId, itemType, itemId)
	-- Invalidar cache
	invalidateCache(recipientUserId, itemId)
	
	-- Obtener nombre del recipient
	local recipientName = "Usuario"
	pcall(function()
		recipientName = Players:GetNameFromUserIdAsync(recipientUserId)
	end)
	
	-- Notificar a todos los clientes
	OwnershipUpdated:FireAllClients({
		type = itemType,
		itemId = itemId,
		userId = recipientUserId,
		username = recipientName,
	})
end

-- ═══════════════════════════════════════════════════════════════
-- CLEANUP
-- ═══════════════════════════════════════════════════════════════
Players.PlayerRemoving:Connect(function(player)
	-- Limpiar rate limit del jugador
	if _G.shopGiftingRateLimit then
		_G.shopGiftingRateLimit[player.UserId .. "_shopGifting"] = nil
	end
end)

-- ═══════════════════════════════════════════════════════════════
-- UTILIDADES PÚBLICAS
-- ═══════════════════════════════════════════════════════════════
local ShopGiftingServer = {}

function ShopGiftingServer.InvalidateOwnershipCache(userId, itemId)
	invalidateCache(userId, itemId)
end

function ShopGiftingServer.NotifyOwnershipChange(itemType, itemId, userId, username)
	OwnershipUpdated:FireAllClients({
		type = itemType,
		itemId = itemId,
		userId = userId,
		username = username,
	})
end

-- Exponer para otros scripts
_G.ShopGiftingServer = ShopGiftingServer

print("[ShopGifting] ✓ Sistema inicializado")

return ShopGiftingServer
