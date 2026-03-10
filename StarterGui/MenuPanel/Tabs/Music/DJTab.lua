-- Music/DJTab.lua — Sub-tab DJ (lista DJs, canciones, virtual scroll, busqueda)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local ModernScrollbar = require(ReplicatedStorage:WaitForChild("UIComponents"):WaitForChild("ModernScrollbar"))
local SearchModern = require(ReplicatedStorage:WaitForChild("UIComponents"):WaitForChild("SearchModern"))

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
		BackgroundColor3 = THEME.bg, BackgroundTransparency = 0,
		ClipsDescendants = true,
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
	local djListSB = ModernScrollbar.setup(djListView, panel, THEME, { transparency = 0.45, offset = -4, zIndex = 300 })
	make("UIListLayout", { Padding = UDim.new(0, 0), SortOrder = Enum.SortOrder.LayoutOrder, Parent = djListView })
	make("UIPadding", {
		PaddingLeft = UDim.new(0, 0), PaddingRight = UDim.new(0, 0),
		PaddingTop = UDim.new(0, 0), PaddingBottom = UDim.new(0, 0),
		Parent = djListView,
	})

	-- ── DJ SONGS VIEW ──
	local djSongsView = make("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1, ClipsDescendants = true,
		ZIndex = 211, Visible = false, Parent = panel,
	})

	local djHeaderH = 60
	local djHeader = make("Frame", {
		Size = UDim2.new(1, 0, 0, djHeaderH),
		BackgroundColor3 = THEME.card,
		ClipsDescendants = true, ZIndex = 213, Parent = djSongsView,
	})

	local djHeaderBg = make("ImageLabel", {
		Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
		ScaleType = Enum.ScaleType.Crop, Image = "",
		ImageTransparency = 0.2, ZIndex = 213, Name = "HeaderBg", Parent = djHeader,
	})
	make("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.35,
		BorderSizePixel = 0, ZIndex = 214, Parent = djHeader,
	})

	local djBackBtn, _backIcon = H.outlinedCircleBtn(djHeader, {
		size = 36, icon = H.ICONS.BACK, theme = THEME,
		position = UDim2.new(0, 8, 0.5, -18),
		zIndex = 215, name = "BackBtn",
	})

	local djHeaderName = make("TextLabel", {
		Size = UDim2.new(1, -60, 0, 22), Position = UDim2.new(0, 52, 0, 6),
		BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 16,
		TextColor3 = Color3.new(1, 1, 1), Text = "",
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 215, Parent = djHeader,
	})

	local djHeaderCount = make("TextLabel", {
		Size = UDim2.new(1, -60, 0, 16), Position = UDim2.new(0, 52, 0, 30),
		BackgroundTransparency = 1, Font = Enum.Font.GothamMedium, TextSize = 13,
		TextColor3 = THEME.accent, Text = "0 canciones",
		TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 215, Parent = djHeader,
	})

	-- Search bar (SearchModern)
	local djSearchBar, djSearchInput = SearchModern.new(djSongsView, {
		placeholder = "Buscar Canción",
		size = UDim2.new(1, 0, 0, 46),
		bg = THEME.card,
		corner = 0,
		z = 213,
		inputName = "DJSearchInput",
		textSize = 16,
	})
	djSearchBar.Position = UDim2.new(0, 0, 0, djHeaderH)

	local djSongListTop = djHeaderH + 46
	local djSongListScroll = make("ScrollingFrame", {
		Size = UDim2.new(1, 0, 1, -djSongListTop),
		Position = UDim2.new(0, 0, 0, djSongListTop),
		BackgroundTransparency = 1, BorderSizePixel = 0,
		ScrollBarThickness = 0, ClipsDescendants = true,
		CanvasSize = UDim2.new(0, 0, 0, 0), ZIndex = 212, Parent = djSongsView,
	})
	local djSongsSB = ModernScrollbar.setup(djSongListScroll, djSongsView, THEME, { transparency = 0.45, offset = -2, zIndex = 300 })

	local djSongsContainer = make("Frame", {
		Size = UDim2.fromScale(1, 0), BackgroundTransparency = 1,
		ZIndex = 213, Parent = djSongListScroll,
	})

	-- ── SONG CARD VIRTUAL SCROLL (CanvasGroup + iconos modernos) ──
	local ICONS = H.ICONS

	local function createSongCard()
		local card = Instance.new("CanvasGroup")
		card.Name = "SongCard"
		card.Size = UDim2.new(1, -12, 0, CARD_H)
		card.BackgroundColor3 = THEME.card
		card.BackgroundTransparency = 0
		card.BorderSizePixel = 0
		card.GroupTransparency = 0
		card.ZIndex = 214
		card.Visible = false
		card.Parent = djSongsContainer
		make("UICorner", { CornerRadius = UDim.new(0, 10), Parent = card })
		H.stroked(card, 0.3)

		-- Cover full-height izquierda (CanvasGroup recorta bordes)
		local coverBg = make("Frame", {
			Size = UDim2.new(0, CARD_H, 1, 0),
			BackgroundColor3 = THEME.elevated, BackgroundTransparency = 0,
			BorderSizePixel = 0, ZIndex = 215, Name = "CoverBg", Parent = card,
		})
		make("ImageLabel", {
			Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
			ScaleType = Enum.ScaleType.Crop, Image = "", BorderSizePixel = 0,
			ZIndex = 216, Name = "DJCover", Parent = coverBg,
		})

		local tx = CARD_H + 8
		make("TextLabel", {
			Size = UDim2.new(1, -(tx + 44), 0, 20), Position = UDim2.new(0, tx, 0, 10),
			BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 14,
			TextColor3 = THEME.text, Text = "",
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			ZIndex = 215, Name = "NameLabel", Parent = card,
		})

		make("TextLabel", {
			Size = UDim2.new(1, -(tx + 44), 0, 14), Position = UDim2.new(0, tx, 0, 32),
			BackgroundTransparency = 1, Font = Enum.Font.GothamMedium, TextSize = 12,
			TextColor3 = THEME.dim, Text = "",
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			ZIndex = 215, Name = "ArtistLabel", Parent = card,
		})

		-- Botón agregar (outlined circle)
		local addBtn, addIcon = H.outlinedCircleBtn(card, {
			size = 36, icon = ICONS.PLAY_ADD, theme = THEME,
			position = UDim2.new(1, -42, 0.5, -18),
			zIndex = 216, name = "AddButton",
		})
		make("ImageLabel", {
			Size = UDim2.new(0.55, 0, 0.55, 0), Position = UDim2.new(0.225, 0, 0.225, 0),
			BackgroundTransparency = 1, Image = ICONS.LOADING,
			ImageColor3 = THEME.dim, ZIndex = 218,
			Visible = false, Name = "LoadingIcon", Parent = addBtn,
		})

		addBtn.MouseButton1Click:Connect(function()
			local songId = card:GetAttribute("SongID")
			if songId and not H.isInQueue(state.playQueue, songId) and not state.pendingCardSongIds[songId] then
				state.pendingCardSongIds[songId] = true
				local iconImg = addBtn:FindFirstChild("IconImage")
				local loadingIcon = addBtn:FindFirstChild("LoadingIcon")
				if iconImg then iconImg.Visible = false end
				if loadingIcon then
					loadingIcon.Visible = true
					loadingIcon.Rotation = 0
					task.spawn(function()
						local tw = TweenService:Create(
							loadingIcon,
							TweenInfo.new(1.2, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1),
							{ Rotation = 360 }
						)
						tw:Play()
						while loadingIcon.Visible do task.wait(0.1) end
						if tw then tw:Cancel() end
					end)
				end
				addBtn.BackgroundColor3 = THEME.elevated
				addBtn.AutoButtonColor = false
				if R.Add then pcall(function() R.Add:FireServer(songId) end) end
			end
		end)

		card.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseMovement then
				tween(card, 0.1, { BackgroundColor3 = THEME.elevated })
			end
		end)
		card.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseMovement then
				tween(card, 0.1, { BackgroundColor3 = THEME.card })
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
			local icon = ab:FindFirstChild("IconImage")
			local loadingIcon = ab:FindFirstChild("LoadingIcon")
			local inQ = H.isInQueue(state.playQueue, data.id)
			local pending = state.pendingCardSongIds[data.id]

			if pending then
				ab.BackgroundTransparency = 1
				ab.AutoButtonColor = false
				local st = ab:FindFirstChildWhichIsA("UIStroke")
				if st then st.Transparency = 0 end
				if icon then icon.Visible = false end
				if loadingIcon then loadingIcon.Visible = true end
			elseif inQ then
				ab.BackgroundTransparency = 0
				ab.BackgroundColor3 = THEME.success
				ab.AutoButtonColor = false
				local st = ab:FindFirstChildWhichIsA("UIStroke")
				if st then st.Transparency = 1 end
				if icon then icon.Image = ICONS.CHECK; icon.ImageColor3 = Color3.new(1, 1, 1); icon.Visible = true end
				if loadingIcon then loadingIcon.Visible = false end
			else
				ab.BackgroundTransparency = 1
				ab.AutoButtonColor = false
				local st = ab:FindFirstChildWhichIsA("UIStroke")
				if st then st.Transparency = 0 end
				if icon then icon.Image = ICONS.PLAY_ADD; icon.ImageColor3 = THEME.dim; icon.Visible = true end
				if loadingIcon then loadingIcon.Visible = false end
			end
		end

		card.Position = UDim2.new(0, 6, 0, (index - 1) * (CARD_H + CARD_PAD))
		card.Visible = true
	end

	for _ = 1, 8 do table.insert(djCardPool, createSongCard()) end

	-- API
	local api = { panel = panel }

	-- Actualiza directamente la card visible de un songId tras AddResponse
	function api.updatePendingCard(response, songId, isSuccess)
		task.defer(function()
			if not songId then return end
			for _, card in ipairs(djCardPool) do
				if card.Visible and card:GetAttribute("SongID") == songId then
					local addBtn = card:FindFirstChild("AddButton", true)
					if not addBtn then break end

					local loadingIcon = addBtn:FindFirstChild("LoadingIcon")
					if loadingIcon then loadingIcon.Visible = false end

					local icon = addBtn:FindFirstChild("IconImage")
					if icon then icon.Visible = true end

					if isSuccess then
						if icon then icon.Image = ICONS.CHECK; icon.ImageColor3 = Color3.new(1, 1, 1) end
					addBtn.BackgroundTransparency = 0
					addBtn.BackgroundColor3 = THEME.success
					local st = addBtn:FindFirstChildWhichIsA("UIStroke")
					if st then st.Transparency = 1 end
				else
					if icon then icon.Image = ICONS.PLAY_ADD; icon.ImageColor3 = THEME.dim end
					addBtn.BackgroundTransparency = 1
					local st = addBtn:FindFirstChildWhichIsA("UIStroke")
					if st then st.Transparency = 0 end
					end
					break
				end
			end
		end)
	end

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

	local TW_PAGE = TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	local _djSliding = false

	function api.selectDJ(djName, djData)
		state.selectedDJ = djName; state.selectedDJInfo = djData

		-- Slide: lista sale izquierda, canciones entran desde derecha
		if not _djSliding then
			_djSliding = true
			djSongsView.Position = UDim2.fromScale(1, 0)
			djSongsView.Visible = true
			TweenService:Create(djListView, TW_PAGE, { Position = UDim2.fromScale(-1, 0) }):Play()
			TweenService:Create(djSongsView, TW_PAGE, { Position = UDim2.fromScale(0, 0) }):Play()
			task.delay(0.28, function()
				djListView.Visible = false
				djListView.Position = UDim2.fromScale(0, 0)
				_djSliding = false
			end)
		end

		djHeaderName.Text = djName
		djHeaderCount.Text = (djData.songCount or 0) .. " canciones"
		djHeaderBg.Image = djData.cover or ""

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
		-- Slide inverso: canciones salen derecha, lista entra desde izquierda
		if _djSliding then return end
		_djSliding = true
		djListView.Position = UDim2.fromScale(-1, 0)
		djListView.Visible = true
		TweenService:Create(djSongsView, TW_PAGE, { Position = UDim2.fromScale(1, 0) }):Play()
		TweenService:Create(djListView, TW_PAGE, { Position = UDim2.fromScale(0, 0) }):Play()
		task.delay(0.28, function()
			djSongsView.Visible = false
			djSongsView.Position = UDim2.fromScale(0, 0)
			djListView.Visible = true
			_djSliding = false
		end)
		state.selectedDJ = nil; state.selectedDJInfo = nil
	end)
	djBackBtn.MouseEnter:Connect(function() tween(djBackBtn, 0.1, { BackgroundTransparency = 0, BackgroundColor3 = THEME.elevated }) end)
	djBackBtn.MouseLeave:Connect(function() tween(djBackBtn, 0.1, { BackgroundTransparency = 1 }) end)

	function api.drawDJs()
		for _, child in pairs(djListView:GetChildren()) do
			if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then child:Destroy() end
		end

		if #state.allDJs == 0 then
			make("TextLabel", {
				Size = UDim2.new(1, 0, 0, 60), BackgroundTransparency = 1,
				Font = Enum.Font.Gotham, TextSize = 14,
				TextColor3 = THEME.muted,
				Text = "Sin DJs disponibles", ZIndex = 213, Parent = djListView,
			})
			return
		end

		for idx, dj in ipairs(state.allDJs) do
			local DJ_CARD_H = 100
			local djCard = make("Frame", {
				Size = UDim2.new(1, 0, 0, DJ_CARD_H),
				BackgroundColor3 = THEME.card,
				ClipsDescendants = true, ZIndex = 213,
				LayoutOrder = idx, Parent = djListView,
			})

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
			BackgroundTransparency = 1, Font = Enum.Font.GothamMedium, TextSize = 13,
				TextColor3 = THEME.accent,
				Text = (dj.songCount or 0) .. " canciones",
				TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 216, Parent = djCard,
			})

			local clickBtn = make("TextButton", {
				Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "",
				ZIndex = 217, Parent = djCard,
			})
			clickBtn.MouseButton1Click:Connect(function() api.selectDJ(dj.name, dj) end)
			clickBtn.MouseEnter:Connect(function() tween(djCard, 0.15, { BackgroundColor3 = THEME.elevated }) end)
			clickBtn.MouseLeave:Connect(function() tween(djCard, 0.15, { BackgroundColor3 = THEME.card }) end)
		end

		if djListSB then task.defer(djListSB.update) end
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
