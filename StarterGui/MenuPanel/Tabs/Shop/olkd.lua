
local Shop = {}

function Shop.build(parent, THEME, sharedState)
    local Players            = game:GetService("Players")
    local ReplicatedStorage  = game:GetService("ReplicatedStorage")
    local TweenService       = game:GetService("TweenService")
    local MarketplaceService = game:GetService("MarketplaceService")

    local player = Players.LocalPlayer

    local Configuration = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("Configuration"))
    local ModernScrollbar = require(ReplicatedStorage:WaitForChild("UIComponents"):WaitForChild("ModernScrollbar"))

    local TW = TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    local ROBUX_CHAR = utf8.char(0xE002)

    -- Colores del gradiente lateral por card (toque de color unico)
    local GRAD_COLORS = {
        Color3.fromRGB(90,  40, 140),  -- VIP:        morado
        Color3.fromRGB(40,  80, 160),  -- COMANDOS:   azul
        Color3.fromRGB(50, 130,  80),  -- COLORES:    verde
        Color3.fromRGB(30,  80, 160),  -- POLICIA:    azul oscuro
        Color3.fromRGB(160, 50,  50),  -- LADRON:     rojo
        Color3.fromRGB(60, 100, 160),  -- SEGURIDAD:  azul gris
        Color3.fromRGB(180, 90,  20),  -- ARMY BOOMS: naranja
        Color3.fromRGB(20, 140, 160),  -- LIGHTSTICK: cyan
        Color3.fromRGB(120, 40, 180),  -- AURA PACK:  violeta
    }

    local GAMEPASSES = {
        { name = "VIP",        price = 200,  gid = Configuration.Gamepasses.VIP.id,        icon = "76721656269888",
            desc = "[ + ] Acceso VIP exclusivo!\n[ + ] Las mejores vistas y zonas!\n[ + ] Etiqueta VIP!" },
        { name = "COMANDOS",   price = 1500, gid = Configuration.Gamepasses.COMMANDS.id,   icon = "128637341143304",
            desc = "[ + ] Acceso ilimitado a una\nemocionante variedad de\ncomandos de chat!" },
        { name = "COLORES",    price = 50,   gid = Configuration.Gamepasses.COLORS.id,     icon = "91877799240345",
            desc = "[ + ] Personaliza tu nombre!\n[ + ] Usa ;cl [color] en el chat!\n[ + ] Múltiples colores!" },
        { name = "POLICIA",    price = 135,  gid = Configuration.Gamepasses.TOMBO.id,      icon = "139661313218787",
            desc = "[ + ] Traje de policía!\n[ + ] Usa ;tombo en el chat!\n[ + ] Look exclusivo!" },
        { name = "LADRON",     price = 135,  gid = Configuration.Gamepasses.CHORO.id,      icon = "84699864716808",
            desc = "[ + ] Traje de ladrón!\n[ + ] Usa ;choro en el chat!\n[ + ] Look exclusivo!" },
        { name = "SEGURIDAD",  price = 135,  gid = Configuration.Gamepasses.SERE.id,       icon = "85734290151599",
            desc = "[ + ] Traje de seguridad!\n[ + ] Usa ;sere en el chat!\n[ + ] Look exclusivo!" },
        { name = "ARMY BOOMS", price = 80,   gid = Configuration.Gamepasses.ARMYBOOMS.id,  icon = "134501492548324",
            desc = "[ + ] Efectos Army Booms!\n[ + ] Actívalo en el chat!\n[ + ] Efecto exclusivo!" },
        { name = "LIGHTSTICK", price = 80,   gid = Configuration.Gamepasses.LIGHTSTICK.id, icon = "86122436659328",
            desc = "[ + ] ¡Lightstick brillante!\n[ + ] Actívalo en el chat!\n[ + ] Efecto exclusivo!" },
        { name = "AURA PACK",  price = 2500, gid = Configuration.Gamepasses.AURA_PACK.id,  icon = "129517460766852",
            desc = "[ + ] Pack de 6 auras únicas!\n[ + ] Dragon, Atomic, Blazing...\n[ + ] Usa ;aura [nombre]!" },
    }

    -- Ownership cache
    local gpCache = {}
    local ownershipRemote = nil
    pcall(function()
        ownershipRemote = ReplicatedStorage
            :WaitForChild("RemotesGlobal", 5)
            :WaitForChild("Gamepass Gifting")
            :WaitForChild("Remotes")
            :WaitForChild("Ownership")
    end)

    local function fetchOwnership(gid, cb)
        if gpCache[gid] ~= nil then cb(gpCache[gid]); return end
        task.spawn(function()
            local owned = false
            if ownershipRemote then
                local ok, res = pcall(function() return ownershipRemote:InvokeServer(gid) end)
                owned = ok and res or false
            else
                local ok, res = pcall(function()
                    return MarketplaceService:UserOwnsGamePassAsync(player.UserId, gid)
                end)
                owned = ok and res or false
            end
            gpCache[gid] = owned
            cb(owned)
        end)
    end

    -- Scroll
    local scroll = Instance.new("ScrollingFrame")
    scroll.Size                   = UDim2.fromScale(1, 1)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel        = 0
    scroll.ScrollBarThickness     = 0
    scroll.CanvasSize             = UDim2.new(0, 0, 0, 0)
    scroll.AutomaticCanvasSize    = Enum.AutomaticSize.Y
    scroll.ClipsDescendants       = true
    scroll.ZIndex                 = 204
    scroll.Parent                 = parent
    ModernScrollbar.setup(scroll, parent, THEME, {transparency = 0.4, offset = -4, zIndex = 220})

    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding             = UDim.new(0, 0)
    listLayout.SortOrder           = Enum.SortOrder.LayoutOrder
    listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    listLayout.Parent              = scroll

    local sPad = Instance.new("UIPadding")
    sPad.PaddingLeft   = UDim.new(0, 0)
    sPad.PaddingRight  = UDim.new(0, 0)
    sPad.PaddingTop    = UDim.new(0, 0)
    sPad.PaddingBottom = UDim.new(0, 0)
    sPad.Parent        = scroll

    sharedState.shopCards = sharedState.shopCards or {}

    for i, gp in ipairs(GAMEPASSES) do
        local gradColor = GRAD_COLORS[i] or Color3.fromRGB(60, 40, 120)

        -- Card (sin stroke, sin accent bar)
        local card = Instance.new("CanvasGroup")
        card.Name                   = "Card_" .. i
        card.Size                   = UDim2.new(1, 0, 0, 0)
        card.AutomaticSize          = Enum.AutomaticSize.Y
        card.BackgroundColor3       = THEME.card
        card.BackgroundTransparency = 0
        card.BorderSizePixel        = 0
        card.ZIndex                 = 205
        card.LayoutOrder            = i
        card.Parent                 = scroll

        -- Linea separadora inferior (1px)
        local sep = Instance.new("Frame")
        sep.Size = UDim2.new(1, 0, 0, 1)
        sep.Position = UDim2.new(0, 0, 1, -1)
        sep.BackgroundColor3 = THEME.stroke
        sep.BackgroundTransparency = 0.5
        sep.BorderSizePixel = 0
        sep.ZIndex = 215
        sep.Parent = card

        -- Gradiente lateral (cubre ~35% izquierdo, se desvanece a transparente)
        local gradOverlay = Instance.new("Frame")
        gradOverlay.Size = UDim2.new(0.45, 0, 1, 0)
        gradOverlay.Position = UDim2.fromScale(0, 0)
        gradOverlay.BackgroundColor3 = gradColor
        gradOverlay.BackgroundTransparency = 0
        gradOverlay.BorderSizePixel = 0
        gradOverlay.ZIndex = 206
        gradOverlay.Parent = card
        local gd = Instance.new("UIGradient")
        gd.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.55),
            NumberSequenceKeypoint.new(0.6, 0.85),
            NumberSequenceKeypoint.new(1, 1),
        })
        gd.Rotation = 0
        gd.Parent = gradOverlay

        -- Padding interno del contenido
        local content = Instance.new("Frame")
        content.Size = UDim2.new(1, 0, 0, 0)
        content.AutomaticSize = Enum.AutomaticSize.Y
        content.BackgroundTransparency = 1
        content.ZIndex = 210
        content.Parent = card
        local cPad = Instance.new("UIPadding")
        cPad.PaddingLeft = UDim.new(0, 14); cPad.PaddingRight = UDim.new(0, 12)
        cPad.PaddingTop = UDim.new(0, 14); cPad.PaddingBottom = UDim.new(0, 14)
        cPad.Parent = content

        local innerLay = Instance.new("UIListLayout")
        innerLay.Padding = UDim.new(0, 10)
        innerLay.SortOrder = Enum.SortOrder.LayoutOrder
        innerLay.Parent = content

        -- ═══ Top row: avatar + title + desc ═══
        local topRow = Instance.new("Frame")
        topRow.Size = UDim2.new(1, 0, 0, 76)
        topRow.BackgroundTransparency = 1
        topRow.ZIndex = 210
        topRow.LayoutOrder = 1
        topRow.Parent = content

        -- Avatar (76x76 circulo)
        local AVATAR_S = 76
        local avatarFrame = Instance.new("Frame")
        avatarFrame.Size = UDim2.new(0, AVATAR_S, 0, AVATAR_S)
        avatarFrame.BackgroundColor3 = THEME.elevated
        avatarFrame.BorderSizePixel = 0
        avatarFrame.ZIndex = 211
        avatarFrame.Parent = topRow
        local aC = Instance.new("UICorner"); aC.CornerRadius = UDim.new(1, 0); aC.Parent = avatarFrame

        local avatarImg = Instance.new("ImageLabel")
        avatarImg.Size = UDim2.fromScale(1, 1)
        avatarImg.BackgroundTransparency = 1
        avatarImg.Image = "rbxassetid://" .. gp.icon
        avatarImg.ScaleType = Enum.ScaleType.Crop
        avatarImg.ZIndex = 212
        avatarImg.Parent = avatarFrame
        local aiC = Instance.new("UICorner"); aiC.CornerRadius = UDim.new(1, 0); aiC.Parent = avatarImg

        -- Title (orange, bold, grande)
        local TEXT_X = AVATAR_S + 12
        local titleLbl = Instance.new("TextLabel")
        titleLbl.Size = UDim2.new(1, -TEXT_X, 0, 28)
        titleLbl.Position = UDim2.new(0, TEXT_X, 0, 0)
        titleLbl.BackgroundTransparency = 1
        titleLbl.Font = Enum.Font.GothamBlack
        titleLbl.TextSize = 20
        titleLbl.TextColor3 = THEME.accent
        titleLbl.TextXAlignment = Enum.TextXAlignment.Left
        titleLbl.TextTruncate = Enum.TextTruncate.AtEnd
        titleLbl.Text = gp.name
        titleLbl.ZIndex = 211
        titleLbl.Parent = topRow

        -- Description
        local descLbl = Instance.new("TextLabel")
        descLbl.Size = UDim2.new(1, -TEXT_X, 0, 0)
        descLbl.Position = UDim2.new(0, TEXT_X, 0, 30)
        descLbl.AutomaticSize = Enum.AutomaticSize.Y
        descLbl.BackgroundTransparency = 1
        descLbl.Font = Enum.Font.Gotham
        descLbl.TextSize = 13
        descLbl.TextColor3 = THEME.dim
        descLbl.TextXAlignment = Enum.TextXAlignment.Left
        descLbl.TextWrapped = true
        descLbl.RichText = true
        descLbl.Text = gp.desc or ""
        descLbl.ZIndex = 211
        descLbl.Parent = topRow

        -- Ajustar topRow al contenido
        task.defer(function()
            if descLbl.Parent then
                task.wait() -- esperar layout
                local descH = descLbl.TextBounds.Y
                local totalH = math.max(AVATAR_S, 30 + descH + 4)
                topRow.Size = UDim2.new(1, 0, 0, totalH)
            end
        end)

        -- ═══ Bottom row: buy button + gift + discount ═══
        local bottomRow = Instance.new("Frame")
        bottomRow.Size = UDim2.new(1, 0, 0, 44)
        bottomRow.BackgroundTransparency = 1
        bottomRow.ZIndex = 210
        bottomRow.LayoutOrder = 2
        bottomRow.Parent = content

        -- Buy pill
        local buyBtn = Instance.new("TextButton")
        buyBtn.Name = "BuyBtn"
        buyBtn.Size = UDim2.new(0, 170, 0, 40)
        buyBtn.BackgroundColor3 = THEME.elevated
        buyBtn.Font = Enum.Font.GothamBold
        buyBtn.TextSize = 15
        buyBtn.TextColor3 = Color3.new(1, 1, 1)
        buyBtn.Text = ROBUX_CHAR .. " " .. gp.price
        buyBtn.BorderSizePixel = 0
        buyBtn.AutoButtonColor = false
        buyBtn.ZIndex = 212
        buyBtn.Parent = bottomRow
        local bC = Instance.new("UICorner"); bC.CornerRadius = UDim.new(0, 20); bC.Parent = buyBtn

        -- Gift icon y discount eliminados — solo boton de compra

        sharedState.shopCards[gp.gid] = buyBtn
        if _G._MenuPanelShopCards then _G._MenuPanelShopCards[gp.gid] = buyBtn end

        fetchOwnership(gp.gid, function(owned)
            if owned then
                buyBtn.Text = "TIENES"
                buyBtn.BackgroundColor3 = Color3.fromRGB(40, 180, 80)
                buyBtn.TextColor3 = Color3.new(1, 1, 1)
            end
        end)

        -- Hover en el card
        card.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement then
                TweenService:Create(card, TW, {BackgroundColor3 = THEME.elevated}):Play()
            end
        end)
        card.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement then
                TweenService:Create(card, TW, {BackgroundColor3 = THEME.card}):Play()
            end
        end)

        buyBtn.MouseButton1Click:Connect(function()
            if gpCache[gp.gid] then return end
            pcall(function() MarketplaceService:PromptGamePassPurchase(player, gp.gid) end)
        end)
        buyBtn.MouseEnter:Connect(function()
            if not gpCache[gp.gid] then
                TweenService:Create(buyBtn, TW, {BackgroundColor3 = THEME.subtle}):Play()
            end
        end)
        buyBtn.MouseLeave:Connect(function()
            if not gpCache[gp.gid] then
                TweenService:Create(buyBtn, TW, {BackgroundColor3 = THEME.elevated}):Play()
            end
        end)
    end

    -- Purchase callback
    MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(plr, passId, bought)
        if plr ~= player or not bought then return end
        gpCache[passId] = true
        local btn = sharedState.shopCards and sharedState.shopCards[passId]
        if btn and btn.Parent then
            btn.Text = "TIENES"
            btn.BackgroundColor3 = Color3.fromRGB(40, 180, 80)
            btn.TextColor3 = Color3.new(1, 1, 1)
        end
    end)
end

return Shop
