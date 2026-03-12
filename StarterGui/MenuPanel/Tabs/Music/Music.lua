-- Music/init.lua — MusicTab orquestador v7.0
local Players            = game:GetService("Players")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local RunService         = game:GetService("RunService")
local MarketplaceService = game:GetService("MarketplaceService")
local SoundService       = game:GetService("SoundService")

local player = Players.LocalPlayer

local Helpers  = require(script.Parent:WaitForChild("Helpers"))
local ActualTab = require(script.Parent:WaitForChild("ActualTab"))
local DJTab     = require(script.Parent:WaitForChild("DJTab"))

local Notify = require(ReplicatedStorage:WaitForChild("Systems"):WaitForChild("NotificationSystem"):WaitForChild("NotificationSystem"))

-- Response codes (mismos que MusicDjDashboard)
local ResponseCodes = {
	SUCCESS = "SUCCESS", ERROR_INVALID_ID = "ERROR_INVALID_ID",
	ERROR_BLACKLISTED = "ERROR_BLACKLISTED", ERROR_DUPLICATE = "ERROR_DUPLICATE",
	ERROR_NOT_FOUND = "ERROR_NOT_FOUND", ERROR_NOT_AUDIO = "ERROR_NOT_AUDIO",
	ERROR_NOT_AUTHORIZED = "ERROR_NOT_AUTHORIZED", ERROR_QUEUE_FULL = "ERROR_QUEUE_FULL",
	ERROR_PERMISSION = "ERROR_PERMISSION", ERROR_UNKNOWN = "ERROR_UNKNOWN",
}

local ResponseMessages = {
	[ResponseCodes.SUCCESS] = {type = "success", title = "Éxito"},
	[ResponseCodes.ERROR_INVALID_ID] = {type = "error", title = "ID Inválido"},
	[ResponseCodes.ERROR_BLACKLISTED] = {type = "error", title = "Audio Bloqueado"},
	[ResponseCodes.ERROR_DUPLICATE] = {type = "warning", title = "Duplicado"},
	[ResponseCodes.ERROR_NOT_FOUND] = {type = "error", title = "No Encontrado"},
	[ResponseCodes.ERROR_NOT_AUDIO] = {type = "error", title = "Tipo Incorrecto"},
	[ResponseCodes.ERROR_NOT_AUTHORIZED] = {type = "error", title = "No Autorizado"},
	[ResponseCodes.ERROR_QUEUE_FULL] = {type = "warning", title = "Cola Llena"},
	[ResponseCodes.ERROR_PERMISSION] = {type = "error", title = "Sin Permiso"},
	[ResponseCodes.ERROR_UNKNOWN] = {type = "error", title = "Error"},
}

local function showNotification(response)
	local cfg = ResponseMessages[response.code] or ResponseMessages[ResponseCodes.ERROR_UNKNOWN]
	local msg = response.message or "Operación completada"
	if response.data and response.data.songName then msg = msg .. ": " .. response.data.songName end
	local fn = ({success = Notify.Success, warning = Notify.Warning, error = Notify.Error})[cfg.type] or Notify.Info
	fn(Notify, cfg.title, msg, cfg.type == "error" and 4 or 3)
end

local MusicConfig = nil
pcall(function()
	MusicConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("MusicSystemConfig"))
end)

local Music = {}

function Music.build(parent, THEME, sharedState)
	local isAdmin  = MusicConfig and MusicConfig.IsAdmin and MusicConfig:IsAdmin(player) or false
	local MAX_VOL  = (MusicConfig and MusicConfig.PLAYBACK and MusicConfig.PLAYBACK.MaxVolume) or 1
	local MIN_VOL  = (MusicConfig and MusicConfig.PLAYBACK and MusicConfig.PLAYBACK.MinVolume) or 0
	local DEF_VOL  = (MusicConfig and MusicConfig.PLAYBACK and MusicConfig.PLAYBACK.DefaultVolume) or 0.5
	local SKIP_PRODUCT     = 3468988018
	local UPDATE_THROTTLE  = 0.15
	local SUB_TAB_H        = 38

	-- ── REMOTES ──
	local R = {}
	task.spawn(function()
		local rg = ReplicatedStorage:WaitForChild("RemotesGlobal", 8)
		if not rg then return end
		local UI_F = rg:FindFirstChild("UI")
		local PB   = rg:FindFirstChild("MusicPlayback")
		local MQ   = rg:FindFirstChild("MusicQueue")
		local ML   = rg:FindFirstChild("MusicLibrary")
		if UI_F then R.Update = UI_F:FindFirstChild("UpdateUI") end
		if PB then R.Next = PB:FindFirstChild("NextSong"); R.ChangeVol = PB:FindFirstChild("ChangeVolume") end
		if MQ then
			R.Add            = MQ:FindFirstChild("AddToQueue")
			R.AddResponse    = MQ:FindFirstChild("AddToQueueResponse")
			R.Remove         = MQ:FindFirstChild("RemoveFromQueue")
			R.RemoveResponse = MQ:FindFirstChild("RemoveFromQueueResponse")
			R.Clear          = MQ:FindFirstChild("ClearQueue")
			R.ClearResponse  = MQ:FindFirstChild("ClearQueueResponse")
		end
		if ML then
			R.GetDJs       = ML:FindFirstChild("GetDJs")
			R.GetSongsByDJ = ML:FindFirstChild("GetSongsByDJ")
			R.GetSongRange = ML:FindFirstChild("GetSongRange")
			R.SearchSongs  = ML:FindFirstChild("SearchSongs")
		end
		if R.GetDJs then R.GetDJs:FireServer() end
	end)

	-- ── STATE ──
	local state = {
		playQueue          = {},
		currentSong        = nil,
		currentSoundObj    = nil,
		allDJs             = {},
		selectedDJ         = nil,
		selectedDJInfo     = nil,
		currentVolume      = DEF_VOL,
		pendingCardSongIds = {},
		isAdmin            = isAdmin,
		subTabH            = SUB_TAB_H,
		vs = {
			totalSongs      = 0,
			songData        = {},
			searchResults   = {},
			isSearching     = false,
			searchQuery     = "",
			pendingRequests = {},
		},
	}

	-- ── SUB-TAB BAR ──
	local SubTabs = require(ReplicatedStorage:WaitForChild("UIComponents"):WaitForChild("SubTabs"))

	local subTabs = SubTabs.new(parent, THEME, {
		tabs = { {id = "actual", label = "ACTUAL"}, {id = "dj", label = "DJ"} },
		height = SUB_TAB_H,
		default = "actual",
		z = 215,
	})

	-- ── BUILD SUB-TABS ──
	local actual = ActualTab.build(parent, THEME, state, R, Helpers)
	local dj     = DJTab.build(parent, THEME, state, R, Helpers)

	subTabs:register("actual", actual.panel)
	subTabs:register("dj", dj.panel)

	-- ── VOLUME ──
	local musicGroup = SoundService:FindFirstChild("MusicSoundGroup")
	if musicGroup then state.currentVolume = musicGroup.Volume end

	local volCheckAccum = 0
	RunService.Heartbeat:Connect(function(dt)
		volCheckAccum += dt
		if volCheckAccum < 2 then return end
		volCheckAccum = 0
		if musicGroup and sharedState then
			-- Sincronizar con _G.MusicVolume (slider de Settings)
			if _G.MusicVolume and _G.MusicVolume ~= state.currentVolume then
				state.currentVolume = _G.MusicVolume
			end
			if sharedState.isMuted then
				musicGroup.Volume = 0
			elseif musicGroup.Volume ~= state.currentVolume then
				musicGroup.Volume = state.currentVolume
			end
		end
	end)

	-- ── PROCESS UPDATE ──
	local _isActive = false
	local lastUpdateTime = 0
	local pendingUpdate  = nil

	local function processUpdate(data)
		state.playQueue     = data.queue or {}
		state.currentSong   = data.currentSong
		state.currentSoundObj = workspace:FindFirstChild("QueueSound")

		-- Skip expensive UI work when tab is not visible
		if not _isActive then return end

		actual.updateCover(state.currentSong)
		actual.drawQueue()

		if state.selectedDJ then dj.updateVisibleCards() end

		local newDJs  = data.djs or state.allDJs
		local changed = #newDJs ~= #state.allDJs
		if not changed then
			for i, d in ipairs(newDJs) do
				if not state.allDJs[i] or state.allDJs[i].name ~= d.name then changed = true; break end
			end
		end
		if changed then state.allDJs = newDJs; dj.drawDJs() end
	end

	-- ── REMOTE HANDLERS ──
	task.spawn(function()
		local rg = ReplicatedStorage:WaitForChild("RemotesGlobal", 10)
		if not rg then return end

		repeat task.wait(0.5) until R.Update

		R.Update.OnClientEvent:Connect(function(data)
			local now = tick()
			if (now - lastUpdateTime) < UPDATE_THROTTLE then
				pendingUpdate = data
				if not (pendingUpdate and pendingUpdate._sched) then
					if pendingUpdate then pendingUpdate._sched = true end
					task.delay(UPDATE_THROTTLE, function()
						if pendingUpdate then
							lastUpdateTime = tick()
							processUpdate(pendingUpdate)
							pendingUpdate = nil
						end
					end)
				end
				return
			end
			lastUpdateTime = now; pendingUpdate = nil
			processUpdate(data)
		end)

		if R.GetDJs then
			R.GetDJs.OnClientEvent:Connect(function(d)
				state.allDJs = (d and (d.djs or d)) or state.allDJs
				if _isActive then dj.drawDJs() end
			end)
		end

		if R.GetSongRange then
			R.GetSongRange.OnClientEvent:Connect(function(data)
				if _isActive then dj.handleSongRange(data) end
			end)
		end
		if R.SearchSongs then
			R.SearchSongs.OnClientEvent:Connect(function(data)
				if _isActive then dj.handleSearchResults(data) end
			end)
		end

		if R.AddResponse then
			R.AddResponse.OnClientEvent:Connect(function(response)
				if not response then return end
				showNotification(response)

				-- Resolver pending cards (mismo patrón que MusicDjDashboard)
				local songId = response.data and response.data.songId
				local isSuccess = response.success or response.code == ResponseCodes.ERROR_DUPLICATE

				if songId then
					state.pendingCardSongIds[songId] = nil
				else
					-- Sin songId específico: limpiar TODOS los pending
					for sid, _ in pairs(state.pendingCardSongIds) do
						state.pendingCardSongIds[sid] = nil
					end
				end

				-- Actualizar UI solo si la tab está activa
				if _isActive then
					dj.updatePendingCard(response, songId, isSuccess)
					dj.updateVisibleCards()
					actual.handleAddResponse(response, songId, isSuccess)
					actual.drawQueue()
				end
			end)
		end
		if R.RemoveResponse then
			R.RemoveResponse.OnClientEvent:Connect(function(response)
				if response then showNotification(response) end
			end)
		end
		if R.ClearResponse then
			R.ClearResponse.OnClientEvent:Connect(function(response)
				if response then showNotification(response) end
			end)
		end
	end)

	-- ── SKIP PURCHASE ──
	MarketplaceService.PromptProductPurchaseFinished:Connect(function(uid, pid, bought)
		if uid == player.UserId and pid == SKIP_PRODUCT and bought then
			if R.Next then pcall(function() R.Next:FireServer() end) end
		end
	end)

	-- ── LIFECYCLE ──
	local progressConn = nil

	local function onOpen()
		_isActive = true
		if progressConn then progressConn:Disconnect() end
		progressConn = RunService.Heartbeat:Connect(function() actual.updateProgress() end)
		actual.updateCover(state.currentSong)
		actual.drawQueue()
		if R.GetDJs then pcall(function() R.GetDJs:FireServer() end) end
		if #state.allDJs > 0 then dj.drawDJs() end
	end

	local function onClose()
		_isActive = false
		if progressConn then progressConn:Disconnect(); progressConn = nil end
	end

	dj.connectScrollListener()

	return { onOpen = onOpen, onClose = onClose }
end

return Music
