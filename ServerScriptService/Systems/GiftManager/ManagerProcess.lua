-- ModuleScript: ManagerProcess (Central Purchase Handler)
-- Centraliza ProcessReceipt para que múltiples sistemas
-- (regalos, donaciones, super likes) puedan registrar handlers.
-- Roblox solo permite UN callback ProcessReceipt.

local MarketplaceService = game:GetService("MarketplaceService")

local CentralPurchaseHandler = {}

local giftHandlers = {}
local donationHandlers = {}
local superlikeHandlers = {}

function CentralPurchaseHandler.registerGiftHandler(handler)
	table.insert(giftHandlers, handler)
end

function CentralPurchaseHandler.registerDonationHandler(handler)
	table.insert(donationHandlers, handler)
end

function CentralPurchaseHandler.registerSuperLikeHandler(handler)
	table.insert(superlikeHandlers, handler)
end

MarketplaceService.ProcessReceipt = function(receiptInfo)
	for _, handler in ipairs(giftHandlers) do
		local result = handler(receiptInfo)
		if result ~= Enum.ProductPurchaseDecision.NotProcessedYet then
			return result
		end
	end

	for _, handler in ipairs(donationHandlers) do
		local result = handler(receiptInfo)
		if result ~= Enum.ProductPurchaseDecision.NotProcessedYet then
			return result
		end
	end

	for _, handler in ipairs(superlikeHandlers) do
		local result = handler(receiptInfo)
		if result ~= Enum.ProductPurchaseDecision.NotProcessedYet then
			return result
		end
	end

	return Enum.ProductPurchaseDecision.NotProcessedYet
end

return CentralPurchaseHandler
