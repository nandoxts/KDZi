-- GlobalCommandHandler.lua (Optimizado + Filtro Roblox)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextService = game:GetService("TextService")

-- ═══════════════════════════════════════════════════════════════════
-- CONFIGURACIÓN
-- ═══════════════════════════════════════════════════════════════════
local AdminConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("AdminConfig"))
local MusicConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("MusicSystemConfig"))
local Configuration = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("Configuration"))

local GroupService = game:GetService("GroupService")
local GroupId = Configuration.GroupID


local CONFIG = {
	eventPrefix = ";event",
	uneventPrefix = ";unevent",
	m2Prefix = ";m2",
}

-- ═══════════════════════════════════════════════════════════════════
-- REMOTES
-- ═══════════════════════════════════════════════════════════════════
local remotesGlobal = ReplicatedStorage:WaitForChild("RemotesGlobal")
local commandsFolder = remotesGlobal:WaitForChild("Commands")

local eventMessageEvent = commandsFolder:WaitForChild("EventMessage")

-- M2 Announcement Remotes
local messageFolder = remotesGlobal:WaitForChild("Message")
local localAnnouncement = messageFolder:WaitForChild("LocalAnnouncement")
local m2CooldownNotif = messageFolder:WaitForChild("M2CooldownNotif")

local m2FilterNotif = messageFolder:WaitForChild("M2FilterNotif")

-- ═══════════════════════════════════════════════════════════════════
-- FUNCIONES AUXILIARES
-- ═══════════════════════════════════════════════════════════════════

-- Filtrar mensaje con TextService de Roblox

local function filterMessage(text, userId)
	local ok1, result = pcall(TextService.FilterStringAsync, TextService, text, userId, Enum.TextFilterContext.PublicChat)
	if not ok1 or not result then return text end

	local ok2, filtered = pcall(function() return result:GetNonChatStringForBroadcastAsync() end)
	if not ok2 or filtered == nil then return text end

	-- Solo bloquear si Roblox reemplazó contenido con #
	if filtered:find("#") then return nil end

	return filtered
end

-- Validar permisos para ;m2 (DJ o superior = rango 251+)
local function canUseM2Command(player)
	local ok, groups = pcall(function()
		return GroupService:GetGroupsAsync(player.UserId)
	end)

	if not ok then return false end

	for _, group in ipairs(groups) do
		if group.Id == GroupId then
			local rankId = group.Rank
			-- DJ o superior (251+)
			return rankId >= 251
		end
	end

	return false
end

-- m2Cooldown
local m2Cooldown = {}
local M2_COOLDOWN_TIME = 7

local function canUseM2Cooldown(player)
	local now = tick()
	local lastUse = m2Cooldown[player.UserId]

	if lastUse and (now - lastUse) < M2_COOLDOWN_TIME then
		local remainingTime = math.ceil(M2_COOLDOWN_TIME - (now - lastUse))
		pcall(function()
			m2CooldownNotif:FireClient(player, remainingTime)
		end)
		return false
	end

	m2Cooldown[player.UserId] = now
	return true
end

local eventModeActive = MusicConfig.EVENT_MODE.Enabled or false

-- Exportar a _G para que otros scripts puedan acceder
_G.EventModeActive = eventModeActive

local function fireAllClients(remote, message)
	if remote then
		for _, p in ipairs(Players:GetPlayers()) do
			pcall(function() remote:FireClient(p, message) end)
		end
	end
end

-- Actualizar _G cuando cambia el estado
local function setEventMode(value)
	eventModeActive = value
	_G.EventModeActive = value
end

local function onChatted(player, message)
	local lower = message:lower()

	-- Procesar comando ;event (requiere admin)
	if lower == CONFIG.eventPrefix then
		if AdminConfig:IsAdmin(player) then
			setEventMode(true)
			local msg = "MODO EVENTO ACTIVADO"
			fireAllClients(eventMessageEvent, msg)
		end
	end

	-- Procesar comando ;unevent (requiere admin)
	if lower == CONFIG.uneventPrefix then
		if AdminConfig:IsAdmin(player) then
			setEventMode(false)
			local msg = " MODO EVENTO DESACTIVADO"
			fireAllClients(eventMessageEvent, msg)
		end
	end

	-- Procesar comando ;m2 (requiere Influencer+ en HD Admin)
	if lower:sub(1, #CONFIG.m2Prefix) == CONFIG.m2Prefix and lower:sub(#CONFIG.m2Prefix + 1, #CONFIG.m2Prefix + 1) == " " then
		-- Si modo evento está activo, deshabilitar ;m2
		if eventModeActive then
			return
		end

		-- Validar cooldown
		if not canUseM2Cooldown(player) then
			return
		end

		-- Validar permisos (Solo Influencer+)
		if not canUseM2Command(player) then
			return
		end

		-- Extraer mensaje original (preserva mayúsculas)
		local m2Message = message:sub(#CONFIG.m2Prefix + 2)

		if m2Message and m2Message ~= "" then
			task.spawn(function()
				local filteredText = filterMessage(m2Message, player.UserId)

				if not filteredText then
					pcall(function() m2FilterNotif:FireClient(player) end)
					return
				end

				local displayName = player.DisplayName or player.Name
				pcall(function()
					localAnnouncement:FireAllClients(displayName, player.Name, filteredText)
				end)
			end)
		end
	end
end

local function connectPlayer(player)
	player.Chatted:Connect(function(msg) onChatted(player, msg) end)
end

-- Limpiar cooldown cuando el jugador se va
Players.PlayerRemoving:Connect(function(player)
	m2Cooldown[player.UserId] = nil
end)

-- ═══════════════════════════════════════════════════════════════════
-- INICIALIZACIÓN
-- ═══════════════════════════════════════════════════════════════════
-- Pequeño delay para asegurar que los Remotes estén disponibles en clientes
task.wait(0.5)

for _, player in ipairs(Players:GetPlayers()) do
	connectPlayer(player)
end

Players.PlayerAdded:Connect(connectPlayer)