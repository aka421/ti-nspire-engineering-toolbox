-- Lossless transmission-line calculator definitions.

local function tlRequirePositive(value, name)
    if value <= 0 then return name .. " must be greater than zero" end
end

local function cAdd(ar, ai, br, bi) return ar + br, ai + bi end
local function cSub(ar, ai, br, bi) return ar - br, ai - bi end
local function cMul(ar, ai, br, bi) return ar * br - ai * bi, ar * bi + ai * br end
local function cDiv(ar, ai, br, bi)
    local denominator = br * br + bi * bi
    if denominator == 0 then error("complex division by zero") end
    return (ar * br + ai * bi) / denominator, (ai * br - ar * bi) / denominator
end
local function cMagnitude(r, i) return math.sqrt(r * r + i * i) end
local function cAngleDegrees(r, i) return math.atan2(i, r) * 180 / math.pi end

function registerTransmissionCalculators(calculators)
    calculators.reflectionCoefficient = Calculator.new({
        id = "reflectionCoefficient",
        title = "Reflection Coefficient",
        subtitle = "Gamma = (ZL - Z0)/(ZL + Z0)",
        inputs = {
            {label = "Load resistance", unit = "ohm"},
            {label = "Load reactance", unit = "ohm"},
            {label = "Characteristic Z0", unit = "ohm"}
        },
        outputs = {
            {label = "Gamma real"},
            {label = "Gamma imag"},
            {label = "Magnitude"},
            {label = "Angle", unit = "degrees"}
        },
        validate = function(v) return tlRequirePositive(v[3], "Characteristic impedance") end,
        calculate = function(v)
            local nr, ni = cSub(v[1], v[2], v[3], 0)
            local dr, di = cAdd(v[1], v[2], v[3], 0)
            local gr, gi = cDiv(nr, ni, dr, di)
            return gr, gi, cMagnitude(gr, gi), cAngleDegrees(gr, gi)
        end
    })

    calculators.loadFromReflection = Calculator.new({
        id = "loadFromReflection",
        title = "Load from Reflection Coefficient",
        subtitle = "ZL = Z0(1 + Gamma)/(1 - Gamma)",
        inputs = {
            {label = "Gamma real"},
            {label = "Gamma imag"},
            {label = "Characteristic Z0", unit = "ohm"}
        },
        outputs = {
            {label = "Load resistance", unit = "ohm"},
            {label = "Load reactance", unit = "ohm"},
            {label = "Load magnitude", unit = "ohm"},
            {label = "Load angle", unit = "degrees"}
        },
        validate = function(v)
            return tlRequirePositive(v[3], "Characteristic impedance")
        end,
        calculate = function(v)
            local nr, ni = 1 + v[1], v[2]
            local dr, di = 1 - v[1], -v[2]
            local zr, zi = cDiv(nr, ni, dr, di)
            zr, zi = v[3] * zr, v[3] * zi
            return zr, zi, cMagnitude(zr, zi), cAngleDegrees(zr, zi)
        end
    })

    calculators.vswr = Calculator.new({
        id = "vswr",
        title = "VSWR",
        subtitle = "VSWR = (1 + |Gamma|)/(1 - |Gamma|)",
        inputs = {{label = "Reflection magnitude"}},
        outputs = {{label = "VSWR"}},
        validate = function(v)
            if v[1] < 0 or v[1] >= 1 then return "Reflection magnitude must be from 0 to less than 1" end
        end,
        calculate = function(v) return (1 + v[1]) / (1 - v[1]) end
    })

    calculators.returnLoss = Calculator.new({
        id = "returnLoss",
        title = "Return and Mismatch Loss",
        subtitle = "Losses from reflection coefficient magnitude",
        inputs = {{label = "Reflection magnitude"}},
        outputs = {
            {label = "Return loss", unit = "dB"},
            {label = "Mismatch loss", unit = "dB"},
            {label = "Reflected power", unit = "%"},
            {label = "Delivered power", unit = "%"}
        },
        validate = function(v)
            if v[1] < 0 or v[1] >= 1 then return "Reflection magnitude must be from 0 to less than 1" end
        end,
        calculate = function(v)
            local g2 = v[1] ^ 2
            local returnLoss = v[1] == 0 and 1e99 or -20 * math.log(v[1]) / math.log(10)
            local mismatchLoss = -10 * math.log(1 - g2) / math.log(10)
            return returnLoss, mismatchLoss, 100 * g2, 100 * (1 - g2)
        end
    })

    calculators.losslessInputImpedance = Calculator.new({
        id = "losslessInputImpedance",
        title = "Input Impedance",
        subtitle = "Lossless line: Zin at distance l from load",
        inputs = {
            {label = "Load resistance", unit = "ohm"},
            {label = "Load reactance", unit = "ohm"},
            {label = "Characteristic Z0", unit = "ohm"},
            {label = "Phase constant beta", unit = "rad/m"},
            {label = "Line length l", unit = "m"}
        },
        outputs = {
            {label = "Input resistance", unit = "ohm"},
            {label = "Input reactance", unit = "ohm"},
            {label = "Input magnitude", unit = "ohm"},
            {label = "Input angle", unit = "degrees"}
        },
        validate = function(v)
            return tlRequirePositive(v[3], "Characteristic impedance") or
                tlRequirePositive(v[4], "Phase constant") or
                (v[5] < 0 and "Line length cannot be negative" or nil)
        end,
        calculate = function(v)
            local tangent = math.tan(v[4] * v[5])
            local nr, ni = v[1], v[2] + v[3] * tangent
            local zrT, ziT = cMul(v[1], v[2], 0, tangent)
            local dr, di = v[3] + zrT, ziT
            local rr, ri = cDiv(nr, ni, dr, di)
            rr, ri = v[3] * rr, v[3] * ri
            return rr, ri, cMagnitude(rr, ri), cAngleDegrees(rr, ri)
        end
    })

    calculators.quarterWaveTransformer = Calculator.new({
        id = "quarterWaveTransformer",
        title = "Quarter-Wave Transformer",
        subtitle = "Match two positive real impedances",
        inputs = {
            {label = "Source line Z0", unit = "ohm"},
            {label = "Load resistance", unit = "ohm"},
            {label = "Frequency f", unit = "Hz"},
            {label = "Wave velocity", unit = "m/s"}
        },
        outputs = {
            {label = "Transformer impedance", unit = "ohm"},
            {label = "Quarter-wave length", unit = "m"},
            {label = "Wavelength", unit = "m"}
        },
        validate = function(v)
            return tlRequirePositive(v[1], "Source impedance") or
                tlRequirePositive(v[2], "Load resistance") or
                tlRequirePositive(v[3], "Frequency") or
                tlRequirePositive(v[4], "Wave velocity")
        end,
        calculate = function(v)
            local wavelength = v[4] / v[3]
            return math.sqrt(v[1] * v[2]), wavelength / 4, wavelength
        end
    })

    calculators.electricalLength = Calculator.new({
        id = "electricalLength",
        title = "Electrical Length",
        subtitle = "Convert physical length to phase",
        inputs = {
            {label = "Line length", unit = "m"},
            {label = "Frequency f", unit = "Hz"},
            {label = "Wave velocity", unit = "m/s"}
        },
        outputs = {
            {label = "Electrical length", unit = "degrees"},
            {label = "Electrical length", unit = "rad"},
            {label = "Wavelengths"},
            {label = "Wavelength", unit = "m"}
        },
        validate = function(v)
            if v[1] < 0 then return "Line length cannot be negative" end
            return tlRequirePositive(v[2], "Frequency") or tlRequirePositive(v[3], "Wave velocity")
        end,
        calculate = function(v)
            local wavelength = v[3] / v[2]
            local cycles = v[1] / wavelength
            return 360 * cycles, 2 * math.pi * cycles, cycles, wavelength
        end
    })
end
