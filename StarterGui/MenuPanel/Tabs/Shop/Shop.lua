--[[
	Shop/Shop.lua — Tab de TIENDA para el MenuPanel v2.0
	Sistema de tabs internas: GAME PASS | TITLES
	Permite regalar gamepasses y títulos a otros jugadores
	
	Diseño similar a Music con SubTabs
]]

local Shop = {}

function Shop.build(parent, THEME, sharedState)
	local Players            = game:GetService("Players")
	local ReplicatedStorage  = game:GetService("ReplicatedStorage")
	local TweenService       = game:GetService("TweenService")
	local MarketplaceService = game:GetService("MarketplaceService")

	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")

	-- Módulos
	local SubTabs = require(ReplicatedStorage:WaitForChild("UIComponents"):WaitForChild("SubTabs"))
	local GamepassTab = require(script.Parent:WaitForChild("GamepassTab"))
	local TitlesTab = require(script.Parent:WaitForChild("TitlesTab"))

	local SUB_TAB_H = 38

	-- Estado compartido para las tabs
	local state = {
		subTabH = SUB_TAB_H,
	}

	-- ScreenGui para modales (necesario para ConfirmationModal)
	local screenGui = playerGui:FindFirstChild("MenuPanelUI") or playerGui

	-- ══════════════════════════════════════════════════════════════
	-- SUB-TAB BAR
	-- ══════════════════════════════════════════════════════════════
	local subTabs = SubTabs.new(parent, THEME, {
		tabs = {
			{ id = "gamepass", label = "GAME PASS" },
			{ id = "titles", label = "TITLES" }
		},
		height = SUB_TAB_H,
		default = "gamepass",
		z = 215,
	})

	-- ══════════════════════════════════════════════════════════════
	-- BUILD TABS
	-- ══════════════════════════════════════════════════════════════
	local gamepassResult = GamepassTab.build(parent, THEME, state, screenGui)
	local titlesResult = TitlesTab.build(parent, THEME, state, screenGui)

	subTabs:register("gamepass", gamepassResult.panel)
	subTabs:register("titles", titlesResult.panel)

	-- ══════════════════════════════════════════════════════════════
	-- LIFECYCLE
	-- ══════════════════════════════════════════════════════════════
	local function onClose()
		if gamepassResult.cleanup then gamepassResult.cleanup() end
		if titlesResult.cleanup then titlesResult.cleanup() end
	end

	return { onOpen = function() end, onClose = onClose }
end

return Shop
