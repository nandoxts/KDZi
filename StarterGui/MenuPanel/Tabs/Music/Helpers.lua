-- Music/Helpers.lua — Utilidades compartidas (delega a Core/UI donde puede)
local TweenService = game:GetService("TweenService")
local UI = require(game:GetService("ReplicatedStorage"):WaitForChild("Core"):WaitForChild("UI"))

local Helpers = {}

-- Delegados de UI global
Helpers.rounded = UI.rounded       -- (inst, px)
Helpers.stroked = UI.stroked       -- (inst, alpha, color)
Helpers.hover   = UI.hover         -- (btn, normalColor, hoverColor)
Helpers.brighten = UI.brighten     -- (color, factor)

-- Genérico — UI.lua no tiene create genérico, se mantiene acá
function Helpers.make(class, props)
	local i = Instance.new(class)
	for k, v in pairs(props) do
		if k ~= "Parent" then i[k] = v end
	end
	if props.Parent then i.Parent = props.Parent end
	return i
end

-- Tween rápido — UI.lua no expone un tween genérico
function Helpers.tween(obj, t, props)
	TweenService:Create(obj, TweenInfo.new(t, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), props):Play()
end

-- Funciones específicas de música
function Helpers.formatTime(s)
	return string.format("%d:%02d", math.floor(s / 60), math.floor(s % 60))
end

function Helpers.isInQueue(queue, id)
	for _, s in ipairs(queue) do
		if s.id == id then return true end
	end
	return false
end

-- Referencia directa a UI por si los módulos necesitan más
Helpers.UI = UI

return Helpers
