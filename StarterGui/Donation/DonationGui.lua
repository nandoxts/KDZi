local MarketplaceService = game:GetService("MarketplaceService")
local TweenService = game:GetService("TweenService")

script.Parent.Donate.Visible = false
local imageCache = {}
local ownershipCache = {}

local function GetGamepassImageId(id)
	local ok, result = pcall(function()
		return MarketplaceService:GetProductInfoAsync(id, Enum.InfoType.GamePass).IconImageAssetId
	end)
	return ok and result or nil
end

local function formatNumber(n): number?
	n = tostring(n)
	return (n:reverse():gsub("...", "%0.", math.floor((#n - 1) / 3)):reverse()) :: number
end

local function fadeIn(frame)
	frame.BackgroundTransparency = 1
	for _, obj in frame:GetDescendants() do
		if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("ImageLabel") then
			local prop = obj:IsA("ImageLabel") and "ImageTransparency" or "TextTransparency"
			obj[prop] = 1
		end
	end
	TweenService:Create(frame, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0}):Play()
	for _, obj in frame:GetDescendants() do
		if obj:IsA("TextLabel") or obj:IsA("TextButton") then
			TweenService:Create(obj, TweenInfo.new(0.18), {TextTransparency = 0}):Play()
		elseif obj:IsA("ImageLabel") then
			TweenService:Create(obj, TweenInfo.new(0.18), {ImageTransparency = 0}):Play()
		end
	end
end

local function applyOwnedState(btn)
	btn.PriceTag.Text = "YA COMPRADO"
	btn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
	btn.Active = false
	btn.AutoButtonColor = false
end

local loadCoroutine = nil

game.ReplicatedStorage.Remotes.GetGamePasses.OnClientEvent:Connect(function(userId, gamePasses, use)
	if use ~= "Donate" then return end

	local player = game.Players:GetPlayerByUserId(userId)
	local list = script.Parent.Donate.Donate.Contents.List
	local header = script.Parent.Donate.Donate.DonateName

	header.Username.Text = "@"..game.Players:GetNameFromUserIdAsync(userId)
	header.DisplayName.Text = player and player.DisplayName or header.Username.Text:sub(2)
	header.ImageLabel.Image = game.Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)

	if player then
		header.Raised.Text = "RAISED: "..utf8.char(0xE002)..player:WaitForChild("Raised").Value
		header.Donated.Text = "DONATED: "..utf8.char(0xE002)..player:WaitForChild("Donated").Value
	end

	if loadCoroutine then coroutine.close(loadCoroutine) end

	for _, v in list:GetChildren() do
		if v:IsA("Frame") and v.Name ~= "_Top" and v.Name ~= "_Bottom" then
			v:Destroy()
		end
	end

	if #gamePasses > 1 then
		table.sort(gamePasses, function(a, b)
			if not a.price or not b.price then return false end
			return a.price < b.price
		end)
	end

	local localUserId = game.Players.LocalPlayer.UserId

	loadCoroutine = coroutine.create(function()
		for i, gamePass in gamePasses do
			if not gamePass.price then continue end

			local card = game.ReplicatedStorage.Templates.GamePassTemp:Clone()
			card.Price.Value = gamePass.price
			card.GamePassId.Value = gamePass.id
			card.GamePassName.Text = gamePass.name
			card.BuyButton.PriceTag.Text = "CARGANDO..."
			card.LayoutOrder = i
			card.Parent = list

			fadeIn(card)

			-- Imagen async
			task.spawn(function()
				local imgId = imageCache[gamePass.id] or GetGamepassImageId(gamePass.id)
				imageCache[gamePass.id] = imgId
				if imgId and card.Parent then
					card.GamePassImage.Image = "rbxassetid://"..imgId
				end
			end)

			-- Ownership async
			task.spawn(function()
				local owned
				if ownershipCache[gamePass.id] ~= nil then
					owned = ownershipCache[gamePass.id]
				else
					local ok, result = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, localUserId, gamePass.id)
					owned = ok and result or false
					ownershipCache[gamePass.id] = owned
				end
				if not card.Parent then return end
				if owned then
					applyOwnedState(card.BuyButton)
				else
					card.BuyButton.PriceTag.Text = utf8.char(0xE002)..formatNumber(gamePass.price)
				end
			end)

			card.BuyButton.MouseButton1Click:Connect(function()
				if ownershipCache[gamePass.id] then return end
				MarketplaceService:PromptGamePassPurchase(game.Players.LocalPlayer, gamePass.id)
			end)

			task.wait(0.05)
		end
	end)

	coroutine.resume(loadCoroutine)
end)

script.Parent.Donate.CloseButton.MouseButton1Click:Connect(function()
	script.Parent.Donate.Visible = false
end)

game.ReplicatedStorage.Remotes.OpenDonate.OnClientEvent:Connect(function(userId, disableInfo)
	if not userId then return end

	local ui = script.Parent.Donate
	local targetPlayer = game.Players:GetPlayerByUserId(userId)

	if ui.Donate.DonateName.Username.Text == "@"..game.Players:GetNameFromUserIdAsync(userId) and ui.Visible then
		return
	end

	ui.Visible = true
	ui.Donate.DonateName.DisplayName.Text = targetPlayer and targetPlayer.DisplayName or game.Players:GetNameFromUserIdAsync(userId)
	ui.Donate.DonateName.Username.Text = "@"..game.Players:GetNameFromUserIdAsync(userId)

	if targetPlayer then
		ui.Donate.DonateName.Raised.Visible = true ~= disableInfo
		ui.Donate.DonateName.Donated.Visible = true ~= disableInfo
		ui.Donate.DonateName.Raised.Text = "RAISED: "..utf8.char(0xE002)..targetPlayer:WaitForChild("Raised").Value
		ui.Donate.DonateName.Donated.Text = "DONATED: "..utf8.char(0xE002)..targetPlayer:WaitForChild("Donated").Value
	else
		ui.Donate.DonateName.Raised.Visible = false
		ui.Donate.DonateName.Donated.Visible = false
	end

	ui.Donate.DonateName.ImageLabel.Image = game.Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)

	for _, v in ui.Donate.Contents.List:GetChildren() do
		if v:IsA("Frame") and v.Name ~= "_Top" and v.Name ~= "_Bottom" then
			v:Destroy()
		end
	end

	game.ReplicatedStorage.Remotes.GetGamePasses:FireServer(userId, "Donate")
end)

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, id, purchased)
	if not player or not id or player ~= game.Players.LocalPlayer then return end
	if purchased then ownershipCache[id] = true end
	local ui = script.Parent.Donate
	local plr = game.Players:FindFirstChild(ui.Donate.DonateName.Username.Text:sub(2))
	if plr then
		ui.Donate.DonateName.Raised.Text = "RAISED: "..utf8.char(0xE002)..plr:WaitForChild("Raised").Value
		ui.Donate.DonateName.Donated.Text = "DONATED: "..utf8.char(0xE002)..plr:WaitForChild("Donated").Value
	end
end)