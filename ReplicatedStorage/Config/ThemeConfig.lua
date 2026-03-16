-- ════════════════════════════════════════════════════════════════
-- THEME CONFIGURATION v2.0 - CYAN & NEON PURPLE
-- Paleta cyan / morado neón
-- by ignxts
-- ════════════════════════════════════════════════════════════════

local THEME = {
	-- Modern dark background palette (Neutro oscuro, sin tinte morado)
	bg       = Color3.fromRGB(18, 18, 21),      -- Fondo principal / profundo
	card     = Color3.fromRGB(28, 28, 32),      -- Cards / paneles
	surface  = Color3.fromRGB(30, 30, 35),      -- Superficies interactivas
	elevated = Color3.fromRGB(35, 35, 40),      -- Elementos elevados (hover)

	-- Text colors
	text     = Color3.fromRGB(236, 240, 241),   -- Texto principal (casi blanco)
	muted    = Color3.fromRGB(132, 142, 151),   -- Texto secundario
	subtle   = Color3.fromRGB(95, 100, 110),    -- Texto muy sutil
	dim      = Color3.fromRGB(95, 100, 110),    -- Alias de subtle (iconos/texto apagado)

	-- Accent (cyan + neon purple)
	accent      = Color3.fromRGB(0, 230, 255),    -- Cyan neón
	accentHover = Color3.fromRGB(180, 0, 255),    -- Morado neón (hover)

	-- Buttons
	warn       = Color3.fromRGB(251, 140, 0),    -- Orange suave
	warnMuted  = Color3.fromRGB(88, 56, 20),     -- Orange muted más oscuro
	btnDanger  = Color3.fromRGB(229, 57, 53),    -- Rojo profundo
	success    = Color3.fromRGB(76, 175, 80),    -- Verde suave (Spotify-like)

	-- UI elements
	stroke = Color3.fromRGB(40, 44, 52),
	hover  = Color3.fromRGB(45, 50, 58),

	-- Transparencies
	subtleAlpha = 0.1,  -- Muy poco transparente
	lightAlpha  = 0.3,  -- Ligeramente transparente
	frameAlpha  = 0.4,  -- Frames principales
	mediumAlpha = 0.6,  -- Medio transparente

	-- Panel sizes
	panelWidth  = 780,
	panelHeight = 650,
}

return THEME