-- Music/DJTab.lua — Sub-tab DJ (lista DJs, canciones, virtual scroll, busqueda)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ModernScrollbar = require(ReplicatedStorage:WaitForChild("UIComponents"):WaitForChild("ModernScrollbar"))

local DJTab = {}

function DJTab.build(parent, THEME, state, R, H)
	local make, tween, rounded = H.make, H.tween, H.rounded

	local CARD_H      = 58
	local CARD_PAD    = 2
	local VISIBLE_BUF = 3
	local MAX_POOL    = 30
	local SCROLL_DEB  = 0.05
	local CONTENT_TOP = state.subTabH + 1

	local djCardPool        = {}
	local djCardsIndex      = {}
	local djScrollDebThread = nil
	local djScrollConn      = nil

	-- Panel
	local panel = make("Frame", {
		Size = UDim2.new(1, 0, 1, -CONTENT_TOP),
		Position = UDim2.new(0, 0, 0, CONTENT_TOP),
		BackgroundTransparency = 1, ClipsDescendants = true,
		ZIndex = 210, Visible = false, Parent = parent,
	})

	-- ── DJ LIST VIEW ──
	local djListView = make("ScrollingFrame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1, BorderSizePixel = 0,
		ScrollBarThickness = 0, ClipsDescendants = true,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ZIndex = 211, Visible = true, Parent = panel,
	})
	ModernScrollbar.setup(djListView, panel, THEME, { transparency = 0.45, offset = -4 })
	make("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = djListView })
	make("UIPadding", {
		PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10),
		PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 12),
		Parent = djListView,
	})

	-- ── DJ SONGS VIEW ──
	local djSongsView = make("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1, ClipsDescendants = true,
		ZIndex = 211, Visible = false, Parent = panel,
	})

	local djHeaderH = 56
	local djHeader = make("Frame", {
		Size = UDim2.new(1, 0, 0, djHeaderH),
		BackgroundColor3 = Color3.fromRGB(22, 22, 22), ZIndex = 213, Parent = djSongsView,
	})

	local djBackBtn = make("TextButton", {
		Size = UDim2.new(0, 36, 0, 36), Position = UDim2.new(0, 8, 0.5, -18),
		BackgroundColor3 = Color3.fromRGB(40, 40, 40),
		Font = Enum.Font.GothamBold, TextSize = 16,
		TextColor3 = THEME.text, Text = "←",
		BorderSizePixel = 0, AutoButtonColor = false, ZIndex = 214, Parent = djHeader,
	})
	rounded(djBackBtn, 8)

	local djHeaderCover = make("ImageLabel", {
		Size = UDim2.new(0, 36, 0, 36), Position = UDim2.new(0, 52, 0.5, -18),
		BackgroundColor3 = Color3.fromRGB(35, 35, 35),
		ScaleType = Enum.ScaleType.Crop, Image = "",
		ZIndex = 214, Parent = djHeader,
	})
	rounded(djHeaderCover, 8)

	local djHeaderName = make("TextLabel", {
		Size = UDim2.new(1, -110, 0, 20), Position = UDim2.new(0, 96, 0, 8),
		BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 15,
		TextColor3 = THEME.text, Text = "",
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 214, Parent = djHeader,
	})

	local djHeaderCount = make("TextLabel", {
		Size = UDim2.new(1, -110, 0, 14), Position = UDim2.new(0, 96, 0, 30),
		BackgroundTransparency = 1, Font = Enum.Font.GothamMedium, TextSize = 11,
		TextColor3 = THEME.accent, Text = "0 canciones",
		TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 214, Parent = djHeader,
	})

	-- Search bar
	local djSearchBar = make("Frame", {
		Size = UDim2.new(1, -20, 0, 36), Position = UDim2.new(0, 10, 0, djHeaderH + 6),
		BackgroundColor3 = Color3.fromRGB(30, 30, 30), ZIndex = 213, Parent = djSongsView,
	})
	rounded(djSearchBar, 10)

	make("TextLabel", {
		Size = UDim2.new(0, 28, 1, 0), Position = UDim2.new(0, 6, 0, 0),
		BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 14,
		TextColor3 = Color3.fromRGB(100, 100, 100), Text = "🔍",
		ZIndex = 214, Parent = djSearchBar,
	})

	local djSearchInput = make("TextBox", {
		Size = UDim2.new(1, -38, 1, 0), Position = UDim2.new(0, 34, 0, 0),
		BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 13,
		TextColor3 = THEME.text,
		PlaceholderText = "Buscar Canción",
		PlaceholderColor3 = Color3.fromRGB(100, 100, 100),
		ClearTextOnFocus = false, Text = "", ZIndex = 214, Parent = djSearchBar,
	})

	local djSongListTop = djHeaderH + 48
	local djSongListScroll = make("ScrollingFrame", {
		Size = UDim2.new(1, 0, 1, -djSongListTop),
		Position = UDim2.new(0, 0, 0, djSongListTop),
		BackgroundTransparency = 1, BorderSizePixel = 0,
		ScrollBarThickness = 0, ClipsDescendants = true,
		CanvasSize = UDim2.new(0, 0, 0, 0), ZIndex = 212, Parent = djSongsView,
	})
	ModernScrollbar.setup(djSongListScroll, djSongsView, THEME, { transparency = 0.45, offset = -2 })

	local djSongsContainer = make("Frame", {
		Size = UDim2.fromScale(1, 0), BackgroundTransparency = 1,
		ZIndex = 213, Parent = djSongListScroll,
	})

	-- ── SONG CARD VIRTUAL SCROLL ──
	local function createSongCard()
		local card = make("Frame", {
			Size = UDim2.new(1, -12, 0, CARD_H),
			BackgroundColor3 = Color3.fromRGB(26, 26, 26),
			ZIndex = 214, Visible = false, Parent = djSongsContainer,
		})
		rounded(card, 10)

		local coverBg = make("ImageLabel", {
			Size = UDim2.new(0, 42, 0, 42), Position = UDim2.new(0, 8, 0.5, -21),
			BackgroundColor3 = Color3.fromRGB(40, 40, 40),
			ScaleType = Enum.ScaleType.Crop, Image = "",
			ZIndex = 215, Name = "DJCover", Parent = card,
		})
		rounded(coverBg, 8)

		local tx = 58
		make("TextLabel", {
			Size = UDim2.new(1, -(tx + 40), 0, 20), Position = UDim2.new(0, tx, 0, 10),
			BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 14,
			TextColor3 = THEME.text, Text = "",
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			ZIndex = 215, Name = "NameLabel", Parent = card,
		})

		make("TextLabel", {
			Size = UDim2.new(1, -(tx + 40), 0, 14), Position = UDim2.new(0, tx, 0, 32),
			BackgroundTransparency = 1, Font = Enum.Font.GothamMedium, TextSize = 11,
			TextColor3 = Color3.fromRGB(130, 130, 130), Text = "",
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			ZIndex = 215, Name = "ArtistLabel", Parent = card,
		})

		local addBtn = make("TextButton", {
			Size = UDim2.new(0, 30, 0, 30), Position = UDim2.new(1, -36, 0.5, -15),
			BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 18,
			TextColor3 = Color3.fromRGB(180, 180, 180), Text = "▶",
			BorderSizePixel = 0, AutoButtonColor = false,
			ZIndex = 216, Name = "AddButton", Parent = card,
		})

		addBtn.MouseButton1Click:Connect(function()
			local songId = card:GetAttribute("SongID")
			if songId and not H.isInQueue(state.playQueue, songId) and not state.pendingCardSongIds[songId] then
				state.pendingCardSongIds[songId] = true
				addBtn.Text = "…"; addBtn.TextColor3 = THEME.accent
				if R.Add then pcall(function() R.Add:FireServer(songId) end) end
			end
		end)

		card.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseMovement then
				tween(card, 0.1, { BackgroundColor3 = Color3.fromRGB(36, 36, 36) })
			end
		end)
		card.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseMovement then
				tween(card, 0.1, { BackgroundColor3 = Color3.fromRGB(26, 26, 26) })
			end
		end)

		return card
	end

	local function getCardFromPool()
		for _, c in ipairs(djCardPool) do if not c.Visible then return c end end
		if #djCardPool < MAX_POOL then
			local c = createSongCard(); table.insert(djCardPool, c); return c
		end
	end

	local function releaseCard(card)
		local idx = card:GetAttribute("SongIndex")
		if idx then djCardsIndex[idx] = nil end
		card.Visible = false
		card:SetAttribute("SongIndex", nil); card:SetAttribute("SongID", nil)
	end

	local function releaseAllCards()
		djCardsIndex = {}
		for _, c in ipairs(djCardPool) do
			c.Visible = false
			c:SetAttribute("SongIndex", nil); c:SetAttribute("SongID", nil)
		end
	end

	local function updateSongCard(card, data, index)
		if not card or not data then return end
		card:SetAttribute("SongIndex", index); card:SetAttribute("SongID", data.id)
		djCardsIndex[index] = card

		local cov = card:FindFirstChild("DJCover", true)
		if cov and state.selectedDJInfo and state.selectedDJInfo.cover then cov.Image = state.selectedDJInfo.cover end

		local nl = card:FindFirstChild("NameLabel", true)
		if nl then nl.Text = data.name or "Cargando..."; nl.TextColor3 = data.loaded and THEME.text or THEME.muted end

		local al = card:FindFirstChild("ArtistLabel", true)
		if al then al.Text = data.artist or ("ID: " .. tostring(data.id)) end

		local ab = card:FindFirstChild("AddButton", true)
		if ab then
			local inQ = H.isInQueue(state.playQueue, data.id)
			local pending = state.pendingCardSongIds[data.id]
			if pending then
				ab.Text = "…"; ab.TextColor3 = THEME.accent
			elseif inQ then
				ab.Text = "✓"; ab.TextColor3 = THEME.success or Color3.fromRGB(40, 180, 80)
			else
				ab.Text = "▶"; ab.TextColor3 = Color3.fromRGB(180, 180, 180)
			end
		end

		card.Position = UDim2.new(0, 6, 0, (index - 1) * (CARD_H + CARD_PAD))
		card.Visible = true
	end

	for _ = 1, 8 do table.insert(djCardPool, createSongCard()) end

	-- API
	local api = { panel = panel }

	function api.updateVisibleCards()
		if not djSongListScroll or not djSongListScroll.Parent then return end
		local vs = state.vs
		local total = vs.isSearching and #vs.searchResults or vs.totalSongs
		if total == 0 then releaseAllCards(); return end

		local scrollY = djSongListScroll.CanvasPosition.Y
		local vpH = djSongListScroll.AbsoluteSize.Y
		local step = CARD_H + CARD_PAD
		local first = math.max(1, math.floor(scrollY / step) + 1 - VISIBLE_BUF)
		local last = math.min(total, math.ceil((scrollY + vpH) / step) + VISIBLE_BUF)

		local totalH = total * step
		djSongsContainer.Size = UDim2.new(1, 0, 0, totalH)
		djSongListScroll.CanvasSize = UDim2.new(0, 0, 0, totalH + 16)

		for idx, card in pairs(djCardsIndex) do
			if card and card.Visible and (idx < first or idx > last) then releaseCard(card) end
		end

		local dataSource = vs.isSearching and vs.searchResults or vs.songData
		local needsFetch = {}

		for i = first, last do
			local sd = dataSource[i]
			if sd then
				local c = djCardsIndex[i] or getCardFromPool()
				if c then updateSongCard(c, sd, i) end
			elseif not vs.isSearching then
				table.insert(needsFetch, i)
			end
		end

		if #needsFetch > 0 and not vs.isSearching and state.selectedDJ then
			local mn, mx = math.huge, 0
			for _, idx in ipairs(needsFetch) do mn = math.min(mn, idx); mx = math.max(mx, idx) end
			local key = mn .. "-" .. mx
			if not vs.pendingRequests[key] then
				vs.pendingRequests[key] = true
				if R.GetSongRange then pcall(function() R.GetSongRange:FireServer(state.selectedDJ, mn, mx) end) end
			end
		end
	end

	function api.connectScrollListener()
		if djScrollConn then djScrollConn:Disconnect() end
		djScrollConn = djSongListScroll:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
			if djScrollDebThread then return end
			djScrollDebThread = task.delay(SCROLL_DEB, function()
				djScrollDebThread = nil
				api.updateVisibleCards()
			end)
		end)
	end

	function api.selectDJ(djName, djData)
		state.selectedDJ = djName; state.selectedDJInfo = djData
		djListView.Visible = false; djSongsView.Visible = true

		djHeaderName.Text = djName
		djHeaderCount.Text = (djData.songCount or 0) .. " canciones"
		djHeaderCover.Image = djData.cover or ""

		local vs = state.vs
		vs.totalSongs = djData.songCount or 0
		vs.songData = {}; vs.searchResults = {}
		vs.isSearching = false; vs.searchQuery = ""
		vs.pendingRequests = {}

		djSearchInput.Text = ""
		releaseAllCards()
		djSongListScroll.CanvasPosition = Vector2.new(0, 0)

		local totalH = vs.totalSongs * (CARD_H + CARD_PAD)
		djSongsContainer.Size = UDim2.new(1, 0, 0, totalH)
		djSongListScroll.CanvasSize = UDim2.new(0, 0, 0, totalH + 16)

		api.connectScrollListener()
		local limit = math.min(vs.totalSongs, 20)
		if limit > 0 and R.GetSongRange then
			pcall(function() R.GetSongRange:FireServer(djName, 1, limit) end)
		end
	end

	djBackBtn.MouseButton1Click:Connect(function()
		djSongsView.Visible = false; djListView.Visible = true
		state.selectedDJ = nil; state.selectedDJInfo = nil
	end)
	djBackBtn.MouseEnter:Connect(function() tween(djBackBtn, 0.1, { BackgroundColor3 = Color3.fromRGB(55, 55, 55) }) end)
	djBackBtn.MouseLeave:Connect(function() tween(djBackBtn, 0.1, { BackgroundColor3 = Color3.fromRGB(40, 40, 40) }) end)

	function api.drawDJs()
		for _, child in pairs(djListView:GetChildren()) do
			if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then child:Destroy() end
		end

		if #state.allDJs == 0 then
			make("TextLabel", {
				Size = UDim2.new(1, 0, 0, 60), BackgroundTransparency = 1,
				Font = Enum.Font.Gotham, TextSize = 14,
				TextColor3 = Color3.fromRGB(100, 100, 100),
				Text = "Sin DJs disponibles", ZIndex = 213, Parent = djListView,
			})
			return
		end

		for idx, dj in ipairs(state.allDJs) do
			local DJ_CARD_H = 100
			local djCard = make("Frame", {
				Size = UDim2.new(1, 0, 0, DJ_CARD_H),
				BackgroundColor3 = Color3.fromRGB(25, 25, 25),
				ClipsDescendants = true, ZIndex = 213,
				LayoutOrder = idx, Parent = djListView,
			})
			rounded(djCard, 12)

			if dj.cover and dj.cover ~= "" then
				make("ImageLabel", {
					Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
					ScaleType = Enum.ScaleType.Crop,
					Image = dj.cover, ImageTransparency = 0.25,
					ZIndex = 214, Parent = djCard,
				})
			end

			local djGrad = make("Frame", {
				Size = UDim2.new(1, 0, 0.6, 0), Position = UDim2.new(0, 0, 0.4, 0),
				BackgroundColor3 = Color3.new(0, 0, 0), ZIndex = 215, Parent = djCard,
			})
			make("UIGradient", {
				Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 1),
					NumberSequenceKeypoint.new(0.4, 0.5),
					NumberSequenceKeypoint.new(1, 0.1),
				}),
				Rotation = 90, Parent = djGrad,
			})

			make("TextLabel", {
				Size = UDim2.new(1, -20, 0, 24), Position = UDim2.new(0, 10, 1, -46),
				BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 17,
				TextColor3 = Color3.new(1, 1, 1), Text = dj.name,
				TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 216, Parent = djCard,
			})

			make("TextLabel", {
				Size = UDim2.new(1, -20, 0, 16), Position = UDim2.new(0, 10, 1, -22),
				BackgroundTransparency = 1, Font = Enum.Font.GothamMedium, TextSize = 12,
				TextColor3 = THEME.accent,
				Text = (dj.songCount or 0) .. " canciones",
				TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 216, Parent = djCard,
			})

			local clickBtn = make("TextButton", {
				Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "",
				ZIndex = 217, Parent = djCard,
			})
			clickBtn.MouseButton1Click:Connect(function() api.selectDJ(dj.name, dj) end)
			clickBtn.MouseEnter:Connect(function() tween(djCard, 0.15, { BackgroundColor3 = Color3.fromRGB(35, 35, 35) }) end)
			clickBtn.MouseLeave:Connect(function() tween(djCard, 0.15, { BackgroundColor3 = Color3.fromRGB(25, 25, 25) }) end)
		end
	end

	-- DJ Search handler
	function api.handleSongRange(data)
		if not data or data.djName ~= state.selectedDJ then return end
		local vs = state.vs
		for _, song in ipairs(data.songs or {}) do
			vs.songData[song.index] = song
		end
		vs.pendingRequests[(data.startIndex or 0) .. "-" .. (data.endIndex or 0)] = nil
		djHeaderCount.Text = vs.totalSongs .. " canciones"
		api.updateVisibleCards()
	end

	function api.handleSearchResults(data)
		if not data or data.djName ~= state.selectedDJ then return end
		local vs = state.vs
		vs.searchResults = data.songs or {}
		local total = data.totalInDJ or vs.totalSongs
		djHeaderCount.Text = #vs.searchResults .. "/" .. total .. " canciones"
		djSongListScroll.CanvasPosition = Vector2.new(0, 0)
		api.updateVisibleCards()
	end

	-- Search debounce
	local djSearchDeb = nil
	djSearchInput:GetPropertyChangedSignal("Text"):Connect(function()
		if not state.selectedDJ then return end
		if djSearchDeb then task.cancel(djSearchDeb) end
		djSearchDeb = task.delay(0.3, function()
			local query = djSearchInput.Text
			local vs = state.vs
			if query == "" then
				vs.isSearching = false; vs.searchQuery = ""; vs.searchResults = {}
				djHeaderCount.Text = vs.totalSongs .. " canciones"
				djSongListScroll.CanvasPosition = Vector2.new(0, 0)
				api.updateVisibleCards()
			else
				vs.isSearching = true; vs.searchQuery = query
				if R.SearchSongs then pcall(function() R.SearchSongs:FireServer(state.selectedDJ, query) end) end
			end
		end)
	end)

	return api
end

return DJTab
