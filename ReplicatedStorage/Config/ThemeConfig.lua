-- ════════════════════════════════════════════════════════════════
-- THEME CONFIGURATION v3.0 - PANEL MENU
-- Paleta negra/blanca minimalista (estilo app móvil de la foto)
-- Fondo: negro profundo · Texto: blanco puro · Acento: blanco
-- by ignxts
-- ════════════════════════════════════════════════════════════════

local THEME = {
	-- Backgrounds: negro profundo, sin tinte
	deep     = Color3.fromRGB(10, 10, 10),      -- Fondo más profundo
	bg       = Color3.fromRGB(18, 18, 18),      -- Fondo principal del panel
	panel    = Color3.fromRGB(22, 22, 22),      -- Tabbar / paneles internos
	head     = Color3.fromRGB(12, 12, 12),      -- Header (más oscuro que bg)
	card     = Color3.fromRGB(28, 28, 28),      -- Cards de canciones/DJs
	elevated = Color3.fromRGB(40, 40, 40),      -- Hover / elementos elevados
	surface  = Color3.fromRGB(32, 32, 32),      -- Superficies interactivas

	-- Text: blanco puro y grises limpios
	text     = Color3.fromRGB(255, 255, 255),   -- Texto principal blanco puro
	muted    = Color3.fromRGB(150, 150, 150),   -- Texto secundario gris
	subtle   = Color3.fromRGB(80,  80,  80),    -- Texto muy sutil

	-- Acento: blanco (tab activo, barras indicadoras, highlights)
	accent      = Color3.fromRGB(255, 255, 255),  -- Blanco puro
	accentHover = Color3.fromRGB(200, 200, 200),  -- Blanco suavizado (hover)

	-- Buttons / estados
	warn       = Color3.fromRGB(251, 140,  0),   -- Naranja
	warnMuted  = Color3.fromRGB(80,  50,  15),   -- Naranja oscuro
	btnDanger  = Color3.fromRGB(211, 47,  47),   -- Rojo
	success    = Color3.fromRGB(200, 200, 200),  -- Blanco/gris (estado activado)

	-- Bordes: muy sutiles sobre negro
	stroke = Color3.fromRGB(48, 48, 48),
	hover  = Color3.fromRGB(55, 55, 55),

	-- Transparencies
	opaqueAlpha    = 0,
	subtleAlpha    = 0.05,
	lightAlpha     = 0.1,
	frameAlpha     = 0.08,
	mediumAlpha    = 0.2,
	heavyAlpha     = 0.5,
	invisibleAlpha = 1,

	-- Panel sizes
	panelWidth  = 780,
	panelHeight = 650,
}

return THEME