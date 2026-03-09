--[[
	═══════════════════════════════════════════════════════════
	CLAN CONSTANTS - Configuración UI y constantes
	═══════════════════════════════════════════════════════════
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local THEME = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("ThemeConfig"))

local ClanConstants = {}

-- Configuración UI
ClanConstants.CONFIG = {
	panel = { corner = 12 },  -- width/height removidos - ModalManager maneja responsive automáticamente
	blur = { enabled = true, size = 14 },
	cooldown = 1.5,
	listenerCooldown = 0.5,

}

-- Estado centralizado
ClanConstants.State = {
	currentPage = nil,
	currentView = "main",
	loadingId = 0,  -- Sistema de cancelación de refreshes obsoletos
	isOpen = false,
	selectedColor = 1,
	clanData = nil,
	playerRole = nil,
	views = {},
	membersList = nil,
	pendingList = nil,
}

-- Memory Manager
ClanConstants.Memory = { connections = {} }

function ClanConstants.Memory:track(conn)
	if conn then table.insert(self.connections, conn) end
	return conn
end

function ClanConstants.Memory:cleanup()
	local UI = require(ReplicatedStorage:WaitForChild("Core"):WaitForChild("UI"))
	for i, conn in ipairs(self.connections) do
		if conn then pcall(function() conn:Disconnect() end) end
	end
	self.connections = {}
	UI.cleanupLoading()
end

function ClanConstants.Memory:destroyChildren(parent, except)
	if not parent then return end
	for _, child in ipairs(parent:GetChildren()) do
		if not except or not child:IsA(except) then 
			child:Destroy() 
		end
	end
end

return ClanConstants
