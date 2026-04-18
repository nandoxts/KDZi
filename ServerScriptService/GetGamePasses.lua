local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")

local function safeRequest(url, retries)
	retries = retries or 3
	for i = 1, retries do
		local success, result = pcall(function()
			return HttpService:GetAsync(url)
		end)

		if success then
			local ok, decoded = pcall(function()
				return HttpService:JSONDecode(result)
			end)
			if ok then
				return decoded
			else
				warn("JSON decode failed:", decoded)
			end
		else
			warn("Request failed ("..i.."):", result)
		end

		task.wait(1)
		print("Loading Passes, "..i)
	end
	return nil
end

local function getUserCreatedGamepassesRecursive(userId)
	local gamepasses = {}

	local nextPageCursor = ""
	repeat
		local getGamesUrl = string.format(
			"https://games.roproxy.com/v2/users/%s/games?accessFilter=Public&sortOrder=Asc&limit=50&cursor=%s",
			userId,
			nextPageCursor
		)

		local gamesData = safeRequest(getGamesUrl)
		if not gamesData then
			warn("Failed to fetch games for user:", userId)
			break
		end

		if not gamesData.data or #gamesData.data == 0 then
			warn("No games found for user:", userId)
			break
		end

		for _, universe in pairs(gamesData.data) do
			local nextPageToken = ""

			repeat
				local Url = string.format(
					"https://apis.roproxy.com/game-passes/v1/universes/%s/game-passes?passView=Full&pageSize=100&pageToken=%s",
					universe.id,
					nextPageCursor
				)

				local gpData = safeRequest(Url)
				if gpData then

					nextPageToken = gpData.nextPageToken

					for _, pass in pairs(gpData.gamePasses) do
						table.insert(gamepasses, pass)
					end
				else
					warn("Fetch failed for",universe)
					task.wait(0.2)
				end
			until not nextPageToken or #nextPageToken == 0
		end

		nextPageCursor = gamesData.nextPageCursor
	until not nextPageCursor

	return gamepasses
end

local usernameCache = {}

local function getUsername(userId)
	local nameFromCache = usernameCache[userId]
	if nameFromCache then
		return nameFromCache
	end
	local success, result = pcall(function()
		return game.Players:GetNameFromUserIdAsync(userId)
	end)
	if success then
		usernameCache[userId] = result
		return result
	else
		warn("Error with getting username")
		return
	end
end

local gamepassCache = {}

game.ReplicatedStorage.Remotes.GetGamePasses.OnServerEvent:Connect(function(player, userId, use)
	local userGamepasses = gamepassCache[userId] or getUserCreatedGamepassesRecursive(userId)
	
	gamepassCache[userId] = userGamepasses
	
	if #userGamepasses == 0 then
		warn("No passes returned for:", getUsername(userId))
	end
	game.ReplicatedStorage.Remotes.GetGamePasses:FireClient(player, userId, userGamepasses, use)
end)