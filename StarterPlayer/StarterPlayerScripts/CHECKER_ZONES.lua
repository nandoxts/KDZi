-- CHECKER ZONES - VIP
local Configuration = require(game.ReplicatedStorage.Config.Configuration)
local MarketplaceService = game:GetService("MarketplaceService")
local player = game.Players.LocalPlayer

-- ID del gamepass VIP desde la config central
local VIP_ID = Configuration.Gamepasses.VIP.id

-- Carpeta VIP en el workspace (ZoneVIP > VIP)
local FolderzonaVIP = nil

-- Buscar y guardar la carpeta VIP del workspace
local function setupInitialVIPFolders()
	local mainZoneVIP = workspace:FindFirstChild("ZoneVIP")
	if mainZoneVIP then
		FolderzonaVIP = mainZoneVIP:FindFirstChild("VIP")
	end
end

-- Activar/desactivar colisión en todas las partes de una carpeta
local function setPartsCollision(folder, shouldCollide)
	if not folder then return end
	for _, part in ipairs(folder:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CanCollide = shouldCollide
		end
	end
end

-- Verificar si el jugador tiene VIP:
-- 1. Atributo HasVIP (seteado por GamepassGUI al comprar en vivo)
-- 2. MarketplaceService (jugadores que ya tenían VIP al entrar)
local function checkHasVIP()
	if player:GetAttribute("HasVIP") == true then return true end
	local ok, owns = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, VIP_ID)
	end)
	return ok and owns or false
end

-- Lógica principal
local function handleVIPZones()
	local hasVIP = checkHasVIP()
	setPartsCollision(FolderzonaVIP, not hasVIP)
end

-- Esperar al jugador
player:WaitForChild("PlayerGui")
if not player.Character then
	player.CharacterAdded:Wait()
end
task.wait(2)

-- Inicializar
setupInitialVIPFolders()
handleVIPZones()

-- Reaccionar en tiempo real si compra el VIP mientras está en juego
player:GetAttributeChangedSignal("HasVIP"):Connect(function()
	handleVIPZones()
end)

-- Re-verificar al respawnear
player.CharacterAdded:Connect(function()
	task.wait(1)
	handleVIPZones()
end)

-- Si ZoneVIP se agrega tarde al workspace
workspace.ChildAdded:Connect(function(child)
	if child.Name == "ZoneVIP" then
		task.wait(0.5)
		setupInitialVIPFolders()
		handleVIPZones()
	end
end)