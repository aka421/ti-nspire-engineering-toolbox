-- Coordinate-system calculator definitions.

local function validateNonnegative(value, name)
    if value < 0 then return name .. " cannot be negative" end
end

local function validateTheta(value)
    if value < 0 or value > 180 then
        return "Theta must be between 0 and 180 degrees"
    end
end

function registerCoordinateCalculators(calculators)
    calculators.cartesianToCylindrical = Calculator.new({
        title = "Cartesian to Cylindrical",
        subtitle = "phi is measured from +x toward +y",
        inputs = {{label = "x"}, {label = "y"}, {label = "z"}},
        outputs = {
            {label = "rho"},
            {label = "phi", unit = "degrees"},
            {label = "z"}
        },
        calculate = function(v)
            return coordinates.cartesianToCylindrical(v[1], v[2], v[3])
        end
    })

    calculators.cylindricalToCartesian = Calculator.new({
        title = "Cylindrical to Cartesian",
        subtitle = "phi is entered in degrees",
        inputs = {
            {label = "rho"},
            {label = "phi", unit = "degrees"},
            {label = "z"}
        },
        outputs = {{label = "x"}, {label = "y"}, {label = "z"}},
        validate = function(v)
            return validateNonnegative(v[1], "rho")
        end,
        calculate = function(v)
            return coordinates.cylindricalToCartesian(v[1], v[2], v[3])
        end
    })

    calculators.cartesianToSpherical = Calculator.new({
        title = "Cartesian to Spherical",
        subtitle = "theta from +z; phi from +x",
        inputs = {{label = "x"}, {label = "y"}, {label = "z"}},
        outputs = {
            {label = "r"},
            {label = "theta", unit = "degrees"},
            {label = "phi", unit = "degrees"}
        },
        calculate = function(v)
            return coordinates.cartesianToSpherical(v[1], v[2], v[3])
        end
    })

    calculators.sphericalToCartesian = Calculator.new({
        title = "Spherical to Cartesian",
        subtitle = "theta from +z; phi from +x",
        inputs = {
            {label = "r"},
            {label = "theta", unit = "degrees"},
            {label = "phi", unit = "degrees"}
        },
        outputs = {{label = "x"}, {label = "y"}, {label = "z"}},
        validate = function(v)
            return validateNonnegative(v[1], "r") or validateTheta(v[2])
        end,
        calculate = function(v)
            return coordinates.sphericalToCartesian(v[1], v[2], v[3])
        end
    })

    calculators.cylindricalVectorToCartesian = Calculator.new({
        title = "Cylindrical Vector to Cartesian",
        subtitle = "Enter vector components and point angle",
        inputs = {
            {label = "A rho"},
            {label = "A phi"},
            {label = "A z"},
            {label = "phi", unit = "degrees"}
        },
        outputs = {{label = "Ax"}, {label = "Ay"}, {label = "Az"}},
        calculate = function(v)
            return coordinates.cylindricalVectorToCartesian(v[1], v[2], v[3], v[4])
        end
    })

    calculators.sphericalVectorToCartesian = Calculator.new({
        title = "Spherical Vector to Cartesian",
        subtitle = "theta from +z; phi from +x",
        inputs = {
            {label = "A r"},
            {label = "A theta"},
            {label = "A phi"},
            {label = "theta", unit = "degrees"},
            {label = "phi", unit = "degrees"}
        },
        outputs = {{label = "Ax"}, {label = "Ay"}, {label = "Az"}},
        validate = function(v)
            return validateTheta(v[4])
        end,
        calculate = function(v)
            return coordinates.sphericalVectorToCartesian(v[1], v[2], v[3], v[4], v[5])
        end
    })
end
