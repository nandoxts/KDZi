-- Music/ActualTab.lua — Sub-tab ACTUAL (cover, progreso, reproduccion, cola)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UI = require(ReplicatedStorage:WaitForChild("Core"):WaitForChild("UI"))
local ModernScrollbar = require(ReplicatedStorage:WaitForChild("UIComponents"):WaitForChild("ModernScrollbar"))

local make, tween, rounded = UI.make, UI.tween, UI.rounded
local ICONS = UI.ICONS

local ActualTab = {}

function ActualTab.build(parent, THEME, state, R, H)
	local formatTime = H.formatTime
	local CONTENT_TOP = state.subTabH + 1

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
	ModernScrollbar.setup(panel, parent, THEME, { transparency = 0.45, offset = -4, zIndex = 300 })
	make("UIListLayout", { Padding = UDim.new(0, 0), SortOrder = Enum.SortOrder.LayoutOrder, Parent = panel })

	-- ── COVER ──
	local COVER_H = 520
	local coverSection = make("Frame", {
		Size = UDim2.new(1, 0, 0, COVER_H),
		BackgroundColor3 = THEME.bg,
		BackgroundTransparency = 0, BorderSizePixel = 0,
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
		Size = UDim2.new(1, 0, 0.65, 0), Position = UDim2.new(0, 0, 0.35, 0),
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
		TextColor3 = THEME.dim, Text = "",
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 214, Parent = coverSection,
	})

	-- ── PROGRESO (barra full-width + tiempos abajo) ──
	local progressSection = make("Frame", {
		Size = UDim2.new(1, 0, 0, 38), BackgroundTransparency = 1,
		LayoutOrder = 2, ZIndex = 211, Parent = panel,
	})

	local timeLeft = make("TextLabel", {
		Size = UDim2.new(0, 50, 0, 22), Position = UDim2.new(0, 12, 0, 16),
		BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 16,
		TextColor3 = THEME.accent, Text = "0:00",
		TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 212, Parent = progressSection,
	})

	local timeRight = make("TextLabel", {
		Size = UDim2.new(0, 50, 0, 22), Position = UDim2.new(1, -62, 0, 16),
		BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 16,
		TextColor3 = THEME.dim, Text = "0:00",
		TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 212, Parent = progressSection,
	})

	local progressBar = make("Frame", {
		Size = UDim2.new(1, -24, 0, 8), Position = UDim2.new(0, 12, 0, 6),
		BackgroundColor3 = THEME.elevated, ZIndex = 212, Parent = progressSection,
	})
	rounded(progressBar, 4)

	local progressFill = make("Frame", {
		Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = THEME.accent,
		ZIndex = 213, Parent = progressBar,
	})
	rounded(progressFill, 3)

	-- ── REPRODUCCION ──
	local ADMIN_BTN = 42
	local reproSection = make("Frame", {
		Size = UDim2.new(1, 0, 0, 78), BackgroundTransparency = 1,
		LayoutOrder = 3, ZIndex = 211, Parent = panel,
	})

	make("TextLabel", {
		Size = UDim2.new(1, -24, 0, 18), Position = UDim2.new(0, 12, 0, 4),
		BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 13,
		TextColor3 = THEME.dim, Text = "REPRODUCCION",
		TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 212, Parent = reproSection,
	})

	local reproRow = make("Frame", {
		Size = UDim2.new(1, -24, 0, 42), Position = UDim2.new(0, 12, 0, 28),
		BackgroundTransparency = 1, ZIndex = 212, Parent = reproSection,
	})

	-- Admin buttons (outlined, matching input style)
	local skipBtn, clearBtn
	local inputLeftOff, inputRightOff = 0, 0

	if state.isAdmin then
		-- SKIP button (left)
		skipBtn = make("TextButton", {
			Size = UDim2.new(0, ADMIN_BTN, 0, ADMIN_BTN),
			Position = UDim2.new(0, 0, 0, 0),
			BackgroundColor3 = THEME.bg,
			BackgroundTransparency = 1,
			Text = "", BorderSizePixel = 0, AutoButtonColor = false,
			ZIndex = 214, Parent = reproRow,
		})
		rounded(skipBtn, ADMIN_BTN / 2)
		make("UIStroke", {
			Color = THEME.stroke, Thickness = 1.5,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = skipBtn,
		})
		make("ImageLabel", {
			Size = UDim2.new(0.55, 0, 0.55, 0), Position = UDim2.new(0.225, 0, 0.225, 0),
			BackgroundTransparency = 1, Image = ICONS.SKIP,
			ImageColor3 = THEME.dim,
			ZIndex = 215, Parent = skipBtn,
		})

		-- CLEAR button (right)
		clearBtn = make("TextButton", {
			Size = UDim2.new(0, ADMIN_BTN, 0, ADMIN_BTN),
			Position = UDim2.new(1, -ADMIN_BTN, 0, 0),
			BackgroundColor3 = THEME.bg,
			BackgroundTransparency = 1,
			Text = "", BorderSizePixel = 0, AutoButtonColor = false,
			ZIndex = 214, Parent = reproRow,
		})
		rounded(clearBtn, ADMIN_BTN / 2)
		make("UIStroke", {
			Color = THEME.stroke, Thickness = 1.5,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = clearBtn,
		})
		make("ImageLabel", {
			Size = UDim2.new(0.55, 0, 0.55, 0), Position = UDim2.new(0.225, 0, 0.225, 0),
			BackgroundTransparency = 1, Image = ICONS.DELETE,
			ImageColor3 = THEME.dim,
			ZIndex = 215, Parent = clearBtn,
		})

		inputLeftOff = ADMIN_BTN + 4
		inputRightOff = ADMIN_BTN + 4
	end

	-- Combined input + add button (outlined pill)
	local inputContainer = make("Frame", {
		Size = UDim2.new(1, -(inputLeftOff + inputRightOff), 1, 0),
		Position = UDim2.new(0, inputLeftOff, 0, 0),
		BackgroundColor3 = THEME.bg,
		BackgroundTransparency = 1,
		BorderSizePixel = 0, ZIndex = 213, Parent = reproRow,
	})
	rounded(inputContainer, 21)
	make("UIStroke", {
		Color = THEME.stroke, Thickness = 1.5,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = inputContainer,
	})

	local reproInput = make("TextBox", {
		Size = UDim2.new(1, -46, 1, 0),
		Position = UDim2.new(0, 0, 0, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold, TextSize = 15,
		TextColor3 = THEME.text,
		PlaceholderText = "ID de cancion...",
		PlaceholderColor3 = THEME.muted,
		ClearTextOnFocus = false, Text = "",
		ZIndex = 214, Parent = inputContainer,
	})
	make("UIPadding", { PaddingLeft = UDim.new(0, 16), PaddingRight = UDim.new(0, 6), Parent = reproInput })

	local addBtn = make("TextButton", {
		Size = UDim2.new(0, 38, 0, 38),
		Position = UDim2.new(1, -40, 0.5, -19),
		BackgroundTransparency = 1,
		Text = "", BorderSizePixel = 0, AutoButtonColor = false,
		ZIndex = 215, Parent = inputContainer,
	})
	local addIcon = make("ImageLabel", {
		Size = UDim2.new(0.6, 0, 0.6, 0), Position = UDim2.new(0.2, 0, 0.2, 0),
		BackgroundTransparency = 1, Image = ICONS.PLAY_ADD,
		ImageColor3 = THEME.dim,
		ZIndex = 216, Name = "IconImage", Parent = addBtn,
	})
	local addLoading = make("ImageLabel", {
		Size = UDim2.new(0.55, 0, 0.55, 0), Position = UDim2.new(0.225, 0, 0.225, 0),
		BackgroundTransparency = 1, Image = ICONS.LOADING,
		ImageColor3 = THEME.dim, ZIndex = 216,
		Visible = false, Name = "LoadingIcon", Parent = addBtn,
	})

	local inputStroke = inputContainer:FindFirstChildWhichIsA("UIStroke")
	local pendingInputSongId = nil

	reproInput:GetPropertyChangedSignal("Text"):Connect(function()
		reproInput.Text = reproInput.Text:gsub("[^%d]", ""):sub(1, 15)
	end)

	local function doQuickAdd()
		local songId = tonumber(reproInput.Text)
		if not songId or pendingInputSongId then return end
		pendingInputSongId = songId
		reproInput.Text = ""

		-- Show loading
		addIcon.Visible = false
		addLoading.Visible = true
		addLoading.Rotation = 0
		task.spawn(function()
			local tw = game:GetService("TweenService"):Create(
				addLoading,
				TweenInfo.new(1.2, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1),
				{ Rotation = 360 }
			)
			tw:Play()
			while addLoading.Visible do task.wait(0.1) end
			if tw then tw:Cancel() end
		end)

		if R.Add then pcall(function() R.Add:FireServer(songId) end) end
	end

	addBtn.MouseButton1Click:Connect(doQuickAdd)
	reproInput.FocusLost:Connect(function(enterPressed)
		if enterPressed then doQuickAdd() end
	end)

	if state.isAdmin then
		skipBtn.MouseButton1Click:Connect(function()
			if R.Next then pcall(function() R.Next:FireServer() end) end
		end)
		skipBtn.MouseEnter:Connect(function()
			tween(skipBtn, 0.15, { BackgroundTransparency = 0, BackgroundColor3 = THEME.elevated })
		end)
		skipBtn.MouseLeave:Connect(function()
			tween(skipBtn, 0.15, { BackgroundTransparency = 1 })
		end)

		clearBtn.MouseButton1Click:Connect(function()
			if R.Clear then pcall(function() R.Clear:FireServer() end) end
		end)
		clearBtn.MouseEnter:Connect(function()
			tween(clearBtn, 0.15, { BackgroundTransparency = 0, BackgroundColor3 = THEME.elevated })
		end)
		clearBtn.MouseLeave:Connect(function()
			tween(clearBtn, 0.15, { BackgroundTransparency = 1 })
		end)
	end

	-- ── COLA (LISTA) ──
	local listaSection = make("Frame", {
		Size = UDim2.new(1, 0, 0, 500), BackgroundTransparency = 1,
		LayoutOrder = 4, ZIndex = 211, Parent = panel,
	})

	local listaLabel = make("TextLabel", {
		Size = UDim2.new(1, -24, 0, 20), Position = UDim2.new(0, 12, 0, 2),
		BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 13,
		TextColor3 = THEME.dim, Text = "LISTA · 0",
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
		TextColor3 = THEME.muted, Text = "La cola está vacía",
		ZIndex = 212, Visible = true, Parent = queueContainer,
	})

	-- Queue card factory (CanvasGroup + iconos modernos — mismo estilo MusicDjDashboard)
	local QC_H = 58

	local function createQueueCard()
		local card = Instance.new("CanvasGroup")
		card.Name = "QueueCard"
		card.Size = UDim2.new(1, 0, 0, QC_H)
		card.BackgroundColor3 = THEME.card
		card.BackgroundTransparency = 0
		card.BorderSizePixel = 0
		card.GroupTransparency = 0
		card.ZIndex = 213
		card.Visible = false
		card.Parent = queueContainer
		make("UICorner", { CornerRadius = UDim.new(0, 10), Parent = card })
		make("UIStroke", {
			Color = THEME.stroke, Thickness = 1, Transparency = 0.3,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Name = "CardStroke", Parent = card,
		})

		-- Cover full-height izquierda (CanvasGroup recorta los bordes)
		local coverBg = make("Frame", {
			Size = UDim2.new(0, QC_H, 1, 0),
			BackgroundColor3 = THEME.elevated, BackgroundTransparency = 0,
			BorderSizePixel = 0, ZIndex = 214, Name = "CoverBg", Parent = card,
		})
		make("ImageLabel", {
			Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
			ScaleType = Enum.ScaleType.Crop, Image = "", BorderSizePixel = 0,
			ZIndex = 215, Name = "Cover", Parent = coverBg,
		})

		local tx = QC_H + 8
		make("TextLabel", {
			Size = UDim2.new(1, -(tx + 8), 0, 20), Position = UDim2.new(0, tx, 0, 10),
			BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 14,
			TextColor3 = THEME.text, Text = "",
			TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
			ZIndex = 214, Name = "NameLabel", Parent = card,
		})

		make("TextLabel", {
			Size = UDim2.new(1, -(tx + 8), 0, 14), Position = UDim2.new(0, tx, 0, 32),
			BackgroundTransparency = 1, Font = Enum.Font.GothamMedium, TextSize = 12,
			TextColor3 = THEME.dim, Text = "",
			TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
			ZIndex = 214, Name = "ArtistLabel", Parent = card,
		})

		if state.isAdmin then
			local rmBtn, rmIcon = UI.outlinedCircleBtn(card, {
				size = 30, icon = ICONS.DELETE, theme = THEME,
				position = UDim2.new(1, -38, 0.5, -15),
				zIndex = 216, name = "RemoveBtn",
			})
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

	function api.handleAddResponse(response, songId, isSuccess)
		-- Stop loading
		addLoading.Visible = false
		addIcon.Visible = true
		pendingInputSongId = nil

		if inputStroke then
			local color = isSuccess and THEME.success or THEME.danger
			tween(inputStroke, 0.15, { Color = color })
			task.delay(2, function()
				if inputStroke then tween(inputStroke, 0.4, { Color = THEME.stroke }) end
			end)
		end

		if isSuccess then
			addIcon.Image = ICONS.CHECK
			addIcon.ImageColor3 = THEME.success
			task.delay(2, function()
				addIcon.Image = ICONS.PLAY_ADD
				addIcon.ImageColor3 = THEME.dim
			end)
		end
	end

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

			card.BackgroundColor3 = isActive and THEME.elevated or THEME.card

			-- UIStroke activa
			local stroke = card:FindFirstChild("CardStroke")
			if stroke then
				stroke.Color = isActive and THEME.accent or THEME.stroke
				stroke.Transparency = isActive and 0.4 or 0.3
			end

			local nl = card:FindFirstChild("NameLabel")
			if nl then nl.Text = song.name or "Desconocida"; nl.TextColor3 = isActive and THEME.accent or THEME.text end

			local al = card:FindFirstChild("ArtistLabel")
			if al then al.Text = song.artist or song.requestedBy or "" end

			local cov = card:FindFirstChild("Cover", true)
			if cov then cov.Image = song.djCover or "" end

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
