-- ════════════════════════════════════════════════════════════════
-- TOPBAR CONTROLLER - LocalScript en StarterPlayerScripts
-- Usando SoundGroup para mute LOCAL sin entrecortes
-- ════════════════════════════════════════════════════════════════

local Icon = require(game:GetService("ReplicatedStorage").Icon)
local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Esperar a que se carguen las GUIs de sistema
task.wait(1)

-- ════════════════════════════════════════════════════════════════
-- MÓDULOS
-- ════════════════════════════════════════════════════════════════
local GlobalModalManager = require(game:GetService("ReplicatedStorage"):WaitForChild("Systems"):WaitForChild("GlobalModalManager"))

-- ════════════════════════════════════════════════════════════════
-- SERVICIOS
-- ════════════════════════════════════════════════════════════════
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")

-- ════════════════════════════════════════════════════════════════
-- CONFIGURACIÓN DE ANIMACIONES
-- ════════════════════════════════════════════════════════════════
local Info = TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, 0, false, 0)

-- Crear efecto de desenfoque
local Blur = Instance.new('BlurEffect')
Blur.Parent = game.Lighting
Blur.Size = 0

-- Configuración de la cámara
local Camera = game.Workspace.CurrentCamera
local FOV = Camera.FieldOfView

-- Debounce para las GUIs
local guiDebounce = false

-- ════════════════════════════════════════════════════════════════
-- FUNCIONES DE GUI
-- ════════════════════════════════════════════════════════════════

local function openGUIAnimation()
	TweenService:Create(Blur, Info, {Size = 15}):Play()
	TweenService:Create(Camera, Info, {FieldOfView = FOV - 10}):Play()
end

local function closeGUIAnimation()
	TweenService:Create(Blur, Info, {Size = 0}):Play()
	TweenService:Create(Camera, Info, {FieldOfView = FOV}):Play()
end

-- ════════════════════════════════════════════════════════════════
-- ICONOS DEL TOPBAR
-- ════════════════════════════════════════════════════════════════

-- ════════════════════════════════════════════════════════════════
-- ICONO: EMOTES
-- ════════════════════════════════════════════════════════════════
_G.EmotesIcon = Icon.new()
	:setOrder(2)
	:setImage("127784597936941")
	:autoDeselect(false)

_G.EmotesIcon:bindEvent("selected", function(icon)
	GlobalModalManager:openModal("Emotes")
end)

_G.EmotesIcon:bindEvent("deselected", function(icon)
	GlobalModalManager:closeModal("Emotes")
end)

-- ════════════════════════════════════════════════════════════════
-- ICONO: MENÚ (abre panel lateral unificado)
-- ════════════════════════════════════════════════════════════════
_G.MenuIcon = Icon.new()
	:setLabel("MENU")
	:setName("Menu")
	:setCaption("Abrir Menu")
	:align("Right")
	:autoDeselect(false)

_G.MenuIcon:bindEvent("selected", function()
	GlobalModalManager:openModal("Menu")
end)

_G.MenuIcon:bindEvent("deselected", function()
	GlobalModalManager:closeModal("Menu")
end)

-- ════════════════════════════════════════════════════════════════
-- FIN DEL SCRIPT
-- ════════════════════════════════════════════════════════════════