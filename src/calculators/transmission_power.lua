-- Transmission-line time-average power calculator.
-- Voltage input is the RMS magnitude of the forward-traveling wave.

local previousRegisterTransmissionCalculators = registerTransmissionCalculators

function registerTransmissionCalculators(calculators)
    previousRegisterTransmissionCalculators(calculators)

    calculators.transmissionAveragePower = Calculator.new({
        id = "transmissionAveragePower",
        title = "Transmission-Line Average Power",
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
end
