-- ════════════════════════════════════════════════════════════════
-- THEME CONFIGURATION v2.0 - PROFESSIONAL DARK
-- Paleta madura estilo Discord/Spotify
-- by ignxts
-- ════════════════════════════════════════════════════════════════

local THEME = {
	-- Modern dark background palette (Neutro oscuro, sin tinte morado)
	bg       = Color3.fromRGB(0, 0, 0),      -- Fondo principal / profundo
	card     = Color3.fromRGB(20, 20, 20),      -- Cards / paneles
	surface  = Color3.fromRGB(37, 37, 37),      -- Superficies interactivas
	elevated = Color3.fromRGB(37, 37, 37),      -- Elementos elevados (hover)

	-- Text colors
	text     = Color3.fromRGB(236, 240, 241),   -- Texto principal (casi blanco)
	muted    = Color3.fromRGB(132, 142, 151),   -- Texto secundario
	subtle   = Color3.fromRGB(95, 100, 110),    -- Texto muy sutil
	dim      = Color3.fromRGB(95, 100, 110),    -- Alias de subtle (iconos/texto apagado)

	-- Accent (purple)
	accent      = Color3.fromRGB(147, 76, 255),  -- Morado vibrante
	accentHover = Color3.fromRGB(186, 129, 255), -- Hover más claro

	-- Buttons
	warn       = Color3.fromRGB(251, 140, 0),    -- Orange suave
	warnMuted  = Color3.fromRGB(88, 56, 20),     -- Orange muted más oscuro
	btnDanger  = Color3.fromRGB(229, 57, 53),    -- Rojo profundo
	success    = Color3.fromRGB(76, 175, 80),    -- Verde suave (Spotify-like)

	-- UI elements
	stroke = Color3.fromRGB(0, 0, 0),

	-- Transparencies
	subtleAlpha = 0.18, -- Elementos sutiles
	lightAlpha  = 0.3,  -- Ligeramente transparente
	frameAlpha  = 0.72, -- Glass principal (paneles)
	mediumAlpha = 0.6,  -- Medio transparente

	-- Panel sizes
	panelWidth  = 390,
	panelHeight = 500,
}

return THEME