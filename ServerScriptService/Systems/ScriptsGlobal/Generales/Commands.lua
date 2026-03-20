--[[
	Command System (Refactored)
	- Efectos visuales, items VIP
	- Refactorizado: sin memory leaks, anti-spam funcional, código centralizado
]]

--> Services
local MarketplaceService = game:GetService("MarketplaceService")
local Players            = game:GetService("Players")
local InsertService      = game:GetService("InsertService")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local ServerStorage      = game:GetService("ServerStorage"):WaitForChild("Systems")
local ServerScriptService = game:GetService("ServerScriptService"):WaitForChild("Systems")
local TweenService       = game:GetService("TweenService")
local Debris             = game:GetService("Debris")

--> Modules
local Configuration  = require(game.ReplicatedStorage.Config.Configuration)
local AdminConfig    = require(game.ReplicatedStorage.Config.AdminConfig)
local GamepassManager = require(ServerScriptService["Gamepass Gifting"].GamepassManager)
local ColorEffects = require(game.ReplicatedStorage.Config.ColorConfig)


--> ClanData (carga segura)
local ClanData = nil
do
	local clanSystem = game:GetService("ServerStorage"):FindFirstChild("Systems")
	clanSystem = clanSystem and clanSystem:FindFirstChild("ClanSystem")
	if clanSystem then
		local module = clanSystem:FindFirstChild("ClanDataV2") or clanSystem:FindFirstChild("ClanData")
		if module then
			local ok, result = pcall(require, module)
			if ok then ClanData = result end
		end
	end
end

--> Constants
local EFFECT_PARTS = {"Head", "LeftLowerArm", "RightLowerArm", "LeftLowerLeg", "RightLowerLeg"}
local COOLDOWN_SECONDS = 0.5 -- Anti-spam entre comandos

--=============================================================================
-- RANK SYSTEM  (fuente única de verdad: Configuration)
--=============================================================================

local _gp = {}
for _, e in ipairs(Configuration.AdminRanksByGamepass) do _gp[e.Name] = e.Level end

local RANK = {
	NONE       = 0,
	VIP        = _gp.VIP,
	COMMANDS   = _gp.COMMANDS,
	SOCIO      = 248,
	INFLUENCER = 249,
	DJ         = 250,
	MOD        = 251,
	ADMIN      = 252,
	HEAD_ADMIN = 253,
	CREATOR    = 254, -- 254 y 255 son ambos Creator
}

-- Retorna el rango efectivo del jugador: rango de grupo > gamepass > ninguno
local function getPlayerRank(player)
	local ok, groupRank = pcall(function()
		return player:GetRankInGroup(Configuration.GroupID)
	end)
	if ok and groupRank >= RANK.SOCIO then return groupRank end
	if GamepassManager.HasGamepass(player, Configuration.Gamepasses.COMMANDS.id) then
		return RANK.COMMANDS
	end
	if GamepassManager.HasGamepass(player, Configuration.Gamepasses.VIP.id) then
		return RANK.VIP
	end
	return RANK.NONE
end



--> Player State (todo centralizado en una tabla por UserId)
local playerState = {} -- [userId] = { effects, origAccessories, origTools, lastCommandTime }

local function getState(player)
	local uid = player.UserId
	if not playerState[uid] then
		playerState[uid] = {
			effects          = {},    -- instancias de efectos activos
			origAccessories  = {},    -- nombres de accesorios originales
			origTools        = {},    -- nombres de tools originales
			lastCommandTime  = 0,     -- timestamp del último comando (anti-spam)
		}
	end
	return playerState[uid]
end

local function clearState(player)
	playerState[player.UserId] = nil
end

--=============================================================================
-- UTILIDADES
--=============================================================================

local function resolveColor(token)
	if not token or token == "" then
		return Color3.new(1, 0, 0)
	end

	local key = string.lower(token)
	if ColorEffects.colors[key] then
		return ColorEffects.colors[key]
	end

	local hex = key:gsub("#", "")
	if hex:match("^%x%x%x%x%x%x$") then
		local r = tonumber(hex:sub(1, 2), 16) / 255
		local g = tonumber(hex:sub(3, 4), 16) / 255
		local b = tonumber(hex:sub(5, 6), 16) / 255
		return Color3.new(r, g, b)
	end

	return Color3.new(1, 0, 0)
end

local function isOnCooldown(player)
	local state = getState(player)
	local now = tick()
	if now - state.lastCommandTime < COOLDOWN_SECONDS then
		return true
	end
	state.lastCommandTime = now
	return false
end

local function getHumanoid(character)
	local hum = character:FindFirstChildOfClass("Humanoid")
	if not hum then
		local ok, result = pcall(function()
			return character:WaitForChild("Humanoid", 2)
		end)
		if ok then hum = result end
	end
	return hum
end

local function isVIPItem(item)
	local itemsFolder = ServerStorage:FindFirstChild("Items")
	if not itemsFolder then return false end

	local folder = itemsFolder:FindFirstChild("VIP")
	if folder and folder:FindFirstChild(item.Name) then
		return true
	end
	return false
end

--=============================================================================
-- EFFECT SYSTEM
--=============================================================================

-- Generador genérico: crea una instancia por cada parte del efecto
local function createEffectOnParts(character, className, propertySetup)
	local created = {}
	for _, name in ipairs(EFFECT_PARTS) do
		local part = character:FindFirstChild(name)
		if part then
			local inst = Instance.new(className)
			propertySetup(inst)
			inst.Parent = part
			table.insert(created, inst)
		end
	end
	return created
end

local EffectCreators = {
	fire = function(character, color)
		return createEffectOnParts(character, "Fire", function(fire)
			fire.Color = color
			fire.SecondaryColor = Color3.new(color.R * 0.5, color.G * 0.5, color.B * 0.5)
			fire.Size = 3
		end)
	end,

	smk = function(character, color)
		return createEffectOnParts(character, "Smoke", function(smoke)
			smoke.Color = color
			smoke.Size = 0.0005
			smoke.Opacity = 0.005
			smoke.RiseVelocity = 1
		end)
	end,

	lght = function(character, color)
		return createEffectOnParts(character, "PointLight", function(light)
			light.Color = color
			light.Brightness = 5
			light.Range = 10
			light.Shadows = true
		end)
	end,

	prtcl = function(character, color)
		return createEffectOnParts(character, "ParticleEmitter", function(emitter)
			emitter.Color = ColorSequence.new(color)
			emitter.Size = NumberSequence.new(0.4, 0.8)
			emitter.LightEmission = 0.5
			emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
			emitter.Lifetime = NumberRange.new(1, 2)
			emitter.Rate = 10
			emitter.Speed = NumberRange.new(1)
		end)
	end,

	trail = function(character, color)
		local created = {}
		for _, name in ipairs(EFFECT_PARTS) do
			local part = character:FindFirstChild(name)
			if part then
				local att0 = Instance.new("Attachment", part)
				local att1 = Instance.new("Attachment", part)
				att1.Position = Vector3.new(0, -1, 0)

				local trail = Instance.new("Trail")
				trail.Color = ColorSequence.new(color)
				trail.LightEmission = 1
				trail.Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 0),
					NumberSequenceKeypoint.new(0.6, 0.2),
					NumberSequenceKeypoint.new(1, 0.9),
				})
				trail.WidthScale = NumberSequence.new(0.2, 1)
				trail.Lifetime = 0.6
				trail.Attachment0 = att0
				trail.Attachment1 = att1
				trail.Parent = part
				table.insert(created, {trail, att0, att1})
			end
		end
		return created
	end,

	destacar = function(character, color)
		local existing = character:FindFirstChild("Destacar")
		if existing then
			pcall(function() existing:Destroy() end)
			task.wait()
		end

		local highlight = Instance.new("Highlight")
		highlight.Name = "Destacar"
		highlight.OutlineColor = color
		highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		highlight.FillTransparency = 1
		highlight.OutlineTransparency = 0.1
		highlight.Parent = character
		return {highlight}
	end,
}

local function clearPlayerEffect(player)
	local state = getState(player)

	for _, inst in ipairs(state.effects) do
		if typeof(inst) == "table" then
			for _, sub in ipairs(inst) do
				if typeof(sub) == "Instance" and sub.Parent then
					pcall(function() sub:Destroy() end)
				end
			end
		elseif typeof(inst) == "Instance" and inst.Parent then
			pcall(function() inst:Destroy() end)
		end
	end
	state.effects = {}

	local character = player.Character
	if character then
		local h = character:FindFirstChild("Destacar")
		if h and h:IsA("Highlight") then
			pcall(function() h:Destroy() end)
		end
	end
end

local function applyEffectToPlayer(targetPlayer, effectType, color, commandingPlayer)
	local character = targetPlayer.Character
	if not character then return end

	if commandingPlayer and commandingPlayer ~= targetPlayer then
		if getPlayerRank(commandingPlayer) < RANK.SOCIO then
			return
		end
	end

	clearPlayerEffect(targetPlayer)

	local fn = EffectCreators[effectType]
	if fn then
		getState(targetPlayer).effects = fn(character, color)
	end
end

--=============================================================================
-- CHARACTER MODIFICATION
--=============================================================================

local function modifyCharacter(character, modification)
	if not character or not character:IsDescendantOf(game) then return false end

	local humanoid = getHumanoid(character)
	if not humanoid then return false end

	local ok, err = pcall(function()
		if modification.type == "description" then
			local desc = humanoid:GetAppliedDescription()
			desc[modification.part] = modification.value
			humanoid:ApplyDescription(desc)
		elseif modification.type == "scale" then
			humanoid:WaitForChild("BodyHeightScale").Value = modification.value
			humanoid:WaitForChild("BodyDepthScale").Value  = modification.value
			humanoid:WaitForChild("BodyWidthScale").Value  = modification.value
			humanoid:WaitForChild("HeadScale").Value       = modification.value
		end
	end)

	if not ok then warn("Error al modificar personaje:", err) end
	return ok
end

local function equipAccessory(character, accessoryId)
	if not character then return end
	local ok, asset = pcall(InsertService.LoadAsset, InsertService, accessoryId)
	if ok and asset then
		local acc = asset:FindFirstChildOfClass("Accessory")
		if acc then
			acc.Parent = character
			task.wait(0.05)
		end
	end
end

local function applyClothing(character, clothingConfig)
	if not character then return end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	pcall(function()
		local desc = humanoid:GetAppliedDescription()
		if clothingConfig.shirtID then desc.Shirt = clothingConfig.shirtID end
		if clothingConfig.pantsID then desc.Pants = clothingConfig.pantsID end
		humanoid:ApplyDescription(desc)
	end)
end

--=============================================================================
-- ITEM MANAGEMENT
--=============================================================================

local function equipItems(player, itemType)
	local itemsFolder = ServerStorage:FindFirstChild("Items")
	if not itemsFolder then return end
	local typeFolder = itemsFolder:FindFirstChild(itemType)
	if not typeFolder then return end

	local backpack = player:WaitForChild("Backpack")
	for _, item in ipairs(typeFolder:GetChildren()) do
		if not backpack:FindFirstChild(item.Name) then
			local clone = item:Clone()
			if clone:IsA("Tool") then clone.CanBeDropped = false end
			clone.Parent = backpack
		end
	end
end

--=============================================================================
-- ORIGINAL ITEMS TRACKING & RESET
--=============================================================================

local function storeOriginalItems(player)
	local character = player.Character
	if not character then return end

	local state = getState(player)

	state.origAccessories = {}
	for _, acc in ipairs(character:GetChildren()) do
		if acc:IsA("Accessory") then
			table.insert(state.origAccessories, acc.Name)
		end
	end

	local backpack = player:WaitForChild("Backpack")
	state.origTools = {}
	for _, tool in ipairs(backpack:GetChildren()) do
		if tool:IsA("Tool") then
			table.insert(state.origTools, tool.Name)
		end
	end
end

local function resetCharacter(player)
	local character = player.Character
	if not character then return end

	local humanoid = character:WaitForChild("Humanoid")
	local state = getState(player)

	-- Guardar overhead
	local overheadClone = nil
	local head = character:FindFirstChild("Head")
	if head then
		local overhead = head:FindFirstChild("Overhead")
		if overhead then overheadClone = overhead:Clone() end
	end

	-- Remover accesorios no originales y no VIP
	for _, acc in ipairs(character:GetChildren()) do
		if acc:IsA("Accessory")
			and not isVIPItem(acc)
			and not table.find(state.origAccessories, acc.Name) then
			acc:Destroy()
		end
	end

	-- Remover tools duplicados
	local backpack = player:WaitForChild("Backpack")
	local seen = {}
	for _, tool in ipairs(backpack:GetChildren()) do
		if tool:IsA("Tool") then
			local isProtected = isVIPItem(tool) or table.find(state.origTools, tool.Name)
			if not isProtected and seen[tool.Name] then
				tool:Destroy()
			else
				seen[tool.Name] = true
			end
		end
	end

	-- Reset apariencia
	local ok, desc = pcall(Players.GetHumanoidDescriptionFromUserId, Players, player.UserId)
	if ok and desc then
		humanoid:ApplyDescription(desc)
	end

	-- Restaurar overhead
	if overheadClone then
		task.delay(0.5, function()
			local h = character:FindFirstChild("Head")
			if h then
				local old = h:FindFirstChild("Overhead")
				if old then old:Destroy() end
				pcall(function() overheadClone.Parent = h end)
			end
		end)
	end

	-- Remover partículas de comando
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if hrp then
		local cp = hrp:FindFirstChild("CommandParticles")
		if cp and cp:IsA("ParticleEmitter") then cp:Destroy() end
	end

	-- Limpiar todo
	clearPlayerEffect(player)
	storeOriginalItems(player)
end

--=============================================================================
-- COMMAND HANDLERS
--=============================================================================

local function handleParticleCommand(player, character, textureId)
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	local textureIdToUse = textureId

	if string.lower(textureId) == "clan" and ClanData then
		local clan = ClanData:GetPlayerClan(player.UserId)
		if clan and clan.logo then
			textureIdToUse = clan.logo:gsub("rbxassetid://", "")
		end
	end

	local emitter = hrp:FindFirstChild("CommandParticles")
	if not emitter then
		local templates = ServerStorage:FindFirstChild("Commands")
		local template = templates and templates:FindFirstChild("CommandParticles")
		if not template then return end
		emitter = template:Clone()
		emitter.Name = "CommandParticles"
		emitter.Parent = hrp
	end

	emitter.Size = NumberSequence.new(0.25, 0.35)
	emitter.Lifetime = NumberRange.new(2, 3)
	emitter.Rate = 15
	emitter.Speed = NumberRange.new(2, 4)
	emitter.Drag = 1.5
	emitter.VelocityInheritance = 0.1
	emitter.Acceleration = Vector3.new(0, 0, 0)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Transparency = NumberSequence.new(0.2, 0.5, 1)
	pcall(function() emitter.Texture = "rbxassetid://" .. textureIdToUse end)
	emitter.Enabled = true
end

local function handleCloneCommand(player, targetName)
	local ok, targetUserId = pcall(Players.GetUserIdFromNameAsync, Players, targetName)
	if not ok then return end

	if AdminConfig:IsAdmin(targetName) then
		player:Kick("No puedes clonar a este usuario")
		return
	end

	local humanoidDescription
	local targetPlayer = Players:FindFirstChild(targetName)

	if targetPlayer and targetPlayer.Character then
		local hum = targetPlayer.Character:FindFirstChild("Humanoid")
		if hum then humanoidDescription = hum:GetAppliedDescription() end
	end

	if not humanoidDescription then
		local s, r = pcall(Players.GetHumanoidDescriptionFromUserId, Players, targetUserId)
		if s then humanoidDescription = r end
	end

	if humanoidDescription and player.Character then
		local hum = player.Character:FindFirstChild("Humanoid")
		if hum then hum:ApplyDescription(humanoidDescription) end
	end
end

local function handleAppearanceCommand(player, commandType)
	local character = player.Character
	if not character or not character:IsDescendantOf(game) then
		task.delay(1, function() handleAppearanceCommand(player, commandType) end)
		return
	end

	local MODIFICATIONS = {
		headless = {type = "description", part = "Head", value = 15093053680},
		korblox  = {type = "description", part = "RightLeg", value = 139607718},
	}

	local modification = MODIFICATIONS[commandType]
	if not modification then return end

	local attempt = 0
	local function tryModify()
		attempt += 1
		if attempt > 3 then return end
		if not modifyCharacter(character, modification) and attempt < 3 then
			task.delay(0.5 * attempt, tryModify)
		end
	end
	tryModify()
end

--=============================================================================
-- EFFECT TARGETING (centralizado)
--=============================================================================

local function applyEffectWithTarget(player, effectType, input)
	if not input then return end

	local parts = {}
	for part in string.gmatch(input, "%S+") do
		table.insert(parts, part)
	end

	local color = resolveColor(parts[1])
	local targetName = parts[2]

	if not targetName then
		applyEffectToPlayer(player, effectType, color, player)
		return
	end

	local lower = string.lower(targetName)
	if lower == "all" or lower == "todos" then
		if getPlayerRank(player) < RANK.MOD then return end
		for _, target in ipairs(Players:GetPlayers()) do
			applyEffectToPlayer(target, effectType, color, player)
		end
	else
		local target = Players:FindFirstChild(targetName)
		if target then
			applyEffectToPlayer(target, effectType, color, player)
		end
	end
end

--=============================================================================
-- COMMAND ROUTER
--=============================================================================

local function processCommand(player, message)
	if isOnCooldown(player) then return end

	local character = player.Character
	if not character then return end

	-- Mapeo de efectos: patrón → tipo
	local EFFECT_MAP = {
		{pattern = Configuration.CommandFIRE,      effect = "fire"},
		{pattern = Configuration.CommandLGHT,      effect = "lght"},
		{pattern = Configuration.CommandPRTCL,     effect = "prtcl"},
		{pattern = Configuration.CommandTRAIL,     effect = "trail"},
		{pattern = Configuration.CommandDestacado, effect = "destacar"},
	}

	local rank = getPlayerRank(player)

	-- 1. Efectos visuales (rango mínimo: VIP)
	if rank >= RANK.VIP then
		for _, entry in ipairs(EFFECT_MAP) do
			local match = message:match(entry.pattern)
			if match then
				applyEffectWithTarget(player, entry.effect, match)
				return
			end
		end

		local rmv = message:match(Configuration.CommandRMV)
		if rmv then
			clearPlayerEffect(player)
			return
		end
	end

	-- 2. Apariencia propia (rango mínimo: VIP)
	local korblox = message:match(Configuration.CommandKorblox)
	if korblox and rank >= RANK.VIP then
		handleAppearanceCommand(player, "korblox")
		return
	end

	local headless = message:match(Configuration.CommandHeadless)
	if headless and rank >= RANK.VIP then
		handleAppearanceCommand(player, "headless")
		return
	end

	-- 3. Clone (rango mínimo: Socio)
	local cloneTarget = message:match(Configuration.CommandClone)
	if cloneTarget and rank >= RANK.SOCIO then
		handleCloneCommand(player, cloneTarget)
		return
	end

	-- 4. Reset de personaje (rango mínimo: VIP)
	local isReset = message:match(Configuration.CommandReset) or message:match(Configuration.CommandReset2)
	if isReset and rank >= RANK.VIP then
		resetCharacter(player)
		return
	end
end

--=============================================================================
-- PLAYER SETUP
--=============================================================================

Players.PlayerAdded:Connect(function(player)
	-- Una sola conexión a CharacterAdded (no anidamos Chatted aquí)
	player.CharacterAdded:Connect(function(character)
		storeOriginalItems(player)
		-- Equipar items VIP automáticamente
		if GamepassManager.HasGamepass(player, Configuration.Gamepasses.VIP.id) then
			equipItems(player, "VIP")
		end
	end)

	-- Chatted conectado UNA sola vez (fuera de CharacterAdded = sin memory leak)
	player.Chatted:Connect(function(message)
		processCommand(player, message)
	end)

	-- Prevenir tools duplicados en backpack
	player:WaitForChild("Backpack").ChildAdded:Connect(function(child)
		if not child:IsA("Tool") then return end
		task.wait(0.1)
		local count = 0
		for _, tool in ipairs(player.Backpack:GetChildren()) do
			if tool.Name == child.Name then
				count += 1
				if count > 1 then
					child:Destroy()
					return
				end
			end
		end
	end)

	-- Cleanup al salir
	player.AncestryChanged:Connect(function()
		if not player:IsDescendantOf(game) then
			clearState(player)
		end
	end)
end)