--[[
	Command System (Refactored)
	- Efectos visuales, auras, comandos especiales, items por gamepass
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
local GamepassManager = require(ServerScriptService["Gamepass Gifting"].GamepassManager)
local ColorEffects   = require(ServerScriptService.Effects.ColorEffectsModule)

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
local BLACKLISTED_USERIDS = Configuration.OWS
local COOLDOWN_SECONDS = 0.5 -- Anti-spam entre comandos

local SPECIAL_COMMANDS = {
	TOMBO = {
		gamepassKey = Configuration.TOMBO,
		clothing    = { pantsID = 10820482467, shirtID = 16963556758 },
		itemFolder  = "TOMBO",
	},
	SERE = {
		gamepassKey = Configuration.SERE,
		clothing    = { shirtID = 7650880991 },
		accessories = { hatID = 125648027192051, backAccessoryID = 125602307013071 },
		itemFolder  = "SERE",
	},
	CHORO = {
		gamepassKey = Configuration.CHORO,
		itemFolder  = "CHORO",
	},
	ARMYBOOMS = {
		gamepassKey = Configuration.ARMYBOOMS,
		itemFolder  = "ARMYBOOMS",
	},
	LIGHTSTICK = {
		gamepassKey = Configuration.LIGHTSTICK,
		itemFolder  = "LIGHTSTICK",
	},
}

local AURA_COMMANDS = {
	atomic   = { gamepassKey = Configuration.AURA_ATOMIC,   folder = "ATOMIC"    },
	blazing  = { gamepassKey = Configuration.AURA_BLAZING,  folder = "BLAZING"   },
	nano     = { gamepassKey = Configuration.AURA_NANO,     folder = "NANO"      },
	redheart = { gamepassKey = Configuration.AURA_REDHEART, folder = "RED HEART" },
	snow     = { gamepassKey = Configuration.AURA_SNOW,     folder = "SNOW"      },
	dragon   = { gamepassKey = Configuration.AURA_PACK,     folder = "DRAGON"    },
}

local AURA_SOUNDS = {
	atomic   = "rbxassetid://96776624852409",
	blazing  = "rbxassetid://82388464656965",
	nano     = "rbxassetid://139565608032266",
	redheart = "rbxassetid://82388464656965",
	snow     = "rbxassetid://9125402528",
	dragon   = "rbxassetid://121322612850251",
}

local R6_TO_R15 = {
	["Head"]             = {"Head"},
	["Torso"]            = {"UpperTorso", "LowerTorso"},
	["HumanoidRootPart"] = {"HumanoidRootPart"},
	["Left Arm"]         = {"LeftUpperArm", "LeftLowerArm", "LeftHand"},
	["Right Arm"]        = {"RightUpperArm", "RightLowerArm", "RightHand"},
	["Left Leg"]         = {"LeftUpperLeg", "LeftLowerLeg", "LeftFoot"},
	["Right Leg"]        = {"RightUpperLeg", "RightLowerLeg", "RightFoot"},
}

local MANNEQUIN_SKIP = {
	ThumbnailCamera = true, ["Body Colors"] = true,
	Description = true, Humanoid = true,
}

local PAID_ITEM_FOLDERS = {"VIP", "TOMBO", "CHORO", "SERE", "ARMYBOOMS", "LIGHTSTICK"}

--> Player State (todo centralizado en una tabla por UserId)
local playerState = {} -- [userId] = { effects, activeCommand, activeAura, origAccessories, origTools, giftEquipped, lastCommandTime }

local function getState(player)
	local uid = player.UserId
	if not playerState[uid] then
		playerState[uid] = {
			effects          = {},    -- instancias de efectos activos
			activeCommand    = nil,   -- comando especial activo (TOMBO, SERE, etc.)
			activeAura       = nil,   -- aura activa ("atomic", "blazing", etc.)
			origAccessories  = {},    -- nombres de accesorios originales
			origTools        = {},    -- nombres de tools originales
			giftEquipped     = false, -- si ya se equiparon gift items
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

	for _, folderName in ipairs(PAID_ITEM_FOLDERS) do
		local folder = itemsFolder:FindFirstChild(folderName)
		if folder and folder:FindFirstChild(item.Name) then
			return true
		end
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
		if not ColorEffects.hasPermission(commandingPlayer, Configuration.GroupID, Configuration.ALLOWED_RANKS_OWS) then
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
-- AURA SYSTEM
--=============================================================================

local function removeAura(player)
	local character = player.Character
	if character then
		local toRemove = {}
		for _, obj in ipairs(character:GetDescendants()) do
			if obj:GetAttribute("PlayerAura") then
				table.insert(toRemove, obj)
			end
		end
		for _, obj in ipairs(toRemove) do
			pcall(function() obj:Destroy() end)
		end
	end
	getState(player).activeAura = nil
end

local function handleAuraCommand(player, auraName)
	local key = string.lower(auraName)
	local config = AURA_COMMANDS[key]
	if not config then return end

	-- Si tiene el AURA PACK, puede usar todas las auras
	local hasAuraPack = GamepassManager.HasGamepass(player, Configuration.AURA_PACK)
	local hasPass = GamepassManager.HasGamepass(player, config.gamepassKey) or hasAuraPack
	if not hasPass then return end

	local character = player.Character
	if not character then return end

	removeAura(player)

	-- Buscar carpeta del aura (Assets está dentro de Systems = ServerStorage)
	local assetsFolder = ServerStorage:FindFirstChild("Assets")
	if not assetsFolder then return end
	local aurasGMPS = assetsFolder:FindFirstChild("AurasGMPS")
	if not aurasGMPS then return end
	local auraFolder = aurasGMPS:FindFirstChild(config.folder)
	if not auraFolder then return end

	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	-- Sonido de inicio
	local sound = Instance.new("Sound")
	sound.SoundId = AURA_SOUNDS[key] or "rbxassetid://9122258437"
	sound.Volume = 1
	sound.Parent = hrp
	task.defer(function()
		if hrp.Parent and sound.Parent then
			sound:Play()
			Debris:AddItem(sound, 5)
		end
	end)

	-- Clonar efectos del maniquí al personaje
	for _, auraPartContainer in ipairs(auraFolder:GetChildren()) do
		local partName = auraPartContainer.Name
		if not MANNEQUIN_SKIP[partName] then
			local targetNames = R6_TO_R15[partName] or {partName}

			for _, targetName in ipairs(targetNames) do
				local targetPart = character:FindFirstChild(targetName)
				if targetPart then
					for _, effect in ipairs(auraPartContainer:GetChildren()) do
						if not (effect:IsA("Decal") and string.lower(effect.Name) == "face") then
							local clone = effect:Clone()
							clone:SetAttribute("PlayerAura", true)
							for _, desc in ipairs(clone:GetDescendants()) do
								desc:SetAttribute("PlayerAura", true)
							end

							-- Fade in según tipo
							if clone:IsA("ParticleEmitter") then
								local originalRate = effect.Rate or 10
								clone.Rate = 0
								clone.Enabled = true
								clone.Parent = targetPart
								TweenService:Create(clone, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Rate = originalRate}):Play()

							elseif clone:IsA("PointLight") then
								local originalBrightness = effect.Brightness or 5
								clone.Brightness = 0
								clone.Parent = targetPart
								TweenService:Create(clone, TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Brightness = originalBrightness}):Play()

							else
								clone.Parent = targetPart
							end
						end
					end
				end
			end
		end
	end

	getState(player).activeAura = key
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

local function grantItemsBasedOnPasses(player)
	local autoGrant = {
		{folder = "VIP",        id = Configuration.VIP},
		{folder = "ARMYBOOMS",  id = Configuration.ARMYBOOMS},
		{folder = "LIGHTSTICK", id = Configuration.LIGHTSTICK},
	}

	for _, gp in ipairs(autoGrant) do
		if gp.id and GamepassManager.HasGamepass(player, gp.id) then
			equipItems(player, gp.folder)
		end
	end
end

--=============================================================================
-- SPECIAL COMMANDS (TOMBO, SERE, CHORO, etc.)
--=============================================================================

local function removeSpecialCommandItems(player, commandName)
	local config = SPECIAL_COMMANDS[commandName]
	if not config then return end

	local character = player.Character
	local backpack = player.Backpack

	-- Remover tools del folder
	if config.itemFolder then
		local itemsFolder = ServerStorage:FindFirstChild("Items")
		local typeFolder = itemsFolder and itemsFolder:FindFirstChild(config.itemFolder)
		if typeFolder then
			local function removeMatchingTools(container)
				for _, tool in ipairs(container:GetChildren()) do
					if tool:IsA("Tool") and typeFolder:FindFirstChild(tool.Name) then
						tool:Destroy()
					end
				end
			end
			removeMatchingTools(backpack)
			if character then removeMatchingTools(character) end
		end
	end

	-- Reset ropa a la original
	if config.clothing and character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			local ok, origDesc = pcall(Players.GetHumanoidDescriptionFromUserId, Players, player.UserId)
			if ok and origDesc then
				pcall(function()
					local currentDesc = humanoid:GetAppliedDescription()
					if config.clothing.shirtID then currentDesc.Shirt = origDesc.Shirt end
					if config.clothing.pantsID then currentDesc.Pants = origDesc.Pants end
					humanoid:ApplyDescription(currentDesc)
				end)
			end
		end
	end
end

local function clearAllSpecialCommands(player)
	for commandName in pairs(SPECIAL_COMMANDS) do
		removeSpecialCommandItems(player, commandName)
	end
	getState(player).activeCommand = nil
end

local function handleSpecialCommand(player, commandName)
	local config = SPECIAL_COMMANDS[commandName]
	if not config then return end
	if not GamepassManager.HasGamepass(player, config.gamepassKey) then return end

	local character = player.Character
	if not character then return end

	local state = getState(player)

	-- Si hay otro comando activo, limpiarlo primero
	if state.activeCommand and state.activeCommand ~= commandName then
		removeSpecialCommandItems(player, state.activeCommand)
	end

	if config.clothing then applyClothing(character, config.clothing) end

	if config.accessories then
		for _, accId in pairs(config.accessories) do
			equipAccessory(character, accId)
		end
	end

	if config.itemFolder then equipItems(player, config.itemFolder) end

	state.activeCommand = commandName
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
	clearAllSpecialCommands(player)
	removeAura(player)
	state.giftEquipped = false
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

	for _, blocked in ipairs(BLACKLISTED_USERIDS) do
		if targetUserId == blocked then
			player:Kick("No puedes clonar a este usuario")
			return
		end
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
		attempt = attempt + 1
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
		local isAdmin = ColorEffects.hasPermission(player, Configuration.GroupID, Configuration.ALLOWED_RANKS_OWS)
		for _, target in ipairs(Players:GetPlayers()) do
			if target == player or isAdmin then
				applyEffectToPlayer(target, effectType, color, player)
			end
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
		{pattern = Configuration.CommandSMK,       effect = "smk"},
		{pattern = Configuration.CommandLGHT,      effect = "lght"},
		{pattern = Configuration.CommandPRTCL,     effect = "prtcl"},
		{pattern = Configuration.CommandTRAIL,     effect = "trail"},
		{pattern = Configuration.CommandDestacado, effect = "destacar"},
	}

	local hasCommands = GamepassManager.HasGamepass(player, Configuration.COMMANDS)

	-- 1. Efectos (requieren COMMANDS gamepass)
	if hasCommands then
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
			removeAura(player)
			return
		end
	end

	-- 2. VIP commands (korblox, headless)
	local function checkVIP()
		return Configuration.VIP == nil or GamepassManager.HasGamepass(player, Configuration.VIP)
	end

	local korblox = message:match(Configuration.CommandKorblox)
	if korblox and checkVIP() then
		handleAppearanceCommand(player, "korblox")
		return
	end

	local headless = message:match(Configuration.CommandHeadless)
	if headless and checkVIP() then
		handleAppearanceCommand(player, "headless")
		return
	end

	-- 3. Commands gamepass extras
	if hasCommands then
		local hatMatch = message:match(Configuration.CommandHat)
		if hatMatch then
			for id in string.gmatch(hatMatch, "%d+") do
				equipAccessory(character, tonumber(id))
			end
			return
		end

		local particleMatch = message:match(Configuration.CommandParticle)
		if particleMatch then
			handleParticleCommand(player, character, particleMatch)
			return
		end

		local sizeMatch = message:match(Configuration.CommandSize)
		if sizeMatch then
			local size = tonumber(sizeMatch)
			if size and size >= 0.5 and size <= 2 then
				modifyCharacter(character, {type = "scale", value = size})
			end
			return
		end

		local cloneMatch = message:match(Configuration.CommandClone)
		if cloneMatch then
			handleCloneCommand(player, cloneMatch)
			return
		end
	end

	-- 4. Comandos especiales (cada uno verifica su propio gamepass)
	local SPECIAL_PATTERNS = {
		{pattern = Configuration.CommandTOMBO, name = "TOMBO"},
		{pattern = Configuration.CommandCHORO, name = "CHORO"},
		{pattern = Configuration.CommandSERE,  name = "SERE"},
	}

	for _, entry in ipairs(SPECIAL_PATTERNS) do
		if message:match(entry.pattern) then
			handleSpecialCommand(player, entry.name)
			return
		end
	end

	-- 5. Auras
	local auraMatch = message:match(Configuration.CommandAURA)
	if auraMatch then
		handleAuraCommand(player, auraMatch)
		return
	end

	-- 6. Reset
	local isReset = message:match(Configuration.CommandReset) or message:match(Configuration.CommandReset2)
	if isReset then
		if Configuration.COMMANDS == nil or hasCommands then
			resetCharacter(player)
		end
	end
end

--=============================================================================
-- PLAYER SETUP
--=============================================================================

Players.PlayerAdded:Connect(function(player)
	-- Una sola conexión a CharacterAdded (no anidamos Chatted aquí)
	player.CharacterAdded:Connect(function(character)
		storeOriginalItems(player)
		grantItemsBasedOnPasses(player)
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
				count = count + 1
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