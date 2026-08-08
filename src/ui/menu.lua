-- Reusable menu drawing and navigation.

Menu = {}

local VISIBLE_ITEMS = 5
local scrollPositions = {}

local function drawCenteredFitted(gc, text, y, bold, preferredSize, minimumSize)
    local width = platform.window:width()
    local padding = 12
    local size = preferredSize
    while size > minimumSize do
        gc:setFont("sansserif", bold and "b" or "r", size)
        if gc:getStringWidth(text) <= width - 2 * padding then break end
        size = size - 1
    end
    gc:setFont("sansserif", bold and "b" or "r", size)
    gc:drawString(text, math.max(padding, (width - gc:getStringWidth(text)) / 2), y, "top")
end

function Menu.ensureVisible(selectedItem, scrollOffset, itemCount)
    scrollOffset = scrollOffset or 0
    if selectedItem <= scrollOffset then
        scrollOffset = selectedItem - 1
    elseif selectedItem > scrollOffset + VISIBLE_ITEMS then
        scrollOffset = selectedItem - VISIBLE_ITEMS
    end
    local maximumOffset = math.max(0, itemCount - VISIBLE_ITEMS)
    if scrollOffset < 0 then scrollOffset = 0 end
    if scrollOffset > maximumOffset then scrollOffset = maximumOffset end
    return scrollOffset
end

function Menu.draw(gc, title, items, selectedItem, subtitle, scrollOffset, breadcrumb)
    local key = title or "menu"
    if scrollOffset == nil then scrollOffset = scrollPositions[key] or 0 end
    scrollOffset = Menu.ensureVisible(selectedItem, scrollOffset, #items)
    scrollPositions[key] = scrollOffset

    drawCenteredFitted(gc, title, 8, true, 14, 9)
    drawCenteredFitted(gc, breadcrumb or subtitle or "Use arrows and Enter", 30, false, 9, 6)

    local first = scrollOffset + 1
    local last = math.min(#items, scrollOffset + VISIBLE_ITEMS)
    for i = first, last do
        local y = 56 + ((i - first) * 30)
        gc:setFont("sansserif", i == selectedItem and "b" or "r", 11)
        gc:drawString((i == selectedItem and "> " or "  ") .. items[i], 26, y, "top")
    end

    gc:setFont("sansserif", "r", 8)
    if first > 1 then gc:drawString("^ more", platform.window:width() - 48, 48, "top") end
    if last < #items then gc:drawString("v more", platform.window:width() - 48, 202, "top") end

    local countText = tostring(selectedItem) .. "/" .. tostring(#items)
    gc:drawString(countText, platform.window:width() - gc:getStringWidth(countText) - 12, 220, "top")
    drawCenteredFitted(gc, "Enter: select   Esc: back", 218, false, 8, 6)

    return scrollOffset
end

function Menu.move(selectedItem, itemCount, key)
    if key == "up" then
        selectedItem = selectedItem - 1
        if selectedItem < 1 then selectedItem = itemCount end
    elseif key == "down" then
        selectedItem = selectedItem + 1
        if selectedItem > itemCount then selectedItem = 1 end
    end
    return selectedItem
end
