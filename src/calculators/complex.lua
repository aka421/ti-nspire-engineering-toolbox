-- Complex-number calculator definitions.

local function degrees(value)
    return string.format("%.4f degrees", value)
end

local function arithmeticInputs()
    return {
        {label = "A real"}, {label = "A imaginary"},
        {label = "B real"}, {label = "B imaginary"}
    }
end

local function arithmeticOutputs()
    return {{label = "Real part"}, {label = "Imaginary part"}}
end

function registerComplexCalculators(calculators)
    calculators.rectToPolar = Calculator.new({
        title = "Rectangular to Polar",
        inputs = {{label = "Real part"}, {label = "Imaginary part"}},
        outputs = {{label = "Magnitude"}, {label = "Angle", format = degrees}},
        calculate = function(v) return complex.rectToPolar(v[1], v[2]) end
    })

    calculators.polarToRect = Calculator.new({
        title = "Polar to Rectangular",
        subtitle = "Angle is entered in degrees",
        inputs = {{label = "Magnitude"}, {label = "Angle", unit = "degrees"}},
        outputs = {{label = "Real part"}, {label = "Imaginary part"}},
        validate = function(v)
            if v[1] < 0 then return "Magnitude cannot be negative" end
        end,
        calculate = function(v) return complex.polarToRect(v[1], v[2]) end
    })

    calculators.magnitudePhase = Calculator.new({
        title = "Magnitude and Phase",
        inputs = {{label = "Real part"}, {label = "Imaginary part"}},
        outputs = {{label = "Magnitude"}, {label = "Phase", format = degrees}},
        calculate = function(v)
            return complex.magnitude(v[1], v[2]), complex.phase(v[1], v[2])
        end
    })

    calculators.complexAdd = Calculator.new({
        title = "Complex Addition", subtitle = "A + B",
        inputs = arithmeticInputs(), outputs = arithmeticOutputs(),
        calculate = function(v) return complex.add(v[1], v[2], v[3], v[4]) end
    })

    calculators.complexSubtract = Calculator.new({
        title = "Complex Subtraction", subtitle = "A - B",
        inputs = arithmeticInputs(), outputs = arithmeticOutputs(),
        calculate = function(v) return complex.subtract(v[1], v[2], v[3], v[4]) end
    })

    calculators.complexMultiply = Calculator.new({
        title = "Complex Multiplication", subtitle = "A x B",
        inputs = arithmeticInputs(), outputs = arithmeticOutputs(),
        calculate = function(v) return complex.multiply(v[1], v[2], v[3], v[4]) end
    })

    calculators.complexDivide = Calculator.new({
        title = "Complex Division", subtitle = "A / B",
        inputs = arithmeticInputs(), outputs = arithmeticOutputs(),
        validate = function(v)
            if v[3] == 0 and v[4] == 0 then return "Cannot divide by zero" end
        end,
        calculate = function(v) return complex.divide(v[1], v[2], v[3], v[4]) end
    })
end
