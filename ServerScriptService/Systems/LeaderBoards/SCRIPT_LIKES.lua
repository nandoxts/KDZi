-- SERVICES --
local DatastoreService = game:GetService('DataStoreService')
local BadgeService = game:GetService("BadgeService")
local Players = game:GetService('Players')

-- Módulo central
local Configuration = require(game.ReplicatedStorage.Config.Configuration)

local ID_BADGE = Configuration.BADGES_TopLikes

-- VARIABLES --
local LEADERBOARD_COUNT = 50
local Datastore = DatastoreService:GetOrderedDataStore('TopLikes')
local likesCache = {}
local cacheDb = {}
local lastLikesUpdate = 0
local CACHE_TTL = 300 -- 5 minutos

local Leaderboard = workspace.LeaderBoards.Leaderboards.LikesLeaderboard
local Container = Leaderboard.SurfaceGui.Container
local Scrolling = Container.TopsContainer.TopsScrolling
local Template = Scrolling.Template

local Model = workspace.LeaderBoards.Leaderboards.LikesModel
local UserTag = Model.HumanoidRootPart.UserTag
local UsernameLabel = UserTag.Username

-- Almacenar información de los jugadores que ya recibieron el badge
local TopPlayersCache = {}

-- FUNCIONES UTILES --
local function FormatNumber(Amount)
	local formatted = tostring(Amount)
	while true do  
		local k
		formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
		if (k==0) then break end
	end
	return formatted
end

-- Función para verificar si un jugador ya tiene el badge
local function CheckBadgeOwnership(playerUserId)
	local success, hasBadge = pcall(function()
		return BadgeService:UserHasBadgeAsync(playerUserId, ID_BADGE)
	end)

	return success and hasBadge
end

-- Función para otorgar badge al jugador top 1
local function AwardTopBadge(playerUserId)
	-- Si ya lo tenemos cacheado, no repetimos
	if TopPlayersCache[playerUserId] then
		return
	end

	-- Verificar si realmente ya tiene el badge en Roblox
	if CheckBadgeOwnership(playerUserId) then
		TopPlayersCache[playerUserId] = true
		return
	end

	-- Verificar si el jugador está en el juego
	local player = Players:GetPlayerByUserId(playerUserId)
	if player then
		-- Intentar otorgar el badge
		local success, error = pcall(function()
			BadgeService:AwardBadgeAsync(player.UserId, ID_BADGE)
		end)

		if success then
			TopPlayersCache[playerUserId] = true
			--print(string.format("[BADGE] Otorgado badge TopLikes a %s (UserId: %d)", player.Name, player.UserId))
		else
			--warn(string.format("[BADGE] Error al otorgar badge a %s: %s", player.Name, error))
		end
	else
		-- Si no está en el juego, simplemente cacheamos para no repetir
		TopPlayersCache[playerUserId] = true
	end
end

-- Actualizar un item en el leaderboard
local function AddItem(Rank, Data)
	if not Scrolling:FindFirstChild(tostring(Data.key)) then
		local NewTemplate = Template:Clone()
		local Info = NewTemplate:WaitForChild('Info')
		local NameLabel = Info:WaitForChild('Name'):WaitForChild('TextLabel')
		NameLabel.Text = 'Cargando...'

		-- Obtener nombre del jugador
		local playerName = "Jugador Desconocido"
		local success, error = pcall(function()
			playerName = Players:GetNameFromUserIdAsync(Data.key)
		end)

		if not success then
			--warn(string.format("[LEADERBOARD] Error al obtener nombre para userId %d: %s", Data.key, error))
			playerName = "Usuario " .. tostring(Data.key)
		end

		NameLabel.Text = playerName

		-- Si es el primer lugar, actualizar el modelo y otorgar badge
		if Rank == 1 then
			UsernameLabel.Text = playerName

			-- Actualizar el modelo del jugador
			local success, humanoidDescription = pcall(function()
				return Players:GetHumanoidDescriptionFromUserIdAsync(Data.key)
			end)

			if success and humanoidDescription then
				Model.Humanoid:ApplyDescriptionAsync(humanoidDescription)
			end

			-- Otorgar badge al jugador top 1
			AwardTopBadge(Data.key)
		end

		Info.Count.TextLabel.Text = string.format("Likes totales: %s 👍", FormatNumber(Data.value))
		NewTemplate.Rank.TextLabel.Text = string.format('#%d', Rank)
		NewTemplate.Icon.Image = string.format('rbxthumb://type=AvatarHeadShot&id=%d&w=60&h=60', Data.key)

		NewTemplate.Parent = Scrolling
		NewTemplate.LayoutOrder = Rank
		NewTemplate.Name = tostring(Data.key)
		NewTemplate.Visible = true
	end
end

-- Refrescar leaderboard
local function UpdateLeaderboard()
	for _, Child in pairs(Scrolling:GetChildren()) do
		if Child.Name ~= 'Template' and Child.Name ~= 'ListLayout' then
			Child:Destroy()
		end
	end

	local success, data = pcall(function()
		return Datastore:GetSortedAsync(false, LEADERBOARD_COUNT)
	end)

	if success and data then
		cacheDb = data:GetCurrentPage()
		for rank, item in ipairs(cacheDb) do
			AddItem(rank, item)
		end
	else
		--warn("[LEADERBOARD] Error al obtener datos: " .. tostring(data))
	end
end

-- Verificar badges cuando un jugador se une al juego
local function onPlayerAdded(player)
	if #cacheDb > 0 and cacheDb[1].key == player.UserId then
		-- Este jugador es el top 1, otorgar badge si no lo tiene
		if not CheckBadgeOwnership(player.UserId) then
			AwardTopBadge(player.UserId)
		else
			TopPlayersCache[player.UserId] = true
		end
	end
end

-- Conectar evento de jugadores que se unen
Players.PlayerAdded:Connect(onPlayerAdded)

-- INICIALIZAR
UpdateLeaderboard()

-- Actualizar el leaderboard periódicamente
task.spawn(function()
	while task.wait(300) do -- 5 minutos
		UpdateLeaderboard()
	end
end)

--print("Sistema de Leaderboard y Badges inicializado correctamente")