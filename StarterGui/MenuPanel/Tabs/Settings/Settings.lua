--[[
	Settings/Settings.lua — Tab de AJUSTES para el MenuPanel.
	Secciones: Volumen, Gráficos, Pantalla con toggles modernos.
]]

local Settings = {}

function Settings.build(parent, THEME)
	local TweenService      = game:GetService("TweenService")
	local UserInputService  = game:GetService("UserInputService")
	local Lighting          = game:GetService("Lighting")
	local StarterGui        = game:GetService("StarterGui")
	local Players           = game:GetService("Players")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local ModernScrollbar   = require(ReplicatedStorage:WaitForChild("UIComponents"):WaitForChild("ModernScrollbar"))

	local TW = TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

	-- State
	local state = {
		volume = 50,
		lowPerformance = false,
		globalShadows = true,
		sunRays = true,
		playerInterface = true,
		hideNames = false,
		hideEffects = false,
		hideChat = false,
		hideBubbleChat = false,
	}

	-- Scroll
	local scroll = Instance.new("ScrollingFrame")
	scroll.Size                   = UDim2.fromScale(1, 1)
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel        = 0
	scroll.ScrollBarThickness     = 0
	scroll.CanvasSize             = UDim2.new(0, 0, 0, 0)
	scroll.AutomaticCanvasSize    = Enum.AutomaticSize.Y
	scroll.ClipsDescendants       = true
	scroll.ZIndex                 = 204
	scroll.Parent                 = parent
	ModernScrollbar.setup(scroll, parent, THEME, {transparency = 0.4, offset = -4})

	local layout = Instance.new("UIListLayout")
	layout.Padding   = UDim.new(0, 0)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent    = scroll

	local pad = Instance.new("UIPadding")
	pad.PaddingLeft   = UDim.new(0, 14)
	pad.PaddingRight  = UDim.new(0, 14)
	pad.PaddingTop    = UDim.new(0, 4)
	pad.PaddingBottom = UDim.new(0, 20)
	pad.Parent        = scroll

	local layoutOrder = 0
	local function nextOrder() layoutOrder += 1; return layoutOrder end

	-- ══ SECTION HEADER ══
	local function sectionHeader(text)
		local h = Instance.new("TextLabel")
		h.Size                   = UDim2.new(1, 0, 0, 38)
		h.BackgroundTransparency = 1
		h.Font                   = Enum.Font.GothamBold
		h.TextSize               = 13
		h.TextColor3             = THEME.muted
		h.TextXAlignment         = Enum.TextXAlignment.Left
		h.Text                   = text
		h.ZIndex                 = 205
		h.LayoutOrder            = nextOrder()
		h.Parent                 = scroll
	end

	-- ══ TOGGLE ROW ══
	local function toggleRow(label, default, callback)
		local row = Instance.new("Frame")
		row.Size                   = UDim2.new(1, 0, 0, 48)
		row.BackgroundTransparency = 1
		row.BorderSizePixel        = 0
		row.ZIndex                 = 205
		row.LayoutOrder            = nextOrder()
		row.Parent                 = scroll

		-- Separator
		local sep = Instance.new("Frame")
		sep.Size                   = UDim2.new(1, 0, 0, 1)
		sep.Position               = UDim2.new(0, 0, 1, -1)
		sep.BackgroundColor3       = THEME.stroke
		sep.BackgroundTransparency = 0.5
		sep.BorderSizePixel        = 0
		sep.ZIndex                 = 205
		sep.Parent                 = row

		-- Label
		local lbl = Instance.new("TextLabel")
		lbl.Size                   = UDim2.new(1, -60, 1, 0)
		lbl.BackgroundTransparency = 1
		lbl.Font                   = Enum.Font.GothamMedium
		lbl.TextSize               = 14
		lbl.TextColor3             = THEME.text
		lbl.TextXAlignment         = Enum.TextXAlignment.Left
		lbl.Text                   = label
		lbl.ZIndex                 = 206
		lbl.Parent                 = row

		-- Toggle pill
		local bg = Instance.new("Frame")
		bg.Size            = UDim2.new(0, 48, 0, 26)
		bg.Position        = UDim2.new(1, -48, 0.5, -13)
		bg.BackgroundColor3 = THEME.elevated
		bg.BorderSizePixel = 0
		bg.ZIndex          = 206
		bg.Parent          = row
		local bgC = Instance.new("UICorner"); bgC.CornerRadius = UDim.new(0, 13); bgC.Parent = bg

		local circle = Instance.new("Frame")
		circle.Size            = UDim2.new(0, 22, 0, 22)
		circle.BackgroundColor3 = Color3.new(1, 1, 1)
		circle.BorderSizePixel = 0
		circle.ZIndex          = 207
		circle.Parent          = bg
		local cC = Instance.new("UICorner"); cC.CornerRadius = UDim.new(0, 11); cC.Parent = circle

		local isActive = default

		local function update(active)
			isActive = active
			TweenService:Create(bg, TW, {
				BackgroundColor3 = active and THEME.accent or THEME.elevated,
			}):Play()
			TweenService:Create(circle, TW, {
				Position = active and UDim2.new(1, -24, 0.5, -11) or UDim2.new(0, 2, 0.5, -11),
			}):Play()
			if callback then task.spawn(callback, active) end
		end

		update(isActive)

		local click = Instance.new("TextButton")
		click.Size                   = UDim2.fromScale(1, 1)
		click.BackgroundTransparency = 1
		click.Text                   = ""
		click.ZIndex                 = 208
		click.Parent                 = row
		click.MouseButton1Click:Connect(function() update(not isActive) end)
	end

	-- ══ VOLUME SLIDER ══
	local function volumeSlider()
		local row = Instance.new("Frame")
		row.Size                   = UDim2.new(1, 0, 0, 48)
		row.BackgroundTransparency = 1
		row.BorderSizePixel        = 0
		row.ZIndex                 = 205
		row.LayoutOrder            = nextOrder()
		row.Parent                 = scroll

		-- Separator
		local sep = Instance.new("Frame")
		sep.Size                   = UDim2.new(1, 0, 0, 1)
		sep.Position               = UDim2.new(0, 0, 1, -1)
		sep.BackgroundColor3       = THEME.stroke
		sep.BackgroundTransparency = 0.5
		sep.BorderSizePixel        = 0
		sep.ZIndex                 = 205
		sep.Parent                 = row

		-- Speaker icon
		local iconLbl = Instance.new("ImageLabel")
		iconLbl.Size                   = UDim2.new(0, 20, 0, 20)
		iconLbl.Position               = UDim2.new(0, 0, 0.5, -10)
		iconLbl.BackgroundTransparency = 1
		iconLbl.Image                  = "rbxassetid://119463017376976"
		iconLbl.ImageColor3            = THEME.text
		iconLbl.ZIndex                 = 206
		iconLbl.Parent                 = row

		-- Percentage
		local pctLbl = Instance.new("TextLabel")
		pctLbl.Size                   = UDim2.new(0, 42, 1, 0)
		pctLbl.Position               = UDim2.new(0, 26, 0, 0)
		pctLbl.BackgroundTransparency = 1
		pctLbl.Font                   = Enum.Font.GothamMedium
		pctLbl.TextSize               = 14
		pctLbl.TextColor3             = THEME.text
		pctLbl.Text                   = state.volume .. "%"
		pctLbl.TextXAlignment         = Enum.TextXAlignment.Left
		pctLbl.ZIndex                 = 206
		pctLbl.Parent                 = row

		-- Track
		local track = Instance.new("Frame")
		track.Size            = UDim2.new(1, -84, 0, 14)
		track.Position        = UDim2.new(0, 74, 0.5, -7)
		track.BackgroundColor3 = THEME.elevated
		track.BorderSizePixel = 0
		track.ZIndex          = 206
		track.Parent          = row
		local tC = Instance.new("UICorner"); tC.CornerRadius = UDim.new(0, 4); tC.Parent = track

		-- Fill
		local fill = Instance.new("Frame")
		fill.Size            = UDim2.new(state.volume / 100, 0, 1, 0)
		fill.BackgroundColor3 = THEME.accent
		fill.BorderSizePixel = 0
		fill.ZIndex          = 207
		fill.Parent          = track
		local fC = Instance.new("UICorner"); fC.CornerRadius = UDim.new(0, 4); fC.Parent = fill

		-- Thumb
		local thumb = Instance.new("Frame")
		thumb.Size            = UDim2.new(0, 18, 0, 20)
		thumb.Position        = UDim2.new(state.volume / 100, -9, 0.5, -10)
		thumb.BackgroundColor3 = Color3.new(1, 1, 1)
		thumb.BorderSizePixel = 0
		thumb.ZIndex          = 208
		thumb.Parent          = track
		local thC = Instance.new("UICorner"); thC.CornerRadius = UDim.new(0, 4); thC.Parent = thumb

		local dragging = false

		local function setVol(pct)
			pct = math.clamp(math.floor(pct + 0.5), 0, 100)
			state.volume = pct
			pctLbl.Text = pct .. "%"
			fill.Size = UDim2.new(pct / 100, 0, 1, 0)
			thumb.Position = UDim2.new(pct / 100, -9, 0.5, -10)
			local vol = pct / 100
			local snd = workspace:FindFirstChild("QueueSound")
			if snd then snd.Volume = vol end
			_G.MusicVolume = vol
		end

		-- Drag area
		local dragBtn = Instance.new("TextButton")
		dragBtn.Size                   = UDim2.new(1, 20, 0, 30)
		dragBtn.Position               = UDim2.new(0, -10, 0.5, -15)
		dragBtn.BackgroundTransparency = 1
		dragBtn.Text                   = ""
		dragBtn.ZIndex                 = 209
		dragBtn.Parent                 = track

		-- Conectar input global SOLO mientras se arrastra el slider
		local dragConns = {}

		local function stopDrag()
			dragging = false
			for _, c in ipairs(dragConns) do c:Disconnect() end
			dragConns = {}
		end

		dragBtn.MouseButton1Down:Connect(function()
			if dragging then return end
			dragging = true
			table.insert(dragConns, UserInputService.InputChanged:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
					local tX = track.AbsolutePosition.X
					local tW = track.AbsoluteSize.X
					if tW > 0 then
						setVol(math.clamp((input.Position.X - tX) / tW, 0, 1) * 100)
					end
				end
			end))
			table.insert(dragConns, UserInputService.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					stopDrag()
				end
			end))
		end)

		-- Click-to-set
		dragBtn.MouseButton1Click:Connect(function()
			local tX = track.AbsolutePosition.X
			local tW = track.AbsoluteSize.X
			if tW > 0 then
				local mouse = UserInputService:GetMouseLocation()
				setVol(math.clamp((mouse.X - tX) / tW, 0, 1) * 100)
			end
		end)
	end

	-- ═══ BUILD SECTIONS ═══

	-- VOLUMEN
	sectionHeader("VOLUMEN")
	volumeSlider()

	-- GRÁFICOS
	sectionHeader("GRÁFICOS")

	toggleRow("Rendimiento Bajo", state.lowPerformance, function(v)
		state.lowPerformance = v
		pcall(function()
			local rs = settings():GetService("RenderSettings")
			if v then
				rs.QualityLevel = Enum.QualityLevel.Level01
			else
				rs.QualityLevel = Enum.QualityLevel.Automatic
			end
		end)
	end)

	toggleRow("Sombras Globales", state.globalShadows, function(v)
		state.globalShadows = v
		pcall(function() Lighting.GlobalShadows = v end)
	end)

	toggleRow("Rayos Del Sol", state.sunRays, function(v)
		state.sunRays = v
		pcall(function()
			for _, child in pairs(Lighting:GetChildren()) do
				if child:IsA("SunRaysEffect") then child.Enabled = v end
			end
		end)
	end)

	-- PANTALLA
	sectionHeader("PANTALLA")

	toggleRow("Interfaz Del Jugador", state.playerInterface, function(v)
		state.playerInterface = v
		pcall(function()
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, v)
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, v)
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, v)
		end)
	end)

	toggleRow("Ocultar Nombres", state.hideNames, function(v)
		state.hideNames = v
		pcall(function()
			local lp = Players.LocalPlayer
			for _, plr in pairs(Players:GetPlayers()) do
				if plr ~= lp and plr.Character then
					local head = plr.Character:FindFirstChild("Head")
					if head then
						local oh = head:FindFirstChild("Overhead")
						if oh then oh.Enabled = not v end
					end
				end
			end
		end)
	end)

	toggleRow("Ocultar Efectos", state.hideEffects, function(v)
		state.hideEffects = v
		pcall(function()
			for _, p in pairs(workspace:GetDescendants()) do
				if p:IsA("ParticleEmitter") then p.Enabled = not v end
			end
		end)
	end)

	toggleRow("Ocultar Chat", state.hideChat, function(v)
		state.hideChat = v
		pcall(function()
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, not v)
		end)
	end)

	toggleRow("Ocultar Bubble Chat", state.hideBubbleChat, function(v)
		state.hideBubbleChat = v
		pcall(function()
			local TCS = game:GetService("TextChatService")
			if TCS:FindFirstChild("BubbleChatConfiguration") then
				TCS.BubbleChatConfiguration.Enabled = not v
			end
		end)
		pcall(function() game.Chat.BubbleChatEnabled = not v end)
	end)
end

return Settings
