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

local LikesDataStore = DataStoreService:GetDataStore("LikesDatav2")

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
	BG_LOOP_DELAY = 15,

	FRIENDS_API = "https://friends.roproxy.com/v1/users/",
	GAMES_API = "https://games.roproxy.com/v2/users/",
	PASSES_API = "https://apis.roproxy.com/game-passes/v1/universes/",
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

local LikesEvents = remotesGlobal:WaitForChild("LikesEvents")

-- ═══════════════════════════════════════════════════════════════
-- CACHÉ
-- ═══════════════════════════════════════════════════════════════

local Cache = {
	stats = {},         -- Stats temporales (60s TTL)
	groupIcons = {},    -- Group icons PERMANENTES (1 vez por sesión)
	donations = {},
	inflight = {},      -- Anti-duplicados: userId = true mientras fetchea
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
	local player = Players:GetPlayerByUserId(userId)
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
	if type(targetUserId) ~= "number" then return {} end
	return getUserStats(targetUserId)
end

RefreshUserData.OnServerEvent:Connect(function(requestingPlayer, targetUserId)
	if type(targetUserId) ~= "number" then return end
	Cache.stats[targetUserId] = nil
	local freshData = getUserStats(targetUserId)
	RefreshUserData:FireClient(requestingPlayer, freshData)
end)

GetUserDonations.OnServerInvoke = function(player, targetUserId)
	if not player or type(targetUserId) ~= "number" then return {} end
	local ok, srcDonations = pcall(getUserDonations, targetUserId)
	if not ok then
		warn("[UserPanel] Error en getUserDonations:", srcDonations)
		return {}
	end

	-- Copia shallow para no mutar el caché con hasPass de otro jugador
	local donations = {}
	local limit = math.min(#srcDonations, CONFIG.MAX_ITEMS_TO_SHOW)
	for i = 1, limit do
		local src = srcDonations[i]
		donations[i] = {
			passId = src.passId,
			productId = src.productId,
			name = src.name,
			price = src.price,
			icon = src.icon,
		}
	end

	if #donations > 0 then
		local toValidate = math.min(#donations, CONFIG.MAX_ITEMS_TO_VALIDATE)
		local completed = 0

		for i = 1, toValidate do
			local donation = donations[i]
			task.spawn(function()
				donation.hasPass = checkPlayerGamePass(player, donation.passId)
				completed = completed + 1
			end)
		end

		local startTime = tick()
		while completed < toValidate and (tick() - startTime) < 3 do
			task.wait(0.05)
		end
	end

	return donations
end

-- ═══════════════════════════════════════════════════════════════
-- INVALIDAR CACHÉ DE LIKES
-- ═══════════════════════════════════════════════════════════════

if LikesEvents then
	for _, eventName in ipairs({"GiveLikeEvent", "GiveSuperLikeEvent"}) do
		local event = LikesEvents:FindFirstChild(eventName)
		if event then
			event.OnServerEvent:Connect(function(_, _, targetUserId)
				if type(targetUserId) == "number" then
					task.delay(0.5, function()
						Cache.stats[targetUserId] = nil
					end)
				end
			end)
		end
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

local function preloadPlayer(player)
	local userId = player.UserId
	if isCacheValid(Cache.stats[userId], CONFIG.STATS_CACHE_TIME) then return end
	pcall(getUserStats, userId)
end

local function preloadGroupIcon(userId)
	local cached = Cache.stats[userId]
	if cached and cached.data and cached.data.isVip then
		pcall(getUserGroupIcon, userId)
	end
end

Players.PlayerAdded:Connect(function(newPlayer)
	task.delay(1, function()
		pcall(preloadPlayer, newPlayer)
		preloadGroupIcon(newPlayer.UserId)
	end)
end)

task.spawn(function()
	task.wait(2)

	for _, p in ipairs(Players:GetPlayers()) do
		task.spawn(function()
			pcall(preloadPlayer, p)
			preloadGroupIcon(p.UserId)
		end)
		task.wait(0.2)
	end

	while true do
		task.wait(CONFIG.BG_LOOP_DELAY)
		for _, p in ipairs(Players:GetPlayers()) do
			task.spawn(preloadPlayer, p)
			task.wait(1)
		end
	end
end)

-- ═══════════════════════════════════════════════════════════════
-- INICIO
-- ═══════════════════════════════════════════════════════════════

