-- ════════════════════════════════════════════════════════════════
-- THEME v8.0 — FULL BLACK · SIN ALIASES
-- by ignxts
-- ════════════════════════════════════════════════════════════════

local THEME = {
	-- ═══ FONDOS (3 niveles + subtle) ═══
	bg       = Color3.fromRGB(6,   6,   6),   -- fondo base
	card     = Color3.fromRGB(18,  18,  18),   -- tarjetas, contenedores
	elevated = Color3.fromRGB(32,  32,  32),   -- hover, items activos
	subtle   = Color3.fromRGB(55,  55,  55),   -- bordes suaves, placeholders

	-- ═══ TEXTO (3 niveles) ═══
	text     = Color3.fromRGB(255, 255, 255),  -- blanco puro
	dim      = Color3.fromRGB(160, 160, 160),  -- texto suave
	muted    = Color3.fromRGB(90,  90,  90),   -- texto apagado

	-- ═══ BORDE ═══
	stroke   = Color3.fromRGB(38,  38,  38),

	-- ═══ ACENTO ═══
	accent   = Color3.fromRGB(255, 208, 0),   -- naranja (progreso, highlights)

	-- ═══ ESTADOS ═══
	danger   = Color3.fromRGB(220, 50,  50),
	success  = Color3.fromRGB(0, 211, 53),
	warn     = Color3.fromRGB(255, 170, 50),

	-- ═══ ALPHA ═══
	overlayAlpha = 0.6,
	frameAlpha   = 0.06,
	lightAlpha   = 0.2,
	mediumAlpha  = 0.5,
	subtleAlpha  = 0.85,

	-- ═══ LAYOUT ═══
	panelWidth  = 390,
	panelHeight = 500,
}

return THEME