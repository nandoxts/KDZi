-- USER PANEL SERVER - v5.0 (Simplified)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local HttpService = game:GetService("HttpService")

local remotesGlobal   = ReplicatedStorage:WaitForChild("RemotesGlobal")
local userPanelFolder = remotesGlobal:WaitForChild("UserPanel")

local GetUserData     = userPanelFolder:WaitForChild("GetUserData")
local RefreshUserData = userPanelFolder:WaitForChild("RefreshUserData")

local function getDescription(userId)
	local ok, result = pcall(function()
		local response = HttpService:GetAsync("https://users.roproxy.com/v1/users/" .. tostring(userId))
		local parsed = HttpService:JSONDecode(response)
		return parsed.description or ""
	end)
	return (ok and result) or ""
end

GetUserData.OnServerInvoke = function(_, targetUserId)
	if not targetUserId then return {} end
	return { description = getDescription(targetUserId) }
end

RefreshUserData.OnServerEvent:Connect(function(requestingPlayer, targetUserId)
	RefreshUserData:FireClient(requestingPlayer, {})
end)

local CheckGamePass = userPanelFolder:FindFirstChild("CheckGamePass")
if CheckGamePass then
	CheckGamePass.OnServerInvoke = function(player, passId)
		if not player or not passId then return false end
		local owns = false
		pcall(function()
			owns = MarketplaceService:UserOwnsGamePassAsync(player.UserId, passId)
		end)
		return owns
	end
end
