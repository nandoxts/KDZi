-- Music/ActualTab.lua — Sub-tab ACTUAL (cover, progreso, reproduccion, cola)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ModernScrollbar = require(ReplicatedStorage:WaitForChild("UIComponents"):WaitForChild("ModernScrollbar"))

local ActualTab = {}

function ActualTab.build(parent, THEME, state, R, H)
	local make, tween, rounded, formatTime = H.make, H.tween, H.rounded, H.formatTime
	local SKIP_CD = 3
	local CONTENT_TOP = state.subTabH + 1

	local cooldownActive = false
	local currentCover = ""
	local queueCardPool = {}
	local activeQueueCards = {}

	-- Panel principal
	local panel = make("ScrollingFrame", {
		Size = UDim2.new(1, 0, 1, -CONTENT_TOP),
		Position = UDim2.new(0, 0, 0, CONTENT_TOP),
		BackgroundTransparency = 1, BorderSizePixel = 0,
		ScrollBarThickness = 0, ClipsDescendants = true,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ZIndex = 210, Visible = true, Parent = parent,
	})
	ModernScrollbar.setup(panel, parent, THEME, { transparency = 0.45, offset = -4 })
	make("UIListLayout", { Padding = UDim.new(0, 0), SortOrder = Enum.SortOrder.LayoutOrder, Parent = panel })

	-- ── COVER ──
	local COVER_H = 230
	local coverSection = make("Frame", {
		Size = UDim2.new(1, 0, 0, COVER_H),
		BackgroundColor3 = Color3.fromRGB(18, 18, 18),
		ClipsDescendants = true, LayoutOrder = 1, ZIndex = 211, Parent = panel,
	})

	local coverImage = make("ImageLabel", {
		Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
		ScaleType = Enum.ScaleType.Crop, Image = "",
		ImageTransparency = 0, ZIndex = 212, Parent = coverSection,
	})

	local coverPlaceholder = make("TextLabel", {
		Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold, TextSize = 52,
		TextColor3 = THEME.accent, Text = "♪",
		ZIndex = 211, Parent = coverSection,
	})

	local gradientOverlay = make("Frame", {
		Size = UDim2.new(1, 0, 0.55, 0), Position = UDim2.new(0, 0, 0.45, 0),
		BackgroundColor3 = Color3.new(0, 0, 0), ZIndex = 213, Parent = coverSection,
	})
	make("UIGradient", {
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.35, 0.6),
			NumberSequenceKeypoint.new(0.7, 0.15),
			NumberSequenceKeypoint.new(1, 0),
		}),
		Rotation = 90, Parent = gradientOverlay,
	})

	local coverTitle = make("TextLabel", {
		Size = UDim2.new(1, -24, 0, 28), Position = UDim2.new(0, 12, 1, -52),
		BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 20,
		TextColor3 = Color3.new(1, 1, 1), Text = "Sin reproduccion",
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 214, Parent = coverSection,
	})

	local coverArtist = make("TextLabel", {
		Size = UDim2.new(1, -24, 0, 18), Position = UDim2.new(0, 12, 1, -26),
		BackgroundTransparency = 1, Font = Enum.Font.GothamMedium, TextSize = 13,
		TextColor3 = Color3.fromRGB(200, 200, 200), Text = "",
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 214, Parent = coverSection,
	})

	-- ── PROGRESO ──
	local progressSection = make("Frame", {
		Size = UDim2.new(1, 0, 0, 38), BackgroundTransparency = 1,
		LayoutOrder = 2, ZIndex = 211, Parent = panel,
	})

	local progressBar = make("Frame", {
		Size = UDim2.new(1, -24, 0, 4), Position = UDim2.new(0, 12, 0, 10),
		BackgroundColor3 = Color3.fromRGB(55, 55, 55), ZIndex = 212, Parent = progressSection,
	})
	rounded(progressBar, 2)

	local progressFill = make("Frame", {
		Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = THEME.accent,
		ZIndex = 213, Parent = progressBar,
	})
	rounded(progressFill, 2)

	local timeLeft = make("TextLabel", {
		Size = UDim2.new(0.5, -12, 0, 16), Position = UDim2.new(0, 12, 0, 18),
		BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 12,
		TextColor3 = Color3.fromRGB(170, 170, 170), Text = "0:00",
		TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 212, Parent = progressSection,
	})

	local timeRight = make("TextLabel", {
		Size = UDim2.new(0.5, -12, 0, 16), Position = UDim2.new(0.5, 0, 0, 18),
		BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 12,
		TextColor3 = Color3.fromRGB(170, 170, 170), Text = "0:00",
		TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 212, Parent = progressSection,
	})

	-- ── REPRODUCCION ──
	local reproSection = make("Frame", {
		Size = UDim2.new(1, 0, 0, 78), BackgroundTransparency = 1,
		LayoutOrder = 3, ZIndex = 211, Parent = panel,
	})

	make("TextLabel", {
		Size = UDim2.new(1, -24, 0, 18), Position = UDim2.new(0, 12, 0, 4),
		BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 11,
		TextColor3 = Color3.fromRGB(140, 140, 140), Text = "REPRODUCCION",
		TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 212, Parent = reproSection,
	})

	local reproRow = make("Frame", {
		Size = UDim2.new(1, -24, 0, 42), Position = UDim2.new(0, 12, 0, 28),
		BackgroundTransparency = 1, ZIndex = 212, Parent = reproSection,
	})

	local reproInput = make("TextBox", {
		Size = UDim2.new(1, -52, 1, 0),
		BackgroundColor3 = Color3.fromRGB(30, 30, 30),
		Font = Enum.Font.GothamBold, TextSize = 15,
		TextColor3 = THEME.text,
		PlaceholderText = "ID de cancion...",
		PlaceholderColor3 = Color3.fromRGB(100, 100, 100),
		ClearTextOnFocus = false, Text = "",
		ZIndex = 213, Parent = reproRow,
	})
	rounded(reproInput, 10)
	make("UIPadding", { PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14), Parent = reproInput })

	local cooldownBtn = make("TextButton", {
		Size = UDim2.new(0, 42, 0, 42), Position = UDim2.new(1, -42, 0, 0),
		BackgroundColor3 = Color3.fromRGB(55, 55, 55),
		Font = Enum.Font.GothamBold, TextSize = 16,
		TextColor3 = Color3.fromRGB(180, 180, 180), Text = tostring(SKIP_CD),
		BorderSizePixel = 0, AutoButtonColor = false, ZIndex = 214, Parent = reproRow,
	})
	rounded(cooldownBtn, 21)
	local cdStroke = make("UIStroke", {
		Color = Color3.fromRGB(90, 90, 90), Thickness = 2, Transparency = 0.3, Parent = cooldownBtn,
	})

	reproInput:GetPropertyChangedSignal("Text"):Connect(function()
		reproInput.Text = reproInput.Text:gsub("[^%d]", ""):sub(1, 15)
	end)

	local function startCooldownUI(seconds)
		if cooldownActive then return end
		cooldownActive = true
		local remaining = seconds
		cooldownBtn.Text = tostring(remaining)
		tween(cooldownBtn, 0.2, { BackgroundColor3 = THEME.accent })
		tween(cdStroke, 0.2, { Color = THEME.accent, Transparency = 0.1 })
		task.spawn(function()
			while remaining > 0 do
				task.wait(1)
				remaining -= 1
				if cooldownBtn.Parent then cooldownBtn.Text = tostring(remaining) end
			end
			cooldownActive = false
			if cooldownBtn.Parent then
				cooldownBtn.Text = tostring(SKIP_CD)
				tween(cooldownBtn, 0.3, { BackgroundColor3 = Color3.fromRGB(55, 55, 55) })
				tween(cdStroke, 0.3, { Color = Color3.fromRGB(90, 90, 90), Transparency = 0.3 })
			end
		end)
	end

	local function doQuickAdd()
		local songId = tonumber(reproInput.Text)
		if not songId or cooldownActive then return end
		if R.Add then pcall(function() R.Add:FireServer(songId) end) end
		reproInput.Text = ""
		startCooldownUI(SKIP_CD)
	end

	cooldownBtn.MouseButton1Click:Connect(doQuickAdd)
	cooldownBtn.MouseEnter:Connect(function()
		if not cooldownActive then tween(cooldownBtn, 0.12, { BackgroundColor3 = Color3.fromRGB(75, 75, 75) }) end
	end)
	cooldownBtn.MouseLeave:Connect(function()
		if not cooldownActive then tween(cooldownBtn, 0.12, { BackgroundColor3 = Color3.fromRGB(55, 55, 55) }) end
	end)

	-- ── COLA (LISTA) ──
	local listaSection = make("Frame", {
		Size = UDim2.new(1, 0, 0, 500), BackgroundTransparency = 1,
		LayoutOrder = 4, ZIndex = 211, Parent = panel,
	})

	local listaLabel = make("TextLabel", {
		Size = UDim2.new(1, -24, 0, 20), Position = UDim2.new(0, 12, 0, 2),
		BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 11,
		TextColor3 = Color3.fromRGB(140, 140, 140), Text = "LISTA · 0",
		TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 212, Parent = listaSection,
	})

	local queueContainer = make("Frame", {
		Size = UDim2.new(1, -24, 0, 0), Position = UDim2.new(0, 12, 0, 28),
		BackgroundTransparency = 1, ZIndex = 212, Parent = listaSection,
	})
	make("UIListLayout", { Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder, Parent = queueContainer })

	local queueEmptyLbl = make("TextLabel", {
		Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1,
		Font = Enum.Font.Gotham, TextSize = 13,
		TextColor3 = Color3.fromRGB(90, 90, 90), Text = "La cola está vacía",
		ZIndex = 212, Visible = true, Parent = queueContainer,
	})

	-- Queue card factory
	local function createQueueCard()
		local card = make("Frame", {
			Size = UDim2.new(1, 0, 0, 58),
			BackgroundColor3 = Color3.fromRGB(26, 26, 26),
			ZIndex = 213, Visible = false, Parent = queueContainer,
		})
		rounded(card, 10)

		local cover = make("ImageLabel", {
			Size = UDim2.new(0, 42, 0, 42), Position = UDim2.new(0, 8, 0.5, -21),
			BackgroundColor3 = Color3.fromRGB(40, 40, 40),
			ScaleType = Enum.ScaleType.Crop, Image = "",
			ZIndex = 214, Name = "Cover", Parent = card,
		})
		rounded(cover, 8)

		make("TextLabel", {
			Size = UDim2.new(1, -100, 0, 20), Position = UDim2.new(0, 58, 0, 10),
			BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 14,
			TextColor3 = THEME.text, Text = "",
			TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
			ZIndex = 214, Name = "NameLabel", Parent = card,
		})

		make("TextLabel", {
			Size = UDim2.new(1, -100, 0, 15), Position = UDim2.new(0, 58, 0, 31),
			BackgroundTransparency = 1, Font = Enum.Font.GothamMedium, TextSize = 11,
			TextColor3 = Color3.fromRGB(130, 130, 130), Text = "",
			TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
			ZIndex = 214, Name = "ArtistLabel", Parent = card,
		})

		make("TextLabel", {
			Size = UDim2.new(0, 28, 0, 28), Position = UDim2.new(1, -36, 0.5, -14),
			BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 18,
			TextColor3 = Color3.fromRGB(180, 180, 180), Text = "▶",
			ZIndex = 214, Name = "PlayIcon", Parent = card,
		})

		if state.isAdmin then
			local rmBtn = make("TextButton", {
				Size = UDim2.new(0, 24, 0, 24), Position = UDim2.new(1, -64, 0.5, -12),
				BackgroundColor3 = Color3.fromRGB(180, 50, 50), BackgroundTransparency = 0.6,
				Font = Enum.Font.GothamBold, TextSize = 10,
				TextColor3 = Color3.new(1, 1, 1), Text = "✕",
				BorderSizePixel = 0, ZIndex = 215, Name = "RemoveBtn", Parent = card,
			})
			rounded(rmBtn, 6)
			rmBtn.MouseButton1Click:Connect(function()
				local idx = card:GetAttribute("QueueIndex")
				if idx and R.Remove then pcall(function() R.Remove:FireServer(idx) end) end
			end)
		end

		return card
	end

	for _ = 1, 6 do table.insert(queueCardPool, createQueueCard()) end

	local function releaseAllQueueCards()
		for _, c in ipairs(activeQueueCards) do
			c.Visible = false; c:SetAttribute("QueueIndex", nil)
		end
		activeQueueCards = {}
	end

	local function getQueueCard()
		for _, c in ipairs(queueCardPool) do if not c.Visible then return c end end
		if #queueCardPool < 20 then
			local c = createQueueCard(); table.insert(queueCardPool, c); return c
		end
	end

	-- API
	local api = { panel = panel }

	function api.drawQueue()
		releaseAllQueueCards()
		local queue = state.playQueue
		local count = #queue
		listaLabel.Text = "LISTA · " .. count

		if count == 0 then
			queueEmptyLbl.Visible = true
			listaSection.Size = UDim2.new(1, 0, 0, 80)
			return
		end
		queueEmptyLbl.Visible = false

		for i, song in ipairs(queue) do
			local isActive = state.currentSong and song.id == state.currentSong.id
			local card = getQueueCard()
			if not card then break end

			card.LayoutOrder = i; card:SetAttribute("QueueIndex", i)
			card.Visible = true
			table.insert(activeQueueCards, card)

			card.BackgroundColor3 = isActive and Color3.fromRGB(35, 30, 20) or Color3.fromRGB(26, 26, 26)

			local nl = card:FindFirstChild("NameLabel")
			if nl then nl.Text = song.name or "Desconocida"; nl.TextColor3 = isActive and THEME.accent or THEME.text end

			local al = card:FindFirstChild("ArtistLabel")
			if al then al.Text = song.artist or song.requestedBy or "" end

			local cov = card:FindFirstChild("Cover")
			if cov then cov.Image = song.djCover or "" end

			local pi = card:FindFirstChild("PlayIcon")
			if pi then pi.TextColor3 = isActive and THEME.accent or Color3.fromRGB(180, 180, 180) end
		end

		listaSection.Size = UDim2.new(1, 0, 0, count * 61 + 32)
	end

	function api.updateProgress()
		if not state.currentSoundObj then state.currentSoundObj = workspace:FindFirstChild("QueueSound") end
		local snd = state.currentSoundObj
		if not snd or not snd:IsA("Sound") then
			progressFill.Size = UDim2.new(0, 0, 1, 0)
			timeLeft.Text = "0:00"; timeRight.Text = "0:00"
			return
		end
		local cur, total = snd.TimePosition, snd.TimeLength
		if total > 0 then
			progressFill.Size = UDim2.new(math.clamp(cur / total, 0, 1), 0, 1, 0)
			timeLeft.Text = formatTime(cur); timeRight.Text = formatTime(total)
		else
			progressFill.Size = UDim2.new(0, 0, 1, 0)
			timeLeft.Text = "0:00"; timeRight.Text = "0:00"
		end
	end

	function api.updateCover(song)
		local cover = song and (song.djCover or "") or ""
		if cover == currentCover then
			-- Actualizar texto aunque el cover no cambie
			coverTitle.Text = song and (song.name or "Sin reproduccion") or "Sin reproduccion"
			coverArtist.Text = song and (song.artist or "") or ""
			return
		end
		currentCover = cover
		coverTitle.Text = song and (song.name or "Sin reproduccion") or "Sin reproduccion"
		coverArtist.Text = song and (song.artist or "") or ""

		if cover == "" then
			tween(coverImage, 0.25, { ImageTransparency = 1 })
			coverPlaceholder.Visible = true
		else
			coverPlaceholder.Visible = false
			tween(coverImage, 0.15, { ImageTransparency = 1 })
			task.delay(0.15, function()
				if coverImage.Parent then
					coverImage.Image = cover
					tween(coverImage, 0.3, { ImageTransparency = 0 })
				end
			end)
		end
	end

	return api
end

return ActualTab
