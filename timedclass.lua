--[[
  TimePlayedClass, RenanMSV @2023

  A script designed to update a leaderboard with
  the top 10 players who most play your game.
  
  Do not change this script. All configurations can be found
  in the Settings script.
]]

local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

local Config = require(script.Parent.Settings)

local TimePlayedClass = {}
TimePlayedClass.__index = TimePlayedClass


function TimePlayedClass.new()
	local new = {}
	setmetatable(new, TimePlayedClass)

	new._dataStoreName = Config.DATA_STORE
	new._dataStoreStatName = Config.NAME_OF_STAT
	new._scoreUpdateDelay = Config.SCORE_UPDATE * 60
	new._boardUpdateDelay = Config.LEADERBOARD_UPDATE * 60
	new._useLeaderstats = Config.USE_LEADERSTATS
	new._nameLeaderstats = Config.NAME_LEADERSTATS_TIME
	new._nameLeaderstatsLevel = Config.NAME_LEADERSTATS_LEVEL
	new._minutesPerLevel = Config.LEVEL_UP_MINUTES
	new._show1stPlaceAvatar = Config.SHOW_1ST_PLACE_AVATAR
	if new._show1stPlaceAvatar == nil then new._show1stPlaceAvatar = true end
	new._doDebug = Config.DO_DEBUG

	new._datastore = nil
	new._levelDataStore = nil
	new._scoreBlock = script.Parent.ScoreBlock
	new._updateBoardTimer = script.Parent.UpdateBoardTimer.Timer.TextLabel

	new._apiServicesEnabled = false
	new._isMainScript = nil

	new._isDancingRigEnabled = false
	new._dancingRigModule = nil

	new:_init()

	return new
end


function TimePlayedClass:_init()

	self:_checkIsMainScript()

	if self._isMainScript then
		if not self:_checkDataStoreUp() then
			self:_clearBoard()
			self._scoreBlock.NoAPIServices.Warning.Visible = true
			return
		end
	else
		self._apiServicesEnabled = (ServerStorage:WaitForChild("TopTimePlayedLeaderboard_NoAPIServices_Flag", 99) :: BoolValue).Value
		if not self._apiServicesEnabled then
			self:_clearBoard()
			self._scoreBlock.NoAPIServices.Warning.Visible = true
			return
		end
	end

	local suc, err = pcall(function ()
		self._datastore = DataStoreService:GetOrderedDataStore(self._dataStoreName)
		self._levelDataStore = DataStoreService:GetDataStore(self._dataStoreName .. "_Levels")
	end)
	if not suc or self._datastore == nil then warn("Failed to load OrderedDataStore. Error:", err) script.Parent:Destroy() end

	self:_checkDancingRigEnabled()

	-- Crea leaderstats + tiempo + nivel para cada jugador
	if self._useLeaderstats and self._isMainScript then
		local levelDS = self._levelDataStore

		local function setupPlayerStats(player)
			task.spawn(function()
				-- Crear folder leaderstats si no existe
				local ls = player:FindFirstChild("leaderstats")
				if not ls then
					ls = Instance.new("Folder")
					ls.Name = "leaderstats"
					ls.Parent = player
				end

				-- Stat de tiempo jugado
				if not ls:FindFirstChild(self._nameLeaderstats) then
					local t = Instance.new("NumberValue")
					t.Name = self._nameLeaderstats
					t.Value = 0
					t.Parent = ls
				end

				-- Stat de nivel (cargado desde DataStore)
				if not ls:FindFirstChild(self._nameLeaderstatsLevel) then
					local lvl = Instance.new("NumberValue")
					lvl.Name = self._nameLeaderstatsLevel
					lvl.Value = 1
					lvl.Parent = ls
					if levelDS then
						local ok, saved = pcall(function()
							return levelDS:GetAsync("level_" .. player.UserId)
						end)
						if ok and saved and saved > 1 then
							lvl.Value = saved
						end
					end
				end
			end)
		end

		-- Jugadores que ya están en el juego
		for _, p in ipairs(Players:GetPlayers()) do
			setupPlayerStats(p)
		end

		Players.PlayerAdded:Connect(setupPlayerStats)

		-- Guardar nivel al salir
		Players.PlayerRemoving:Connect(function(player)
			if not levelDS then return end
			local ls = player:FindFirstChild("leaderstats")
			if not ls then return end
			local lvl = ls:FindFirstChild(self._nameLeaderstatsLevel)
			if not lvl then return end
			pcall(function()
				levelDS:SetAsync("level_" .. player.UserId, lvl.Value)
			end)
		end)
	end
	-- increments players time in the datastore
	task.spawn(function ()
		if not self._isMainScript then return end
		while true do
			task.wait(self._scoreUpdateDelay)
			self:_updateScore()
		end
	end)

	-- update leaderboard
	task.spawn(function ()
		self:_updateBoard() -- update once
		local count = self._boardUpdateDelay
		while true do
			task.wait(1)
			count -= 1
			self._updateBoardTimer.Text = ("Updating the board in %d seconds"):format(count)
			if count <= 0 then
				self:_updateBoard()
				count = self._boardUpdateDelay
			end
		end
	end)

end


function TimePlayedClass:_clearBoard ()
	for _, folder in pairs({self._scoreBlock.Leaderboard.Names, self._scoreBlock.Leaderboard.Photos, self._scoreBlock.Leaderboard.Score}) do
		for _, item in pairs(folder:GetChildren()) do
			item.Visible = false
		end
	end
end


function TimePlayedClass:_updateBoard ()
	if self._doDebug then print("Updating board") end
	local results = nil

	local suc, results = pcall(function ()
		return self._datastore:GetSortedAsync(false, 10, 1):GetCurrentPage()
	end)

	if not suc or not results then
		if self._doDebug then warn("Failed to retrieve top 10 with most time. Error:", results) end
		return
	end

	local sufgui = self._scoreBlock.Leaderboard
	self._scoreBlock.Credits.Enabled = true
	self._scoreBlock.Leaderboard.Enabled = #results ~= 0
	self._scoreBlock.NoDataFound.Enabled = #results == 0
	self:_clearBoard()
	for k, v in pairs(results) do
		local userid = tonumber(string.split(v.key, self._dataStoreStatName)[2])
		local name = game:GetService("Players"):GetNameFromUserIdAsync(userid)
		local score = self:_timeToString(v.value)
		self:_onPlayerScoreUpdate(userid, v.value)
		sufgui.Names["Name"..k].Visible = true
		sufgui.Score["Score"..k].Visible = true
		sufgui.Photos["Photo"..k].Visible = true
		sufgui.Names["Name"..k].Text = name
		sufgui.Score["Score"..k].Text = score
		sufgui.Photos["Photo"..k].Image = game:GetService("Players"):GetUserThumbnailAsync(userid, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
		if k == 1 and self._dancingRigModule then
			task.spawn(function ()
				self._dancingRigModule.SetRigHumanoidDescription(userid)
			end)
		end
	end
	if self._scoreBlock:FindFirstChild("_backside") then self._scoreBlock["_backside"]:Destroy() end
	local temp = self._scoreBlock.Leaderboard:Clone()
	temp.Parent = self._scoreBlock
	temp.Name = "_backside"
	temp.Face = Enum.NormalId.Back
	if self._doDebug then print("Board updated sucessfully") end
end


function TimePlayedClass:_updateScore ()
	local suc, err = coroutine.resume(coroutine.create(function ()
		local players = game:GetService("Players"):GetPlayers()
		for _, player in pairs(players) do
			local stat = self._dataStoreStatName .. player.UserId
			local newval = self._datastore:IncrementAsync(stat, self._scoreUpdateDelay / 60)
			if self._doDebug then print("Incremented time played stat of", player, stat, "to", newval) end
		end
	end))
	if not suc then warn(err) end
end


function TimePlayedClass:_onPlayerScoreUpdate (userid, minutes)
	if not self._useLeaderstats then return end
	if not self._isMainScript then return end
	local player = Players:GetPlayerByUserId(userid)
	if not player or not player:FindFirstChild("leaderstats") then return end
	local ls = player.leaderstats

	-- Actualizar tiempo
	local timeStat = ls:FindFirstChild(self._nameLeaderstats)
	if timeStat then timeStat.Value = tonumber(minutes) end

	-- Calcular y actualizar nivel
	local levelStat = ls:FindFirstChild(self._nameLeaderstatsLevel)
	if levelStat then
		local newLevel = math.max(1, math.floor((tonumber(minutes) or 0) / self._minutesPerLevel) + 1)
		if newLevel ~= levelStat.Value then
			levelStat.Value = newLevel
			if self._levelDataStore then
				pcall(function()
					self._levelDataStore:SetAsync("level_" .. userid, newLevel)
				end)
			end
		end
	end
end


function TimePlayedClass:_checkDancingRigEnabled()
	if self._show1stPlaceAvatar then
		local rigFolder = script.Parent:FindFirstChild("First Place Avatar")
		if not rigFolder then return end
		local rig = rigFolder:FindFirstChild("Rig")
		local rigModule = rigFolder:FindFirstChild("PlayAnimationInRig")
		if not rig or not rigModule then return end
		self._dancingRigModule = require(rigModule)
		if self._dancingRigModule then
			self._isDancingRigEnabled = true
		end
	else
		local rigFolder = script.Parent:FindFirstChild("First Place Avatar")
		if not rigFolder then return end
		rigFolder:Destroy()
	end
end


function TimePlayedClass:_checkIsMainScript()
	local timePlayedClassRunning = ServerStorage:FindFirstChild("TopTimePlayedLeaderboard_Running_Flag")
	if timePlayedClassRunning then
		self._isMainScript = false
	else
		self._isMainScript = true
		local boolValue = Instance.new("BoolValue", ServerStorage)
		boolValue.Name = "TopTimePlayedLeaderboard_Running_Flag"
		boolValue.Value = true
	end
end


function TimePlayedClass:_checkDataStoreUp()
	local status, message = pcall(function()
		-- This will error if current instance has no Studio API access:
		DataStoreService:GetDataStore("____PS"):SetAsync("____PS", os.time())
	end)
	if status == false and
		(string.find(message, "404", 1, true) ~= nil or 
			string.find(message, "403", 1, true) ~= nil or -- Cannot write to DataStore from studio if API access is not enabled
			string.find(message, "must publish", 1, true) ~= nil) then -- Game must be published to access live keys
		local boolValue = Instance.new("BoolValue", ServerStorage)
		boolValue.Value = false
		boolValue.Name = "TopTimePlayedLeaderboard_NoAPIServices_Flag"
		return false
	end
	self._apiServicesEnabled = true
	local boolValue = Instance.new("BoolValue", ServerStorage)
	boolValue.Value = true
	boolValue.Name = "TopTimePlayedLeaderboard_NoAPIServices_Flag"
	return self._apiServicesEnabled
end


function TimePlayedClass:_timeToString(_time)
	_time = _time * 60
	local days = math.floor(_time / 86400)
	local hours = math.floor(math.fmod(_time, 86400) / 3600)
	local minutes = math.floor(math.fmod(_time, 3600) / 60)
	return string.format("%02dd : %02dh : %02dm",days,hours,minutes)
end


TimePlayedClass.new()
