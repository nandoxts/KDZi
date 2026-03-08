-- ════════════════════════════════════════════════════════════════
-- THEME CONFIGURATION v6.0 — BLACKOUT ORANGE (SLIM)
-- Solo lo necesario. Negro puro + naranja.
-- by ignxts — mejorado por George Bellota
-- ════════════════════════════════════════════════════════════════

local THEME = {
	-- Backgrounds
	deep         = Color3.fromRGB(0,   0,   0),
	bg           = Color3.fromRGB(8,   8,   8),
	panel        = Color3.fromRGB(14,  14,  14),
	head         = Color3.fromRGB(10,  10,  10),
	card         = Color3.fromRGB(22,  22,  22),
	elevated     = Color3.fromRGB(38,  38,  38),
	surface      = Color3.fromRGB(28,  28,  28),

	-- Pill tabs
	pillActive   = Color3.fromRGB(38,  38,  38),
	pillInactive = Color3.fromRGB(20,  20,  20),

	-- Text
	text         = Color3.fromRGB(255, 255, 255),
	textSoft     = Color3.fromRGB(210, 210, 210),
	muted        = Color3.fromRGB(120, 120, 120),
	subtle       = Color3.fromRGB(65,  65,  65),

	-- Acento naranja
	accent       = Color3.fromRGB(255, 140,  0),
	accentHover  = Color3.fromRGB(255, 165, 40),
	accentMuted  = Color3.fromRGB(80,  45,   0),

	-- Tab
	tabActive    = Color3.fromRGB(255, 140,  0),
	tabInactive  = Color3.fromRGB(120, 120, 120),

	-- Botones / estados
	btnDanger    = Color3.fromRGB(220, 50,  50),
	success      = Color3.fromRGB(50, 200, 120),
	warn         = Color3.fromRGB(255, 170, 50),

	-- Bordes (uso interno de tabs)
	stroke       = Color3.fromRGB(40,  40,  40),

	-- Transparencies
	overlayAlpha = 0.6,
	frameAlpha   = 0.08,

	-- Panel
	panelWidth   = 390,

	-- Radius
	radiusPill   = UDim.new(0, 8),
	radiusMd     = UDim.new(0, 8),

	-- Typography
	fontTitle    = 18,
	fontTab      = 13,
	fontBody     = 14,
	fontSmall    = 12,
}

return THEME