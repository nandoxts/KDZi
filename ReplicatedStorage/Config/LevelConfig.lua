local LevelConfigModule = {}

LevelConfigModule.LEVEL_CONFIG = {
	{
		MinLevel = 10000,
		Emoji = "💀",
		Color = Color3.fromRGB(20, 20, 20),        -- Negro casi puro: rango mítico
	},
	{
		MinLevel = 1000,
		MaxLevel = 9999,
		Emoji = "😈",
		Color = Color3.fromRGB(138, 0, 255),        -- Violeta profundo: corrupto/demoníaco
	},
	{
		MinLevel = 901,
		MaxLevel = 999,
		Emoji = "🏆",
		Color = Color3.fromRGB(255, 215, 0),        -- Dorado brillante: campeón
	},
	{
		MinLevel = 801,
		MaxLevel = 900,
		Emoji = "🌙",
		Color = Color3.fromRGB(160, 32, 240),       -- Púrpura real: élite nocturna
	},
	{
		MinLevel = 701,
		MaxLevel = 800,
		Emoji = "⚡",
		Color = Color3.fromRGB(255, 230, 0),        -- Amarillo eléctrico: energía pura
	},
	{
		MinLevel = 601,
		MaxLevel = 700,
		Emoji = "🔥",
		Color = Color3.fromRGB(255, 80, 0),         -- Naranja fuego: llamas intensas
	},
	{
		MinLevel = 501,
		MaxLevel = 600,
		Emoji = "🦄",
		Color = Color3.fromRGB(255, 0, 180),        -- Magenta vibrante: único/raro
	},
	{
		MinLevel = 401,
		MaxLevel = 500,
		Emoji = "🚀",
		Color = Color3.fromRGB(0, 200, 255),        -- Cian espacial: velocidad
	},
	{
		MinLevel = 301,
		MaxLevel = 400,
		Emoji = "👑",
		Color = Color3.fromRGB(50, 220, 50),        -- Verde esmeralda: realeza natural
	},
	{
		MinLevel = 201,
		MaxLevel = 300,
		Emoji = "🐉",
		Color = Color3.fromRGB(220, 50, 50),        -- Rojo dragón: poder y peligro
	},
	{
		MinLevel = 101,
		MaxLevel = 200,
		Emoji = "🌊",
		Color = Color3.fromRGB(30, 120, 255),       -- Azul océano: progreso sólido
	},
	{
		MinLevel = 1,
		MaxLevel = 100,
		Emoji = "🌱",
		Color = Color3.fromRGB(160, 160, 160),      -- Gris: principiante
	}
}

-- Función para obtener configuración de nivel
function LevelConfigModule.getLevelConfig(level)
	for _, config in ipairs(LevelConfigModule.LEVEL_CONFIG) do
		if config.MinLevel and config.MaxLevel then
			if level >= config.MinLevel and level <= config.MaxLevel then
				return config
			end
		elseif config.MinLevel and not config.MaxLevel then
			if level >= config.MinLevel then
				return config
			end
		end
	end
	return LevelConfigModule.LEVEL_CONFIG[#LevelConfigModule.LEVEL_CONFIG] -- Default al último nivel
end

return LevelConfigModule