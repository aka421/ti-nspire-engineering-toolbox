-- Linear-system calculators layered onto the circuit calculator registry.

local previousRegisterCircuitCalculators = registerCircuitCalculators

function registerCircuitCalculators(calculators)
    previousRegisterCircuitCalculators(calculators)

    calculators.meshThree = Calculator.new({
        id = "meshThree",
        title = "Three-Mesh Equation Solver",
        subtitle = "Enter coefficients row by row, including each source term",
        inputs = {
            {label = "a11", unit = "ohm"}, {label = "a12", unit = "ohm"}, {label = "a13", unit = "ohm"}, {label = "b1", unit = "V"},
            {label = "a21", unit = "ohm"}, {label = "a22", unit = "ohm"}, {label = "a23", unit = "ohm"}, {label = "b2", unit = "V"},
            {label = "a31", unit = "ohm"}, {label = "a32", unit = "ohm"}, {label = "a33", unit = "ohm"}, {label = "b3", unit = "V"}
        },
        outputs = {
            {label = "Mesh current I1", unit = "A"},
            {label = "Mesh current I2", unit = "A"},
            {label = "Mesh current I3", unit = "A"}
        },
        visibleInputCount = 5,
        validate = function(v)
            local matrix = {
                {v[1], v[2], v[3]},
                {v[5], v[6], v[7]},
                {v[9], v[10], v[11]}
            }
            local vector = {v[4], v[8], v[12]}
            local solution, err = linear.solve(matrix, vector)
            if not solution then return err end
        end,
        calculate = function(v)
            local matrix = {
                {v[1], v[2], v[3]},
                {v[5], v[6], v[7]},
                {v[9], v[10], v[11]}
            }
            local vector = {v[4], v[8], v[12]}
            local solution = linear.solve(matrix, vector)
            return solution[1], solution[2], solution[3]
        end
    })
end
