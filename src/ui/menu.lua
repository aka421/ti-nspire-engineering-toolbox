-- Reusable menu drawing and navigation.

Menu = {}

local function drawCenteredFitted(gc, text, y, bold, preferredSize, minimumSize)
    local width = platform.window:width()
    local horizontalPadding = 12
    local size = preferredSize

    while size > minimumSize do
        gc:setFont("sansserif", bold and "b" or "r", size)
        if gc:getStringWidth(text) <= width - (2 * horizontalPadding) then
            break
        end
        size = size - 1
    end

    gc:setFont("sansserif", bold and "b" or "r", size)
    local x = math.max(horizontalPadding, (width - gc:getStringWidth(text)) / 2)
    gc:drawString(text, x, y, "top")
end

function Menu.draw(gc, title, items, selectedItem, subtitle)
    drawCenteredFitted(gc, title, 10, true, 14, 10)
    drawCenteredFitted(gc, subtitle or "Use arrows and Enter", 34, false, 9, 7)

    for i, item in ipairs(items) do
        local y = 58 + ((i - 1) * 28)

        if i == selectedItem then
            gc:setFont("sansserif", "b", 11)
            gc:drawString("> " .. item, 30, y, "top")
        else
            gc:setFont("sansserif", "r", 11)
            gc:drawString("  " .. item, 30, y, "top")
        end
    end
end

function Menu.move(selectedItem, itemCount, key)
    if key == "up" then
        selectedItem = selectedItem - 1
        if selectedItem < 1 then
            selectedItem = itemCount
        end
    elseif key == "down" then
        selectedItem = selectedItem + 1
        if selectedItem > itemCount then
            selectedItem = 1
        end
    end

    return selectedItem
end