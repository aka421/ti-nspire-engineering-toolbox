-- Transmission-line time-average power calculators.

local previousRegisterTransmissionCalculators = registerTransmissionCalculators

function registerTransmissionCalculators(calculators)
    previousRegisterTransmissionCalculators(calculators)

    -- Use this version when the forward-traveling RMS voltage is known.
    calculators.transmissionAveragePower = Calculator.new({
        id = "transmissionAveragePower",
        title = "Power from Forward Voltage",
        subtitle = "Lossless line; forward voltage is RMS magnitude",
        inputs = {
            {label = "Forward voltage V0+ RMS", unit = "V"},
            {label = "Characteristic Z0", unit = "ohm"},
            {label = "Reflection magnitude |Gamma|"}
        },
        outputs = {
            {label = "Incident average power", unit = "W"},
            {label = "Reflected average power", unit = "W"},
            {label = "Load average power", unit = "W"},
            {label = "Power delivered", unit = "%"}
        },
        validate = function(v)
            if v[1] < 0 then return "Forward voltage cannot be negative" end
            if v[2] <= 0 then return "Characteristic impedance must be greater than zero" end
            if v[3] < 0 or v[3] > 1 then return "Reflection magnitude must be from 0 to 1" end
        end,
        calculate = function(v)
            local incident = v[1] * v[1] / v[2]
            local reflected = incident * v[3] * v[3]
            local load = incident - reflected
            return incident, reflected, load, 100 * (1 - v[3] * v[3])
        end
    })

    -- Use this version when a peak load-voltage magnitude is measured, as in
    -- ECE 216 Assignment 8 Question 5. Peak phasors require the factor 1/2.
    calculators.transmissionPowerFromLoadVoltage = Calculator.new({
        id = "transmissionPowerFromLoadVoltage",
        title = "Power from Load Voltage",
        subtitle = "Lossless line; load voltage is peak magnitude",
        inputs = {
            {label = "Load voltage |VL| peak", unit = "V"},
            {label = "Load resistance RL", unit = "ohm"},
            {label = "Load reactance XL", unit = "ohm"},
            {label = "Characteristic Z0", unit = "ohm"}
        },
        outputs = {
            {label = "Incident average power", unit = "W"},
            {label = "Reflected average power", unit = "W"},
            {label = "Load average power", unit = "W"},
            {label = "Recovered |V0+| peak", unit = "V"}
        },
        validate = function(v)
            if v[1] < 0 then return "Load voltage cannot be negative" end
            if v[2] < 0 then return "Load resistance cannot be negative" end
            if v[4] <= 0 then return "Characteristic impedance must be greater than zero" end
            if v[2] == 0 and v[3] == 0 then return "Load impedance cannot be zero" end
        end,
        calculate = function(v)
            local vl = v[1]
            local rl = v[2]
            local xl = v[3]
            local z0 = v[4]

            -- Gamma_L = (ZL - Z0)/(ZL + Z0)
            local numeratorReal = rl - z0
            local numeratorImag = xl
            local denominatorReal = rl + z0
            local denominatorImag = xl
            local denominatorMagnitudeSquared = denominatorReal * denominatorReal + denominatorImag * denominatorImag
            local gammaReal = (numeratorReal * denominatorReal + numeratorImag * denominatorImag) / denominatorMagnitudeSquared
            local gammaImag = (numeratorImag * denominatorReal - numeratorReal * denominatorImag) / denominatorMagnitudeSquared
            local gammaMagnitudeSquared = gammaReal * gammaReal + gammaImag * gammaImag

            -- VL = V0+ (1 + Gamma_L)
            local onePlusGammaMagnitude = math.sqrt((1 + gammaReal) * (1 + gammaReal) + gammaImag * gammaImag)
            local vForwardPeak = vl / onePlusGammaMagnitude

            local incident = vForwardPeak * vForwardPeak / (2 * z0)
            local reflected = incident * gammaMagnitudeSquared
            local load = incident - reflected
            return incident, reflected, load, vForwardPeak
        end
    })
end
