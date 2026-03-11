-- GlobalMessageClient.lua - Universal message handler for all system messages
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")
local StarterGui = game:GetService("StarterGui")

local remotesGlobal = ReplicatedStorage:WaitForChild("RemotesGlobal", 10)
local commandsFolder = remotesGlobal:WaitForChild("Commands", 10)

-- Colores para diferentes tipos de mensajes
local MESSAGE_COLORS = {
	tone     = { hex = "#FFC800", rgb = Color3.fromRGB(255, 200, 0) },      -- Amarillo/Dorado
	event    = { hex = "#00D4FF", rgb = Color3.fromRGB(0, 212, 255) },      -- Azul/Cian
	gift     = { hex = "#FF6EC7", rgb = Color3.fromRGB(255, 110, 199) },    -- Rosa (regalos)
	donation = { hex = "#00FF88", rgb = Color3.fromRGB(0, 255, 136) },      -- Verde (donaciones)
}

local function displayMessage(message, colorInfo)
	-- Intentar con TextChatService (nuevo chat)
	local textChannels = TextChatService:WaitForChild("TextChannels", 5)
	if textChannels then
		local systemChannel = textChannels:FindFirstChild("RBXSystem")
		if systemChannel then
			local coloredMessage = '<font color="' .. colorInfo.hex .. '"><b>' .. message .. '</b></font>'
			systemChannel:DisplaySystemMessage(coloredMessage)
			return
		end
	end

	-- Fallback: chat legacy
	pcall(function()
		StarterGui:SetCore("ChatMakeSystemMessage", {
			Text = message,
			Color = colorInfo.rgb,
			Font = Enum.Font.GothamBold,
		})
	end)
end

-- Handler para ToneMessage
local toneMessageEvent = commandsFolder:WaitForChild("ToneMessage", 10)
if toneMessageEvent then
	toneMessageEvent.OnClientEvent:Connect(function(message)
		displayMessage(message, MESSAGE_COLORS.tone)
	end)
else
	warn("[CLIENT] ToneMessage NO encontrado!")
end

-- Handler para EventMessage (acepta colorType opcional: "event", "gift", "tone", ...)
local eventMessageEvent = commandsFolder:WaitForChild("EventMessage", 10)
if eventMessageEvent then
	eventMessageEvent.OnClientEvent:Connect(function(message, colorType)
		local color = MESSAGE_COLORS[colorType] or MESSAGE_COLORS.event
		displayMessage(message, color)
	end)
else
	warn("[CLIENT] EventMessage NO encontrado!")
end



