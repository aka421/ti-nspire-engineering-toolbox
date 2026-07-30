-- Electromagnetics calculator definitions.

local function vectorInputs(prefix)
    return {
        {label = prefix .. "x"},
        {label = prefix .. "y"},
        {label = prefix .. "z"}
    }
end

local function twoVectorInputs()
    return {
        {label = "Ax"}, {label = "Ay"}, {label = "Az"},
        {label = "Bx"}, {label = "By"}, {label = "Bz"}
    }
end

local function vectorOutputs(prefix)
    return {
        {label = prefix .. "x"},
        {label = prefix .. "y"},
        {label = prefix .. "z"}
    }
end

local function validateNonzeroVector(values, startIndex, name)
    local x, y, z = values[startIndex], values[startIndex + 1], values[startIndex + 2]
    if vectors.magnitude(x, y, z) == 0 then
        return name .. " cannot be the zero vector"
    end
end

function registerElectromagneticsCalculators(calculators)
    calculators.vectorMagnitude = Calculator.new({
        title = "Vector Magnitude",
        subtitle = "Enter Cartesian components",
        inputs = vectorInputs("A"),
        outputs = {{label = "Magnitude"}},
        calculate = function(v)
            return vectors.magnitude(v[1], v[2], v[3])
        end
    })

    calculators.vectorUnit = Calculator.new({
        title = "Unit Vector",
        subtitle = "Find a unit vector parallel to A",
        inputs = vectorInputs("A"),
        outputs = vectorOutputs("u"),
        validate = function(v)
            return validateNonzeroVector(v, 1, "A")
        end,
        calculate = function(v)
            return vectors.unit(v[1], v[2], v[3])
        end
    })

    calculators.vectorDot = Calculator.new({
        title = "Dot Product",
        subtitle = "Calculate A dot B",
        inputs = twoVectorInputs(),
        outputs = {{label = "A dot B"}},
        calculate = function(v)
            return vectors.dot(v[1], v[2], v[3], v[4], v[5], v[6])
        end
    })

    calculators.vectorCross = Calculator.new({
        title = "Cross Product",
        subtitle = "Calculate A x B",
        inputs = twoVectorInputs(),
        outputs = {
            {label = "Cx"}, {label = "Cy"}, {label = "Cz"},
            {label = "Magnitude"}
        },
        calculate = function(v)
            local x, y, z = vectors.cross(v[1], v[2], v[3], v[4], v[5], v[6])
            return x, y, z, vectors.magnitude(x, y, z)
        end
    })

    calculators.vectorAngle = Calculator.new({
        title = "Angle Between Vectors",
        subtitle = "Smallest angle from A to B",
        inputs = twoVectorInputs(),
        outputs = {{label = "Angle", unit = "degrees"}},
        validate = function(v)
            return validateNonzeroVector(v, 1, "A") or
                validateNonzeroVector(v, 4, "B")
        end,
        calculate = function(v)
            return vectors.angleDegrees(v[1], v[2], v[3], v[4], v[5], v[6])
        end
    })

    calculators.vectorProjection = Calculator.new({
        title = "Vector Projection",
        subtitle = "Projection of A onto B",
        inputs = twoVectorInputs(),
        outputs = vectorOutputs("P"),
        validate = function(v)
            return validateNonzeroVector(v, 4, "B")
        end,
        calculate = function(v)
            return vectors.projection(v[1], v[2], v[3], v[4], v[5], v[6])
        end
    })
end
