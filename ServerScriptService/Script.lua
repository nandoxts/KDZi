local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

local GROUP_ID = 156212776
local tool = ServerStorage:WaitForChild("Tip Jar")

local function giveTool(player)
	if player:IsInGroup(GROUP_ID) then

		local backpack = player:FindFirstChild("Backpack")
		if not backpack then return end

		-- Evita duplicados
		if backpack:FindFirstChild("Tip Jar") then return end

		local clone = tool:Clone()
		clone.Parent = backpack
	end
end

Players.PlayerAdded:Connect(function(player)

	player.CharacterAdded:Connect(function()
		task.wait(1)
		giveTool(player)
	end)

end)
