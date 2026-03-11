--[[
	═══════════════════════════════════════════════════════════════
	TitlesTab.lua — Tab de Títulos para la tienda
	Usa ShopItemList (Shared) para cards + slide + regalo.
	═══════════════════════════════════════════════════════════════
]]

local Players            = game:GetService("Players")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local TitleConfig       = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("TitleConfig"))
local AdminConfig       = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("AdminConfig"))
local Notify            = require(ReplicatedStorage:WaitForChild("Systems"):WaitForChild("NotificationSystem"):WaitForChild("NotificationSystem"))
local ShopItemList      = require(script.Parent.Parent:WaitForChild("Shared"):WaitForChild("ShopItemList"))

local player  = Players.LocalPlayer
local isAdmin = AdminConfig:IsAdmin(player)

local ROBUX_CHAR = utf8.char(0xE002)

local TitlesTab = {}

-- ═══════════════════════════════════════════════════════════════
-- HELPERS
-- ═══════════════════════════════════════════════════════════════
local function parseColor(hex, fallback)
	if not hex then return fallback end
	local h = hex:gsub("#", "")
	local r = tonumber(h:sub(1, 2), 16) or 255
	local g = tonumber(h:sub(3, 4), 16) or 255
	local b = tonumber(h:sub(5, 6), 16) or 255
	return Color3.fromRGB(r, g, b)
end

-- ═══════════════════════════════════════════════════════════════
-- BUILD
-- ═══════════════════════════════════════════════════════════════
function TitlesTab.build(parent, THEME, state, screenGui)

	-- ── Remotes ──────────────────────────────────────────────────
	local GetPlayersWithoutItem, GiftingRemote, OwnershipUpdated
	local ownershipRemote, equipRemote

	task.spawn(function()
		local rg = ReplicatedStorage:WaitForChild("RemotesGlobal", 5)
		if not rg then return end
		local shopFolder = rg:FindFirstChild("ShopGifting")
		if shopFolder then
			GetPlayersWithoutItem = shopFolder:FindFirstChild("GetPlayersWithoutItem")
			OwnershipUpdated      = shopFolder:FindFirstChild("OwnershipUpdated")
		end
		local giftFolder = rg:FindFirstChild("Gamepass Gifting")
		if giftFolder then
			local remotes = giftFolder:FindFirstChild("Remotes")
			if remotes then
				GiftingRemote   = remotes:FindFirstChild("Gifting")
				ownershipRemote = remotes:FindFirstChild("Ownership")
			end
		end
		local titleFolder = rg:FindFirstChild("Title")
		if titleFolder then
			equipRemote = titleFolder:FindFirstChild("Titles")
		end
	end)

	-- ── Items (gamepassId = id para marketplace) ──────────────────
	local items = {}
	for _, t in ipairs(TitleConfig) do
		if t.gamepassId and t.name then
			table.insert(items, {
				id      = t.gamepassId,
				titleId = t.id,          -- string id para equip remote ("fresita", etc.)
				name    = t.name,
				price   = t.price or 500,
				icon    = t.icon or "",
				color   = parseColor(t.color, THEME.accent),
			})
		end
	end

	-- ── ShopItemList ─────────────────────────────────────────────
	local listApi = ShopItemList.build({
		parent        = parent,
		theme         = THEME,
		state         = state,
		items         = items,
		emptyListText = "No hay títulos disponibles",

		onBuy = function(item)
			pcall(function() MarketplaceService:PromptGamePassPurchase(player, item.id) end)
		end,

		onEquip = function(item)
			if equipRemote then
				equipRemote:FireServer(item.titleId)
			end
		end,

		onGift = function(item, userId, username, displayName)
			if GiftingRemote then
				GiftingRemote:FireServer({ item.id, item.id }, userId, username, player.UserId)
				Notify:Info("Regalo", "Procesando regalo de " .. item.name .. " para " .. displayName, 3)
			else
				Notify:Error("Error", "Sistema de regalos no disponible", 3)
			end
		end,

		loadPlayers = function(item, callback)
			task.spawn(function()
				if not GetPlayersWithoutItem then task.wait(1) end
				if GetPlayersWithoutItem then
					local result = GetPlayersWithoutItem:InvokeServer("title", item.id)
					callback(result and result.success and result.players or {})
				else
					callback({})
				end
			end)
		end,
	})

	-- ── Purchase callback (por si compran para sí mismos) ─────────
	local mpConn = MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(plr, passId, bought)
		if plr ~= player or not bought then return end
		listApi.markOwned(passId)
	end)
	-- ── Ownership check al cargar ─────────────────────────────────
	for _, item in ipairs(items) do
		task.spawn(function()
			local owned = false
			if ownershipRemote then
				local ok, res = pcall(function() return ownershipRemote:InvokeServer(item.id) end)
				owned = ok and res or false
			else
				local ok, res = pcall(function()
					return MarketplaceService:UserOwnsGamePassAsync(player.UserId, item.id)
				end)
				owned = ok and res or false
			end
			if owned then listApi.markOwned(item.id) end
		end)
	end
	-- ── OwnershipUpdated ──────────────────────────────────────────
	task.spawn(function()
		task.wait(1)
		if OwnershipUpdated then
			OwnershipUpdated.OnClientEvent:Connect(function(data)
				if data.type == "title" then
					listApi.handleOwnershipRemoved(data.itemId, data.userId)
					Notify:Success("Actualizado", data.username .. " ahora tiene este título", 2)
				end
			end)
		end
	end)

	local function cleanup()
		mpConn:Disconnect()
		listApi.cleanup()
	end

	return { panel = listApi.panel, cleanup = cleanup }
end

return TitlesTab

