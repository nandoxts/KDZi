-- ════════════════════════════════════════════════════════════════
-- USER PANEL SERVER - v4.0 (Background-Optimized)
-- ════════════════════════════════════════════════════════════════
--[[
	Cambios vs v3:
	• Group icon se fetchea 1 SOLA VEZ al entrar (PlayerAdded)
	• Caché de groupIcon permanente por sesión
	• Stats se refrescan en background cada 60s
	• HTTP calls en paralelo (~200ms vs ~1s)
	• Inflight guard evita fetches duplicados
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")
local DataStoreService = game:GetService("DataStoreService")

local UNIVERSE_ID = game.GameId
local PLACE_ID = game.PlaceId

local LikesDataStore = DataStoreService:GetDataStore("LikesData")

local SysConfig = require(game.ReplicatedStorage.Config.Configuration)

-- ═══════════════════════════════════════════════════════════════
-- CONFIGURACIÓN
-- ═══════════════════════════════════════════════════════════════

local CONFIG = {
	STATS_CACHE_TIME = 60,
	DONATIONS_CACHE_TIME = 120,
	MAX_GAMES_TO_SEARCH = 5,
	HTTP_DELAY = 0.1,
	MAX_ITEMS_TO_SHOW = 15,
	MAX_ITEMS_TO_VALIDATE = 10,

	FRIENDS_API = "https://friends.roproxy.com/v1/users/",
	GAMES_API = "https://games.roproxy.com/v2/users/",
	PASSES_API = "https://apis.rotunnel.com/game-passes/v1/universes/",
	GROUPS_API = "https://groups.roproxy.com/v1/users/",
}

-- ═══════════════════════════════════════════════════════════════
-- REMOTES
-- ═══════════════════════════════════════════════════════════════

local remotesGlobal   = ReplicatedStorage:WaitForChild("RemotesGlobal")
local userPanelFolder = remotesGlobal:WaitForChild("UserPanel")

local GetUserData      = userPanelFolder:WaitForChild("GetUserData")
local RefreshUserData  = userPanelFolder:WaitForChild("RefreshUserData")
local GetUserDonations = userPanelFolder:WaitForChild("GetUserDonations")
local CheckGamePass    = userPanelFolder:WaitForChild("CheckGamePass")

local LikesEvents = remotesGlobal:WaitForChild("LikesEvents")

-- ═══════════════════════════════════════════════════════════════
-- CACHÉ
-- ═══════════════════════════════════════════════════════════════

local Cache = {
	stats = {},         -- Stats temporales (30s TTL)
	groupIcons = {},    -- Group icons PERMANENTES (1 vez por sesión)
	donations = {},
	inflight = {},      -- Anti-duplicados: userId = { waiting = {threads...} }
}

local function checkPlayerGamePass(player, passId)
	if not player or not passId then return false end

	local folder = player:FindFirstChild("Gamepasses")
	if folder then
		local success, info = pcall(function()
			return MarketplaceService:GetProductInfo(passId, Enum.InfoType.GamePass)
		end)

		if success and info then
			for _, child in pairs(folder:GetChildren()) do
				if child:IsA("BoolValue") and child.Name == info.Name and child.Value then
					return true
				end
			end
		end
	end

	local owns = false
	pcall(function()
		owns = MarketplaceService:UserOwnsGamePassAsync(player.UserId, passId)
	end)

	return owns
end

local function isCacheValid(cacheEntry, maxAge)
	if not cacheEntry then return false end
	return os.time() - cacheEntry.timestamp < maxAge
end

-- ═══════════════════════════════════════════════════════════════
-- HTTP
-- ═══════════════════════════════════════════════════════════════

local function httpGet(url)
	local success, result = pcall(function()
		local response = HttpService:GetAsync(url)
		return HttpService:JSONDecode(response)
	end)

	if not success then
		warn("[UserPanel] HTTP Error:", result)
		return nil
	end

	return result
end

-- ═══════════════════════════════════════════════════════════════
-- LIKES
-- ═══════════════════════════════════════════════════════════════

local function getTotalLikes(userId)
	local player = Players:FindFirstChild(tostring(userId))
	if player then
		return player:GetAttribute("TotalLikes") or 0
	end

	local success, data = pcall(function()
		return LikesDataStore:GetAsync("Player_" .. userId)
	end)

	if success and data and data.TotalLikes then
		return data.TotalLikes
	end

	return 0
end

-- ═══════════════════════════════════════════════════════════════
-- GROUP ICON (1 SOLA VEZ POR SESIÓN)
-- ═══════════════════════════════════════════════════════════════

local function getUserGroupIcon(userId)
	-- Si ya lo tenemos cacheado (incluso si es nil), retornar
	if Cache.groupIcons[userId] ~= nil then
		-- Usamos un wrapper: { icon = string|nil, loaded = true }
		return Cache.groupIcons[userId].icon
	end

	-- Fetch 1 sola vez
	local data = httpGet(CONFIG.GROUPS_API .. userId .. "/groups/primary/role")
	local icon = nil

	if data and data.group and data.group.id then
		icon = "rbxthumb://type=GroupIcon&id=" .. tostring(data.group.id) .. "&w=420&h=420"
	end

	-- Guardar permanentemente (incluso si es nil, para no re-intentar)
	Cache.groupIcons[userId] = { icon = icon, loaded = true }

	return icon
end

-- ═══════════════════════════════════════════════════════════════
-- ESTADÍSTICAS
-- ═══════════════════════════════════════════════════════════════

-- Fetch interno (sin guard, solo lo llama getUserStats)
local function _fetchUserStats(userId)
	local stats = {
		followers = 0,
		friends = 0,
		likes = 0,
		isVip = false,
		groupIcon = nil,
	}

	-- ═══ PARALELO: solo lo necesario ═══
	-- followers + friends = 2 HTTP calls
	-- VIP = MarketplaceService (no cuenta como HTTP)
	-- likes = atributo local (0 calls)
	local completed = 0
	local total = 3

	task.spawn(function()
		local data = httpGet(CONFIG.FRIENDS_API .. userId .. "/followers/count")
		if data and data.count then stats.followers = data.count end
		completed += 1
	end)

	task.spawn(function()
		local data = httpGet(CONFIG.FRIENDS_API .. userId .. "/friends/count")
		if data and data.count then stats.friends = data.count end
		completed += 1
	end)

	task.spawn(function()
		local targetPlayer = Players:GetPlayerByUserId(userId)
		if targetPlayer then
			stats.isVip = checkPlayerGamePass(targetPlayer, SysConfig.Gamepasses.VIP.id)
		else
			pcall(function()
				stats.isVip = MarketplaceService:UserOwnsGamePassAsync(userId, SysConfig.Gamepasses.VIP.id)
			end)
		end
		completed += 1
	end)

	stats.likes = getTotalLikes(userId)

	-- Esperar (máx 4s timeout)
	local startTime = tick()
	while completed < total and (tick() - startTime) < 4 do
		task.wait(0.05)
	end

	Cache.stats[userId] = { data = stats, timestamp = os.time() }
	return stats
end

-- Guard: si ya hay un fetch en curso para este userId, esperar ese resultado
local function getUserStats(userId)
	local data

	-- 1. Caché válido → retornar inmediato
	local cached = Cache.stats[userId]
	if isCacheValid(cached, CONFIG.STATS_CACHE_TIME) then
		data = cached.data
	end

	-- 2. Ya hay un fetch en curso → esperar que termine
	if not data and Cache.inflight[userId] then
		local startWait = tick()
		while Cache.inflight[userId] and (tick() - startWait) < 5 do
			task.wait(0.05)
		end
		local fresh = Cache.stats[userId]
		if fresh then data = fresh.data end
	end

	-- 3. Nada en caché → fetchear
	if not data then
		Cache.inflight[userId] = true
		local ok, result = pcall(_fetchUserStats, userId)
		Cache.inflight[userId] = nil

		if ok then
			data = result
		else
			warn("[UserPanel] Error fetching stats:", result)
			data = { followers = 0, friends = 0, likes = 0, isVip = false, groupIcon = nil }
		end
	end

	-- SIEMPRE adjuntar groupIcon del caché permanente (puede haberse cargado después)
	if data.isVip and Cache.groupIcons[userId] then
		data.groupIcon = Cache.groupIcons[userId].icon
	end

	return data
end

-- ═══════════════════════════════════════════════════════════════
-- GAME PASSES VIA API (donaciones)
-- ═══════════════════════════════════════════════════════════════

local function getGamePassesFromAPI(universeId)
	local passes = {}
	local nextPageToken = ""

	repeat
		local url = CONFIG.PASSES_API .. universeId .. "/game-passes?passView=Full&pageSize=100"
		if nextPageToken ~= "" then
			url = url .. "&pageToken=" .. nextPageToken
		end

		local data = httpGet(url)
		if not data or not data.gamePasses then break end

		for _, pass in ipairs(data.gamePasses) do
			if pass.price and pass.price > 0 and pass.id then
				local iconId = pass.displayIconImageAssetId or 0
				table.insert(passes, {
					passId = pass.id,
					productId = pass.id,
					name = pass.displayName or pass.name or "Pass",
					price = pass.price,
					icon = iconId > 0 and ("rbxassetid://" .. tostring(iconId)) or ""
				})
			end
		end

		nextPageToken = data.nextPageToken or ""
	until nextPageToken == ""

	return passes
end

-- ═══════════════════════════════════════════════════════════════
-- DONACIONES
-- ═══════════════════════════════════════════════════════════════

local function getUserGames(userId)
	local games = {}
	local cursor = ""

	repeat
		local url = CONFIG.GAMES_API .. userId .. "/games?accessFilter=Public&limit=50"
		if cursor ~= "" then
			url = url .. "&cursor=" .. cursor
		end

		local data = httpGet(url)
		if not data or not data.data then break end

		for _, game in ipairs(data.data) do
			table.insert(games, { universeId = game.id, name = game.name })
		end

		cursor = data.nextPageCursor or ""
	until cursor == ""

	return games
end

local function getUserDonations(userId)
	local cached = Cache.donations[userId]
	if isCacheValid(cached, CONFIG.DONATIONS_CACHE_TIME) then
		return cached.data
	end

	local allPasses = {}
	local games = getUserGames(userId)
	local gamesToSearch = math.min(#games, CONFIG.MAX_GAMES_TO_SEARCH)

	for i = 1, gamesToSearch do
		local game = games[i]
		local passes = getGamePassesFromAPI(game.universeId)

		for _, pass in ipairs(passes) do
			table.insert(allPasses, pass)
		end

		if i < gamesToSearch then
			task.wait(CONFIG.HTTP_DELAY)
		end
	end

	table.sort(allPasses, function(a, b) return a.price < b.price end)
	Cache.donations[userId] = { data = allPasses, timestamp = os.time() }

	return allPasses
end

-- ═══════════════════════════════════════════════════════════════
-- HANDLERS
-- ═══════════════════════════════════════════════════════════════

GetUserData.OnServerInvoke = function(_, targetUserId)
	return getUserStats(targetUserId)
end

RefreshUserData.OnServerEvent:Connect(function(requestingPlayer, targetUserId)
	Cache.stats[targetUserId] = nil
	local freshData = getUserStats(targetUserId)
	RefreshUserData:FireClient(requestingPlayer, freshData)
end)

GetUserDonations.OnServerInvoke = function(player, targetUserId)
	if not targetUserId or not player then return {} end
	local ok, donations = pcall(getUserDonations, targetUserId)
	if not ok then
		warn("[UserPanel] Error en getUserDonations:", donations)
		return {}
	end

	if #donations > CONFIG.MAX_ITEMS_TO_SHOW then
		local limited = {}
		for i = 1, CONFIG.MAX_ITEMS_TO_SHOW do
			table.insert(limited, donations[i])
		end
		donations = limited
	end

	if player and donations and #donations > 0 then
		local toValidate = math.min(#donations, CONFIG.MAX_ITEMS_TO_VALIDATE)
		local completed = 0

		for i = 1, toValidate do
			local donation = donations[i]
			task.spawn(function()
				donation.hasPass = checkPlayerGamePass(player, donation.passId)
				completed = completed + 1
			end)
		end

		for i = toValidate + 1, #donations do
			donations[i].hasPass = nil
		end

		local startTime = tick()
		while completed < toValidate and (tick() - startTime) < 3 do
			task.wait(0.05)
		end
	end

	return donations
end

CheckGamePass.OnServerInvoke = function(player, passId, targetUserId)
	if not passId then return false end

	local playerToCheck = player
	if targetUserId then
		playerToCheck = Players:GetPlayerByUserId(targetUserId)
		if not playerToCheck then return false end
	end

	if not playerToCheck then return false end
	return checkPlayerGamePass(playerToCheck, passId)
end

-- ═══════════════════════════════════════════════════════════════
-- INVALIDAR CACHÉ DE LIKES
-- ═══════════════════════════════════════════════════════════════

local function invalidateStatsCache(userId)
	Cache.stats[userId] = nil
end

if LikesEvents then
	local GiveLikeEvent = LikesEvents:FindFirstChild("GiveLikeEvent")
	local GiveSuperLikeEvent = LikesEvents:FindFirstChild("GiveSuperLikeEvent")

	if GiveLikeEvent then
		GiveLikeEvent.OnServerEvent:Connect(function(player, action, targetUserId)
			if action == "GiveLike" and targetUserId then
				task.delay(0.5, function()
					invalidateStatsCache(targetUserId)
				end)
			end
		end)
	end

	if GiveSuperLikeEvent then
		GiveSuperLikeEvent.OnServerEvent:Connect(function(player, action, targetUserId)
			if action == "GiveSuperLike" and targetUserId then
				task.delay(0.5, function()
					invalidateStatsCache(targetUserId)
				end)
			end
		end)
	end
end

-- Limpiar caché permanente cuando el jugador sale
Players.PlayerRemoving:Connect(function(leavingPlayer)
	local uid = leavingPlayer.UserId
	Cache.stats[uid] = nil
	Cache.groupIcons[uid] = nil
	Cache.donations[uid] = nil
end)

-- ═══════════════════════════════════════════════════════════════
-- BACKGROUND PRE-CACHE (el server mantiene la data fresca)
-- ═══════════════════════════════════════════════════════════════

local BG_REFRESH_INTERVAL = 60   -- Debe coincidir con STATS_CACHE_TIME
local BG_LOOP_DELAY = 15         -- Espera entre ciclos completos

-- Pre-cargar data de un jugador (si el caché expiró)
local function preloadPlayer(targetPlayer)
	local userId = targetPlayer.UserId
	local cached = Cache.stats[userId]
	if isCacheValid(cached, BG_REFRESH_INTERVAL) then return end

	pcall(getUserStats, userId)
end

-- Cuando entra un jugador: pre-cargar stats + groupIcon (1 SOLA VEZ)
Players.PlayerAdded:Connect(function(newPlayer)
	task.delay(1, function()
		-- Stats
		pcall(preloadPlayer, newPlayer)

		-- GroupIcon: 1 sola vez, se guarda permanente en Cache.groupIcons
		-- getUserGroupIcon internamente cachea y no repite
		local userId = newPlayer.UserId
		local stats = Cache.stats[userId] and Cache.stats[userId].data
		if stats and stats.isVip then
			pcall(getUserGroupIcon, userId)
		end
	end)
end)

-- Loop de background que mantiene el caché fresco
task.spawn(function()
	task.wait(2) -- Esperar a que el server arranque

	-- Primer ciclo: cargar stats + groupIcon (1 sola vez) para todos
	for _, p in ipairs(Players:GetPlayers()) do
		task.spawn(function()
			pcall(preloadPlayer, p)
			-- GroupIcon 1 vez para VIPs ya presentes
			local userId = p.UserId
			local stats = Cache.stats[userId] and Cache.stats[userId].data
			if stats and stats.isVip and not Cache.groupIcons[userId] then
				pcall(getUserGroupIcon, userId)
			end
		end)
		task.wait(0.2)
	end

	-- Ciclos siguientes: solo stats (groupIcon ya está)
	while true do
		task.wait(BG_LOOP_DELAY)

		for _, p in ipairs(Players:GetPlayers()) do
			task.spawn(preloadPlayer, p)
			task.wait(1)
		end
	end
end)

-- ═══════════════════════════════════════════════════════════════
-- INICIO
-- ═══════════════════════════════════════════════════════════════