local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

-- Cache math functions (evita lookups repetidos en hot loops)
local mfloor = math.floor
local mclamp = math.clamp
local mmin   = math.min
local mrandom = math.random
local sformat = string.format

-- ═══════════════════════════════════════════════════════
-- THEME
-- ═══════════════════════════════════════════════════════
local okTheme, THEME = pcall(function()
	return require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("ThemeConfig"))
end)
if not okTheme then
	THEME = { accent = Color3.fromRGB(70, 30, 215) }
end

-- ═══════════════════════════════════════════════════════
-- UI
-- ═══════════════════════════════════════════════════════
local visuals = Workspace:WaitForChild("visuals", 15)
if not visuals then return end

local MusicPlayerUI = visuals:WaitForChild("MusicPlayerUI", 15)
if not MusicPlayerUI then return end

local Main = MusicPlayerUI:WaitForChild("Main", 15)
if not Main then return end

local UI = {
	SongTitle = Main:FindFirstChild("SongTitle"),
	Artist = Main:FindFirstChild("Artist"),
	TimeDisplay = Main:FindFirstChild("TimeDisplay"),
	ProgressBg = Main:FindFirstChild("ProgressBg"),
	ProgressFill = nil,
	Equalizer = Main:FindFirstChild("Equalizer"),
	SeparatorLine = Main:FindFirstChild("SeparatorLine"),
	EqualizerBars = {},
	Glow = nil,
}

if UI.ProgressBg then
	UI.ProgressFill = UI.ProgressBg:FindFirstChild("ProgressFill")
	if UI.ProgressFill then
		UI.Glow = UI.ProgressFill:FindFirstChild("Glow")
	end
end

local function getAllGuiObjects(parent)
	local guiObjects = {}
	for _, child in ipairs(parent:GetChildren()) do
		if child:IsA("GuiObject") then
			table.insert(guiObjects, child)
		end
		for _, g in ipairs(getAllGuiObjects(child)) do
			table.insert(guiObjects, g)
		end
	end
	return guiObjects
end

if UI.Equalizer then
	UI.EqualizerBars = getAllGuiObjects(UI.Equalizer)
end

-- ═══════════════════════════════════════════════════════
-- ESTADO
-- ═══════════════════════════════════════════════════════
local SongHolder = nil
local displayedSongId = nil
local metadataCache = {}
local loudnessValue = 0
local loudnessAlpha = 0.18
local loudnessSensitivity = 1.6

-- FIX 1: Tabla para guardar conexiones activas y poder desconectarlas
local activeConnections = {}

-- FIX 2: Control para evitar llamadas concurrentes a GetProductInfo
local metadataInFlight = {} -- assetId -> true mientras se está fetching

-- Pre-calcular datos de barras
local barCount = #UI.EqualizerBars
local barHues = {}
local barCurrentHeights = {}
local barTargetHeights = {}
local barJitter = {}
local barXScale = {}

for i = 1, barCount do
	barHues[i] = (i - 1) / math.max(barCount, 1)
	barCurrentHeights[i] = 0.08
	barTargetHeights[i] = 0.08
	barJitter[i] = (i % 3) * 0.03
	if UI.EqualizerBars[i] then
		barXScale[i] = UI.EqualizerBars[i].Size.X.Scale
	else
		barXScale[i] = 0
	end
end

-- ═══════════════════════════════════════════════════════
-- HELPERS
-- ═══════════════════════════════════════════════════════
local function formatTime(s)
	if not s or s ~= s or s < 0 then return "0:00" end
	return sformat("%d:%02d", mfloor(s / 60), mfloor(s % 60))
end

local function getAssetId(soundId)
	if not soundId or soundId == "" then return nil end
	return soundId:match("rbxassetid://(%d+)")
end

local function showText(title, artist)
	if UI.SongTitle then UI.SongTitle.Text = title or "Sin música" end
	if UI.Artist then UI.Artist.Text = artist or "" end
end

local function showNoMusic()
	displayedSongId = nil
	showText("Sin música", "Esperando...")
	if UI.TimeDisplay then UI.TimeDisplay.Text = "0:00 / 0:00" end
	if UI.ProgressFill then UI.ProgressFill.Size = UDim2.fromScale(0, 1) end
end

-- FIX 2: getMetadata ahora es no-bloqueante para la UI
-- Muestra un placeholder inmediato y actualiza async cuando llega la info
local function getMetadataCached(sound, assetId)
	-- Prioridad 1: Atributos del Sound (instantáneo)
	if sound then
		local attrName = sound:GetAttribute("SongName")
		local attrArtist = sound:GetAttribute("SongArtist")
		if attrName and attrName ~= "" then
			return attrName, attrArtist or "Desconocido", true -- true = final
		end
	end

	-- Prioridad 2: Cache local (instantáneo)
	if assetId and metadataCache[assetId] then
		local cached = metadataCache[assetId]
		return cached.name, cached.artist, true
	end

	-- Prioridad 3: No hay data aún, retornar placeholder
	return assetId and ("Audio " .. assetId) or "Sin música", "Cargando...", false
end

local function fetchMetadataAsync(assetId, callback)
	if not assetId then return end
	if metadataCache[assetId] then
		callback(metadataCache[assetId].name, metadataCache[assetId].artist)
		return
	end

	-- FIX: Evitar múltiples llamadas simultáneas al mismo assetId
	if metadataInFlight[assetId] then return end
	metadataInFlight[assetId] = true

	task.spawn(function()
		local success, info = pcall(function()
			return MarketplaceService:GetProductInfo(tonumber(assetId), Enum.InfoType.Asset)
		end)

		metadataInFlight[assetId] = nil

		if success and info then
			local name = info.Name or ("Audio " .. assetId)
			local artist = (info.Creator and info.Creator.Name) or "Desconocido"
			metadataCache[assetId] = { name = name, artist = artist }
			callback(name, artist)
		end
	end)
end

-- FIX 1: Limpiar conexiones anteriores antes de crear nuevas
local function disconnectAll()
	for _, conn in ipairs(activeConnections) do
		if conn and conn.Connected then
			conn:Disconnect()
		end
	end
	activeConnections = {}
end

local function updateSongInfo()
	if not SongHolder then showNoMusic() return end
	local soundId = ""
	pcall(function() soundId = SongHolder.SoundId end)
	if soundId == "" then showNoMusic() return end

	local assetId = getAssetId(soundId)
	if not assetId then showNoMusic() return end
	if assetId == displayedSongId then return end

	if UI.ProgressFill then UI.ProgressFill.Size = UDim2.fromScale(0, 1) end
	if UI.TimeDisplay then UI.TimeDisplay.Text = "0:00 / 0:00" end

	-- Mostrar info inmediata (cache o placeholder)
	local name, artist, isFinal = getMetadataCached(SongHolder, assetId)
	showText(name, artist)
	displayedSongId = assetId

	-- Si no es final, buscar async y actualizar cuando llegue
	if not isFinal then
		local capturedAssetId = assetId
		fetchMetadataAsync(assetId, function(fetchedName, fetchedArtist)
			-- Solo actualizar si seguimos mostrando la misma canción
			if displayedSongId == capturedAssetId then
				showText(fetchedName, fetchedArtist)
			end
		end)
	end
end

local function connectToSound(sound)
	-- FIX 1: Limpiar conexiones del sound anterior
	disconnectAll()

	SongHolder = sound
	displayedSongId = nil

	if not sound then
		showNoMusic()
		return
	end

	-- Guardar conexiones para poder limpiarlas después
	local conn1 = sound:GetPropertyChangedSignal("SoundId"):Connect(function()
		task.delay(0.05, updateSongInfo)
	end)
	table.insert(activeConnections, conn1)

	local conn2 = sound:GetAttributeChangedSignal("SongName"):Connect(function()
		updateSongInfo()
	end)
	table.insert(activeConnections, conn2)

	-- FIX 4: Detectar si el sound se destruye mientras lo usamos
	local conn3 = sound.Destroying:Connect(function()
		if SongHolder == sound then
			disconnectAll()
			SongHolder = nil
			showNoMusic()
		end
	end)
	table.insert(activeConnections, conn3)

	updateSongInfo()
end

-- ═══════════════════════════════════════════════════════
-- BUSCAR SOUND CON EVENTOS
-- ═══════════════════════════════════════════════════════
local function onQueueSoundAdded(child)
	if child.Name == "QueueSound" and child:IsA("Sound") then
		if SongHolder ~= child then
			connectToSound(child)
		end
	end
end

local function onQueueSoundRemoved(child)
	if child == SongHolder then
		connectToSound(nil)
	end
end

Workspace.ChildAdded:Connect(onQueueSoundAdded)
Workspace.ChildRemoved:Connect(onQueueSoundRemoved)

-- FIX 4: Check inicial más robusto con retry
local existingSound = Workspace:FindFirstChild("QueueSound")
if existingSound and existingSound:IsA("Sound") then
	connectToSound(existingSound)
else
	-- Si no existe aún, esperar un momento y reintentar UNA vez
	-- (cubre el caso donde el sound se crea durante el load del script)
	task.delay(1, function()
		if not SongHolder then
			local retrySound = Workspace:FindFirstChild("QueueSound")
			if retrySound and retrySound:IsA("Sound") then
				connectToSound(retrySound)
			end
		end
	end)
end

-- ═══════════════════════════════════════════════════════
-- LOOP PRINCIPAL UNIFICADO
-- ═══════════════════════════════════════════════════════

local progressAccum = 0
local PROGRESS_INTERVAL = 0.15

-- Glow state
local glowTweenExpand, glowTweenShrink
local glowLastTick = 0
local glowExpanding = false

if UI.Glow then
	glowTweenExpand = TweenService:Create(UI.Glow, TweenInfo.new(0.6, Enum.EasingStyle.Sine), {ImageTransparency = 0.1, Size = UDim2.fromOffset(60, 60)})
	glowTweenShrink = TweenService:Create(UI.Glow, TweenInfo.new(0.6, Enum.EasingStyle.Sine), {ImageTransparency = 0.4, Size = UDim2.fromOffset(40, 40)})
end

-- Separator gradient state
local separatorGradient = nil
local separatorOffset = 0
if UI.SeparatorLine then
	separatorGradient = UI.SeparatorLine:FindFirstChild("UIGradient")
end

RunService.RenderStepped:Connect(function(dt)
	local playing = false
	local dur, pos = 0, 0

	if SongHolder then
		local ok, _playing, _dur, _pos, _loudness = pcall(function()
			return SongHolder.Playing, SongHolder.TimeLength, SongHolder.TimePosition, SongHolder.PlaybackLoudness
		end)
		if ok then
			playing = _playing
			dur = _dur
			pos = _pos
			if playing and type(_loudness) == "number" then
				local scaled = mclamp(_loudness * loudnessSensitivity / 100, 0, 1)
				loudnessValue = loudnessValue * (1 - loudnessAlpha) + scaled * loudnessAlpha
			end
		end
	end

	-- ── PROGRESO Y TIEMPO (throttled) ──
	progressAccum = progressAccum + dt
	if progressAccum >= PROGRESS_INTERVAL then
		progressAccum = 0
		if dur > 0 then
			if UI.TimeDisplay then UI.TimeDisplay.Text = formatTime(pos) .. " / " .. formatTime(dur) end
			if UI.ProgressFill then UI.ProgressFill.Size = UDim2.fromScale(mclamp(pos / dur, 0, 1), 1) end
		end
	end

	-- ── EQUALIZER ──
	if barCount > 0 then
		local hueStep = dt * 0.6
		for i = 1, barCount do
			barHues[i] = (barHues[i] + hueStep) % 1
			UI.EqualizerBars[i].BackgroundColor3 = Color3.fromHSV(barHues[i], 1, 1)
		end

		if playing then
			local base = 0.12
			local intensity = base + (loudnessValue * 0.88)
			for i = 1, barCount do
				local randomFactor = 0.6 + mrandom() * 0.4
				barTargetHeights[i] = mclamp(base + randomFactor * intensity + barJitter[i], 0.08, 1)
			end
		else
			-- FIX 3: Decay independiente del framerate usando dt
			local decayFactor = math.exp(-5 * dt) -- equivale a ~0.9 a 60fps pero se adapta
			loudnessValue = loudnessValue * decayFactor
			for i = 1, barCount do
				barTargetHeights[i] = 0.08
			end
		end

		local speed = playing and 18 or 9
		local alpha = mmin(1, dt * speed)
		for i = 1, barCount do
			local curr = barCurrentHeights[i]
			local target = barTargetHeights[i]
			if math.abs(target - curr) > 0.001 then
				curr = curr + (target - curr) * alpha
				barCurrentHeights[i] = curr
				UI.EqualizerBars[i].Size = UDim2.fromScale(barXScale[i], curr)
			end
		end
	end

	-- ── SEPARATOR RAINBOW ──
	if separatorGradient then
		separatorOffset = (separatorOffset + dt * 0.6) % 1
		separatorGradient.Offset = Vector2.new(separatorOffset, 0)
	end

	-- ── GLOW ──
	if UI.Glow and playing then
		local now = tick()
		if now - glowLastTick >= 0.6 then
			glowLastTick = now
			glowExpanding = not glowExpanding
			if glowExpanding then glowTweenExpand:Play() else glowTweenShrink:Play() end
		end
	end
end)

-- ═══════════════════════════════════════════════════════
-- START
-- ═══════════════════════════════════════════════════════
showNoMusic()