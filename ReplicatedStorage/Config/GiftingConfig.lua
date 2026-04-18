--[[
GiftingConfig.lua — Genera listas de items regalables
desde Configuration.Gamepasses y TitleConfig.
No necesitas editar este archivo cuando agregas gamepasses o títulos.
]]

local Configuration = require(script.Parent.Configuration)
local TitleConfig   = require(script.Parent.TitleConfig)

-- ══════════════════════════════════════════════════════════════
--  GAMEPASSES  →  { gamepassId, devProductId }
--  Se construye automáticamente desde Configuration.Gamepasses
-- ══════════════════════════════════════════════════════════════
local gamepasses = {}
for _, gpData in pairs(Configuration.Gamepasses) do
	if gpData.id and gpData.devId and gpData.devId ~= 0 then
		table.insert(gamepasses, { gpData.id, gpData.devId })
	end
end

-- ══════════════════════════════════════════════════════════════
--  EXPORT
-- ══════════════════════════════════════════════════════════════
return {
	Gamepasses = gamepasses,
	Titles     = {},
}
