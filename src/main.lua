-- TI-Nspire Engineering Toolbox
-- Application menu tree and calculator definitions.

platform.apiLevel = "2.0"

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
    }),

    voltageDivider = Calculator.new({
        title = "Voltage Divider",
        subtitle = "Output is measured across R2",
        inputs = {
            {label = "Input voltage", unit = "V"},
            {label = "R1", unit = "ohm"},
            {label = "R2", unit = "ohm"}
        },
        outputs = {
            {label = "Output voltage", unit = "V"}
        },
        validate = function(values)
            local r1 = values[2]
            local r2 = values[3]

            if r1 < 0 or r2 < 0 then
                return "Resistance cannot be negative"
            end

            if r1 + r2 == 0 then
                return "Total resistance cannot be zero"
            end
        end,
        calculate = function(values)
            local inputVoltage = values[1]
            local r1 = values[2]
            local r2 = values[3]
            return inputVoltage * r2 / (r1 + r2)
        end
    })
}

-- Menu nodes may contain submenu items, calculator items, or placeholders.
local complexArithmeticMenu = {
    title = "Complex Arithmetic",
    subtitle = "Choose an operation",
    items = {
        {label = "Add", calculator = "complexAdd"},
        {label = "Subtract", calculator = "complexSubtract"},
        {label = "Multiply", calculator = "complexMultiply"},
        {label = "Divide", calculator = "complexDivide"}
    }
}

local complexMenu = {
    title = "Complex Numbers",
    subtitle = "Enter to select, Esc to return",
    items = {
        {label = "Rectangular to Polar", calculator = "rectToPolar"},
        {label = "Polar to Rectangular", calculator = "polarToRect"},
        {label = "Magnitude and Phase", calculator = "magnitudePhase"},
        {label = "Complex Arithmetic", menu = complexArithmeticMenu}
    }
}

local basicCircuitsMenu = {
    title = "Basic Circuits",
    subtitle = "Enter to select, Esc to return",
    items = {
        {label = "Ohm's Law", calculator = "ohmsLaw"},
        {label = "Electrical Power", calculator = "electricalPower"},
        {label = "Voltage Divider", calculator = "voltageDivider"},
        {label = "Current Divider"}
    }
}

local resistorNetworksMenu = {
    title = "Resistor Networks",
    subtitle = "More tools coming soon",
    items = {
        {label = "Series Resistance"},
        {label = "Parallel Resistance"},
        {label = "Delta to Wye"},
        {label = "Wye to Delta"}
    }
}

local networkTheoremsMenu = {
    title = "Network Theorems",
    subtitle = "More tools coming soon",
    items = {
        {label = "Thevenin Equivalent"},
        {label = "Norton Equivalent"},
        {label = "Source Transformation"}
    }
}

local circuitMenu = {
    title = "Circuit Analysis",
    subtitle = "Choose a category",
    items = {
        {label = "Basic Circuits", menu = basicCircuitsMenu},
        {label = "Resistor Networks", menu = resistorNetworksMenu},
        {label = "Network Theorems", menu = networkTheoremsMenu}
    }
}

local rootMenu = {
    title = "Engineering Toolbox",
    subtitle = "Use arrows and Enter",
    items = {
        {label = "Complex Numbers", menu = complexMenu},
        {label = "Circuit Analysis", menu = circuitMenu},
        {label = "Linear Algebra"},
        {label = "Signals and Systems"},
        {label = "General Math"}
    }
}

local menuStack = {
    {menu = rootMenu, selected = 1}
}
local activeCalculator = nil

local function currentFrame()
    return menuStack[#menuStack]
end

local function menuLabels(menu)
    local labels = {}
    for i, item in ipairs(menu.items) do
        labels[i] = item.label
    end
    return labels
end

local function openCalculator(name)
    activeCalculator = calculators[name]
    activeCalculator:reset()
end

local function openSelectedMenuItem()
    local frame = currentFrame()
    local item = frame.menu.items[frame.selected]

    if item.menu then
        menuStack[#menuStack + 1] = {menu = item.menu, selected = 1}
    elseif item.calculator then
        openCalculator(item.calculator)
    end
end

function on.paint(gc)
    if activeCalculator then
        activeCalculator:draw(gc)
        return
    end

    local frame = currentFrame()
    Menu.draw(
        gc,
        frame.menu.title,
        menuLabels(frame.menu),
        frame.selected,
        frame.menu.subtitle
    )
end

function on.arrowKey(key)
    if activeCalculator then
        activeCalculator:moveField(key)
    else
        local frame = currentFrame()
        frame.selected = Menu.move(frame.selected, #frame.menu.items, key)
    end

    platform.window:invalidate()
end

function on.enterKey()
    if activeCalculator then
        activeCalculator:enter()
    else
        openSelectedMenuItem()
    end

    platform.window:invalidate()
end

function on.charIn(character)
    if activeCalculator then
        activeCalculator:append(character)
        platform.window:invalidate()
    end
end

function on.backspaceKey()
    if activeCalculator then
        activeCalculator:backspace()
        platform.window:invalidate()
    end
end

function on.escapeKey()
    if activeCalculator then
        activeCalculator = nil
    elseif #menuStack > 1 then
        table.remove(menuStack)
    end

    platform.window:invalidate()
end
