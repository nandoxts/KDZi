script.Parent.Triggered:Connect(function(plr:Player)
	local toolOwner = game.Players:FindFirstChild(script.Parent.Parent.Parent.Parent.Name)
	if not toolOwner then return end
	game.ReplicatedStorage.Remotes.OpenDonate:FireClient(plr, toolOwner.UserId)
end)