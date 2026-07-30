-- TI-Nspire Engineering Toolbox
-- Main menu and Rectangular-to-Polar calculator

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

local rectToPolar = {
    selectedField = 1,
    realText = "",
    imaginaryText = "",
    magnitude = nil,
    angle = nil,
    errorMessage = nil
}


local function drawMenu(gc)
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


local function drawInputField(gc, label, text, y, isSelected)
    gc:setFont("sansserif", "r", 11)
    gc:drawString(label, 25, y, "top")

    if isSelected then
        gc:setFont("sansserif", "b", 11)
        gc:drawString("> " .. text .. "_", 135, y, "top")
    else
        gc:setFont("sansserif", "r", 11)
        gc:drawString("  " .. text, 135, y, "top")
    end
end


local function drawRectToPolar(gc)
    local width = platform.window:width()

    gc:setFont("sansserif", "b", 14)
    gc:drawString(
        "Rectangular to Polar",
        width / 2,
        15,
        "middle"
    )

    gc:setFont("sansserif", "r", 9)
    gc:drawString(
        "Type a value, then press Enter",
        width / 2,
        38,
        "middle"
    )

    drawInputField(
        gc,
        "Real part:",
        rectToPolar.realText,
        65,
        rectToPolar.selectedField == 1
    )

    drawInputField(
        gc,
        "Imaginary part:",
        rectToPolar.imaginaryText,
        95,
        rectToPolar.selectedField == 2
    )

    if rectToPolar.errorMessage then
        gc:setFont("sansserif", "b", 10)
        gc:drawString(
            rectToPolar.errorMessage,
            width / 2,
            130,
            "middle"
        )
    end

    if rectToPolar.magnitude then
        gc:setFont("sansserif", "b", 11)

        gc:drawString(
            "Magnitude: " ..
            string.format("%.4f", rectToPolar.magnitude),
            25,
            145,
            "top"
        )

        gc:drawString(
            "Angle: " ..
            string.format("%.4f", rectToPolar.angle) ..
            " degrees",
            25,
            175,
            "top"
        )
    end

    gc:setFont("sansserif", "r", 9)
    gc:drawString(
        "Esc: back   Del: erase",
        width / 2,
        210,
        "middle"
    )
end


local function calculateRectToPolar()
    local realValue = tonumber(rectToPolar.realText)
    local imaginaryValue = tonumber(rectToPolar.imaginaryText)

    if realValue == nil or imaginaryValue == nil then
        rectToPolar.errorMessage = "Enter two valid numbers"
        rectToPolar.magnitude = nil
        rectToPolar.angle = nil
        return
    end

    rectToPolar.magnitude,
    rectToPolar.angle =
        complex.rectToPolar(realValue, imaginaryValue)

    rectToPolar.errorMessage = nil
end


function on.paint(gc)
    if currentScreen == "rectToPolar" then
        drawRectToPolar(gc)
    else
        drawMenu(gc)
    end
end


function on.arrowKey(key)
    if currentScreen == "rectToPolar" then
        if key == "up" or key == "down" then
            if rectToPolar.selectedField == 1 then
                rectToPolar.selectedField = 2
            else
                rectToPolar.selectedField = 1
            end
        end

        platform.window:invalidate()
        return
    end

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

    elseif currentScreen == "complex" then
        if selectedItem == 1 then
            currentScreen = "rectToPolar"

            rectToPolar.selectedField = 1
            rectToPolar.realText = ""
            rectToPolar.imaginaryText = ""
            rectToPolar.magnitude = nil
            rectToPolar.angle = nil
            rectToPolar.errorMessage = nil
        end

    elseif currentScreen == "rectToPolar" then
        if rectToPolar.selectedField == 1 then
            rectToPolar.selectedField = 2
        else
            calculateRectToPolar()
        end
    end

    platform.window:invalidate()
end


function on.charIn(character)
    if currentScreen ~= "rectToPolar" then
        return
    end

    local isDigit =
        character >= "0" and character <= "9"

    local isDecimal =
        character == "."

    local isNegative =
        character == "-"

    if not isDigit and not isDecimal and not isNegative then
        return
    end

    if rectToPolar.selectedField == 1 then
        rectToPolar.realText =
            rectToPolar.realText .. character
    else
        rectToPolar.imaginaryText =
            rectToPolar.imaginaryText .. character
    end

    rectToPolar.magnitude = nil
    rectToPolar.angle = nil
    rectToPolar.errorMessage = nil

    platform.window:invalidate()
end


function on.backspaceKey()
    if currentScreen ~= "rectToPolar" then
        return
    end

    if rectToPolar.selectedField == 1 then
        rectToPolar.realText =
            string.sub(rectToPolar.realText, 1, -2)
    else
        rectToPolar.imaginaryText =
            string.sub(rectToPolar.imaginaryText, 1, -2)
    end

    rectToPolar.magnitude = nil
    rectToPolar.angle = nil
    rectToPolar.errorMessage = nil

    platform.window:invalidate()
end


function on.escapeKey()
    if currentScreen == "rectToPolar" then
        currentScreen = "complex"
        selectedItem = 1

    elseif currentScreen == "complex" then
        currentScreen = "main"
        selectedItem = 1
    end

    platform.window:invalidate()
end