-- Electromagnetics calculator definitions.

local EPSILON_0 = 8.854187817e-12
local COULOMB_K = 1 / (4 * math.pi * EPSILON_0)

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

local function requirePositive(value, name)
    if value <= 0 then return name .. " must be greater than zero" end
end

function registerElectromagneticsCalculators(calculators)
    -- General vector tools used throughout electromagnetics.
    calculators.vectorMagnitude = Calculator.new({
        id = "vectorMagnitude",
        title = "Vector Magnitude",
        subtitle = "Enter Cartesian components",
        inputs = vectorInputs("A"),
        outputs = {{label = "Magnitude"}},
        calculate = function(v)
            return vectors.magnitude(v[1], v[2], v[3])
        end
    })

    calculators.vectorUnit = Calculator.new({
        id = "vectorUnit",
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
        id = "vectorDot",
        title = "Dot Product",
        subtitle = "Calculate A dot B",
        inputs = twoVectorInputs(),
        outputs = {{label = "A dot B"}},
        calculate = function(v)
            return vectors.dot(v[1], v[2], v[3], v[4], v[5], v[6])
        end
    })

    calculators.vectorCross = Calculator.new({
        id = "vectorCross",
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
        id = "vectorAngle",
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
        id = "vectorProjection",
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

    -- Electrostatics.
    calculators.coulombsLaw = Calculator.new({
        id = "coulombsLaw",
        title = "Coulomb's Law",
        subtitle = "Signed radial force; + repulsive, - attractive",
        inputs = {
            {label = "Charge q1", unit = "C"},
            {label = "Charge q2", unit = "C"},
            {label = "Separation r", unit = "m"},
            {label = "Relative permittivity"}
        },
        outputs = {
            {label = "Radial force", unit = "N"},
            {label = "Magnitude", unit = "N"}
        },
        validate = function(v)
            return requirePositive(v[3], "Separation") or requirePositive(v[4], "Relative permittivity")
        end,
        calculate = function(v)
            local force = COULOMB_K * v[1] * v[2] / (v[4] * v[3] ^ 2)
            return force, math.abs(force)
        end
    })

    calculators.pointChargeField = Calculator.new({
        id = "pointChargeField",
        title = "Point-Charge Electric Field",
        subtitle = "Signed radial field from a point charge",
        inputs = {
            {label = "Source charge q", unit = "C"},
            {label = "Distance r", unit = "m"},
            {label = "Relative permittivity"}
        },
        outputs = {
            {label = "Radial E", unit = "V/m"},
            {label = "Magnitude", unit = "V/m"}
        },
        validate = function(v)
            return requirePositive(v[2], "Distance") or requirePositive(v[3], "Relative permittivity")
        end,
        calculate = function(v)
            local field = COULOMB_K * v[1] / (v[3] * v[2] ^ 2)
            return field, math.abs(field)
        end
    })

    calculators.pointChargePotential = Calculator.new({
        id = "pointChargePotential",
        title = "Electric Potential",
        subtitle = "Potential due to a point charge, zero at infinity",
        inputs = {
            {label = "Source charge q", unit = "C"},
            {label = "Distance r", unit = "m"},
            {label = "Relative permittivity"}
        },
        outputs = {{label = "Potential", unit = "V"}},
        validate = function(v)
            return requirePositive(v[2], "Distance") or requirePositive(v[3], "Relative permittivity")
        end,
        calculate = function(v)
            return COULOMB_K * v[1] / (v[3] * v[2])
        end
    })

    calculators.forceOnCharge = Calculator.new({
        id = "forceOnCharge",
        title = "Force on a Charge",
        subtitle = "Calculate F = qE in Cartesian components",
        inputs = {
            {label = "Charge q", unit = "C"},
            {label = "Ex", unit = "V/m"},
            {label = "Ey", unit = "V/m"},
            {label = "Ez", unit = "V/m"}
        },
        outputs = {
            {label = "Fx", unit = "N"},
            {label = "Fy", unit = "N"},
            {label = "Fz", unit = "N"},
            {label = "Magnitude", unit = "N"}
        },
        calculate = function(v)
            local fx, fy, fz = v[1] * v[2], v[1] * v[3], v[1] * v[4]
            return fx, fy, fz, vectors.magnitude(fx, fy, fz)
        end
    })

    calculators.gaussLaw = Calculator.new({
        id = "gaussLaw",
        title = "Gauss's Law",
        subtitle = "Electric flux through a closed surface",
        inputs = {
            {label = "Enclosed charge", unit = "C"},
            {label = "Relative permittivity"}
        },
        outputs = {{label = "Electric flux", unit = "V*m"}},
        validate = function(v)
            return requirePositive(v[2], "Relative permittivity")
        end,
        calculate = function(v)
            return v[1] / (EPSILON_0 * v[2])
        end
    })

    calculators.parallelPlateCapacitance = Calculator.new({
        id = "parallelPlateCapacitance",
        title = "Parallel-Plate Capacitance",
        subtitle = "Ideal plates with uniform dielectric",
        inputs = {
            {label = "Plate area", unit = "m^2"},
            {label = "Plate spacing", unit = "m"},
            {label = "Relative permittivity"}
        },
        outputs = {{label = "Capacitance", unit = "F"}},
        validate = function(v)
            return requirePositive(v[1], "Area") or requirePositive(v[2], "Spacing") or
                requirePositive(v[3], "Relative permittivity")
        end,
        calculate = function(v)
            return EPSILON_0 * v[3] * v[1] / v[2]
        end
    })
end
