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
-- TEST USERS (datos pre-resueltos, 0 llamadas API = instantáneo)
-- ═══════════════════════════════════════════════════════════════
local USE_TEST_USERS = true
local TEST_USERS = {
	{ userId = 8471071247,  username = "ignxts0",             displayName = "UserData",          isPremium = true },
	{ userId = 3126383506,  username = "Jeniferx_xd",         displayName = "Jeniferx_xd",      isPremium = true },
	{ userId = 9764396115,  username = "AltSocratic",          displayName = "AltSocratic" },
	{ userId = 9673877,     username = "angelogarcia",         displayName = "angelogarcia" },
	{ userId = 8364521132,  username = "Jeny02093",            displayName = "Jeny12",            isPremium = true },
	{ userId = 8342896662,  username = "TsAlfred",             displayName = "KD_AlfreD" },
	{ userId = 2920297608,  username = "Fueg2oh",              displayName = "Alexan_L",          isPremium = true },
	{ userId = 4074563891,  username = "bvwdhfv",              displayName = "Manuel" },
	{ userId = 8307337692,  username = "Krizart16",            displayName = "Arturo_KOD",        isPremium = true },
	{ userId = 7225573626,  username = "JackFox188",           displayName = "DemonKr" },
	{ userId = 9333058985,  username = "FranckCazou",          displayName = "CXZOUxRAQUI" },
	{ userId = 3931737942,  username = "Rach_pr",              displayName = "Rach",              isPremium = true },
	{ userId = 8109061566,  username = "GalletaDeAgua20",      displayName = "DeseadoP_INF" },
	{ userId = 2888323694,  username = "ThealexGamesYTOF",     displayName = "DJ_Poolexx" },
	{ userId = 1413370554,  username = "tfifa20",              displayName = "tfifa20",           isPremium = true },
	{ userId = 5819550352,  username = "xlm_brem",             displayName = "Owner_SoyDeLuana" },
	{ userId = 3602855856,  username = "itzjheiner",           displayName = "OwnerJheiner_HFZ" },
	{ userId = 5295409243,  username = "SCISSORSV7",           displayName = "Agus_ROSxREL" },
	{ userId = 8914937246,  username = "Xandroquis",           displayName = "Xandro_CoOwnerMG" },
	{ userId = 7247625721,  username = "suzu1k",               displayName = "suzu" },
	{ userId = 8812902108,  username = "JuanMVP36",            displayName = "DonJuan",           isPremium = true },
	{ userId = 7904861114,  username = "Fercho_ZP",            displayName = "EDXXN_TKG" },
	{ userId = 197012474,   username = "ClasicSans738",        displayName = "SL1_ClassicDev" },
	{ userId = 5713127491,  username = "ISMAXXX77",            displayName = "uliiiii" },
	{ userId = 1629407842,  username = "tulobitajanethalexa",   displayName = "ale_nena" },
	{ userId = 9458202259,  username = "caramandungap",        displayName = "JzzzxHellen_MG" },
}

local function getTestUsersForGifting(requestingPlayer)
	local out = {}
	for _, user in ipairs(TEST_USERS) do
		if user.userId ~= requestingPlayer.UserId then
			table.insert(out, {
				userId      = user.userId,
				username    = user.username,
				displayName = user.displayName,
				isPremium   = user.isPremium or false,
			})
		end
	end
	table.sort(out, function(a, b)
		return a.displayName:lower() < b.displayName:lower()
	end)
	return out
end

-- ═══════════════════════════════════════════════════════════════
-- CACHE
-- ═══════════════════════════════════════════════════════════════
local ownershipCache = {} -- [userId-itemId] = {owns = bool, timestamp = tick()}
local CACHE_DURATION = 300 -- 5 minutos (se invalida por eventos de compra/regalo)

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
-- PRE-CACHE: Calentar ownership al entrar un jugador
-- ═══════════════════════════════════════════════════════════════
local ALL_ITEM_IDS = {}
do
	for _, gp in pairs(Configuration.Gamepasses) do
		table.insert(ALL_ITEM_IDS, gp.id)
	end
	for _, title in ipairs(TitleConfig) do
		if title.gamepassId then
			table.insert(ALL_ITEM_IDS, title.gamepassId)
		end
	end
end

local function warmOwnershipCache(player)
	for _, itemId in ipairs(ALL_ITEM_IDS) do
		task.spawn(function()
			checkGamepassOwnership(player.UserId, itemId)
		end)
	end
end

-- Calentar para jugadores que ya estén en el servidor
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(warmOwnershipCache, player)
end

Players.PlayerAdded:Connect(function(player)
	task.spawn(warmOwnershipCache, player)
end)

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
					isPremium = targetPlayer.MembershipType == Enum.MembershipType.Premium,
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
	-- Limpiar cache de ownership del jugador
	for _, itemId in ipairs(ALL_ITEM_IDS) do
		ownershipCache[getCacheKey(player.UserId, itemId)] = nil
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
