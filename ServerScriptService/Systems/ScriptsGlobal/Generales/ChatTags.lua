-- ========================================
-- SERVERSCRIPT (en ServerScriptService)
-- ========================================
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RemotesGlobal = ReplicatedStorage:WaitForChild("RemotesGlobal")
local MarketplaceService = game:GetService("MarketplaceService")
local DataStoreService = game:GetService("DataStoreService")

local configuration = require(game.ReplicatedStorage.Config.Configuration)

-- DataStore y cache para gamepasses
local GiftedGamepassesData = DataStoreService:GetDataStore("Gifting.1")
local GamepassCache = {}

-- Cache del servidor para tags
local serverTagCache = {}
local groupRoles = configuration.GroupRoles

local chatFolder = RemotesGlobal:WaitForChild("Chat")
local tagDataEvent = chatFolder:WaitForChild("PlayerTagData")
local remoteFunction = chatFolder:WaitForChild("CheckGamePass")

-- Función optimizada para verificar gamepasses (tu código integrado)
local function checkPlayerGamepasses(userId)
	-- Si ya está en cache, devolverlo
	if GamepassCache[userId] then
		return GamepassCache[userId]
	end

	local cacheEntry = {
		status = nil, -- "VIP" o nil
		lastChecked = os.time()
	}

	-- Verificar VIP
	local vipId = configuration.Gamepasses.VIP.id
	local successVIP, hasVIP = pcall(function()
		if MarketplaceService:UserOwnsGamePassAsync(userId, vipId) then
			return true
		end
		return GiftedGamepassesData:GetAsync(userId .. "-" .. vipId)
	end)

	if successVIP and hasVIP then
		cacheEntry.status = "VIP"
		GamepassCache[userId] = cacheEntry
		return cacheEntry
	end

	cacheEntry.status = nil
	GamepassCache[userId] = cacheEntry
	return cacheEntry
end

-- Función mejorada para obtener rank (SOLO en servidor)
local function getPlayerGroupRank(player)
	local groupId = tonumber(configuration.GroupID)

	-- Intentar método nativo primero (más rápido)
	local success, rank = pcall(function()
		return player:GetRankInGroupAsync(groupId)
	end)

	if success and rank > 0 then
		return rank
	end

	-- Fallback con HttpService solo si es necesario
	local httpSuccess, result = pcall(function()
		return HttpService:GetAsync("https://groups.roblox.com/v1/users/" .. player.UserId .. "/groups/roles")
	end)

	if httpSuccess then
		local data = HttpService:JSONDecode(result)
		for _, groupData in ipairs(data.data) do
			if tostring(groupData.group.id) == configuration.GroupID then
				return groupData.role.rank
			end
		end
	end

	return 0
end

-- Función para convertir Color3 a hex
local function color3ToHex(color)
	return string.format("#%02X%02X%02X", 
		math.round(color.R * 255), 
		math.round(color.G * 255), 
		math.round(color.B * 255)
	)
end

-- Función integrada para determinar tag completo
local function calculatePlayerTag(player)
	local userId = player.UserId

	-- Verificar cache del servidor
	if serverTagCache[userId] then
		return serverTagCache[userId]
	end

	local tagInfo = {}

	-- 1. Rango de grupo
	do
		local playerRank = getPlayerGroupRank(player)
		local roleData = groupRoles[playerRank]
		if roleData and playerRank >= 1 then -- Miembro hacia arriba
			local colorHex = color3ToHex(roleData.Color)
			local icon = roleData.Icon

			tagInfo = {
				Prefix = string.format("<font color='%s'>[%s]</font> <font color='%s'>%s</font> ",
					colorHex, icon, colorHex, roleData.Name),
				Priority = playerRank,
				HasSpecialTag = true,
				Source = "GROUP_RANK",
			}
		else
			-- 3. VIP GamePass
			local gamepassInfo = checkPlayerGamepasses(userId)

			if gamepassInfo and gamepassInfo.status == "VIP" then
				tagInfo = {
					Prefix = "<font color='#C500FF'>[👑]</font> <font color='#C500FF'>[VIP]</font> ",
					TextColor = "#C500FF",
					Priority = 5,
					HasSpecialTag = true,
					Source = "VIP_GAMEPASS"
				}
			else
				-- Tag por defecto
				tagInfo = {
					Prefix = "<font color='#AAAAAA'>[👤]</font> <font color='#AAAAAA'>[PLAYER]</font> ",
					TextColor = "#AAAAAA",
					Priority = 0,
					HasSpecialTag = false,
					Source = "DEFAULT"
				}
			end
		end
	end

	-- Guardar en cache del servidor
	serverTagCache[userId] = tagInfo

	return tagInfo
end

-- Verificar al unirse y al reaparecer el personaje (tu código integrado)
local function setupPlayer(player)
	-- 1. Calcular y enviar tag INMEDIATAMENTE (rango de grupo es síncrono)
	local tagInfo = calculatePlayerTag(player)
	tagDataEvent:FireAllClients(player.UserId, tagInfo)

	-- 2. Enviar tags de jugadores existentes al nuevo cliente
	for _, existingPlayer in ipairs(Players:GetPlayers()) do
		if existingPlayer ~= player and serverTagCache[existingPlayer.UserId] then
			tagDataEvent:FireClient(player, existingPlayer.UserId, serverTagCache[existingPlayer.UserId])
		end
	end

	-- 3. Verificar gamepasses en background y actualizar solo si cambia el tag
	task.spawn(function()
		checkPlayerGamepasses(player.UserId)
		task.wait(2)
		local oldTag = serverTagCache[player.UserId]
		serverTagCache[player.UserId] = nil
		local updatedTag = calculatePlayerTag(player)
		if oldTag and oldTag.Source ~= updatedTag.Source then
			tagDataEvent:FireAllClients(player.UserId, updatedTag)
		end
	end)

	player.CharacterAdded:Connect(function()
		serverTagCache[player.UserId] = nil
		GamepassCache[player.UserId] = nil
		task.wait(1)
		local newTagInfo = calculatePlayerTag(player)
		tagDataEvent:FireAllClients(player.UserId, newTagInfo)
	end)
end

Players.PlayerAdded:Connect(setupPlayer)

-- Limpiar ambos caches al desconectar
Players.PlayerRemoving:Connect(function(player)
	serverTagCache[player.UserId] = nil
	GamepassCache[player.UserId] = nil
end)

-- Para jugadores ya conectados cuando se inicia el script
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(function()
		local tagInfo = calculatePlayerTag(player)
		tagDataEvent:FireAllClients(player.UserId, tagInfo)
	end)
end

-- Manejar la invocación remota (tu código integrado - compatibilidad)
remoteFunction.OnServerInvoke = function(player, targetUserId)
	-- Si no está en cache, verificar ahora
	if not GamepassCache[targetUserId] then
		checkPlayerGamepasses(targetUserId)
	end

	-- Devolver el estado cacheado (puede ser nil)
	return GamepassCache[targetUserId] and GamepassCache[targetUserId].status
end

-- Función para forzar actualización de tag (útil para cambios de gamepass)
local function forceUpdatePlayerTag(player)
	-- Limpiar ambos caches
	serverTagCache[player.UserId] = nil
	GamepassCache[player.UserId] = nil

	-- Recalcular
	local tagInfo = calculatePlayerTag(player)

	-- Enviar actualización
	tagDataEvent:FireAllClients(player.UserId, tagInfo)

	--print("Tag forzado para", player.Name, ":", tagInfo.Source)
end

-- Event para actualizaciones manuales (opcional - para admins)
local updateTagEvent = chatFolder:WaitForChild("ForceUpdateTag")

updateTagEvent.OnServerEvent:Connect(function(player, targetUserId)
	-- Solo admins pueden forzar actualización
	local ok, rank = pcall(function() return player:GetRankInGroupAsync(tonumber(configuration.GroupID)) end)
	if ok and rank >= 255 then -- Admin o superior
		local targetPlayer = Players:GetPlayerByUserId(targetUserId)
		if targetPlayer then
			forceUpdatePlayerTag(targetPlayer)
		end
	end
end)