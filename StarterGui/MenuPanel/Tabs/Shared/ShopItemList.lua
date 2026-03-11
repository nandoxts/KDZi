--[[
═══════════════════════════════════════════════════════════════
ShopItemList.lua — Lista de items de tienda reutilizable
═══════════════════════════════════════════════════════════════
Cards con diseño gradiente + icono + nombre + descripción.
Botón COMPRAR y botón REGALAR → slide con SlideHeader + PlayerList.
Compartido entre GamepassTab y TitlesTab.

API:
  ShopItemList.build(props) → { panel, markOwned(id), handleOwnershipRemoved(itemId, userId), cleanup }

  props = {
      parent        : Instance
      theme         : table
      state         : { subTabH: number }
      items         : { {id, name, price, icon, color, gradColor?, desc?, titleId?}, ... }
      emptyListText : string?
      onBuy         : function(item)
      onGift        : function(item, userId, username, displayName)
      loadPlayers   : function(item, setPlayers)   -- setPlayers(array)
      onEquip       : function(item)?  -- si se da, los items owned muestran EQUIPAR/DESEQUIPAR
  }
]]

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")

local player = Players.LocalPlayer

local UI              = require(ReplicatedStorage:WaitForChild("Core"):WaitForChild("UI"))
local ModernScrollbar = require(ReplicatedStorage:WaitForChild("UIComponents"):WaitForChild("ModernScrollbar"))
local PlayerList      = require(script.Parent:WaitForChild("PlayerList"))
local SlideHeader     = require(script.Parent:WaitForChild("SlideHeader"))

local ROBUX_CHAR = utf8.char(0xE002)
local TW         = TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local TW_PAGE    = TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

local GRAD_DEFAULTS = {
    Color3.fromRGB(90,  40, 140), Color3.fromRGB(40,  80, 160),
    Color3.fromRGB(50, 130,  80), Color3.fromRGB(30,  80, 160),
    Color3.fromRGB(160, 50,  50), Color3.fromRGB(60, 100, 160),
    Color3.fromRGB(180, 90,  20), Color3.fromRGB(20, 140, 160),
    Color3.fromRGB(120, 40, 180),
}

local ShopItemList = {}

function ShopItemList.build(props)
    local THEME    = props.theme
    local state    = props.state
    local HEADER_H = 60

    local root = UI.frame({
        name  = "ShopItemListRoot",
        size  = UDim2.new(1, 0, 1, -(state.subTabH or 38)),
        pos   = UDim2.new(0, 0, 0, state.subTabH or 38),
        bg    = THEME.bg, clips = true, z = 100, parent = props.parent,
    })

    -- ── ESTADO ──
    local _sliding     = false
    local selectedItem = nil
    local buyBtnRefs   = {}    -- [item.id] → buyBtn
    local itemByIdRefs = {}    -- [item.id] → item
    local attrConns    = {}    -- conexiones EquippedTitle para cleanup

    -- ── VIEW 1: LISTA ──
    local listView = Instance.new("ScrollingFrame")
    listView.Name                = "ItemListView"
    listView.Size                = UDim2.fromScale(1, 1)
    listView.BackgroundTransparency = 1
    listView.BorderSizePixel     = 0
    listView.ScrollBarThickness  = 0
    listView.CanvasSize          = UDim2.new(0, 0, 0, 0)
    listView.AutomaticCanvasSize = Enum.AutomaticSize.Y
    listView.ClipsDescendants    = true
    listView.ZIndex              = 204
    listView.Parent              = root
    ModernScrollbar.setup(listView, root, THEME, { transparency = 0.4, offset = -4, zIndex = 220 })

    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding             = UDim.new(0, 0)
    listLayout.SortOrder           = Enum.SortOrder.LayoutOrder
    listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    listLayout.Parent              = listView
    Instance.new("UIPadding").Parent = listView

    -- Forward declarations (se crean después del loop)
    local giftView, giftHdr, playerListInstance

    -- ── CARDS ──
    for i, item in ipairs(props.items) do
        local gradColor = item.gradColor or GRAD_DEFAULTS[((i - 1) % #GRAD_DEFAULTS) + 1]

        local card = Instance.new("CanvasGroup")
        card.Name             = "Card_" .. i
        card.Size             = UDim2.new(1, 0, 0, 0)
        card.AutomaticSize    = Enum.AutomaticSize.Y
        card.BackgroundColor3 = THEME.card
        card.BorderSizePixel  = 0
        card.ZIndex           = 205
        card.LayoutOrder      = i
        card.Parent           = listView

        -- Separador inferior
        UI.frame({ name = "Sep", size = UDim2.new(1, 0, 0, 1), pos = UDim2.new(0, 0, 1, -1), bg = THEME.stroke, bgT = 0.5, z = 215, parent = card })

        -- Gradiente lateral izquierdo
        local gradOverlay = UI.frame({ size = UDim2.new(0.45, 0, 1, 0), bg = gradColor, z = 206, parent = card })
        local gd = Instance.new("UIGradient")
        gd.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.55),
            NumberSequenceKeypoint.new(0.6, 0.85),
            NumberSequenceKeypoint.new(1, 1),
        })
        gd.Parent = gradOverlay

        -- Contenido con padding
        local content = UI.frame({ size = UDim2.new(1, 0, 0, 0), bgT = 1, z = 210, parent = card })
        content.AutomaticSize = Enum.AutomaticSize.Y
        local cPad = Instance.new("UIPadding")
        cPad.PaddingLeft  = UDim.new(0, 14); cPad.PaddingRight  = UDim.new(0, 12)
        cPad.PaddingTop   = UDim.new(0, 14); cPad.PaddingBottom = UDim.new(0, 14)
        cPad.Parent = content

        local innerLay = Instance.new("UIListLayout")
        innerLay.Padding   = UDim.new(0, 10)
        innerLay.SortOrder = Enum.SortOrder.LayoutOrder
        innerLay.Parent    = content

        -- Top row: icono + nombre + descripción
        local topRow = UI.frame({ size = UDim2.new(1, 0, 0, 76), bgT = 1, z = 210, parent = content })
        topRow.LayoutOrder = 1

        local AVATAR_S    = 76
        local avatarFrame = UI.frame({ size = UDim2.new(0, AVATAR_S, 0, AVATAR_S), bg = THEME.elevated, z = 211, parent = topRow, corner = AVATAR_S })
        local avatarImg   = Instance.new("ImageLabel")
        avatarImg.Size                = UDim2.fromScale(1, 1)
        avatarImg.BackgroundTransparency = 1
        avatarImg.Image               = "rbxassetid://" .. tostring(item.icon)
        avatarImg.ScaleType           = Enum.ScaleType.Crop
        avatarImg.ZIndex              = 212
        avatarImg.Parent              = avatarFrame
        UI.rounded(avatarImg, AVATAR_S)

        local TEXT_X = AVATAR_S + 12
        UI.label({
            size = UDim2.new(1, -TEXT_X, 0, 28), pos = UDim2.new(0, TEXT_X, 0, 0),
            text = item.name, color = item.color or THEME.accent,
            font = Enum.Font.GothamBlack, textSize = 20,
            truncate = Enum.TextTruncate.AtEnd, z = 211, parent = topRow,
        })

        if item.desc and item.desc ~= "" then
            local descLbl = UI.label({
                size = UDim2.new(1, -TEXT_X, 0, 0), pos = UDim2.new(0, TEXT_X, 0, 30),
                text = item.desc, color = THEME.dim, textSize = 13,
                wrap = true, z = 211, parent = topRow,
            })
            descLbl.AutomaticSize = Enum.AutomaticSize.Y
            descLbl.RichText      = true

            task.defer(function()
                if descLbl.Parent then
                    task.wait()
                    local descH  = descLbl.TextBounds.Y
                    local totalH = math.max(AVATAR_S, 30 + descH + 4)
                    topRow.Size  = UDim2.new(1, 0, 0, totalH)
                end
            end)
        end

        -- Bottom row: comprar + regalar
        local bottomRow   = UI.frame({ size = UDim2.new(1, 0, 0, 44), bgT = 1, z = 210, parent = content })
        bottomRow.LayoutOrder = 2

        local buyBtn = UI.button({
            name = "BuyBtn", size = UDim2.new(0, 150, 0, 40),
            bg = THEME.elevated, text = ROBUX_CHAR .. " " .. tostring(item.price),
            textSize = 15, z = 212, parent = bottomRow, corner = 20,
        })

        local giftBtn = UI.button({
            name = "GiftBtn", size = UDim2.new(0, 130, 0, 40), pos = UDim2.new(0, 158, 0, 0),
            bg = item.color or THEME.accent, text = "REGALAR",
            textSize = 14, z = 212, parent = bottomRow, corner = 20,
        })
        giftBtn.BackgroundTransparency = 0.3

        buyBtnRefs[item.id]   = buyBtn
        itemByIdRefs[item.id] = item

        -- Hover card
        card.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement then
                TweenService:Create(card, TW, { BackgroundColor3 = THEME.elevated }):Play()
            end
        end)
        card.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement then
                TweenService:Create(card, TW, { BackgroundColor3 = THEME.card }):Play()
            end
        end)

        -- Buy hover + click
        buyBtn.MouseButton1Click:Connect(function()
            if buyBtn:GetAttribute("Owned") then
                if props.onEquip then props.onEquip(item) end
                return
            end
            if props.onBuy then props.onBuy(item) end
        end)
        buyBtn.MouseEnter:Connect(function()
            if not buyBtn:GetAttribute("Owned") then
                TweenService:Create(buyBtn, TW, { BackgroundColor3 = THEME.subtle }):Play()
            end
        end)
        buyBtn.MouseLeave:Connect(function()
            if not buyBtn:GetAttribute("Owned") then
                TweenService:Create(buyBtn, TW, { BackgroundColor3 = THEME.elevated }):Play()
            end
        end)

        -- Gift hover
        giftBtn.MouseEnter:Connect(function()
            TweenService:Create(giftBtn, TW, { BackgroundTransparency = 0 }):Play()
        end)
        giftBtn.MouseLeave:Connect(function()
            TweenService:Create(giftBtn, TW, { BackgroundTransparency = 0.3 }):Play()
        end)

        -- Gift click → slide a gift view
        giftBtn.MouseButton1Click:Connect(function()
            if _sliding then return end
            selectedItem = item

            giftHdr.title.Text          = "Regalar " .. item.name
            giftHdr.subtitle.Text       = ROBUX_CHAR .. " " .. tostring(item.price)
            giftHdr.bg.BackgroundColor3 = item.color or THEME.accent

            _sliding = true
            giftView.Position = UDim2.fromScale(1, 0)
            giftView.Visible  = true
            TweenService:Create(listView, TW_PAGE, { Position = UDim2.fromScale(-1, 0) }):Play()
            TweenService:Create(giftView, TW_PAGE, { Position = UDim2.fromScale(0,  0) }):Play()
            task.delay(0.28, function()
                listView.Visible  = false
                listView.Position = UDim2.fromScale(0, 0)
                _sliding = false
            end)

            if playerListInstance then
                playerListInstance:setLoading(true)
                playerListInstance:setAccentColor(item.color or THEME.accent)
            end

            if props.loadPlayers then
                props.loadPlayers(item, function(players)
                    if playerListInstance then
                        playerListInstance:setPlayers(players or {})
                        playerListInstance:setLoading(false)
                    end
                end)
            end
        end)
    end

    -- ── VIEW 2: GIFT VIEW ──
    giftView = UI.frame({ name = "GiftView", bgT = 1, clips = true, z = 211, parent = root })
    giftView.Visible = false

    giftHdr = SlideHeader.new({ parent = giftView, theme = THEME, bgMode = "color" })

    local playerListContainer = UI.frame({
        name = "PlayerListContainer",
        size = UDim2.new(1, 0, 1, -HEADER_H), pos = UDim2.new(0, 0, 0, HEADER_H),
        bgT  = 1, z = 212, parent = giftView,
    })

    -- Botón back
    giftHdr.backBtn.MouseButton1Click:Connect(function()
        if _sliding then return end
        _sliding = true
        listView.Position = UDim2.fromScale(-1, 0)
        listView.Visible  = true
        TweenService:Create(giftView, TW_PAGE, { Position = UDim2.fromScale(1, 0) }):Play()
        TweenService:Create(listView, TW_PAGE, { Position = UDim2.fromScale(0, 0) }):Play()
        task.delay(0.28, function()
            giftView.Visible  = false
            giftView.Position = UDim2.fromScale(0, 0)
            listView.Visible  = true
            _sliding = false
        end)
        selectedItem = nil
    end)

    -- Player list
    playerListInstance = PlayerList.new({
        parent      = playerListContainer,
        emptyText   = props.emptyListText or "No hay jugadores disponibles",
        accentColor = THEME.accent,
        buttonText  = "REGALAR",
        buttonIcon  = UI.ICONS.GIFT,
        showSearch  = true,
        searchGap   = 0,
        searchOptions = {
            placeholder = "Buscar jugador...",
            size = UDim2.new(1, 0, 0, 46),
            position = UDim2.new(0, 0, 0, 0),
            bg = THEME.card,
            corner = 0,
            z = 213,
            inputName = "GiftPlayerSearchInput",
            textSize = 16,
        },
        onAction    = function(userId, username, displayName)
            if not selectedItem or not props.onGift then return end
            props.onGift(selectedItem, userId, username, displayName)
        end,
    })

    -- ── API PÚBLICA ──

    local function markOwned(itemId)
        local btn = buyBtnRefs[itemId]
        if not (btn and btn.Parent) then return end
        btn:SetAttribute("Owned", true)

        if props.onEquip then
            -- Modo equip: EQUIPAR / DESEQUIPAR según atributo
            local itm = itemByIdRefs[itemId]
            local function refreshEquipBtn()
                local equipped = tostring(player:GetAttribute("EquippedTitle") or "")
                local titleId  = tostring((itm and itm.titleId) or itemId)
                if titleId == equipped then
                    btn.Text             = "DESEQUIPAR"
                    btn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
                else
                    btn.Text             = "EQUIPAR"
                    btn.BackgroundColor3 = (itm and itm.color) or THEME.accent
                end
            end
            refreshEquipBtn()
            local conn = player:GetAttributeChangedSignal("EquippedTitle"):Connect(refreshEquipBtn)
            table.insert(attrConns, conn)
        else
            btn.Text             = "TIENES"
            btn.BackgroundColor3 = Color3.fromRGB(40, 180, 80)
        end
    end

    local function handleOwnershipRemoved(itemId, userId)
        if selectedItem and selectedItem.id == itemId and playerListInstance then
            playerListInstance:removePlayer(userId)
        end
    end

    local function cleanup()
        for _, conn in ipairs(attrConns) do conn:Disconnect() end
        attrConns = {}
        if playerListInstance then
            playerListInstance:destroy()
            playerListInstance = nil
        end
    end

    return {
        panel                  = root,
        markOwned              = markOwned,
        handleOwnershipRemoved = handleOwnershipRemoved,
        cleanup                = cleanup,
    }
end

return ShopItemList