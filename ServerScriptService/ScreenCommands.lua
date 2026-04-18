local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local liveSystem = ReplicatedStorage:WaitForChild("LiveSystem")
local currentTarget = liveSystem:WaitForChild("CurrentTarget")

-- 🔐 WHITELIST (admins)
local ADMINS = {
	9514936373
}

local function isAdmin(player)
	return table.find(ADMINS, player.UserId) ~= nil
end