-- USER PANEL SERVER - v5.0 (Simplified)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local remotesGlobal   = ReplicatedStorage:WaitForChild("RemotesGlobal")
local userPanelFolder = remotesGlobal:WaitForChild("UserPanel")

local GetUserData     = userPanelFolder:WaitForChild("GetUserData")
local RefreshUserData = userPanelFolder:WaitForChild("RefreshUserData")
local SetStatus       = userPanelFolder:WaitForChild("SetStatus")

-- ══ CACHÉ ════════════════════════════════════════════════════
local descriptionCache = {}
local CACHE_TTL = 120

-- Estados custom de los jugadores (en memoria de sesión)
local playerStatuses = {}
local MAX_STATUS_LEN = 80

local function getDescription(userId)
	local cached = descriptionCache[userId]
	if cached and (os.clock() - cached.time) < CACHE_TTL then
		return cached.value
	end
	local ok, result = pcall(function()
		local response = HttpService:GetAsync("https://users.roproxy.com/v1/users/" .. tostring(userId))
		local parsed = HttpService:JSONDecode(response)
		return parsed.description or ""
	end)
	local desc = (ok and result) or ""
	descriptionCache[userId] = { value = desc, time = os.clock() }
	return desc
end

-- ══ REMOTES ══════════════════════════════════════════════════
GetUserData.OnServerInvoke = function(_, targetUserId)
	if not targetUserId then return {} end
	local customStatus = playerStatuses[targetUserId] or nil
	return {
		description = getDescription(targetUserId),
		status = customStatus,
	}
end

SetStatus.OnServerInvoke = function(requestingPlayer, newStatus)
	if not requestingPlayer then return false end
	if type(newStatus) ~= "string" then return false end
	newStatus = newStatus:sub(1, MAX_STATUS_LEN):gsub("[\n\r]", " ")
	if newStatus == "" then
		playerStatuses[requestingPlayer.UserId] = nil
	else
		playerStatuses[requestingPlayer.UserId] = newStatus
	end
	return true
end

RefreshUserData.OnServerEvent:Connect(function(requestingPlayer, targetUserId)
	RefreshUserData:FireClient(requestingPlayer, {})
end)
