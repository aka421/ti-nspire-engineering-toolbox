-- TI-Nspire Engineering Toolbox
-- Main menu

platform.apiLevel = "2.0"

local menuItems = {
    "Complex Numbers",
    "Circuit Analysis",
    "Linear Algebra",
    "Signals and Systems",
    "General Math"
}

local selectedItem = 1

function on.paint(gc)
    local width = platform.window:width()

    -- Title
    gc:setFont("sansserif", "b", 14)
    gc:drawString(
        "Engineering Toolbox",
        width / 2,
        15,
        "middle"
    )

    -- Instructions
    gc:setFont("sansserif", "r", 9)
    gc:drawString(
        "Use arrows and Enter",
        width / 2,
        38,
        "middle"
    )

    -- Menu items
    for i, item in ipairs(menuItems) do
        local y = 58 + ((i - 1) * 28)

        if i == selectedItem then
            gc:setFont("sansserif", "b", 11)
            gc:drawString("> " .. item, 35, y, "top")
        else
            gc:setFont("sansserif", "r", 11)
            gc:drawString("  " .. item, 35, y, "top")
        end
    end
end

function on.arrowKey(key)
    if key == "up" then
        selectedItem = selectedItem - 1

        if selectedItem < 1 then
            selectedItem = #menuItems
        end

    elseif key == "down" then
        selectedItem = selectedItem + 1

        if selectedItem > #menuItems then
            selectedItem = 1
        end
    end

    platform.window:invalidate()
end

function on.enterKey()
    -- We will make this open modules next.
    platform.window:invalidate()
end