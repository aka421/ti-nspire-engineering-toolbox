-- Circuit-analysis calculator definitions.

local function approximatelyEqual(a, b)
    local scale = math.max(1, math.abs(a), math.abs(b))
    return math.abs(a - b) <= 1e-7 * scale
end

local function resistorInputs(count)
    local inputs = {}
    for i = 1, count do inputs[i] = {label = "R" .. i, unit = "ohm"} end
    return inputs
end

local function eachEnteredValue(values, callback)
    for i = 1, #values do
        if values[i] ~= nil then callback(values[i], i) end
    end
end

local function validatePositiveResistors(values)
    for i = 1, #values do
        if values[i] <= 0 then return "Resistances must be positive" end
    end
end

local function validatePositiveEquivalentResistance(values)
    if values[2] <= 0 then return "Resistance must be positive" end
end

function registerCircuitCalculators(calculators)
    local ohmsLawVariables = {
        {label = "Voltage", unit = "V"},
        {label = "Current", unit = "A"},
        {label = "Resistance", unit = "ohm"}
    }
    local powerVariables = {
        {label = "Voltage", unit = "V"},
        {label = "Current", unit = "A"},
        {label = "Resistance", unit = "ohm"},
        {label = "Power", unit = "W"}
    }

    calculators.ohmsLaw = Calculator.new({
        title = "Ohm's Law", allowOneBlank = true,
        inputs = ohmsLawVariables, outputs = {{label = "Result"}},
        resolveOutputs = function(v, missing) return {ohmsLawVariables[missing]} end,
        validate = function(v, missing)
            if v[3] and v[3] < 0 then return "Resistance cannot be negative" end
            if missing == 2 and v[3] == 0 then return "Resistance cannot be zero" end
            if missing == 3 and v[2] == 0 then return "Current cannot be zero" end
        end,
        calculate = function(v, missing)
            if missing == 1 then return v[2] * v[3] end
            if missing == 2 then return v[1] / v[3] end
            return v[1] / v[2]
        end
    })

    calculators.electricalPower = Calculator.new({
        title = "Electrical Power", subtitle = "Leave exactly one field blank",
        allowOneBlank = true, inputs = powerVariables, outputs = {{label = "Result"}},
        resolveOutputs = function(v, missing) return {powerVariables[missing]} end,
        validate = function(v, missing)
            local voltage, current, resistance, power = v[1], v[2], v[3], v[4]
            if resistance and resistance < 0 then return "Resistance cannot be negative" end
            if power and power < 0 then return "Power cannot be negative" end
            if missing == 1 and not approximatelyEqual(power, current * current * resistance) then
                return "I, R, and P are inconsistent"
            elseif missing == 2 then
                if resistance == 0 then return "Resistance cannot be zero" end
                if not approximatelyEqual(power, voltage * voltage / resistance) then return "V, R, and P are inconsistent" end
            elseif missing == 3 then
                if current == 0 then return "Current cannot be zero" end
                if not approximatelyEqual(power, voltage * current) then return "V, I, and P are inconsistent" end
                if voltage / current < 0 then return "Resistance cannot be negative" end
            elseif missing == 4 and not approximatelyEqual(voltage, current * resistance) then
                return "V, I, and R are inconsistent"
            end
        end,
        calculate = function(v, missing)
            if missing == 1 then return v[2] * v[3] end
            if missing == 2 then return v[1] / v[3] end
            if missing == 3 then return v[1] / v[2] end
            return v[1] * v[2]
        end
    })

    calculators.voltageDivider = Calculator.new({
        title = "Voltage Divider", subtitle = "Output is measured across R2",
        inputs = {{label = "Input voltage", unit = "V"}, {label = "R1", unit = "ohm"}, {label = "R2", unit = "ohm"}},
        outputs = {{label = "Output voltage", unit = "V"}},
        validate = function(v)
            if v[2] < 0 or v[3] < 0 then return "Resistance cannot be negative" end
            if v[2] + v[3] == 0 then return "Total resistance cannot be zero" end
        end,
        calculate = function(v) return v[1] * v[3] / (v[2] + v[3]) end
    })

    calculators.currentDivider = Calculator.new({
        title = "Current Divider", subtitle = "R1 and R2 are parallel branches",
        inputs = {{label = "Input current", unit = "A"}, {label = "R1", unit = "ohm"}, {label = "R2", unit = "ohm"}},
        outputs = {{label = "Current through R1", unit = "A"}, {label = "Current through R2", unit = "A"}},
        validate = function(v)
            if v[2] < 0 or v[3] < 0 then return "Resistance cannot be negative" end
            if v[2] + v[3] == 0 then return "Total resistance cannot be zero" end
        end,
        calculate = function(v)
            local total = v[2] + v[3]
            return v[1] * v[3] / total, v[1] * v[2] / total
        end
    })

    calculators.seriesResistance = Calculator.new({
        title = "Series Resistance", subtitle = "Enter 2 to 5 resistors",
        allowOptionalInputs = true, minimumInputs = 2, inputs = resistorInputs(5),
        outputs = {{label = "Equivalent resistance", unit = "ohm"}},
        validate = function(v)
            local invalid = false
            eachEnteredValue(v, function(value) if value < 0 then invalid = true end end)
            if invalid then return "Resistance cannot be negative" end
        end,
        calculate = function(v)
            local total = 0
            eachEnteredValue(v, function(value) total = total + value end)
            return total
        end
    })

    calculators.parallelResistance = Calculator.new({
        title = "Parallel Resistance", subtitle = "Enter 2 to 5 resistors",
        allowOptionalInputs = true, minimumInputs = 2, inputs = resistorInputs(5),
        outputs = {{label = "Equivalent resistance", unit = "ohm"}},
        validate = function(v)
            local negative, zero = false, false
            eachEnteredValue(v, function(value)
                if value < 0 then negative = true end
                if value == 0 then zero = true end
            end)
            if negative then return "Resistance cannot be negative" end
            if zero then return "Parallel resistance cannot be zero" end
        end,
        calculate = function(v)
            local reciprocalSum = 0
            eachEnteredValue(v, function(value) reciprocalSum = reciprocalSum + 1 / value end)
            return 1 / reciprocalSum
        end
    })

    calculators.deltaToWye = Calculator.new({
        title = "Delta to Wye", subtitle = "Delta resistors connect terminal pairs",
        inputs = {{label = "R_AB", unit = "ohm"}, {label = "R_BC", unit = "ohm"}, {label = "R_CA", unit = "ohm"}},
        outputs = {{label = "R_A", unit = "ohm"}, {label = "R_B", unit = "ohm"}, {label = "R_C", unit = "ohm"}},
        validate = validatePositiveResistors,
        calculate = function(v)
            local sum = v[1] + v[2] + v[3]
            return v[1] * v[3] / sum, v[1] * v[2] / sum, v[2] * v[3] / sum
        end
    })

    calculators.wyeToDelta = Calculator.new({
        title = "Wye to Delta", subtitle = "Wye resistors run from terminal to centre",
        inputs = {{label = "R_A", unit = "ohm"}, {label = "R_B", unit = "ohm"}, {label = "R_C", unit = "ohm"}},
        outputs = {{label = "R_AB", unit = "ohm"}, {label = "R_BC", unit = "ohm"}, {label = "R_CA", unit = "ohm"}},
        validate = validatePositiveResistors,
        calculate = function(v)
            local sum = v[1] * v[2] + v[2] * v[3] + v[3] * v[1]
            return sum / v[3], sum / v[1], sum / v[2]
        end
    })

    calculators.voltageToCurrentSource = Calculator.new({
        title = "Voltage to Current Source", subtitle = "Series voltage source to parallel current source",
        inputs = {{label = "Voltage source", unit = "V"}, {label = "Series resistance", unit = "ohm"}},
        outputs = {{label = "Current source", unit = "A"}, {label = "Parallel resistance", unit = "ohm"}},
        validate = validatePositiveEquivalentResistance,
        calculate = function(v) return v[1] / v[2], v[2] end
    })

    calculators.currentToVoltageSource = Calculator.new({
        title = "Current to Voltage Source", subtitle = "Parallel current source to series voltage source",
        inputs = {{label = "Current source", unit = "A"}, {label = "Parallel resistance", unit = "ohm"}},
        outputs = {{label = "Voltage source", unit = "V"}, {label = "Series resistance", unit = "ohm"}},
        validate = validatePositiveEquivalentResistance,
        calculate = function(v) return v[1] * v[2], v[2] end
    })

    calculators.theveninToNorton = Calculator.new({
        title = "Thevenin to Norton", subtitle = "Convert V_th and R_th to I_N and R_N",
        inputs = {{label = "V_th", unit = "V"}, {label = "R_th", unit = "ohm"}},
        outputs = {{label = "I_N", unit = "A"}, {label = "R_N", unit = "ohm"}},
        validate = validatePositiveEquivalentResistance,
        calculate = function(v) return v[1] / v[2], v[2] end
    })

    calculators.nortonToThevenin = Calculator.new({
        title = "Norton to Thevenin", subtitle = "Convert I_N and R_N to V_th and R_th",
        inputs = {{label = "I_N", unit = "A"}, {label = "R_N", unit = "ohm"}},
        outputs = {{label = "V_th", unit = "V"}, {label = "R_th", unit = "ohm"}},
        validate = validatePositiveEquivalentResistance,
        calculate = function(v) return v[1] * v[2], v[2] end
    })

    calculators.meshTwo = Calculator.new({
        title = "Two-Mesh Equation Solver",
        subtitle = "a11 I1 + a12 I2 = b1; a21 I1 + a22 I2 = b2",
        inputs = {
            {label = "a11", unit = "ohm"}, {label = "a12", unit = "ohm"}, {label = "b1", unit = "V"},
            {label = "a21", unit = "ohm"}, {label = "a22", unit = "ohm"}, {label = "b2", unit = "V"}
        },
        outputs = {{label = "Mesh current I1", unit = "A"}, {label = "Mesh current I2", unit = "A"}},
        validate = function(v)
            if math.abs(v[1] * v[5] - v[2] * v[4]) < 1e-12 then return "Equations are singular" end
        end,
        calculate = function(v)
            local determinant = v[1] * v[5] - v[2] * v[4]
            return (v[3] * v[5] - v[2] * v[6]) / determinant,
                (v[1] * v[6] - v[3] * v[4]) / determinant
        end
    })
end
