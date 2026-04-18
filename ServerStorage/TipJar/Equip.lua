script.Parent.Equipped:Connect(function()
	--script.Parent.Handle.ProximityPrompt.Enabled = false
	script.ProximityPrompt:FireServer(game.Players.LocalPlayer)
end)

script.Parent.Unequipped:Connect(function()
	if game.Players.LocalPlayer:WaitForChild("PlayerGui").DonateGui.Donate.Donate.DonateName.Username.Text == "@"..game.Players.LocalPlayer.Name then
		game.Players.LocalPlayer:WaitForChild("PlayerGui").DonateGui.Donate.Visible = false
	end
end)