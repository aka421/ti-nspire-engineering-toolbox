-- Linear-system calculators layered onto the circuit calculator registry.

local previousRegisterCircuitCalculators = registerCircuitCalculators

local function solveTwo(v)
    return linear.solve({{v[1], v[2]}, {v[4], v[5]}}, {v[3], v[6]})
end

local function solveThree(v)
    return linear.solve({
        {v[1], v[2], v[3]},
        {v[5], v[6], v[7]},
        {v[9], v[10], v[11]}
    }, {v[4], v[8], v[12]})
end

local function validateTwo(v)
    local solution, err = solveTwo(v)
    if not solution then return err end
end

local function validateThree(v)
    local solution, err = solveThree(v)
    if not solution then return err end
end

local function twoSystemInputs(coefficientUnit, sourceUnit)
    return {
        {label = "a11", unit = coefficientUnit}, {label = "a12", unit = coefficientUnit}, {label = "b1", unit = sourceUnit},
        {label = "a21", unit = coefficientUnit}, {label = "a22", unit = coefficientUnit}, {label = "b2", unit = sourceUnit}
    }
end

local function threeSystemInputs(coefficientUnit, sourceUnit)
    return {
        {label = "a11", unit = coefficientUnit}, {label = "a12", unit = coefficientUnit}, {label = "a13", unit = coefficientUnit}, {label = "b1", unit = sourceUnit},
        {label = "a21", unit = coefficientUnit}, {label = "a22", unit = coefficientUnit}, {label = "a23", unit = coefficientUnit}, {label = "b2", unit = sourceUnit},
        {label = "a31", unit = coefficientUnit}, {label = "a32", unit = coefficientUnit}, {label = "a33", unit = coefficientUnit}, {label = "b3", unit = sourceUnit}
    }
end

function registerCircuitCalculators(calculators)
    previousRegisterCircuitCalculators(calculators)

    calculators.meshThree = Calculator.new({
        id = "meshThree",
        title = "Three-Mesh Equation Solver",
        subtitle = "Enter coefficients row by row, including each source term",
        inputs = threeSystemInputs("ohm", "V"),
        outputs = {
            {label = "Mesh current I1", unit = "A"},
            {label = "Mesh current I2", unit = "A"},
            {label = "Mesh current I3", unit = "A"}
        },
        visibleInputCount = 5,
        validate = validateThree,
        calculate = function(v)
            local solution = solveThree(v)
            return solution[1], solution[2], solution[3]
        end
    })

    calculators.nodeTwo = Calculator.new({
        id = "nodeTwo",
        title = "Two-Node Equation Solver",
        subtitle = "a11 V1 + a12 V2 = b1; a21 V1 + a22 V2 = b2",
        inputs = twoSystemInputs("S", "A"),
        outputs = {
            {label = "Node voltage V1", unit = "V"},
            {label = "Node voltage V2", unit = "V"}
        },
        validate = validateTwo,
        calculate = function(v)
            local solution = solveTwo(v)
            return solution[1], solution[2]
        end
    })

    calculators.nodeThree = Calculator.new({
        id = "nodeThree",
        title = "Three-Node Equation Solver",
        subtitle = "Enter conductance coefficients and current terms row by row",
        inputs = threeSystemInputs("S", "A"),
        outputs = {
            {label = "Node voltage V1", unit = "V"},
            {label = "Node voltage V2", unit = "V"},
            {label = "Node voltage V3", unit = "V"}
        },
        visibleInputCount = 5,
        validate = validateThree,
        calculate = function(v)
            local solution = solveThree(v)
            return solution[1], solution[2], solution[3]
        end
    })

    calculators.linearSystemTwo = Calculator.new({
        id = "linearSystemTwo",
        title = "2x2 Linear System",
        subtitle = "Solve A x = b using Gaussian elimination",
        inputs = twoSystemInputs("", ""),
        outputs = {{label = "x1"}, {label = "x2"}},
        validate = validateTwo,
        calculate = function(v)
            local solution = solveTwo(v)
            return solution[1], solution[2]
        end
    })

    calculators.linearSystemThree = Calculator.new({
        id = "linearSystemThree",
        title = "3x3 Linear System",
        subtitle = "Solve A x = b using Gaussian elimination",
        inputs = threeSystemInputs("", ""),
        outputs = {{label = "x1"}, {label = "x2"}, {label = "x3"}},
        visibleInputCount = 5,
        validate = validateThree,
        calculate = function(v)
            local solution = solveThree(v)
            return solution[1], solution[2], solution[3]
        end
    })
end
