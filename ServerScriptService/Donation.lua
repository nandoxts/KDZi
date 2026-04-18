local players = game:GetService("Players")
local replicatedStorage = game:GetService("ReplicatedStorage")

local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local MessagingService = game:GetService("MessagingService")
local Workspace = game:GetService("Workspace")

local AdminConfig = require(replicatedStorage.Config.AdminConfig)

local RemotesGlobal   = replicatedStorage:FindFirstChild("RemotesGlobal") or Instance.new("Folder")
RemotesGlobal.Name = "RemotesGlobal"
RemotesGlobal.Parent = replicatedStorage

local CommandsFolder  = RemotesGlobal:FindFirstChild("Commands") or Instance.new("Folder")
CommandsFolder.Name = "Commands"
CommandsFolder.Parent = RemotesGlobal

local EventMessage    = CommandsFolder:FindFirstChild("EventMessage") or Instance.new("RemoteEvent")
EventMessage.Name = "EventMessage"
EventMessage.Parent = CommandsFolder

local database = DataStoreService:GetDataStore("DonatedRaised")
local sessionData = {}

local gameGamePasses = game.ReplicatedStorage:FindFirstChild("GamePasses")

-- ── Assets para efectos ──────────────────────────────────────
local Assets = game:GetService("ServerStorage"):WaitForChild("Systems"):WaitForChild("Assets")
local Auras = Assets.Auras
local RobuxHammerGiant = Assets:WaitForChild("RobuxHammerGiant")

-- ── Tiers de efectos por monto ───────────────────────────────
local DONATION_EFFECTS = {
	{MaxAmount = 10,        Attachment = "bajo",     Duration = 2.3,  SoundId = "rbxassetid://82616454607059",   Volume = 0.3, GiantEffect = false},
	{MaxAmount = 100,       Attachment = "sayayin1",  Duration = 4,    SoundId = "rbxassetid://7727672197",       Volume = 0.5, GiantEffect = false},
	{MaxAmount = 200,       Attachment = "sayayin2",  Duration = 4.5,  SoundId = "rbxassetid://972919590",        Volume = 0.5, GiantEffect = false},
	{MaxAmount = 300,       Attachment = "sayayin3",  Duration = 4.5,  SoundId = "rbxassetid://2261507666",       Volume = 0.5, GiantEffect = false},
	{MaxAmount = 500,       Attachment = "bajo1",     Duration = 3,    SoundId = "rbxassetid://4612383790",       Volume = 0.5, GiantEffect = false},
	{MaxAmount = 600,       Attachment = "bajo2",     Duration = 3,    SoundId = "rbxassetid://84795270640054",   Volume = 0.5, GiantEffect = false},
	{MaxAmount = 700,       Attachment = "bajo3",     Duration = 3,    SoundId = "rbxassetid://119398240584172",  Volume = 0.5, GiantEffect = false},
	{MaxAmount = 800,       Attachment = "bajo4",     Duration = 5,    SoundId = "rbxassetid://137651128719857",  Volume = 0.5, GiantEffect = false},
	{MaxAmount = 1000,      Attachment = "bajo5",     Duration = 20,   SoundId = "rbxassetid://74948903354832",   Volume = 0.5, GiantEffect = false},
	{MaxAmount = 2000,      Attachment = "bajo6",     Duration = 21,   SoundId = "rbxassetid://74948903354832",   Volume = 0.5, GiantEffect = false},
	{MaxAmount = 3000,      Attachment = "bajo7",     Duration = 22,   SoundId = "rbxassetid://18866194712",      Volume = 0.5, GiantEffect = false},
	{MaxAmount = 5000,      Attachment = "bajo8",     Duration = 23,   SoundId = "rbxassetid://9043179746",       Volume = 0.5, GiantEffect = false},
	{MaxAmount = 7000,      Attachment = "bajo9",     Duration = 24,   SoundId = "rbxassetid://8982060550",       Volume = 0.8, GiantEffect = false},
	{MaxAmount = 10000,     Attachment = "bajo10",    Duration = 25,   SoundId = "rbxassetid://8982060550",       Volume = 1,   GiantEffect = true},
	{MaxAmount = math.huge, Attachment = "bajo9",     Duration = 30,   SoundId = "rbxassetid://8982060550",       Volume = 1.2, GiantEffect = true},
}



local showOnLeaderstats = false

-------------------------------------


local function formatNumber(n): number?
	n = tostring(n)
	return (n:reverse():gsub("...", "%0.", math.floor((#n - 1) / 3)):reverse()) :: number
end

-- ── Efectos visuales/sonoros ─────────────────────────────────
local function createSound(parent, soundId, volume)
	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Volume = volume
	sound.Parent = parent
	sound:Play()
	sound.Ended:Once(function() sound:Destroy() end)
end

local function spawnGiantDonationEffect(donatingPlayer, donatedPlayer, amount)
	if not RobuxHammerGiant or not donatingPlayer or not donatedPlayer then return end
	local giantClone = RobuxHammerGiant:Clone()
	local mamboKing = Workspace:FindFirstChild("KDZ")
	if not mamboKing then giantClone:Destroy(); return end
	giantClone.Parent = mamboKing

	for _, part in ipairs(giantClone:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CanCollide = false; part.CanTouch = false; part.CanQuery = false
		end
	end

	local billboard = giantClone:FindFirstChild("BillboardGuiAnimation", true)
	if billboard and billboard:FindFirstChild("Frame") then
		local f = billboard.Frame
		if f:FindFirstChild("TopText") then f.TopText.Text = "@"..donatingPlayer.Name.." donó" end
		if f:FindFirstChild("MiddleText") then f.MiddleText.Text = formatNumber(amount).." Robux" end
		if f:FindFirstChild("BottomText") then f.BottomText.Text = "Para @"..donatedPlayer.Name end
	end

	local humanoid = giantClone:FindFirstChildOfClass("Humanoid")
	if humanoid then
		task.spawn(function()
			local ok, desc = pcall(players.GetHumanoidDescriptionFromUserId, players, donatingPlayer.UserId)
			if ok and desc and humanoid and humanoid.Parent then
				local head = giantClone:FindFirstChild("Head", true)
				local origFace = head and head:FindFirstChildOfClass("Decal") and head:FindFirstChildOfClass("Decal").Texture
				desc.Face = 0
				pcall(humanoid.ApplyDescription, humanoid, desc)
				if origFace and head then
					local d = head:FindFirstChildOfClass("Decal")
					if d then d.Texture = origFace end
				end
			end
		end)
	end

	task.delay(40, function()
		if giantClone and giantClone.Parent then giantClone:Destroy() end
	end)
end

local function applyDonationEffect(targetPlayer, amount, donatingPlayer)
	if not targetPlayer or not targetPlayer.Character then return end
	local hrp = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	local selectedEffect = nil
	for i = #DONATION_EFFECTS, 1, -1 do
		if amount >= DONATION_EFFECTS[i].MaxAmount then
			selectedEffect = DONATION_EFFECTS[i]; break
		end
	end
	if not selectedEffect then
		selectedEffect = DONATION_EFFECTS[1]
	end

	local aura = Auras:FindFirstChild(selectedEffect.Attachment)
	if aura then
		local clone = aura:Clone()
		clone.Parent = hrp
		for _, p in ipairs(clone:GetChildren()) do
			if p:IsA("ParticleEmitter") or p:IsA("Beam") then p.Enabled = true end
		end
		task.delay(selectedEffect.Duration, function()
			for _, p in ipairs(clone:GetChildren()) do
				if p:IsA("ParticleEmitter") or p:IsA("Beam") then p.Enabled = false end
			end
			task.wait(1)
			if clone and clone.Parent then clone:Destroy() end
		end)
	end

	createSound(hrp, selectedEffect.SoundId, selectedEffect.Volume)

	if selectedEffect.GiantEffect then
		spawnGiantDonationEffect(donatingPlayer, targetPlayer, amount)
	end
end

local function getUserProfile(userId:number)
	local profileUrl = "https://www.roblox.com/users/%d/profile"
	
	return string.format(profileUrl, userId)
end

local function setupLeaderstats(player)
	local leaderstats = player:FindFirstChild("leaderstats") or Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player
	
	local raised = Instance.new("NumberValue")
	raised.Name = "Raised"
	raised.Parent = leaderstats
	
	local donated = Instance.new("NumberValue")
	donated.Name = "Donated"
	donated.Parent = leaderstats
	
	
	
	local trackedRaised = player:FindFirstChild("Raised")
	local trackedDonated = player:FindFirstChild("Donated")
	
	raised.Value = trackedRaised.Value
	donated.Value = trackedDonated.Value
	
	
	trackedRaised.Changed:Connect(function()
		raised.Value = trackedRaised.Value
	end)
	trackedDonated.Changed:Connect(function()
		donated.Value = trackedDonated.Value
	end)
end


-------------------------------------


local function playerJoined(player)
	local char = player.Character or player.CharacterAdded:Wait()


	local raisedRobux = Instance.new("NumberValue")
	raisedRobux.Name = "Raised"
	raisedRobux.Parent = player

	local donatedRobux = Instance.new("NumberValue")
	donatedRobux.Name = "Donated"
	donatedRobux.Parent = player
	
	
	
	if showOnLeaderstats then
		setupLeaderstats(player)
	end
	
	

	local success = nil
	local playerData = nil
	local attempt = 1

	repeat
		success, playerData = pcall(function()
			return database:GetAsync(player.UserId)
		end)
		attempt += 1
		if not success then
			warn(playerData)
			task.wait(2)
		end
	until success or attempt == 5

	if success then
		if not playerData then
			playerData = {
				["Donated"] = 0,
				["Raised"] = 0,
			}
		end
		sessionData[player.UserId] = playerData
	else
		warn("Unable to get data for", player.UserId)
		player:Kick("Something went wrong. Try again later")
	end
	
	
	if sessionData[player.UserId].Donated then
		donatedRobux.Value = sessionData[player.UserId].Donated
	end
	donatedRobux.Changed:Connect(function()
		sessionData[player.UserId].Donated = donatedRobux.Value
	end)
	
	if sessionData[player.UserId].Raised then
		raisedRobux.Value = sessionData[player.UserId].Raised
	end
	raisedRobux.Changed:Connect(function()
		sessionData[player.UserId].Raised = raisedRobux.Value
	end)
end
players.PlayerAdded:Connect(playerJoined)

local function playerLeft(player)
	if sessionData[player.UserId] then
		local success = nil
		local errorMsg = nil
		local attempt = 1

		repeat
			success, errorMsg = pcall(function()
				database:SetAsync(player.UserId, sessionData[player.UserId])
			end)
			attempt += 1
			if not success then
				warn(errorMsg)
				task.wait(2)
			end
		until success or attempt == 5

		if success then
			--print("Data saved for", player.Name)
		else
			warn("Unable to save for", player.Name)
		end
	end
end
players.PlayerRemoving:Connect(playerLeft)

function ServerShutdown()
	if RunService:IsStudio() then
		return
	end

	for i, player in ipairs(players:GetPlayers()) do
		playerLeft(player)
	end
	
	task.wait(5)
end
game:BindToClose(ServerShutdown)


-------------------------------------


local function Donate(player, plr:Player, price, def, test)
	
	if not player or not plr or not price or not def then return end
	
	if def == "Donated" and not test then
		plr:WaitForChild("Donated").Value += price
	elseif def == "Raised" then
		local char = plr.Character or plr.CharacterAdde:Wait()
		
		if not test then
			plr:WaitForChild("Raised").Value += price
		end
		
		local jar = char:FindFirstChild("Tip Jar")
		
		if jar then
			local billboard = jar.Handle:FindFirstChild("BillboardGui")
			if billboard then
				billboard.TextLabel.TextTransparency = 0
				billboard.TextLabel.Text = player.DisplayName.." donated "..utf8.char(0xE002)..price
				billboard.TextLabel.UIStroke.Transparency = 0.5
				billboard.Enabled = true
			end
			jar.Handle:FindFirstChild("Donate"):Play()
			task.spawn(function()
				for i = 1, 50 do
					jar.Handle.Attachment.ParticleEmitter:Emit(1)
					task.wait(0.02)
				end
				task.wait(1)
				if billboard then
					TweenService:Create(billboard.TextLabel, TweenInfo.new(0.25), {TextTransparency = 1}):Play()
					local tween = TweenService:Create(billboard.TextLabel.UIStroke, TweenInfo.new(0.25), {Transparency = 1})
					tween:Play()
					
					tween.Completed:Wait()
					billboard.Enabled = false
				end
			end)
		end
		
		local text = player.Name.." donated "..utf8.char(0xE002)..price.." to "..plr.Name

		-- Efectos de aura + sonido sobre el receptor
		task.spawn(function()
			applyDonationEffect(plr, price, player)
		end)
		
		if price < 10000 then
			EventMessage:FireAllClients(text, "donation")
		else
			local message = player.Name.." donated "..utf8.char(0xE002)..string.format("%s", formatNumber(price)).." to "..plr.Name
			
			local data = {
				["message"] = message,
				["serverId"] = game.JobId,
				["test"] = test,
				["colorType"] = price >= 1000000 and "donation" or "donation"
			}
			
			MessagingService:PublishAsync("Donation", data)
		end
	end
	
end

game:GetService("MarketplaceService").PromptGamePassPurchaseFinished:Connect(function(player, gamepassId, purchased)
	if not purchased then return end
	
	local productInfo

	local success, error = pcall(function()
		productInfo = game:GetService("MarketplaceService"):GetProductInfoAsync(gamepassId, Enum.InfoType.GamePass)
		return productInfo
	end)
	
	if productInfo and (not gameGamePasses or not gameGamePasses:FindFirstChild(gamepassId)) then
		Donate(player, player, productInfo.PriceInRobux, "Donated")
		local receivingPlayer = game.Players:FindFirstChild(productInfo.Creator["Name"])

		if receivingPlayer then
			Donate(player, receivingPlayer, productInfo.PriceInRobux, "Raised")
		end
	end

end)


-------------------------------------


MessagingService:SubscribeAsync("Donation", function(data)
	local message = data.Data.message
	local serverId = data.Data.serverId
	local test = data.Data.test
	local txt = (serverId ~= game.JobId and "[GLOBAL] " or "[SERVER] ")..message

	EventMessage:FireAllClients(txt, "donation")
end)


-------------------------------------
-- ── Comando ;fk username cantidad ────────────────────────────
-------------------------------------

local function setupFKCommand(player)
	player.Chatted:Connect(function(msg)
		if not AdminConfig:IsAdmin(player) then return end

		local lower = msg:lower()
		if not lower:match("^;fk%s") then return end

		local args = {}
		for word in msg:gmatch("%S+") do
			table.insert(args, word)
		end
		local targetName = args[2]
		local amount = tonumber(args[3])

		if not targetName or not amount or amount <= 0 then return end

		local target = players:FindFirstChild(targetName)
		if not target then
			for _, p in ipairs(players:GetPlayers()) do
				if p.Name:lower():find(targetName:lower(), 1, true) then
					target = p
					break
				end
			end
		end

		if not target then return end

		applyDonationEffect(target, amount, player)

		local text = player.Name.." donated "..utf8.char(0xE002)..formatNumber(amount).." to "..target.Name
		EventMessage:FireAllClients(text, "donation")
	end)
end

-- Jugadores ya en el servidor cuando el script carga (ej. Studio)
for _, player in ipairs(players:GetPlayers()) do
	setupFKCommand(player)
end
players.PlayerAdded:Connect(setupFKCommand)