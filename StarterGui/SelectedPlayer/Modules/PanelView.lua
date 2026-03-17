--[[
	═══════════════════════════════════════════════════════════
	PANEL VIEW — Diseño renovado, estático y minimalista
	═══════════════════════════════════════════════════════════
]]

local TweenService  = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PanelView = {}

local State, Utils, Remotes
local Services
local player, playerGui
local PREMIUM_ICON = "rbxassetid://13600832988"

local SyncSystem   -- cargado lazy en createPanel

-- Tweens activos (para cancelar antes de re-animar)
local activeTweens = {}

function PanelView.init(config, state, utils, remotes)
	State            = state
	Utils            = utils
	Remotes          = remotes
	Services         = remotes.Services
	PREMIUM_ICON     = config.PREMIUM_ICON or PREMIUM_ICON
	player           = Services.Player
	playerGui        = Services.PlayerGui
end

-- ═══════════════════════════════════════════════════════════════
-- CONSTANTES DE DISEÑO (ajusta aquí todo el look)
-- ═══════════════════════════════════════════════════════════════
local D = {
	-- Panel
	PANEL_W        = 320,
	CORNER         = 12,

	-- Header (zona avatar)
	HEADER_H       = 110,
	AVATAR_SIZE    = 100,        -- avatar cuadrado a la derecha

	-- Texto header
	NAME_SIZE      = 22,
	USER_SIZE      = 15,
	STATUS_SIZE    = 14,
	PADDING        = 14,

	-- Botones
	BTN_H          = 38,
	BTN_GAP        = 6,
	BTN_SIZE       = 15,
	BTN_CORNER     = 8,

	-- Colores base (se mezclan con playerColor en hover)
	BTN_BG         = Color3.fromRGB(18, 18, 18),
	BTN_BG_HOVER   = Color3.fromRGB(32, 32, 32),
	BTN_STROKE     = Color3.fromRGB(55, 55, 55),
	HEADER_BG      = Color3.fromRGB(14, 14, 14),
	TEXT_PRIMARY   = Color3.fromRGB(240, 240, 240),
	TEXT_MUTED     = Color3.fromRGB(140, 140, 140),
	TEXT_STATUS    = Color3.fromRGB(160, 160, 160),

	-- Animación
	ANIM_IN        = 0.45,
	ANIM_BTN       = 0.12,
}

-- ═══════════════════════════════════════════════════════════════
-- HELPERS INTERNOS
-- ═══════════════════════════════════════════════════════════════
local function tween(inst, props, t, style, dir)
	if not inst or not inst.Parent then return end
	if activeTweens[inst] then activeTweens[inst]:Cancel() end
	local tw = TweenService:Create(inst, TweenInfo.new(t or 0.15, style or Enum.EasingStyle.Sine, dir or Enum.EasingDirection.InOut), props)
	activeTweens[inst] = tw
	tw:Play()
	return tw
end

local function corner(inst, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r or D.CORNER)
	c.Parent = inst
	return c
end

local function stroke(inst, col, thick, transp)
	local s = Instance.new("UIStroke")
	s.Color = col or D.BTN_STROKE
	s.Thickness = thick or 1
	s.Transparency = transp or 0
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = inst
	return s
end

local function frame(props)
	local f = Instance.new("Frame")
	f.BackgroundTransparency = 1
	f.BorderSizePixel = 0
	for k, v in pairs(props) do f[k] = v end
	return f
end

local function label(props)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.BorderSizePixel = 0
	l.RichText = false
	for k, v in pairs(props) do l[k] = v end
	return l
end

-- ═══════════════════════════════════════════════════════════════
-- BOTÓN
-- ═══════════════════════════════════════════════════════════════
local function createButton(parent, text, order, accentColor)
	local container = frame({
		Size            = UDim2.new(1, 0, 0, D.BTN_H),
		LayoutOrder     = order,
		BackgroundTransparency = 1,
		Parent          = parent,
	})

	local btn = Instance.new("TextButton")
	btn.Size               = UDim2.new(1, 0, 1, 0)
	btn.BackgroundColor3   = D.BTN_BG
	btn.BackgroundTransparency = 0
	btn.BorderSizePixel    = 0
	btn.AutoButtonColor    = false
	btn.Text               = text
	btn.TextColor3         = D.TEXT_PRIMARY
	btn.Font               = Enum.Font.GothamBold
	btn.TextSize           = D.BTN_SIZE
	btn.ZIndex             = 5
	btn.Parent             = container

	corner(btn, D.BTN_CORNER)
	local btnStroke = stroke(btn, D.BTN_STROKE, 1, 0)

	local isHovered = false

	btn.MouseEnter:Connect(function()
		isHovered = true
		tween(btn,       { BackgroundColor3 = D.BTN_BG_HOVER }, D.ANIM_BTN)
		tween(btnStroke, { Color = accentColor or D.BTN_STROKE, Transparency = 0.35 }, D.ANIM_BTN)
	end)
	btn.MouseLeave:Connect(function()
		isHovered = false
		tween(btn,       { BackgroundColor3 = D.BTN_BG }, D.ANIM_BTN)
		tween(btnStroke, { Color = D.BTN_STROKE, Transparency = 0 }, D.ANIM_BTN)
	end)
	-- Click: flash instant + reset inmediato (evita hover atascado al perder foco)
	btn.MouseButton1Click:Connect(function()
		isHovered = false
		btn.BackgroundColor3 = accentColor or Color3.fromRGB(50, 50, 50)
		tween(btn,       { BackgroundColor3 = D.BTN_BG }, 0.18)
		tween(btnStroke, { Color = D.BTN_STROKE, Transparency = 0 }, 0.15)
	end)

	return btn
end

-- ═══════════════════════════════════════════════════════════════
-- ADD FRIEND
-- ═══════════════════════════════════════════════════════════════
local function setupAddFriendButton(btn, target)
	if not target then return end

	local userId = target.UserId

	local function checkFriendStatus()
		local ok, isFriend = pcall(function()
			return player:IsFriendsWith(userId)
		end)
		return ok and isFriend
	end

	local function refreshLabel()
		if not btn.Parent then return end
		if checkFriendStatus() then
			btn.Text       = "Eliminar Amigo"
			btn.TextColor3 = Color3.fromRGB(220, 80, 80)
		else
			btn.Text       = "Añadir Amigo"
			btn.TextColor3 = D.TEXT_PRIMARY
		end
	end

	refreshLabel()

	btn.MouseButton1Click:Connect(function()
		if checkFriendStatus() then
			-- Eliminar amigo
			pcall(function()
				local StarterGui = game:GetService("StarterGui")
				StarterGui:SetCore("PromptUnfriend", target)
			end)
		else
			-- Enviar solicitud de amistad
			pcall(function()
				local StarterGui = game:GetService("StarterGui")
				StarterGui:SetCore("PromptSendFriendRequest", target)
			end)
		end
		-- Refresca el texto tras la interacción del usuario
		task.delay(2, refreshLabel)
		task.delay(5, refreshLabel)
	end)
end

-- ═══════════════════════════════════════════════════════════════
-- HEADER (avatar + nombre + estado)
-- ═══════════════════════════════════════════════════════════════
local function createHeader(parent, data, playerColor)
	local isPremium = (data.isPremium == true)
		or (State.target and State.target.MembershipType == Enum.MembershipType.Premium)

	local header = frame({
		Size             = UDim2.new(1, 0, 0, D.HEADER_H),
		BackgroundColor3 = D.HEADER_BG,
		BackgroundTransparency = 0,
		ZIndex           = 3,
		Parent           = parent,
	})
	corner(header, D.CORNER)

	-- Separador inferior (línea sutil)
	local sep = frame({
		Size             = UDim2.new(1, -D.PADDING * 2, 0, 1),
		Position         = UDim2.new(0, D.PADDING, 1, -1),
		BackgroundColor3 = D.BTN_STROKE,
		BackgroundTransparency = 0.4,
		ZIndex           = 4,
		Parent           = header,
	})

	-- ── AVATAR (derecha) ──────────────────────────────────────
	local avatarBorder = frame({
		Size             = UDim2.new(0, D.AVATAR_SIZE + 4, 0, D.AVATAR_SIZE + 4),
		Position         = UDim2.new(1, -(D.AVATAR_SIZE + 4 + D.PADDING), 0.5, -(D.AVATAR_SIZE + 4) / 2),
		ZIndex           = 4,
		Parent           = header,
	})

	local zoomedSize = math.floor(D.AVATAR_SIZE * 1.2)
	local avatarImg = Instance.new("ImageLabel")
	avatarImg.Size               = UDim2.new(0, zoomedSize, 0, zoomedSize)
	avatarImg.Position           = UDim2.new(0.5, -zoomedSize / 2, 0.5, -zoomedSize / 2)
	avatarImg.BackgroundTransparency = 1
	avatarImg.Image              = ""
	avatarImg.ScaleType          = Enum.ScaleType.Crop
	avatarImg.ZIndex             = 5
	avatarImg.Parent             = avatarBorder
	corner(avatarImg, D.BTN_CORNER)

	-- Carga asíncrona del thumbnail
	task.spawn(function()
		local ok, img = pcall(function()
			return game:GetService("Players"):GetUserThumbnailAsync(
				data.userId,
				Enum.ThumbnailType.AvatarThumbnail,
				Enum.ThumbnailSize.Size420x420
			)
		end)
		if ok and avatarImg.Parent then
			avatarImg.Image = img
		end
	end)

	-- ── TEXTOS (izquierda) ────────────────────────────────────
	local textArea = frame({
		Size     = UDim2.new(0, D.PANEL_W - D.AVATAR_SIZE - D.PADDING * 3 - 10, 1, -D.PADDING * 2),
		Position = UDim2.new(0, D.PADDING, 0, D.PADDING),
		ZIndex   = 4,
		Parent   = header,
	})
	local ll = Instance.new("UIListLayout", textArea)
	ll.FillDirection        = Enum.FillDirection.Vertical
	ll.HorizontalAlignment  = Enum.HorizontalAlignment.Left
	ll.VerticalAlignment    = Enum.VerticalAlignment.Center
	ll.Padding              = UDim.new(0, 4)
	ll.SortOrder            = Enum.SortOrder.LayoutOrder
	ll.Parent               = textArea

	-- Display name (con ícono premium si aplica)
	local nameRow = frame({ Size = UDim2.new(1, 0, 0, D.NAME_SIZE + 4), LayoutOrder = 1, Parent = textArea })
	local nlayout = Instance.new("UIListLayout", nameRow)
	nlayout.FillDirection       = Enum.FillDirection.Horizontal
	nlayout.VerticalAlignment   = Enum.VerticalAlignment.Center
	nlayout.Padding             = UDim.new(0, 4)
	nlayout.Parent              = nameRow

	local dnLabel = Instance.new("TextLabel")
	dnLabel.BackgroundTransparency = 1
	dnLabel.Size               = UDim2.new(0, 0, 1, 0)
	dnLabel.AutomaticSize      = Enum.AutomaticSize.X
	dnLabel.Text               = data.displayName or data.username or "Jugador"
	dnLabel.TextColor3         = playerColor
	dnLabel.Font               = Enum.Font.GothamBold
	dnLabel.TextSize           = D.NAME_SIZE
	dnLabel.TextXAlignment     = Enum.TextXAlignment.Left
	dnLabel.TextTruncate       = Enum.TextTruncate.AtEnd
	dnLabel.LayoutOrder        = 1
	dnLabel.Parent             = nameRow

	if isPremium then
		local pIcon = Instance.new("ImageLabel")
		pIcon.BackgroundTransparency = 1
		pIcon.Size               = UDim2.new(0, D.NAME_SIZE, 0, D.NAME_SIZE)
		pIcon.Image              = PREMIUM_ICON
		pIcon.ImageColor3        = playerColor
		pIcon.ScaleType          = Enum.ScaleType.Fit
		pIcon.LayoutOrder        = 2
		pIcon.Parent             = nameRow
	end

	-- @username
	local unLabel = label({
		Size          = UDim2.new(1, 0, 0, D.USER_SIZE + 4),
		Text          = "@" .. (data.username or ""),
		TextColor3    = D.TEXT_MUTED,
		Font          = Enum.Font.GothamBold,
		TextSize      = D.USER_SIZE,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate  = Enum.TextTruncate.AtEnd,
		LayoutOrder   = 2,
		Parent        = textArea,
	})

	-- Status / quote (se actualiza async con descripción del servidor)
	-- Si el target es el jugador local → clickeable para editar
	local isOwnPanel = (data.userId == player.UserId)
	local statusText = (data.status and data.status ~= "") and ('"' .. data.status .. '"') or '"nothing to say."'

	local statusLabel = label({
		Size           = UDim2.new(1, 0, 0, D.STATUS_SIZE + 6),
		Text           = statusText,
		TextColor3     = D.TEXT_STATUS,
		Font           = Enum.Font.GothamBold,
		TextSize       = D.STATUS_SIZE,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate   = Enum.TextTruncate.AtEnd,
		LayoutOrder    = 3,
		Parent         = textArea,
	})
	State.bioLabel = statusLabel

	-- Si es mi panel, hacer clickeable para editar status
	if isOwnPanel then
		local editBtn = Instance.new("TextButton")
		editBtn.Size                   = UDim2.new(1, 0, 1, 0)
		editBtn.BackgroundTransparency = 1
		editBtn.Text                   = ""
		editBtn.ZIndex                 = 10
		editBtn.Parent                 = statusLabel

		editBtn.MouseButton1Click:Connect(function()
			-- Extraer texto limpio (sin comillas)
			local currentText = statusLabel.Text
			if currentText:sub(1, 1) == '"' then
				currentText = currentText:sub(2)
			end
			if currentText:sub(-1) == '"' then
				currentText = currentText:sub(1, -2)
			end
			if currentText == "nothing to say." then
				currentText = ""
			end

			local textBox = Instance.new("TextBox")
			textBox.Size                   = UDim2.new(1, 0, 0, D.STATUS_SIZE + 6)
			textBox.BackgroundTransparency = 1
			textBox.BorderSizePixel        = 0
			textBox.Text                   = currentText
			textBox.PlaceholderText        = "Escribe tu estado..."
			textBox.TextColor3             = Color3.fromRGB(255, 255, 255)
			textBox.Font                   = Enum.Font.Gotham
			textBox.TextSize               = D.STATUS_SIZE
			textBox.TextXAlignment         = Enum.TextXAlignment.Left
			textBox.ClearTextOnFocus       = false
			textBox.LayoutOrder            = 3
			textBox.ZIndex                 = 10
			textBox.Parent                 = textArea
			corner(textBox, 4)

			statusLabel.Visible = false
			textBox:CaptureFocus()

			local function submitStatus()
				local newText = textBox.Text:sub(1, 80):gsub("[\n\r]", " ")
				textBox:Destroy()
				statusLabel.Visible = true

				if newText ~= "" then
					statusLabel.Text = '"' .. newText .. '"'
				else
					statusLabel.Text = '"nothing to say."'
				end

				-- Enviar al servidor
				task.spawn(function()
					pcall(function()
						Remotes.Remotes.SetStatus:InvokeServer(newText)
					end)
				end)
			end

			textBox.FocusLost:Connect(function(enterPressed)
				submitStatus()
			end)
		end)
	end

	return header
end

-- ═══════════════════════════════════════════════════════════════
-- CREAR PANEL COMPLETO
-- ═══════════════════════════════════════════════════════════════
function PanelView.createPanel(data)
	if State.closing or not data or not data.userId then return nil end

	-- Carga lazy de SyncSystem
	if not SyncSystem then
		SyncSystem = require(script.Parent.SyncSystem)
	end

	local playerColor = Utils.getPlayerColor()
	State.playerColor = playerColor

	-- Buscar target
	local target
	for _, p in ipairs(Services.Players:GetPlayers()) do
		if p.UserId == data.userId then target = p; break end
	end
	State.target = target

	-- ScreenGui
	local screenGui = Utils.createScreenGui(playerGui)

	-- ── CONTENEDOR PRINCIPAL ─────────────────────────────────
	--   Centrado en pantalla, sin drag
	local numBtns = 3
	local btnsH   = numBtns * D.BTN_H + (numBtns - 1) * D.BTN_GAP
	local totalH  = D.HEADER_H + D.PADDING + btnsH + D.PADDING

	local container = Instance.new("Frame")
	container.Size               = UDim2.new(0, D.PANEL_W, 0, totalH)
	container.Position           = UDim2.new(0.5, -D.PANEL_W / 2, 1, 60)   -- empieza abajo (animación)
	container.BackgroundTransparency = 1
	container.BorderSizePixel    = 0
	container.ClipsDescendants   = false
	container.ZIndex             = 10
	container.Parent             = screenGui

	State.container = container

	-- ── HEADER ───────────────────────────────────────────────
	createHeader(container, data, playerColor)

	-- ── ZONA DE BOTONES ──────────────────────────────────────
	local btnArea = frame({
		Size     = UDim2.new(1, -D.PADDING * 2, 0, btnsH),
		Position = UDim2.new(0, D.PADDING, 0, D.HEADER_H + D.PADDING),
		ZIndex   = 5,
		Parent   = container,
	})
	local layout = Instance.new("UIListLayout")
	layout.FillDirection       = Enum.FillDirection.Vertical
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.SortOrder           = Enum.SortOrder.LayoutOrder
	layout.Padding             = UDim.new(0, D.BTN_GAP)
	layout.Parent              = btnArea

	-- 1. Sincronizar
	local syncDebounce = false
	local syncBtn = createButton(btnArea, "Sincronizar", 1, playerColor)
	syncBtn.MouseButton1Click:Connect(function()
		if syncDebounce or not target then return end
		syncDebounce = true
		SyncSystem.syncWithPlayer(target)
		task.wait(0.5)
		syncDebounce = false
	end)

	-- 2. Añadir Amigo (solo si NO es tu propio panel)
	if not target or target.UserId ~= player.UserId then
		local addFriendBtn = createButton(btnArea, "Añadir Amigo", 2, playerColor)
		setupAddFriendButton(addFriendBtn, target)
	end

	-- 3. Ver Avatar
	local avatarBtn = createButton(btnArea, "Ver Avatar", 3, playerColor)
	avatarBtn.MouseButton1Click:Connect(function()
		if target then
			pcall(function() Services.GuiService:InspectPlayerFromUserId(target.UserId) end)
		end
	end)

	-- ── ANIMACIÓN DE ENTRADA ─────────────────────────────────
	--   Desliza desde abajo hasta el centro-inferior de la pantalla
	local targetY = 1 - ((totalH + 80) / workspace.CurrentCamera.ViewportSize.Y)
	task.defer(function()
		tween(
			container,
			{ Position = UDim2.new(0.5, -D.PANEL_W / 2, targetY, 0) },
			D.ANIM_IN,
			Enum.EasingStyle.Quint,
			Enum.EasingDirection.Out
		)
	end)

	return screenGui
end

-- ═══════════════════════════════════════════════════════════════
-- CLEANUP
-- ═══════════════════════════════════════════════════════════════
function PanelView.cleanupTweens()
	for k, tw in pairs(activeTweens) do
		pcall(function() tw:Cancel() end)
		activeTweens[k] = nil
	end
end

function PanelView.getLayout()
	return { panelWidth = D.PANEL_W }
end

function PanelView.safeTween(inst, props, t, style, dir)
	return tween(inst, props, t, style, dir)
end

function PanelView.invalidateLayoutCache()
	-- sin cache ahora, pero se mantiene por compatibilidad
end

return PanelView