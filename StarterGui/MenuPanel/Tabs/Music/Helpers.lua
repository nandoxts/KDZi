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

-- Iconos modernos compartidos (mismos que MusicDjDashboard)
Helpers.ICONS = {
	PLAY_ADD = "rbxassetid://108828649435041",
	CHECK    = "rbxassetid://102926522001210",
	DELETE   = "rbxassetid://94904012825024",
	LOADING  = "rbxassetid://122161736287488",
	SKIP     = "rbxassetid://125130348287636",
}

-- CanvasGroup helper — recorta hijos respetando UICorner (protección de bordes)
function Helpers.makeCanvas(parent, corner, z)
	local canvas = Instance.new("CanvasGroup")
	canvas.Name = "Canvas"
	canvas.Size = UDim2.new(1, 0, 1, 0)
	canvas.BackgroundTransparency = 1
	canvas.BorderSizePixel = 0
	canvas.GroupTransparency = 0
	canvas.ZIndex = z or 103
	canvas.Parent = parent
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, corner or 10)
	c.Parent = canvas
	return canvas
end

-- Referencia directa a UI por si los módulos necesitan más
Helpers.UI = UI

return Helpers
