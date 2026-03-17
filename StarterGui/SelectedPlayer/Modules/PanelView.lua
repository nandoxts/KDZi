--[[
	═══════════════════════════════════════════════════════════
	PANEL VIEW — Diseño renovado, estático y minimalista
	═══════════════════════════════════════════════════════════
	• Panel estático (sin drag/arrastre)
	• Sin ModernScrollbar
	• Header: avatar derecha + nombre/estado izquierda
	• Botones: Sincronizar · Abrazar · Propina · Añadir Amigo · Ver Avatar
	• Add Friend con lógica propia
]]

local TweenService  = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PanelView = {}

-- ═══════════════════════════════════════════════════════════════
-- DEPENDENCIAS
-- ═══════════════════════════════════════════════════════════════
local Config, State, Utils, Remotes
local Services, NotificationSystem, THEME
local player, playerGui
local PREMIUM_ICON = "rbxassetid://13600832988"

local AdminConfig  = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("AdminConfig"))
local SyncSystem   -- cargado lazy en createPanel

-- Tweens activos (para cancelar antes de re-animar)
local activeTweens = {}

function PanelView.init(config, state, utils, remotes)
	Config           = config
	State            = state
	Utils            = utils
	Remotes          = remotes
	Services         = remotes.Services
	NotificationSystem = remotes.Systems.NotificationSystem
	THEME            = config.THEME
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
	PANEL_H        = 340,        -- altura total (header + botones)
	CORNER         = 12,

	-- Header (zona avatar)
	HEADER_H       = 110,
	AVATAR_SIZE    = 100,        -- avatar cuadrado a la derecha

	-- Texto header
	NAME_SIZE      = 16,
	USER_SIZE      = 12,
	STATUS_SIZE    = 11,
	PADDING        = 14,

	-- Botones
	BTN_H          = 38,
	BTN_GAP        = 6,
	BTN_SIZE       = 13,
	BTN_CORNER     = 8,

	-- Colores base (se mezclan con playerColor en hover)
	BTN_BG         = Color3.fromRGB(18, 18, 18),
	BTN_BG_HOVER   = Color3.fromRGB(32, 32, 32),
	BTN_STROKE     = Color3.fromRGB(55, 55, 55),
	HEADER_BG      = Color3.fromRGB(14, 14, 14),
	PANEL_BG       = Color3.fromRGB(10, 10, 10),
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
	local key = tostring(inst)
	if activeTweens[key] then activeTweens[key]:Cancel() end
	local tw = TweenService:Create(inst, TweenInfo.new(t or 0.15, style or Enum.EasingStyle.Sine, dir or Enum.EasingDirection.InOut), props)
	activeTweens[key] = tw
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
-- ADMIN
-- ═══════════════════════════════════════════════════════════════
local Admin = {}

function Admin.isAdmin(userName)
	return userName and AdminConfig:IsAdmin(userName) or false
end

PanelView.Admin = Admin

-- ═══════════════════════════════════════════════════════════════
-- BOTÓN
-- ═══════════════════════════════════════════════════════════════
--[[
	Devuelve el TextButton listo para conectar .MouseButton1Click
	accentColor: se usa en hover para el borde
]]
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

	-- Hover
	btn.MouseEnter:Connect(function()
		tween(btn,       { BackgroundColor3 = D.BTN_BG_HOVER }, D.ANIM_BTN)
		tween(btnStroke, { Color = accentColor or D.BTN_STROKE, Transparency = 0.35 }, D.ANIM_BTN)
	end)
	btn.MouseLeave:Connect(function()
		tween(btn,       { BackgroundColor3 = D.BTN_BG },    D.ANIM_BTN)
		tween(btnStroke, { Color = D.BTN_STROKE, Transparency = 0 }, D.ANIM_BTN)
	end)
	-- Click: pequeño flash
	btn.MouseButton1Click:Connect(function()
		tween(btn, { BackgroundColor3 = accentColor or D.BTN_BG_HOVER }, 0.06)
		task.delay(0.10, function()
			tween(btn, { BackgroundColor3 = D.BTN_BG_HOVER }, 0.12)
		end)
	end)

	return btn
end

-- ═══════════════════════════════════════════════════════════════
-- ADD FRIEND — Lógica
-- ═══════════════════════════════════════════════════════════════
--[[
	Conecta el botón de "Añadir Amigo" con la lógica del servidor.
	Cambia el texto del botón según el estado actual de amistad.

	IMPORTANTE: adapta los nombres de Remotes a los que uses en tu proyecto.
	Las líneas marcadas con  ← LÓGICA  son donde debes conectar tu sistema.
]]
local function setupAddFriendButton(btn, target)
	if not target then return end

	local userId = target.UserId

	-- Estado inicial: comprobar si ya son amigos
	-- ← LÓGICA: reemplaza esto con tu Remote/función real
	local function checkFriendStatus()
		local ok, isFriend = pcall(function()
			return player:IsFriendsWith(userId)          -- API nativa de Roblox
		end)
		return ok and isFriend
	end

	local function refreshLabel()
		if checkFriendStatus() then
			btn.Text = "✓ Amigos"
			btn.TextColor3 = Color3.fromRGB(100, 220, 120)
		else
			btn.Text = "Añadir Amigo"
			btn.TextColor3 = D.TEXT_PRIMARY
		end
	end

	refreshLabel()

	btn.MouseButton1Click:Connect(function()
		if checkFriendStatus() then
			-- Ya son amigos, no hacer nada (o deshacer, según tu juego)
			return
		end

		-- ← LÓGICA: aquí disparas tu Remote para solicitar amistad
		--   Ejemplos:
		--     Remotes.FriendRequest:FireServer(userId)
		--     Services.GuiService:InspectPlayerFromUserId(userId)   -- abre el menú nativo

		-- Por ahora usa el menú nativo de Roblox (siempre disponible):
		pcall(function()
			Services.GuiService:InspectPlayerFromUserId(userId)
		end)

		-- Tras un pequeño delay, refresca el texto
		task.delay(1, refreshLabel)
	end)
end

-- ═══════════════════════════════════════════════════════════════
-- HEADER (avatar + nombre + estado)
-- ═══════════════════════════════════════════════════════════════
local function createHeader(parent, data, playerColor)
	local isPremium = (data.isPremium == true)
		or (State.target and State.target.MembershipType == Enum.MembershipType.Premium)
	local isAdmin  = Admin.isAdmin(data.username)

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
		BackgroundColor3 = playerColor,
		BackgroundTransparency = 0.5,
		ZIndex           = 4,
		Parent           = header,
	})
	corner(avatarBorder, D.BTN_CORNER + 2)

	local avatarImg = Instance.new("ImageLabel")
	avatarImg.Size               = UDim2.new(0, D.AVATAR_SIZE, 0, D.AVATAR_SIZE)
	avatarImg.Position           = UDim2.new(0.5, -D.AVATAR_SIZE / 2, 0.5, -D.AVATAR_SIZE / 2)
	avatarImg.BackgroundColor3   = Color3.fromRGB(25, 25, 25)
	avatarImg.BackgroundTransparency = 0
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
				Enum.ThumbnailType.AvatarBust,
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

	-- Admin badge
	if isAdmin then
		local badge = Instance.new("TextLabel")
		badge.BackgroundColor3    = playerColor
		badge.BackgroundTransparency = 0.5
		badge.Size                = UDim2.new(0, 52, 0, 16)
		badge.Text                = "OWNER"
		badge.TextColor3          = Color3.fromRGB(255, 255, 255)
		badge.Font                = Enum.Font.GothamBlack
		badge.TextSize            = 9
		badge.LayoutOrder         = 2
		badge.Parent              = textArea
		corner(badge, 8)
	end

	-- @username
	local unLabel = label({
		Size          = UDim2.new(1, 0, 0, D.USER_SIZE + 4),
		Text          = "@" .. (data.username or ""),
		TextColor3    = D.TEXT_MUTED,
		Font          = Enum.Font.Gotham,
		TextSize      = D.USER_SIZE,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate  = Enum.TextTruncate.AtEnd,
		LayoutOrder   = isAdmin and 3 or 2,
		Parent        = textArea,
	})

	-- Status / quote
	local statusText = (data.status and data.status ~= "") and ('"' .. data.status .. '"') or '"nothing to say."'
	label({
		Size          = UDim2.new(1, 0, 0, D.STATUS_SIZE + 6),
		Text          = statusText,
		TextColor3    = D.TEXT_STATUS,
		Font          = Enum.Font.GothamItalic,
		TextSize      = D.STATUS_SIZE,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate  = Enum.TextTruncate.AtEnd,
		LayoutOrder   = isAdmin and 4 or 3,
		Parent        = textArea,
	})

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
	local numBtns = 5
	local btnsH   = numBtns * D.BTN_H + (numBtns - 1) * D.BTN_GAP
	local totalH  = D.HEADER_H + D.PADDING + btnsH + D.PADDING

	local container = Instance.new("Frame")
	container.Size               = UDim2.new(0, D.PANEL_W, 0, totalH)
	container.Position           = UDim2.new(0.5, -D.PANEL_W / 2, 1, 60)   -- empieza abajo (animación)
	container.BackgroundColor3   = D.PANEL_BG
	container.BackgroundTransparency = 0
	container.BorderSizePixel    = 0
	container.ClipsDescendants   = false
	container.ZIndex             = 10
	container.Parent             = screenGui
	corner(container, D.CORNER)
	stroke(container, D.BTN_STROKE, 1.2, 0.3)

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

	-- 2. Abrazar
	--    ← LÓGICA: conecta tu Remote de abrazo aquí
	local hugBtn = createButton(btnArea, "Abrazar", 2, playerColor)
	hugBtn.MouseButton1Click:Connect(function()
		if not target then return end
		-- Ejemplo: Remotes.HugRemote:FireServer(target)
	end)

	-- 3. Propina
	--    ← LÓGICA: conecta tu Remote de propina aquí
	local tipBtn = createButton(btnArea, "Propina", 3, playerColor)
	tipBtn.MouseButton1Click:Connect(function()
		if not target then return end
		-- Ejemplo: Remotes.TipRemote:FireServer(target)
	end)

	-- 4. Añadir Amigo
	local addFriendBtn = createButton(btnArea, "Añadir Amigo", 4, playerColor)
	setupAddFriendButton(addFriendBtn, target)

	-- 5. Ver Avatar
	local avatarBtn = createButton(btnArea, "Ver Avatar", 5, playerColor)
	avatarBtn.MouseButton1Click:Connect(function()
		if target then
			pcall(function() Services.GuiService:InspectPlayerFromUserId(target.UserId) end)
		end
	end)

	-- ── ANIMACIÓN DE ENTRADA ─────────────────────────────────
	--   Desliza desde abajo hasta el centro-inferior de la pantalla
	local targetY = 1 - ((totalH + 20) / workspace.CurrentCamera.ViewportSize.Y)
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

function PanelView.invalidateLayoutCache()
	-- sin cache ahora, pero se mantiene por compatibilidad
end

return PanelView