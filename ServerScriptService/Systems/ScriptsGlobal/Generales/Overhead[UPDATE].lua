--// Servicios y Template
local OverheadTemplate = script:WaitForChild("Template")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")


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
local Colors = require(game.ReplicatedStorage.Config.ColorConfig)
local AdminConfig = require(game.ReplicatedStorage.Config.AdminConfig)
local LevelConfig = require(game.ReplicatedStorage.Config.LevelConfig)

--// Constantes
local GroupID = Configuration.GroupID
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
		frame = frame,
		roleFrame = frame:FindFirstChild("RoleFrame"),
		nameFrame = frame:FindFirstChild("NameFrame"),
		otherFrame = frame:FindFirstChild("OtherFrame"),
		levelFrame = frame:FindFirstChild("LevelFrame")
	}
end

--------------------------------------------------------------------------------------------------------
-- ✅ Sistema de degradé animado para nombres (solo Creator, Head Admin, Admin)
local GRADIENT_SPEED = 0.5 -- ciclos por segundo
local GRADIENT_UPDATE_RATE = 0.033 -- ~30 FPS para animación fluida
local activeGradientRoles = {} -- [userId] = { player, gradient, icon, roleName }
local lastGradientUpdate = 0

local function lerpColor3(c1, c2, t)
	return Color3.new(
		c1.R + (c2.R - c1.R) * t,
		c1.G + (c2.G - c1.G) * t,
		c1.B + (c2.B - c1.B) * t
	)
end

local function color3ToHex(c)
	return string.format("#%02X%02X%02X",
		math.clamp(math.round(c.R * 255), 0, 255),
		math.clamp(math.round(c.G * 255), 0, 255),
		math.clamp(math.round(c.B * 255), 0, 255)
	)
end

local function interpolateGradient(colors, t)
	if #colors == 1 then return colors[1] end
	local segments = #colors - 1
	local seg = math.clamp(math.floor(t * segments), 0, segments - 1)
	local localT = (t * segments) - seg
	return lerpColor3(colors[seg + 1], colors[seg + 2], localT)
end

local function applyGradientText(text, gradientColors, offset)
	if not gradientColors or #gradientColors == 0 then
		return text
	end
	offset = offset or 0
	if #text <= 1 then
		return '<font color="' .. color3ToHex(gradientColors[1]) .. '">' .. text .. '</font>'
	end
	local result = {}
	for i = 1, #text do
		local char = text:sub(i, i)
		local t = ((i - 1) / (#text - 1) + offset) % 1
		local color = interpolateGradient(gradientColors, t)
		table.insert(result, '<font color="' .. color3ToHex(color) .. '">' .. char .. '</font>')
	end
	return table.concat(result)
end

local function renderDisplayName(player)
	if not player or not player.Character then return end

	local components = getOverheadComponents(player.Character)
	if not components or not components.nameFrame then return end

	local displayNameLabel = components.nameFrame:FindFirstChild("DisplayName")
	if not displayNameLabel then return end

	displayNameLabel.RichText = false
	displayNameLabel.Text = player.DisplayName
	displayNameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
end

-- ✅ Loop de animación global para degradé en roles (Creator, Head Admin, Admin)
RunService.Heartbeat:Connect(function()
	local now = os.clock()
	if now - lastGradientUpdate < GRADIENT_UPDATE_RATE then return end
	lastGradientUpdate = now

	local offset = (now * GRADIENT_SPEED) % 1

	for userId, data in pairs(activeGradientRoles) do
		local player = data.player
		if not player or not player.Parent or not player.Character then
			activeGradientRoles[userId] = nil
			continue
		end

		local components = getOverheadComponents(player.Character)
		if not components or not components.roleFrame then continue end

		local roleText = components.roleFrame:FindFirstChild("Role")
		if not roleText then continue end

		roleText.Text = "[" .. data.icon .. "] " .. applyGradientText(data.roleName, data.gradient, offset)
	end
end)

-- Función para sincronizar estado VIP en tiempo real
local function updateVIPStatus(player)
	if not player or not player.Parent then return end
	local hasVIP = GamepassManager.HasGamepass(player, VIP_ID)
	player:SetAttribute("HasVIP", hasVIP)
end

-- Actualizar nivel en LevelFrame
local function updateLevelDisplay(levelLabel, level)
	if not levelLabel then return end
	local config = LevelConfig.getLevelConfig(level)
	levelLabel.Text = "Lv. " .. level .. " " .. config.Emoji
	levelLabel.TextColor3 = config.Color
end

--------------------------------------------------------------------------------------------------------
-- Actualizar degradé del nombre
local function updatePlayerNameColor(player)
	renderDisplayName(player)
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

	self:configureOverhead(overheadClone, player)
end

function OverheadManager:configureOverhead(overhead, player)
	local frame = overhead:FindFirstChild("Frame")
	if not frame then return end

	local roleFrame  = frame:FindFirstChild("RoleFrame")
	local nameFrame  = frame:FindFirstChild("NameFrame")
	local otherFrame = frame:FindFirstChild("OtherFrame")
	local levelFrame = frame:FindFirstChild("LevelFrame")

	if nameFrame then
		renderDisplayName(player)
	end

	self:setupRole(roleFrame, player)
	self:setupBadges(otherFrame, player)
	self:setupLevelDisplay(levelFrame, player)
end

function OverheadManager:setupLevelDisplay(levelFrame, player)
	if not levelFrame then return end

	local levelLabel = levelFrame:FindFirstChild("Level")
	if not levelLabel then return end

	local function connectLevelStat(levelStat)
		updateLevelDisplay(levelLabel, levelStat.Value)
		trackConnection(player, levelStat:GetPropertyChangedSignal("Value"):Connect(function()
			updateLevelDisplay(levelLabel, levelStat.Value)
		end))
	end

	local function connectLeaderstats(leaderstats)
		local levelStat = leaderstats:FindFirstChild("Level 🌟")
		if levelStat then
			connectLevelStat(levelStat)
			return
		end
		local conn
		conn = leaderstats.ChildAdded:Connect(function(child)
			if child.Name == "Level 🌟" then
				conn:Disconnect()
				connectLevelStat(child)
			end
		end)
	end

	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		connectLeaderstats(leaderstats)
		return
	end

	local conn
	conn = player.ChildAdded:Connect(function(child)
		if child.Name == "leaderstats" then
			conn:Disconnect()
			connectLeaderstats(child)
		end
	end)
end

function OverheadManager:setupRole(roleFrame, player)
	if not roleFrame then return end
	local roleText = roleFrame:FindFirstChild("Role")
	if not roleText then return end

	local function applyRoleText(icon, label, color, gradient)
		local safeIcon = (icon and icon ~= "") and icon or "👤"
		if gradient then
			-- Rol con degradé animado
			roleText.RichText = true
			local offset = (os.clock() * GRADIENT_SPEED) % 1
			roleText.Text = "[" .. safeIcon .. "] " .. applyGradientText(label, gradient, offset)
			activeGradientRoles[player.UserId] = {
				player = player,
				gradient = gradient,
				icon = safeIcon,
				roleName = label
			}
		else
			-- Rol con color sólido
			activeGradientRoles[player.UserId] = nil
			roleText.RichText = false
			roleText.Text = string.format("[%s] %s", safeIcon, label)
			roleText.TextColor3 = color
		end
	end

	local function updateRoleDisplay()
		-- 1. Título equipado (máxima prioridad)
		local titleLabel = player:GetAttribute("EquippedTitleLabel") or ""
		local titleColor = player:GetAttribute("EquippedTitleColor") or "#FFFFFF"

		if titleLabel ~= "" then
			applyRoleText("🏷️", titleLabel, Colors.fromHex(titleColor))
			return
		end

		-- 2. Rango de grupo
		local roleAssigned = false

		if player:IsInGroup(GroupID) then
			local success, rank = pcall(function()
				return player:GetRankInGroup(GroupID)
			end)

			if success then
				local role = GROUP_ROLES[rank]
				if not role then
					local highestRole = nil
					for roleRank in pairs(GROUP_ROLES) do
						if rank >= roleRank and (not highestRole or roleRank > highestRole) then
							highestRole = roleRank
						end
					end
					if highestRole then role = GROUP_ROLES[highestRole] end
				end
				if role then
					applyRoleText(role.Icon, role.Name, role.Color, role.Gradient)
					roleAssigned = true
				end
			end
		end

		-- 3. VIP / Invitado
		if not roleAssigned then
			local hasVIP = player:GetAttribute("HasVIP") or false
			if hasVIP then
				applyRoleText("💎", "[ VIP ]", Color3.fromRGB(255, 85, 255))
			else
				applyRoleText("👤", "[ Invitado ]", Color3.fromRGB(200, 200, 200))
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


local function onCharacterAdded(char, player)
	OverheadManager:setupOverhead(char, player)
	renderDisplayName(player)
	setAFK(player, false)
	setupMovementDetection(char, player)
end

Players.PlayerAdded:Connect(function(player)
	updateVIPStatus(player)

	trackConnection(player, player:GetAttributeChangedSignal("SelectedColor"):Connect(function()
		updatePlayerNameColor(player)
	end))

	trackConnection(player, player:GetAttributeChangedSignal("HasVIP"):Connect(function()
		renderDisplayName(player)
	end))

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

		trackConnection(player, player:GetAttributeChangedSignal("SelectedColor"):Connect(function()
			updatePlayerNameColor(player)
		end))

		trackConnection(player, player:GetAttributeChangedSignal("HasVIP"):Connect(function()
			renderDisplayName(player)
		end))

		local char = player.Character or player.CharacterAdded:Wait()
		onCharacterAdded(char, player)
	end)
end

-- LIMPIAR CONEXIONES CUANDO EL JUGADOR SALE
Players.PlayerRemoving:Connect(function(player)
	disconnectAllPlayerConnections(player.UserId)
	activeGradientRoles[player.UserId] = nil
end)
