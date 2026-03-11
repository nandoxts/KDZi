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
-- TEST USERS (por username @...)
-- ═══════════════════════════════════════════════════════════════
local USE_TEST_USERS = true
local TEST_USERNAMES = {
	"ignxts0",
	"Jeniferx_xd",
	"AltSocratic",
	"AngeloGarcia",
	"Jeny02093",
	"User_JL11",
	"TsAlfred",
	"Fueg2oh",
	"bvwdhfv",
	"kirikin113",
	"Krizart16",
	"JackFox188",
	"FranckCazou",
	"Rach_pr",
	"GalletaDeAgua20",
	"adrilivn",
	"ThealexGamesYTOF",
	"Tfifa20",
	"xlm_brem",
	"itzjheiner",
	"SCISSORSV7",
	"Xandroquis",
	"suzu1k",
	"JuanMVP36",
	"Fercho_ZP",
	"ClasicSans738",
	"Ismaxxx77",
	"tulobitajanethalexa",
	"caramandungap",
	"ISASIO220",
}

local function normalizeUsername(raw)
	if type(raw) ~= "string" then return nil end
	local cleaned = raw:gsub("@", ""):gsub("%s+", "")
	if cleaned == "" then return nil end
	return cleaned
end

local function getTestUsersForGifting(requestingPlayer)
	local out = {}
	for _, rawName in ipairs(TEST_USERNAMES) do
		local username = normalizeUsername(rawName)
		if username then
			local ok, userId = pcall(function()
				return Players:GetUserIdFromNameAsync(username)
			end)
			if ok and userId and userId > 0 and userId ~= requestingPlayer.UserId then
				table.insert(out, {
					userId = userId,
					username = username,
					displayName = username,
				})
			else
				warn("[ShopGifting] Usuario de prueba inválido/no resuelto:", tostring(rawName))
			end
		end
	end

	table.sort(out, function(a, b)
		return (a.displayName or ""):lower() < (b.displayName or ""):lower()
	end)

	return out
end

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

	if USE_TEST_USERS then
		local testPlayers = getTestUsersForGifting(requestingPlayer)
		return {
			success = true,
			players = testPlayers,
			total = #testPlayers,
			isTestMode = true,
		}
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
