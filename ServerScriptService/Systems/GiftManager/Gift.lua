-- ═══════════════════════════════════════════════════════════════
--  Gift.lua  |  GiftManager
--  Sistema central de regalos (gamepasses + títulos)
-- ═══════════════════════════════════════════════════════════════

-- ── Services ─────────────────────────────────────────────────
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local BadgeService       = game:GetService("BadgeService")
local Players            = game:GetService("Players")
local HttpService        = game:GetService("HttpService")
local DataStoreService   = game:GetService("DataStoreService")

-- ── Modules ──────────────────────────────────────────────────
local Configuration      = require(ReplicatedStorage.Config.Configuration)
local AdminConfig        = require(ReplicatedStorage.Config.AdminConfig)
local TitleConfig        = require(ReplicatedStorage.Config.TitleConfig)
local ShopManager        = require(script.Parent.ShopManager)
local CentralPurchaseHandler = require(script.Parent.ManagerProcess)

local RemotesGlobal      = ReplicatedStorage:WaitForChild("RemotesGlobal")
local GiftingFolder      = RemotesGlobal:WaitForChild("Gamepass Gifting")
local GiftingConfig      = require(GiftingFolder:WaitForChild("Modules"):WaitForChild("Config"))

local DataStoreQueueMgr  = require(ReplicatedStorage.Systems.DataStore.DataStoreQueueManager)
local GiftDataStore      = DataStoreService:GetDataStore("Gifting.1")
local DataStoreQueue     = DataStoreQueueMgr.new(GiftDataStore, "GiftedGamepasses", 0.15)

-- ── Remotes ──────────────────────────────────────────────────
local Remotes            = GiftingFolder:WaitForChild("Remotes")
local GiftingRemote      = Remotes.Gifting
local OwnershipRemote    = Remotes.Ownership

local BroadcastEvent     = Remotes:FindFirstChild("GiftBroadcastEvent")
if not BroadcastEvent then
	BroadcastEvent = Instance.new("RemoteEvent")
	BroadcastEvent.Name = "GiftBroadcastEvent"
	BroadcastEvent.Parent = Remotes
end

-- ── Constants ────────────────────────────────────────────────
local BADGE_GIFT     = Configuration.BADGES_Gift
local VIP_GAMEPASS   = Configuration.Gamepasses.VIP.id
local GAME_NAME      = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name or "Experiencia"
local WEBHOOK_URL    = "https://discord.com/api/webhooks/1479279603896815618/ptCDNX6y0LLLqIpSx6SzFLLoJvXCYNJ4StdZfAHBa78C_IxK3ihrCzToE29hlJKZQ_x8"
local DEFAULT_AVATAR = "https://t3.rbxcdn.com/9fc30fe577bf95e045c9a3d4abaca05d"

-- ── State ────────────────────────────────────────────────────
-- pendingGifts[donorUserId] = { recipientId, donorName, donorId }
local pendingGifts = {}

-- ═══════════════════════════════════════════════════════════════
-- HELPERS
-- ═══════════════════════════════════════════════════════════════

local function getAllPurchaseables()
	local all = {}
	for _, gp in ipairs(GiftingConfig.Gamepasses) do
		table.insert(all, gp)
	end
	for _, tool in ipairs(GiftingConfig.Tools) do
		table.insert(all, tool)
	end
	for _, title in ipairs(TitleConfig) do
		if title.gamepassId then
			table.insert(all, { title.gamepassId, title.gamepassId })
		end
	end
	return all
end

local function getItemName(gamepassId)
	local ok, asset = pcall(MarketplaceService.GetProductInfo, MarketplaceService, gamepassId, Enum.InfoType.GamePass)
	return ok and asset and asset.Name or nil
end

local function ensureFolder(player)
	local folder = player:FindFirstChild("Gamepasses")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "Gamepasses"
		folder.Parent = player
	end
	return folder
end

local function setFolderValue(folder, name, value)
	local existing = folder:FindFirstChild(name)
	if not existing then
		local v = Instance.new("BoolValue")
		v.Name = name
		v.Value = value
		v.Parent = folder
	else
		existing.Value = value
	end
end

local function grantToOnlinePlayer(recipientUserId, gamepassId)
	local player = Players:GetPlayerByUserId(recipientUserId)
	if not player then return end

	local folder = ensureFolder(player)
	local name = getItemName(gamepassId)
	if name then
		setFolderValue(folder, name, true)
	end

	if gamepassId == VIP_GAMEPASS then
		player:SetAttribute("HasVIP", true)
	end

	if _G.HDConnect_HandleGiftedGamepass then
		pcall(_G.HDConnect_HandleGiftedGamepass, recipientUserId, gamepassId)
	end
end

-- ═══════════════════════════════════════════════════════════════
-- DISCORD WEBHOOK
-- ═══════════════════════════════════════════════════════════════

local function fetchThumbnail(userId)
	local ok, data = pcall(function()
		return HttpService:JSONDecode(HttpService:GetAsync(
			"https://thumbnails.roproxy.com/v1/users/avatar-headshot?userIds=" .. userId .. "&size=150x150&format=Png"
		))
	end)
	return ok and data.data[1].imageUrl or DEFAULT_AVATAR
end

local function sendWebhook(recipientName, recipientId, donorName, donorId, gamepassId)
	pcall(function()
		local itemName = getItemName(gamepassId) or ("ID: " .. tostring(gamepassId))
		HttpService:PostAsync(WEBHOOK_URL, HttpService:JSONEncode({
			embeds = {{
				title     = "Regalo enviado",
				description = "**" .. donorName .. "** le regaló **" .. itemName .. "** a **" .. recipientName .. "**",
				type      = "rich",
				color     = 0xFF0000,
				thumbnail = { url = fetchThumbnail(recipientId) },
				fields    = {
					{ name = "Destinatario",     value = recipientName, inline = true },
					{ name = "Perfil",           value = "[Ver perfil](https://www.roblox.com/users/" .. recipientId .. "/profile)", inline = true },
					{ name = "Donante",          value = donorName, inline = true },
					{ name = "Perfil",           value = "[Ver perfil](https://www.roblox.com/users/" .. donorId .. "/profile)", inline = true },
					{ name = "Item",             value = itemName, inline = true },
					{ name = "Experiencia",      value = GAME_NAME, inline = true },
				},
				footer = { text = GAME_NAME .. " • Gift System" },
				timestamp = DateTime.now():ToIsoDate(),
			}},
		}), Enum.HttpContentType.ApplicationJson)
	end)
end

-- ═══════════════════════════════════════════════════════════════
-- GIFT LOGIC
-- ═══════════════════════════════════════════════════════════════

local function giftFree(admin, gamepass, recipientUserId, recipientName)
	if not admin or not gamepass or not gamepass[1] or not recipientUserId or not recipientName then
		if admin then GiftingRemote:FireClient(admin, "Error", "Parámetros inválidos") end
		return
	end

	local gamepassId = gamepass[1]

	-- Verificar si ya lo tiene
	if ShopManager.HasGamepassByUserId(recipientUserId, gamepassId) then
		local name = getItemName(gamepassId) or "Unknown"
		GiftingRemote:FireClient(admin, "Error", recipientName .. " ya tiene " .. name)
		return
	end

	-- Guardar en DataStore
	DataStoreQueue:SetAsync(recipientUserId .. "-" .. gamepassId, true)

	-- Conceder al jugador online
	grantToOnlinePlayer(recipientUserId, gamepassId)

	-- Webhook Discord
	sendWebhook(recipientName, recipientUserId, admin.Name, admin.UserId, gamepassId)

	-- Broadcast a todos los clientes
	BroadcastEvent:FireAllClients("GiftNotification", {
		Donor     = admin.Name,
		Recipient = recipientName,
		GamepassName = getItemName(gamepassId) or "Item",
	})

	-- Notificar a ShopGifting
	if _G.ShopGifting_OnItemGifted then
		pcall(_G.ShopGifting_OnItemGifted, recipientUserId, "gamepass", gamepassId)
	end

	-- Confirmar al admin
	GiftingRemote:FireClient(admin, "Purchase")

	-- Badge
	if BADGE_GIFT and BADGE_GIFT ~= 0 then
		pcall(function()
			if not BadgeService:UserHasBadgeAsync(admin.UserId, BADGE_GIFT) then
				BadgeService:AwardBadge(admin.UserId, BADGE_GIFT)
			end
		end)
	end
end

-- ═══════════════════════════════════════════════════════════════
-- EVENT: SOLICITUD DE REGALO
-- ═══════════════════════════════════════════════════════════════

GiftingRemote.OnServerEvent:Connect(function(player, gamepass, userId, username, identifier)
	if not gamepass or type(gamepass) ~= "table" or not gamepass[1] or not gamepass[2] then
		GiftingRemote:FireClient(player, "Error", "Datos inválidos")
		return
	end

	userId     = tonumber(userId)
	identifier = tonumber(identifier)
	if not userId or userId == 0 then return end
	if not identifier or identifier == 0 then identifier = userId end

	local recipientName
	local ok = pcall(function() recipientName = Players:GetNameFromUserIdAsync(userId) end)
	if not ok or not recipientName then return end

	for _, item in ipairs(getAllPurchaseables()) do
		if item[1] == gamepass[1] and item[2] == gamepass[2] then
			if player.UserId == userId then return end

			if AdminConfig:IsAdmin(player) then
				giftFree(player, gamepass, userId, recipientName)
			else
				if not ShopManager.HasGamepassByUserId(userId, gamepass[1]) then
					pendingGifts[player.UserId] = {
						recipientId = userId,
						donorName   = player.Name,
						donorId     = player.UserId,
					}
					MarketplaceService:PromptProductPurchase(player, gamepass[2])
				else
					local name = getItemName(gamepass[1])
					if name then
						GiftingRemote:FireClient(player, "Error", recipientName .. " ya tiene " .. name)
					end
				end
			end
			return
		end
	end
end)

-- ═══════════════════════════════════════════════════════════════
-- EVENT: PLAYER ADDED (crear folder + sincronizar ownership)
-- ═══════════════════════════════════════════════════════════════

Players.PlayerAdded:Connect(function(player)
	local folder = ensureFolder(player)

	local function syncOwnership()
		for _, item in ipairs(getAllPurchaseables()) do
			local id = item[1]
			if id and type(id) == "number" then
				local owns = ShopManager.HasGamepassByUserId(player.UserId, id)
				local name = getItemName(id)
				if name then
					setFolderValue(folder, name, owns)
				end
			end
		end
	end

	syncOwnership()
	player.CharacterAdded:Connect(syncOwnership)
end)

-- ═══════════════════════════════════════════════════════════════
-- EVENT: COMPRA DIRECTA DE GAMEPASS
-- ═══════════════════════════════════════════════════════════════

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamepassId, wasPurchased)
	if not wasPurchased or not player or not player.Parent then return end

	-- Verificar que es uno de nuestros items
	local isOurs = false
	for _, item in ipairs(getAllPurchaseables()) do
		if item[1] == gamepassId then isOurs = true; break end
	end
	if not isOurs then return end

	grantToOnlinePlayer(player.UserId, gamepassId)
end)

-- ═══════════════════════════════════════════════════════════════
-- PROCESS RECEIPT: Regalo pagado (no-admin)
-- ═══════════════════════════════════════════════════════════════

local function handleGiftPurchase(receiptInfo)
	for _, item in ipairs(getAllPurchaseables()) do
		if receiptInfo.ProductId == item[2] then
			local giftInfo = pendingGifts[receiptInfo.PlayerId]
			if not giftInfo then return Enum.ProductPurchaseDecision.NotProcessedYet end
			pendingGifts[receiptInfo.PlayerId] = nil

			local recipientId = giftInfo.recipientId
			local donorName   = giftInfo.donorName
			local donorId     = giftInfo.donorId
			local gamepassId  = item[1]

			-- Guardar en DataStore
			DataStoreQueue:SetAsync(recipientId .. "-" .. gamepassId, true)

			-- Webhook Discord
			pcall(function()
				local recipientName = Players:GetNameFromUserIdAsync(recipientId)
				sendWebhook(recipientName, recipientId, donorName, donorId, gamepassId)
			end)

			-- Conceder al jugador online
			grantToOnlinePlayer(recipientId, gamepassId)

			-- Notificar al donante
			local donor = Players:GetPlayerByUserId(donorId)
			if donor then
				GiftingRemote:FireClient(donor, "Purchase")
				if BADGE_GIFT and BADGE_GIFT ~= 0 then
					pcall(function()
						if not BadgeService:UserHasBadgeAsync(donor.UserId, BADGE_GIFT) then
							BadgeService:AwardBadge(donor.UserId, BADGE_GIFT)
						end
					end)
				end
			end

			-- Notificar a ShopGifting
			if _G.ShopGifting_OnItemGifted then
				pcall(_G.ShopGifting_OnItemGifted, recipientId, "gamepass", gamepassId)
			end

			return Enum.ProductPurchaseDecision.PurchaseGranted
		end
	end
	return Enum.ProductPurchaseDecision.NotProcessedYet
end

CentralPurchaseHandler.registerGiftHandler(handleGiftPurchase)

-- ═══════════════════════════════════════════════════════════════
-- REMOTE: Ownership check (usado por clientes)
-- ═══════════════════════════════════════════════════════════════

OwnershipRemote.OnServerInvoke = function(player, gamepassId)
	return ShopManager.HasGamepass(player, gamepassId)
end