-- Reusable menu drawing and navigation.

Menu = {}

function Menu.draw(gc, title, items, selectedItem, subtitle)
    local width = platform.window:width()

    gc:setFont("sansserif", "b", 14)
    gc:drawString(title, width / 2, 15, "middle")

    gc:setFont("sansserif", "r", 9)
    gc:drawString(subtitle or "Use arrows and Enter", width / 2, 38, "middle")

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
