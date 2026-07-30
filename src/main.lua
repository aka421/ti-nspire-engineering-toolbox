-- TI-Nspire Engineering Toolbox
-- Application menus and calculator definitions.

platform.apiLevel = "2.0"

local menus = {
    main = {
        title = "Engineering Toolbox",
        subtitle = "Use arrows and Enter",
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
        subtitle = "Enter to select, Esc to return",
        items = {
            "Rectangular to Polar",
            "Polar to Rectangular",
            "Magnitude and Phase",
            "Complex Arithmetic"
        }
    }
}

local function degrees(value)
    return string.format("%.4f degrees", value)
end

local calculators = {
    rectToPolar = Calculator.new({
        title = "Rectangular to Polar",
        inputs = {
            {label = "Real part"},
            {label = "Imaginary part"}
        },
        outputs = {
            {label = "Magnitude"},
            {label = "Angle", format = degrees}
        },
        calculate = function(values)
            return complex.rectToPolar(values[1], values[2])
        end
    }),

    polarToRect = Calculator.new({
        title = "Polar to Rectangular",
        subtitle = "Angle is entered in degrees",
        inputs = {
            {label = "Magnitude"},
            {label = "Angle"}
        },
        outputs = {
            {label = "Real part"},
            {label = "Imaginary part"}
        },
        validate = function(values)
            if values[1] < 0 then
                return "Magnitude cannot be negative"
            end
        end,
        calculate = function(values)
            return complex.polarToRect(values[1], values[2])
        end
    }),

    magnitudePhase = Calculator.new({
        title = "Magnitude and Phase",
        inputs = {
            {label = "Real part"},
            {label = "Imaginary part"}
        },
        outputs = {
            {label = "Magnitude"},
            {label = "Phase", format = degrees}
        },
        calculate = function(values)
            return complex.magnitude(values[1], values[2]),
                complex.phase(values[1], values[2])
        end
    })
}

local complexRoutes = {
    [1] = "rectToPolar",
    [2] = "polarToRect",
    [3] = "magnitudePhase"
}

local currentScreen = "main"
local selectedItem = 1
local activeCalculator = nil

local function openCalculator(name)
    activeCalculator = calculators[name]
    activeCalculator:reset()
    currentScreen = "calculator"
end

function on.paint(gc)
    if currentScreen == "calculator" then
        activeCalculator:draw(gc)
        return
    end

    local menu = menus[currentScreen]
    Menu.draw(gc, menu.title, menu.items, selectedItem, menu.subtitle)
end

function on.arrowKey(key)
    if currentScreen == "calculator" then
        activeCalculator:moveField(key)
    else
        selectedItem = Menu.move(selectedItem, #menus[currentScreen].items, key)
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
        local route = complexRoutes[selectedItem]
        if route then
            openCalculator(route)
        end
    elseif currentScreen == "calculator" then
        activeCalculator:enter()
    end

    platform.window:invalidate()
end

function on.charIn(character)
    if currentScreen == "calculator" then
        activeCalculator:append(character)
        platform.window:invalidate()
    end
end

function on.backspaceKey()
    if currentScreen == "calculator" then
        activeCalculator:backspace()
        platform.window:invalidate()
    end
end

function on.escapeKey()
    if currentScreen == "calculator" then
        currentScreen = "complex"
        activeCalculator = nil
        selectedItem = 1
    elseif currentScreen == "complex" then
        currentScreen = "main"
        selectedItem = 1
    end

    platform.window:invalidate()
end
