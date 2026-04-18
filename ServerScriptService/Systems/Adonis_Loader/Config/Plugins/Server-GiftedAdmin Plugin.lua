--[[
	Server-GiftedAdmin Plugin
	══════════════════════════════════════════════════════════════
	Problema: Adonis usa "GamePass:ID" → consulta MarketplaceService.
	Los gamepasses REGALADOS viven en DataStore "Gifting.1" y Adonis no los ve.

	Este plugin:
	1. Al unirse un jugador, revisa DataStore por gamepasses regalados
	2. Si encuentra alguno, agrega al jugador al rank correspondiente
	3. Expone _G.Adonis_SyncAdmin(userId, gamepassId) para mid-session
	   (compras directas y regalos en tiempo real)
]]

return function(Vargs)
	local server, service = Vargs.Server, Vargs.Service
	local DataStoreService = game:GetService("DataStoreService")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Players = game:GetService("Players")

	local Configuration = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("Configuration"))
	local GiftedData = DataStoreService:GetDataStore("Gifting.1")

	-- ═══════════════════════════════════════════════════════════
	-- Mapa: gamepassId → { rankName, level }
	-- ═══════════════════════════════════════════════════════════
	local gpToRank = {}
	for _, entry in ipairs(Configuration.AdminRanksByGamepass) do
		local gp = Configuration.Gamepasses[entry.Gamepass]
		if gp then
			gpToRank[gp.id] = { name = entry.Name, level = entry.Level }
		end
	end

	-- ═══════════════════════════════════════════════════════════
	-- Agregar jugador al rank de Adonis y re-evaluar permisos
	-- ═══════════════════════════════════════════════════════════
	local function grantRank(player, rankName)
		local ranks = server.Settings.Ranks
		if not ranks or not ranks[rankName] then
			warn("[GiftedAdmin] Rank no encontrado:", rankName)
			return false
		end

		local userStr = player.Name .. ":" .. tostring(player.UserId)
		local users = ranks[rankName].Users

		-- Verificar si ya está en la lista
		for _, u in ipairs(users) do
			if u == userStr then
				pcall(function() server.Admin.DoCheck(player) end)
				return true
			end
		end

		-- Agregar y re-evaluar
		table.insert(users, userStr)
		pcall(function() server.Admin.DoCheck(player) end)
		return true
	end

	-- ═══════════════════════════════════════════════════════════
	-- Verificar DataStore de regalos y otorgar rangos
	-- ═══════════════════════════════════════════════════════════
	local function syncGiftedAdmin(player)
		for gpId, rankInfo in pairs(gpToRank) do
			local ok, gifted = pcall(function()
				return GiftedData:GetAsync(player.UserId .. "-" .. gpId)
			end)
			if ok and gifted then
				grantRank(player, rankInfo.name)
			end
		end
	end

	-- ═══════════════════════════════════════════════════════════
	-- Al unirse un jugador (esperar que Adonis termine su check)
	-- ═══════════════════════════════════════════════════════════
	Players.PlayerAdded:Connect(function(player)
		task.delay(5, function()
			if player.Parent then
				syncGiftedAdmin(player)
			end
		end)
	end)

	-- Jugadores que ya están en el server al cargar el plugin
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(function()
			syncGiftedAdmin(player)
		end)
	end

	-- ═══════════════════════════════════════════════════════════
	-- API Global: mid-session updates
	-- Llamado desde GAMEPASS_MANAGER cuando se regala o compra
	-- ═══════════════════════════════════════════════════════════
	_G.Adonis_SyncAdmin = function(userId, gamepassId)
		local player = Players:GetPlayerByUserId(userId)
		if not player then return end

		if gamepassId then
			-- Regalo o compra de un gamepass específico
			local rankInfo = gpToRank[gamepassId]
			if rankInfo then
				grantRank(player, rankInfo.name)
			end
		end

		-- Siempre re-check general (cubre compras directas que Adonis detecta por MarketplaceService)
		pcall(function() server.Admin.DoCheck(player) end)
	end

	print("[GiftedAdmin] Plugin cargado - gamepasses regalados sincronizados con Adonis")
end
