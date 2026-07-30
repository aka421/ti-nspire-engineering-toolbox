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
    },
    complexArithmetic = {
        title = "Complex Arithmetic",
        subtitle = "Choose an operation",
        items = {
            "Add",
            "Subtract",
            "Multiply",
            "Divide"
        }
    },
    circuits = {
        title = "Circuit Analysis",
        subtitle = "Enter to select, Esc to return",
        items = {
            "Ohm's Law",
            "Electrical Power"
        }
    }
}

local function degrees(value)
    return string.format("%.4f degrees", value)
end

local function approximatelyEqual(a, b)
    local scale = math.max(1, math.abs(a), math.abs(b))
    return math.abs(a - b) <= 1e-7 * scale
end

local function arithmeticInputs()
    return {
        {label = "A real"},
        {label = "A imaginary"},
        {label = "B real"},
        {label = "B imaginary"}
    }
end

local function arithmeticOutputs()
    return {
        {label = "Real part"},
        {label = "Imaginary part"}
    }
end

local ohmsLawVariables = {
    [1] = {label = "Voltage", unit = "V"},
    [2] = {label = "Current", unit = "A"},
    [3] = {label = "Resistance", unit = "ohm"}
}

local powerVariables = {
    [1] = {label = "Voltage", unit = "V"},
    [2] = {label = "Current", unit = "A"},
    [3] = {label = "Resistance", unit = "ohm"},
    [4] = {label = "Power", unit = "W"}
}

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
            {label = "Angle", unit = "degrees"}
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
    }),

    complexAdd = Calculator.new({
        title = "Complex Addition",
        subtitle = "A + B",
        inputs = arithmeticInputs(),
        outputs = arithmeticOutputs(),
        calculate = function(values)
            return complex.add(values[1], values[2], values[3], values[4])
        end
    }),

    complexSubtract = Calculator.new({
        title = "Complex Subtraction",
        subtitle = "A - B",
        inputs = arithmeticInputs(),
        outputs = arithmeticOutputs(),
        calculate = function(values)
            return complex.subtract(values[1], values[2], values[3], values[4])
        end
    }),

    complexMultiply = Calculator.new({
        title = "Complex Multiplication",
        subtitle = "A x B",
        inputs = arithmeticInputs(),
        outputs = arithmeticOutputs(),
        calculate = function(values)
            return complex.multiply(values[1], values[2], values[3], values[4])
        end
    }),

    complexDivide = Calculator.new({
        title = "Complex Division",
        subtitle = "A / B",
        inputs = arithmeticInputs(),
        outputs = arithmeticOutputs(),
        validate = function(values)
            if values[3] == 0 and values[4] == 0 then
                return "Cannot divide by zero"
            end
        end,
        calculate = function(values)
            return complex.divide(values[1], values[2], values[3], values[4])
        end
    }),

    ohmsLaw = Calculator.new({
        title = "Ohm's Law",
        allowOneBlank = true,
        inputs = {
            ohmsLawVariables[1],
            ohmsLawVariables[2],
            ohmsLawVariables[3]
        },
        outputs = {
            {label = "Result"}
        },
        resolveOutputs = function(values, missing)
            return {ohmsLawVariables[missing]}
        end,
        validate = function(values, missing)
            if values[3] and values[3] < 0 then
                return "Resistance cannot be negative"
            end

            if missing == 2 and values[3] == 0 then
                return "Resistance cannot be zero"
            elseif missing == 3 and values[2] == 0 then
                return "Current cannot be zero"
            end
        end,
        calculate = function(values, missing)
            if missing == 1 then
                return values[2] * values[3]
            elseif missing == 2 then
                return values[1] / values[3]
            else
                return values[1] / values[2]
            end
        end
    }),

    electricalPower = Calculator.new({
        title = "Electrical Power",
        subtitle = "Leave exactly one field blank",
        allowOneBlank = true,
        inputs = {
            powerVariables[1],
            powerVariables[2],
            powerVariables[3],
            powerVariables[4]
        },
        outputs = {
            {label = "Result"}
        },
        resolveOutputs = function(values, missing)
            return {powerVariables[missing]}
        end,
        validate = function(values, missing)
            local voltage = values[1]
            local current = values[2]
            local resistance = values[3]
            local power = values[4]

            if resistance and resistance < 0 then
                return "Resistance cannot be negative"
            end

            if power and power < 0 then
                return "Power cannot be negative"
            end

            if missing == 1 then
                if not approximatelyEqual(power, current * current * resistance) then
                    return "I, R, and P are inconsistent"
                end
            elseif missing == 2 then
                if resistance == 0 then
                    return "Resistance cannot be zero"
                end
                if not approximatelyEqual(power, voltage * voltage / resistance) then
                    return "V, R, and P are inconsistent"
                end
            elseif missing == 3 then
                if current == 0 then
                    return "Current cannot be zero"
                end
                if not approximatelyEqual(power, voltage * current) then
                    return "V, I, and P are inconsistent"
                end
                if voltage / current < 0 then
                    return "Resistance cannot be negative"
                end
            else
                if not approximatelyEqual(voltage, current * resistance) then
                    return "V, I, and R are inconsistent"
                end
            end
        end,
        calculate = function(values, missing)
            local voltage = values[1]
            local current = values[2]
            local resistance = values[3]

            if missing == 1 then
                return current * resistance
            elseif missing == 2 then
                return voltage / resistance
            elseif missing == 3 then
                return voltage / current
            else
                return voltage * current
            end
        end
    })
}

local complexRoutes = {
    [1] = "rectToPolar",
    [2] = "polarToRect",
    [3] = "magnitudePhase"
}

local arithmeticRoutes = {
    [1] = "complexAdd",
    [2] = "complexSubtract",
    [3] = "complexMultiply",
    [4] = "complexDivide"
}

local circuitRoutes = {
    [1] = "ohmsLaw",
    [2] = "electricalPower"
}

local currentScreen = "main"
local selectedItem = 1
local activeCalculator = nil
local calculatorParent = "complex"

local function openCalculator(name, parent)
    activeCalculator = calculators[name]
    activeCalculator:reset()
    calculatorParent = parent or "complex"
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
        elseif selectedItem == 2 then
            currentScreen = "circuits"
            selectedItem = 1
        end
    elseif currentScreen == "complex" then
        if selectedItem == 4 then
            currentScreen = "complexArithmetic"
            selectedItem = 1
        else
            local route = complexRoutes[selectedItem]
            if route then
                openCalculator(route, "complex")
            end
        end
    elseif currentScreen == "complexArithmetic" then
        local route = arithmeticRoutes[selectedItem]
        if route then
            openCalculator(route, "complexArithmetic")
        end
    elseif currentScreen == "circuits" then
        local route = circuitRoutes[selectedItem]
        if route then
            openCalculator(route, "circuits")
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
        currentScreen = calculatorParent
        activeCalculator = nil
        selectedItem = 1
    elseif currentScreen == "complexArithmetic" then
        currentScreen = "complex"
        selectedItem = 4
    elseif currentScreen == "complex" then
        currentScreen = "main"
        selectedItem = 1
    elseif currentScreen == "circuits" then
        currentScreen = "main"
        selectedItem = 2
    end

    platform.window:invalidate()
end