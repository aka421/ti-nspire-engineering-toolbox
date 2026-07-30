-- TI-Nspire Engineering Toolbox
-- Main menu and Complex Numbers submenu

platform.apiLevel = "2.0"

local complex = {}

function complex.magnitude(re, im)
    return math.sqrt(re * re + im * im)
end

function complex.phase(re, im)
    return math.atan2(im, re) * 180 / math.pi
end

function complex.rectToPolar(re, im)
    return complex.magnitude(re, im), complex.phase(re, im)
end

local screens = {
    main = {
        title = "Engineering Toolbox",
        items = {
            "Complex Numbers",
            "Circuit Analysis",
            "Linear Algebra",
            "Signals and Systems",
            "General Math"
        }
    },

    complex = {
        title = "Complex Numbers",
        items = {
            "Rectangular to Polar",
            "Polar to Rectangular",
            "Magnitude and Phase",
            "Complex Arithmetic"
        }
    }
}

local currentScreen = "main"
local selectedItem = 1

function on.paint(gc)
    local width = platform.window:width()
    local screen = screens[currentScreen]

    gc:setFont("sansserif", "b", 14)
    gc:drawString(
        screen.title,
        width / 2,
        15,
        "middle"
    )

    gc:setFont("sansserif", "r", 9)

    if currentScreen == "main" then
        gc:drawString(
            "Use arrows and Enter",
            width / 2,
            38,
            "middle"
        )
    else
        gc:drawString(
            "Enter to select, Esc to return",
            width / 2,
            38,
            "middle"
        )
    end

    for i, item in ipairs(screen.items) do
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

function on.arrowKey(key)
    local itemCount = #screens[currentScreen].items

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

    platform.window:invalidate()
end

function on.enterKey()
    if currentScreen == "main" then
        if selectedItem == 1 then
            currentScreen = "complex"
            selectedItem = 1
        end
    end

    platform.window:invalidate()
end

function on.escapeKey()
    if currentScreen ~= "main" then
        currentScreen = "main"
        selectedItem = 1
        platform.window:invalidate()
    end
end