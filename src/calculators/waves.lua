-- Electromagnetic wave calculator definitions.

local WAVE_EPSILON_0 = 8.854187817e-12
local WAVE_MU_0 = 4e-7 * math.pi
local C_0 = 1 / math.sqrt(WAVE_MU_0 * WAVE_EPSILON_0)
local ETA_0 = math.sqrt(WAVE_MU_0 / WAVE_EPSILON_0)

local function waveRequirePositive(value, name)
    if value <= 0 then return name .. " must be greater than zero" end
end

local function waveValidateMaterial(v, erIndex, mrIndex)
    return waveRequirePositive(v[erIndex], "Relative permittivity") or
        waveRequirePositive(v[mrIndex], "Relative permeability")
end

function registerWaveCalculators(calculators)
    calculators.waveSpeed = Calculator.new({
        id = "waveSpeed",
        title = "Wave Speed",
        subtitle = "Lossless homogeneous medium",
        inputs = {
            {label = "Relative permittivity"},
            {label = "Relative permeability"}
        },
        outputs = {{label = "Wave speed", unit = "m/s"}},
        validate = function(v) return waveValidateMaterial(v, 1, 2) end,
        calculate = function(v) return C_0 / math.sqrt(v[1] * v[2]) end
    })

    calculators.intrinsicImpedance = Calculator.new({
        id = "intrinsicImpedance",
        title = "Intrinsic Impedance",
        subtitle = "Lossless homogeneous medium",
        inputs = {
            {label = "Relative permittivity"},
            {label = "Relative permeability"}
        },
        outputs = {{label = "Intrinsic impedance", unit = "ohm"}},
        validate = function(v) return waveValidateMaterial(v, 1, 2) end,
        calculate = function(v) return ETA_0 * math.sqrt(v[2] / v[1]) end
    })

    calculators.waveWavelength = Calculator.new({
        id = "waveWavelength",
        title = "Wavelength",
        subtitle = "lambda = v/f for a lossless medium",
        inputs = {
            {label = "Frequency f", unit = "Hz"},
            {label = "Relative permittivity"},
            {label = "Relative permeability"}
        },
        outputs = {
            {label = "Wavelength", unit = "m"},
            {label = "Wave speed", unit = "m/s"},
            {label = "Phase constant", unit = "rad/m"}
        },
        validate = function(v)
            return waveRequirePositive(v[1], "Frequency") or waveValidateMaterial(v, 2, 3)
        end,
        calculate = function(v)
            local speed = C_0 / math.sqrt(v[2] * v[3])
            local wavelength = speed / v[1]
            return wavelength, speed, 2 * math.pi / wavelength
        end
    })

    calculators.lossyPropagation = Calculator.new({
        id = "lossyPropagation",
        title = "Propagation Constant",
        subtitle = "General lossy homogeneous medium",
        inputs = {
            {label = "Frequency f", unit = "Hz"},
            {label = "Conductivity sigma", unit = "S/m"},
            {label = "Relative permittivity"},
            {label = "Relative permeability"}
        },
        outputs = {
            {label = "Attenuation alpha", unit = "Np/m"},
            {label = "Phase beta", unit = "rad/m"},
            {label = "Wavelength", unit = "m"},
            {label = "Phase velocity", unit = "m/s"}
        },
        validate = function(v)
            if v[2] < 0 then return "Conductivity cannot be negative" end
            return waveRequirePositive(v[1], "Frequency") or waveValidateMaterial(v, 3, 4)
        end,
        calculate = function(v)
            local omega = 2 * math.pi * v[1]
            local epsilon = WAVE_EPSILON_0 * v[3]
            local mu = WAVE_MU_0 * v[4]
            local ratio = v[2] / (omega * epsilon)
            local root = math.sqrt(1 + ratio ^ 2)
            local common = omega * math.sqrt(mu * epsilon / 2)
            local alpha = common * math.sqrt(root - 1)
            local beta = common * math.sqrt(root + 1)
            return alpha, beta, 2 * math.pi / beta, omega / beta
        end
    })

    calculators.skinDepth = Calculator.new({
        id = "skinDepth",
        title = "Skin Depth",
        subtitle = "Good-conductor approximation",
        inputs = {
            {label = "Frequency f", unit = "Hz"},
            {label = "Conductivity sigma", unit = "S/m"},
            {label = "Relative permeability"}
        },
        outputs = {
            {label = "Skin depth", unit = "m"},
            {label = "Attenuation alpha", unit = "Np/m"}
        },
        validate = function(v)
            return waveRequirePositive(v[1], "Frequency") or
                waveRequirePositive(v[2], "Conductivity") or
                waveRequirePositive(v[3], "Relative permeability")
        end,
        calculate = function(v)
            local delta = math.sqrt(2 / (2 * math.pi * v[1] * WAVE_MU_0 * v[3] * v[2]))
            return delta, 1 / delta
        end
    })

    calculators.powerDensity = Calculator.new({
        id = "powerDensity",
        title = "Plane-Wave Power Density",
        subtitle = "Time-average power from peak electric field",
        inputs = {
            {label = "Peak electric field", unit = "V/m"},
            {label = "Relative permittivity"},
            {label = "Relative permeability"}
        },
        outputs = {
            {label = "Power density", unit = "W/m^2"},
            {label = "Intrinsic impedance", unit = "ohm"},
            {label = "Peak magnetic field", unit = "A/m"}
        },
        validate = function(v) return waveValidateMaterial(v, 2, 3) end,
        calculate = function(v)
            local eta = ETA_0 * math.sqrt(v[3] / v[2])
            return v[1] ^ 2 / (2 * eta), eta, v[1] / eta
        end
    })
end
