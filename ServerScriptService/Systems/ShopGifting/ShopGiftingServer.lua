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

-- ═══════════════════════════════════════════════════════════════
-- SETUP
-- ═══════════════════════════════════════════════════════════════
local Configuration = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("Configuration"))
local ShopManager = require(game.ServerScriptService.Systems.GiftManager.ShopManager)

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
-- CACHE (evita llamadas repetidas en un mismo request batch)
-- ═══════════════════════════════════════════════════════════════
local ownershipCache = {} -- [userId-itemId] = {owns = bool, timestamp = tick()}
local CACHE_DURATION = 300

local function getCacheKey(userId, itemId)
	return userId .. "-" .. itemId
end

local function invalidateCache(userId, itemId)
	ownershipCache[getCacheKey(userId, itemId)] = nil
end

local function checkOwnership(userId, itemId)
	local key = getCacheKey(userId, itemId)
	local cached = ownershipCache[key]
	if cached and (tick() - cached.timestamp) < CACHE_DURATION then
		return cached.owns
	end
	local owns = ShopManager.HasGamepassByUserId(userId, itemId)
	ownershipCache[key] = { owns = owns, timestamp = tick() }
	return owns
end

-- ═══════════════════════════════════════════════════════════════
-- PRE-CACHE: Calentar ownership al entrar un jugador
-- ═══════════════════════════════════════════════════════════════
local ALL_ITEM_IDS = {}
do
	for _, gp in pairs(Configuration.Gamepasses) do
		table.insert(ALL_ITEM_IDS, gp.id)
	end
end

local function warmCache(player)
	for _, itemId in ipairs(ALL_ITEM_IDS) do
		task.spawn(function()
			checkOwnership(player.UserId, itemId)
		end)
	end
end

for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(warmCache, player)
end

Players.PlayerAdded:Connect(function(player)
	task.spawn(warmCache, player)
end)

-- ═══════════════════════════════════════════════════════════════
-- GET PLAYERS WITHOUT ITEM
-- ═══════════════════════════════════════════════════════════════
local function getPlayersWithoutItem(requestingPlayer, itemType, itemId)
	if not requestingPlayer or not itemType or not itemId then
		return { success = false, error = "Parámetros inválidos" }
	end

	local allPlayers = Players:GetPlayers()
	local results = {} -- [index] = { data = ..., owns = bool }
	local pending = 0

	for i, targetPlayer in ipairs(allPlayers) do
		if targetPlayer.UserId ~= requestingPlayer.UserId then
			pending = pending + 1
			local idx = i
			local tp = targetPlayer
			task.spawn(function()
				local owns = checkOwnership(tp.UserId, itemId)
				results[idx] = {
					owns = owns,
					data = {
						userId = tp.UserId,
						username = tp.Name,
						displayName = tp.DisplayName or tp.Name,
						isPremium = tp.MembershipType == Enum.MembershipType.Premium,
					},
				}
				pending = pending - 1
			end)
		end
	end

	-- Esperar a que todos los checks terminen (max 8s safety)
	local deadline = tick() + 8
	while pending > 0 and tick() < deadline do
		task.wait(0.05)
	end

	local playersWithout = {}
	for _, entry in pairs(results) do
		if not entry.owns then
			table.insert(playersWithout, entry.data)
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
-- HOOKS: INVALIDAR CACHE CUANDO CAMBIA OWNERSHIP
-- ═══════════════════════════════════════════════════════════════

-- Hook para cuando se regala o compra un item (llamado desde GiftGamepass.lua)
_G.ShopGifting_OnItemGifted = function(recipientUserId, itemType, itemId)
	invalidateCache(recipientUserId, itemId)

	local recipientName = "Usuario"
	pcall(function()
		recipientName = Players:GetNameFromUserIdAsync(recipientUserId)
	end)

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

return ShopGiftingServer
