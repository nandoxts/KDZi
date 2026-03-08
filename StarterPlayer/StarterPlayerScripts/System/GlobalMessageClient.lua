-- GlobalMessageClient.lua - Handler para mensajes de evento
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")
local StarterGui = game:GetService("StarterGui")

local remotesGlobal = ReplicatedStorage:WaitForChild("RemotesGlobal", 10)
local commandsFolder = remotesGlobal:WaitForChild("Commands", 10)

local EVENT_COLOR = { hex = "#00D4FF", rgb = Color3.fromRGB(0, 212, 255) }

local function displayMessage(message, colorInfo)
	local textChannels = TextChatService:WaitForChild("TextChannels", 5)
	if textChannels then
		local systemChannel = textChannels:FindFirstChild("RBXSystem")
		if systemChannel then
			local coloredMessage = '<font color="' .. colorInfo.hex .. '"><b>' .. message .. '</b></font>'
			systemChannel:DisplaySystemMessage(coloredMessage)
			return
		end
	end

	pcall(function()
		StarterGui:SetCore("ChatMakeSystemMessage", {
			Text = message,
			Color = colorInfo.rgb,
			Font = Enum.Font.GothamBold,
		})
	end)
end

local eventMessageEvent = commandsFolder:WaitForChild("EventMessage", 10)
if eventMessageEvent then
	eventMessageEvent.OnClientEvent:Connect(function(message)
		displayMessage(message, EVENT_COLOR)
	end)
end

