--// Servicios y Template
local OverheadTemplate = script:WaitForChild("Template")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")




--  GESTIÓN DE CONEXIONES POR JUGADOR
local playerConnections = {}

local function trackConnection(player, connection)
	if not playerConnections[player.UserId] then
		playerConnections[player.UserId] = {}
	end
	table.insert(playerConnections[player.UserId], connection)
	return connection
end

local function disconnectAllPlayerConnections(userId)
	if not playerConnections[userId] then return end
	for _, conn in ipairs(playerConnections[userId]) do
		if conn then
			pcall(function() conn:Disconnect() end)
		end
	end
	playerConnections[userId] = nil
end

--// Módulos
local Systems = ServerScriptService:WaitForChild("Systems")
local Configuration = require(game.ReplicatedStorage.Config.Configuration)
local GamepassManager = require(Systems:WaitForChild("Gamepass Gifting"):WaitForChild("GamepassManager"))
local AdminConfig = require(game.ReplicatedStorage:WaitForChild("Config"):WaitForChild("AdminConfig"))

--// Constantes
local GroupID = tonumber(Configuration.GroupID)
local VIP_ID = Configuration.Gamepasses.VIP.id
local GROUP_ROLES = Configuration.GroupRoles

--// Cache de componentes del overhead para acceso rápido
local function getOverheadComponents(char)
	local head = char:FindFirstChild("Head")
	if not head then return nil end

	local overhead = head:FindFirstChild("Overhead")
	if not overhead then return nil end

	local frame = overhead:FindFirstChild("Frame")
	if not frame then return nil end

	return {
		overhead = overhead,
		frame = frame,
		roleFrame = frame:FindFirstChild("RoleFrame"),
		nameFrame = frame:FindFirstChild("NameFrame"),
		otherFrame = frame:FindFirstChild("OtherFrame")
	}
end

-- Render del DisplayName
local function renderDisplayName(player)
	if not player or not player.Character then return end

	local components = getOverheadComponents(player.Character)
	if not components or not components.nameFrame then return end

	local displayNameLabel = components.nameFrame:FindFirstChild("DisplayName")
	if not displayNameLabel then return end

	displayNameLabel.Text = player.DisplayName
end

-- Función para sincronizar estado VIP en tiempo real
local function updateVIPStatus(player)
	if not player or not player.Parent then return end
	local hasVIP = GamepassManager.HasGamepass(player, VIP_ID)
	player:SetAttribute("HasVIP", hasVIP)
end

--------------------------------------------------------------------------------------------------------
-- Gestión de AFK
local function setAFK(player, state)
	local char = player.Character
	if not char then return end

	local components = getOverheadComponents(char)
	if not components or not components.otherFrame then return end

	local afkImage = components.otherFrame:FindFirstChild("AFK")
	if afkImage then afkImage.Visible = state end

	for _, part in ipairs(char:GetChildren()) do
		if part:IsA("BasePart") then
			if state then
				if not part:GetAttribute("OriginalMaterial") then
					part:SetAttribute("OriginalMaterial", part.Material.Name)
				end
				part.Material = Enum.Material.ForceField
			else
				local original = part:GetAttribute("OriginalMaterial")
				if original then
					part.Material = Enum.Material[original]
					part:SetAttribute("OriginalMaterial", nil)
				end
			end
		end
	end
end

--------------------------------------------------------------------------------------------------------
-- Gestión de overheads
local OverheadManager = {}

function OverheadManager:setupOverhead(char, player)
	local humanoid = char:WaitForChild("Humanoid")
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None

	local existingOverhead = char:FindFirstChild("Overhead")
	if existingOverhead then existingOverhead:Destroy() end

	local overheadClone = OverheadTemplate:Clone()
	overheadClone.Name = "Overhead"
	overheadClone.Parent = char:WaitForChild("Head")

	self:configureOverhead(overheadClone, player, char)
end

function OverheadManager:configureOverhead(overhead, player, char)
	local frame = overhead:FindFirstChild("Frame")
	if not frame then return end

	local roleFrame = frame:FindFirstChild("RoleFrame")
	local nameFrame = frame:FindFirstChild("NameFrame")
	local otherFrame = frame:FindFirstChild("OtherFrame")

	if nameFrame then
		renderDisplayName(player)
	end

	self:setupRole(roleFrame, player)
	self:setupBadges(otherFrame, player)
end

function OverheadManager:setupRole(roleFrame, player)
	if not roleFrame then return end
	local roleText = roleFrame:FindFirstChild("Role")
	if not roleText then return end

	local function updateRoleDisplay()
		-- 1. Título equipado (máxima prioridad)
		local titleLabel = player:GetAttribute("EquippedTitleLabel") or ""
		local titleColor = player:GetAttribute("EquippedTitleColor") or "#FFFFFF"

		if titleLabel ~= "" then
			roleText.RichText   = false
			roleText.Text       = titleLabel
			local r = tonumber(titleColor:sub(2,3), 16) or 255
		local g = tonumber(titleColor:sub(4,5), 16) or 255
		local b = tonumber(titleColor:sub(6,7), 16) or 255
		roleText.TextColor3 = Color3.fromRGB(r, g, b)
			return
		end

		-- 2. Rango de grupo
		local roleAssigned = false

		if player:IsInGroup(GroupID) then
			local success, rank = pcall(function()
				return player:GetRankInGroup(GroupID)
			end)

			if success then
				if GROUP_ROLES[rank] then
					roleText.RichText   = false
					local icon = GROUP_ROLES[rank].Icon
					roleText.Text       = (icon and ("[" .. icon .. "] ") or "") .. GROUP_ROLES[rank].Name
					roleText.TextColor3 = GROUP_ROLES[rank].Color
					roleAssigned = true
				else
					local highestRole = nil
					for roleRank, roleData in pairs(GROUP_ROLES) do
						if rank >= roleRank and (not highestRole or roleRank > highestRole) then
							highestRole = roleRank
						end
					end

					if highestRole then
						roleText.RichText   = false
						local icon = GROUP_ROLES[highestRole].Icon
						roleText.Text       = (icon and ("[" .. icon .. "] ") or "") .. GROUP_ROLES[highestRole].Name
						roleText.TextColor3 = GROUP_ROLES[highestRole].Color
						roleAssigned = true
					end
				end
			end
		end

		-- 3. VIP / PLAYER
		if not roleAssigned then
			local hasVIP = player:GetAttribute("HasVIP") or false
			roleText.RichText = false
			if hasVIP then
				roleText.Text       = "[ VIP ]"
				roleText.TextColor3 = Color3.fromRGB(217, 43, 13)
			else
				roleText.Text       = "[ PLAYER ]"
				roleText.TextColor3 = Color3.fromRGB(111, 0, 255)
			end
		end
	end

	-- Inicial
	updateRoleDisplay()

	-- Escuchar cambios en tiempo real
	trackConnection(player, player:GetAttributeChangedSignal("EquippedTitleLabel"):Connect(updateRoleDisplay))
	trackConnection(player, player:GetAttributeChangedSignal("EquippedTitleColor"):Connect(updateRoleDisplay))
	trackConnection(player, player:GetAttributeChangedSignal("HasVIP"):Connect(updateRoleDisplay))
end

function OverheadManager:setupBadges(otherFrame, player)
	if not otherFrame then return end

	local premium = otherFrame:FindFirstChild("Premium")
	local vip = otherFrame:FindFirstChild("VIP")
	local verify = otherFrame:FindFirstChild("Verify")

	local function updateBadges()
		local hasVIP = player:GetAttribute("HasVIP") or false
		if premium then premium.Visible = player.MembershipType == Enum.MembershipType.Premium end
		if vip then vip.Visible = hasVIP end
		if verify then verify.Visible = AdminConfig:IsAdmin(player) end
	end

	-- Inicial
	updateBadges()

	-- Escuchar cambios en HasVIP
	trackConnection(player, player:GetAttributeChangedSignal("HasVIP"):Connect(updateBadges))
end

--------------------------------------------------------------------------------------------------------
local function setupPlayerChat(player)
	player.Chatted:Connect(function(msg)
		if msg:lower():gsub("%s+", "") == ";afk" then
			setAFK(player, true)
		end
	end)
end

--------------------------------------------------------------------------------------------------------
local function setupMovementDetection(char, player)
	local humanoid = char:WaitForChild("Humanoid")

	local function removeAFK()
		setAFK(player, false)
	end

	trackConnection(player, humanoid.Running:Connect(function(speed)
		if speed > 0 then removeAFK() end
	end))

	trackConnection(player, humanoid.Jumping:Connect(function(isActive)
		if isActive then removeAFK() end
	end))
end

--------------------------------------------------------------------------------------------------------
local function onCharacterAdded(char, player)
	OverheadManager:setupOverhead(char, player)
	setAFK(player, false)
	setupMovementDetection(char, player)
	renderDisplayName(player)
end

Players.PlayerAdded:Connect(function(player)
	updateVIPStatus(player)

	setupPlayerChat(player)

	trackConnection(player, player.CharacterAdded:Connect(function(char)
		onCharacterAdded(char, player)
	end))

	if player.Character then
		onCharacterAdded(player.Character, player)
	end
end)

for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(function()
		setupPlayerChat(player)
		updateVIPStatus(player)

		local char = player.Character or player.CharacterAdded:Wait()
		onCharacterAdded(char, player)
	end)
end

-- LIMPIAR CONEXIONES / CACHES CUANDO EL JUGADOR SALE
Players.PlayerRemoving:Connect(function(player)
	disconnectAllPlayerConnections(player.UserId)
end)
