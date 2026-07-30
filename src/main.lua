-- TI-Nspire Engineering Toolbox
-- Application menu tree and navigation.

platform.apiLevel = "2.0"

local calculators = {}
registerComplexCalculators(calculators)
registerCircuitCalculators(calculators)
registerElectromagneticsCalculators(calculators)
registerCoordinateCalculators(calculators)

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
        {label = "Current Divider", calculator = "currentDivider"}
    }
}

local resistorNetworksMenu = {
    title = "Resistor Networks",
    subtitle = "Equivalent resistance and conversions",
    items = {
        {label = "Series Resistance", calculator = "seriesResistance"},
        {label = "Parallel Resistance", calculator = "parallelResistance"},
        {label = "Delta to Wye", calculator = "deltaToWye"},
        {label = "Wye to Delta", calculator = "wyeToDelta"}
    }
}

local sourceTransformationMenu = {
    title = "Source Transformation",
    subtitle = "Choose the source conversion direction",
    items = {
        {label = "Voltage to Current", calculator = "voltageToCurrentSource"},
        {label = "Current to Voltage", calculator = "currentToVoltageSource"}
    }
}

local equivalentConversionMenu = {
    title = "Thevenin and Norton",
    subtitle = "Choose the equivalent conversion direction",
    items = {
        {label = "Thevenin to Norton", calculator = "theveninToNorton"},
        {label = "Norton to Thevenin", calculator = "nortonToThevenin"}
    }
}

local networkTheoremsMenu = {
    title = "Network Theorems",
    subtitle = "Source and equivalent-circuit conversions",
    items = {
        {label = "Thevenin / Norton", menu = equivalentConversionMenu},
        {label = "Source Transformation", menu = sourceTransformationMenu}
    }
}

local equationSolversMenu = {
    title = "Equation Solvers",
    subtitle = "Solve circuit equation systems",
    items = {
        {label = "Two-Mesh Solver", calculator = "meshTwo"},
        {label = "Three-Mesh Solver"}
    }
}

local circuitMenu = {
    title = "Circuit Analysis",
    subtitle = "Choose a category",
    items = {
        {label = "Basic Circuits", menu = basicCircuitsMenu},
        {label = "Resistor Networks", menu = resistorNetworksMenu},
        {label = "Network Theorems", menu = networkTheoremsMenu},
        {label = "Equation Solvers", menu = equationSolversMenu}
    }
}

local vectorOperationsMenu = {
    title = "Vector Operations",
    subtitle = "Three-dimensional Cartesian vectors",
    items = {
        {label = "Magnitude", calculator = "vectorMagnitude"},
        {label = "Unit Vector", calculator = "vectorUnit"},
        {label = "Dot Product", calculator = "vectorDot"},
        {label = "Cross Product", calculator = "vectorCross"},
        {label = "Angle Between", calculator = "vectorAngle"},
        {label = "Projection A onto B", calculator = "vectorProjection"}
    }
}

local coordinateSystemsMenu = {
    title = "Coordinate Systems",
    subtitle = "Points and vector components",
    items = {
        {label = "Cartesian to Cylindrical", calculator = "cartesianToCylindrical"},
        {label = "Cylindrical to Cartesian", calculator = "cylindricalToCartesian"},
        {label = "Cartesian to Spherical", calculator = "cartesianToSpherical"},
        {label = "Spherical to Cartesian", calculator = "sphericalToCartesian"},
        {label = "Cyl Vector to Cartesian", calculator = "cylindricalVectorToCartesian"},
        {label = "Sph Vector to Cartesian", calculator = "sphericalVectorToCartesian"}
    }
}

local generalMathMenu = {
    title = "General Math",
    subtitle = "Reusable mathematical tools",
    items = {
        {label = "Vector Operations", menu = vectorOperationsMenu},
        {label = "Coordinate Systems", menu = coordinateSystemsMenu}
    }
}

local electromagneticsMenu = {
    title = "Electromagnetics",
    subtitle = "ECE 216 tools",
    items = {
        {label = "Electrostatics"},
        {label = "Magnetostatics"},
        {label = "Waves"},
        {label = "Transmission Lines"}
    }
}

local rootMenu = {
    title = "Engineering Toolbox",
    subtitle = "Use arrows and Enter",
    items = {
        {label = "Complex Numbers", menu = complexMenu},
        {label = "Circuit Analysis", menu = circuitMenu},
        {label = "Electromagnetics", menu = electromagneticsMenu},
        {label = "Linear Algebra"},
        {label = "Signals and Systems"},
        {label = "General Math", menu = generalMathMenu}
    }
}

local menuStack = {{menu = rootMenu, selected = 1}}
local activeCalculator = nil

local function currentFrame()
    return menuStack[#menuStack]
end

local function menuLabels(menu)
    local labels = {}
    for i, item in ipairs(menu.items) do labels[i] = item.label end
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
    Menu.draw(gc, frame.menu.title, menuLabels(frame.menu), frame.selected, frame.menu.subtitle)
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
    if activeCalculator then activeCalculator:enter() else openSelectedMenuItem() end
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
        if activeCalculator.page == "results" then
            activeCalculator.page = "inputs"
            activeCalculator:ensureSelectedVisible()
        else
            activeCalculator = nil
        end
    elseif #menuStack > 1 then
        table.remove(menuStack)
    end
    platform.window:invalidate()
end
