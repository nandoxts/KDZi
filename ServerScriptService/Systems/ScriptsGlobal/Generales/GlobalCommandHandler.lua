-- GlobalCommandHandler.lua (Solo ;event / ;unevent)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AdminConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("AdminConfig"))
local MusicConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("MusicSystemConfig"))

local CONFIG = {
	eventPrefix   = ";event",
	uneventPrefix = ";unevent",
}

-- ═══════════════════════════════════════════════════════════════════
-- REMOTES
-- ═══════════════════════════════════════════════════════════════════
local remotesGlobal = ReplicatedStorage:WaitForChild("RemotesGlobal")
local commandsFolder = remotesGlobal:WaitForChild("Commands")
local eventMessageEvent = commandsFolder:WaitForChild("EventMessage")

-- ═══════════════════════════════════════════════════════════════════
-- ESTADO
-- ═══════════════════════════════════════════════════════════════════
local eventModeActive = MusicConfig.EVENT_MODE.Enabled or false
_G.EventModeActive = eventModeActive

local function fireAllClients(remote, message)
	if remote then
		for _, p in ipairs(Players:GetPlayers()) do
			pcall(function() remote:FireClient(p, message) end)
		end
	end
end

local function setEventMode(value)
	eventModeActive = value
	_G.EventModeActive = value
end

-- ═══════════════════════════════════════════════════════════════════
-- LÓGICA
-- ═══════════════════════════════════════════════════════════════════
local function onChatted(player, message)
	local lower = message:lower()

	if lower == CONFIG.eventPrefix then
		if AdminConfig:IsAdmin(player) then
			setEventMode(true)
			fireAllClients(eventMessageEvent, "MODO EVENTO ACTIVADO")
		end
	elseif lower == CONFIG.uneventPrefix then
		if AdminConfig:IsAdmin(player) then
			setEventMode(false)
			fireAllClients(eventMessageEvent, "MODO EVENTO DESACTIVADO")
		end
	end
end

local function connectPlayer(player)
	player.Chatted:Connect(function(msg) onChatted(player, msg) end)
end

-- ═══════════════════════════════════════════════════════════════════
-- INICIALIZACIÓN
-- ═══════════════════════════════════════════════════════════════════
task.wait(0.5)

for _, player in ipairs(Players:GetPlayers()) do
	connectPlayer(player)
end

Players.PlayerAdded:Connect(connectPlayer)