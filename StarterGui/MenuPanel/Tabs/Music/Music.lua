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

local MusicConfig = nil
pcall(function()
	MusicConfig = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("MusicSystemConfig"))
end)

local Music = {}

function Music.build(parent, THEME, sharedState)
	local isAdmin  = MusicConfig and MusicConfig.IsAdmin and MusicConfig.IsAdmin(player) or false
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
	local make, tween, rounded = Helpers.make, Helpers.tween, Helpers.rounded

	local subTabBar = make("Frame", {
		Size = UDim2.new(1, 0, 0, SUB_TAB_H),
		BackgroundColor3 = THEME.bg, BorderSizePixel = 0,
		ZIndex = 215, Parent = parent,
	})
	make("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Left,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 4), Parent = subTabBar,
	})
	make("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), Parent = subTabBar })

	local activeSubTab = "actual"

	local btnActual = make("TextButton", {
		Size = UDim2.new(0, 90, 0, 30),
		BackgroundColor3 = THEME.accent, BackgroundTransparency = 0.1,
		Font = Enum.Font.GothamBold, TextSize = 12,
		TextColor3 = THEME.text, Text = "ACTUAL",
		BorderSizePixel = 0, AutoButtonColor = false,
		ZIndex = 216, LayoutOrder = 1, Parent = subTabBar,
	})
	rounded(btnActual, 8)

	local btnDJ = make("TextButton", {
		Size = UDim2.new(0, 90, 0, 30),
		BackgroundColor3 = THEME.card or Color3.fromRGB(35, 35, 35),
		BackgroundTransparency = 0.2,
		Font = Enum.Font.GothamBold, TextSize = 12,
		TextColor3 = THEME.muted, Text = "DJ",
		BorderSizePixel = 0, AutoButtonColor = false,
		ZIndex = 216, LayoutOrder = 2, Parent = subTabBar,
	})
	rounded(btnDJ, 8)

	make("Frame", {
		Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 0, SUB_TAB_H),
		BackgroundColor3 = THEME.stroke or Color3.fromRGB(45, 45, 45),
		BackgroundTransparency = 0.6, ZIndex = 215, Parent = parent,
	})

	-- ── BUILD SUB-TABS ──
	local actual = ActualTab.build(parent, THEME, state, R, Helpers)
	local dj     = DJTab.build(parent, THEME, state, R, Helpers)

	local function switchSubTab(tab)
		activeSubTab = tab
		actual.panel.Visible = (tab == "actual")
		dj.panel.Visible     = (tab == "dj")
		if tab == "actual" then
			tween(btnActual, 0.18, { BackgroundColor3 = THEME.accent, BackgroundTransparency = 0.1, TextColor3 = THEME.text })
			tween(btnDJ, 0.18, { BackgroundColor3 = THEME.card or Color3.fromRGB(35, 35, 35), BackgroundTransparency = 0.2, TextColor3 = THEME.muted })
		else
			tween(btnDJ, 0.18, { BackgroundColor3 = THEME.accent, BackgroundTransparency = 0.1, TextColor3 = THEME.text })
			tween(btnActual, 0.18, { BackgroundColor3 = THEME.card or Color3.fromRGB(35, 35, 35), BackgroundTransparency = 0.2, TextColor3 = THEME.muted })
		end
	end

	btnActual.MouseButton1Click:Connect(function() switchSubTab("actual") end)
	btnDJ.MouseButton1Click:Connect(function() switchSubTab("dj") end)

	for _, b in ipairs({ btnActual, btnDJ }) do
		b.MouseEnter:Connect(function()
			if (b == btnActual and activeSubTab ~= "actual") or (b == btnDJ and activeSubTab ~= "dj") then
				tween(b, 0.12, { BackgroundTransparency = 0.15 })
			end
		end)
		b.MouseLeave:Connect(function()
			if (b == btnActual and activeSubTab ~= "actual") or (b == btnDJ and activeSubTab ~= "dj") then
				tween(b, 0.12, { BackgroundTransparency = 0.2 })
			end
		end)
	end

	-- ── VOLUME ──
	local musicGroup = SoundService:FindFirstChild("MusicSoundGroup")
	if musicGroup then state.currentVolume = musicGroup.Volume end

	local volCheckAccum = 0
	RunService.Heartbeat:Connect(function(dt)
		volCheckAccum += dt
		if volCheckAccum < 2 then return end
		volCheckAccum = 0
		if musicGroup and sharedState then
			if sharedState.isMuted then
				musicGroup.Volume = 0
			elseif musicGroup.Volume ~= state.currentVolume then
				musicGroup.Volume = state.currentVolume
			end
		end
	end)

	-- ── PROCESS UPDATE ──
	local lastUpdateTime = 0
	local pendingUpdate  = nil

	local function processUpdate(data)
		state.playQueue     = data.queue or {}
		state.currentSong   = data.currentSong
		state.currentSoundObj = workspace:FindFirstChild("QueueSound")

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
				dj.drawDJs()
			end)
		end

		if R.GetSongRange then
			R.GetSongRange.OnClientEvent:Connect(function(data) dj.handleSongRange(data) end)
		end
		if R.SearchSongs then
			R.SearchSongs.OnClientEvent:Connect(function(data) dj.handleSearchResults(data) end)
		end

		if R.AddResponse then
			R.AddResponse.OnClientEvent:Connect(function(ok, songId)
				if songId then state.pendingCardSongIds[songId] = nil end
				dj.updateVisibleCards(); actual.drawQueue()
			end)
		end
		if R.RemoveResponse then
			R.RemoveResponse.OnClientEvent:Connect(function() actual.drawQueue() end)
		end
		if R.ClearResponse then
			R.ClearResponse.OnClientEvent:Connect(function()
				state.playQueue = {}; actual.drawQueue()
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
		if progressConn then progressConn:Disconnect() end
		progressConn = RunService.Heartbeat:Connect(function() actual.updateProgress() end)
		actual.drawQueue()
		if R.GetDJs then pcall(function() R.GetDJs:FireServer() end) end
		if #state.allDJs > 0 then dj.drawDJs() end
	end

	local function onClose()
		if progressConn then progressConn:Disconnect(); progressConn = nil end
	end

	switchSubTab("actual")
	dj.connectScrollListener()

	return { onOpen = onOpen, onClose = onClose }
end

return Music
