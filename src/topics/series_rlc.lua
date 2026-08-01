-- Solve-by-Topic: Series RLC workspace.
-- Computes operating-point, power, and resonance quantities together.

local function topicNumber(value)
    if value == 0 then return "0" end
    local magnitude = math.abs(value)
    if magnitude >= 1e6 or magnitude < 1e-3 then
        return string.format("%.3e", value)
    end
    return string.format("%.4g", value)
end

local function packedFormat(value)
    return value
end

function registerTopicSolvers(calculators)
    calculators.topicSeriesRLC = Calculator.new({
        id = "topicSeriesRLC",
        title = "Series RLC Workspace",
        subtitle = "RMS source; computes operating point and resonance",
        inputs = {
            {label="Resistance R",unit="ohm"},
            {label="Inductance L",unit="H"},
            {label="Capacitance C",unit="F"},
            {label="Frequency f",unit="Hz"},
            {label="Source voltage RMS",unit="V"}
        },
        outputs = {
            {label="Reactance",format=packedFormat},
            {label="Impedance",format=packedFormat},
            {label="Current/power",format=packedFormat},
            {label="Resonance",format=packedFormat}
        },
        validate = function(v)
            if v[1] <= 0 then return "Resistance must be greater than zero" end
            if v[2] <= 0 then return "Inductance must be greater than zero" end
            if v[3] <= 0 then return "Capacitance must be greater than zero" end
            if v[4] <= 0 then return "Frequency must be greater than zero" end
            if v[5] < 0 then return "Source voltage cannot be negative" end
        end,
        calculate = function(v)
            local r,l,c,f,vrms=v[1],v[2],v[3],v[4],v[5]
            local w=2*math.pi*f
            local xl=w*l
            local xc=1/(w*c)
            local x=xl-xc
            local zmag=math.sqrt(r*r+x*x)
            local angle=math.atan2(x,r)*180/math.pi
            local imag=x
            local current=vrms/zmag
            local currentAngle=-angle
            local pf=r/zmag
            local realPower=current*current*r
            local reactivePower=current*current*x
            local apparentPower=vrms*current
            local f0=1/(2*math.pi*math.sqrt(l*c))
            local q=(2*math.pi*f0*l)/r
            local bandwidth=r/(2*math.pi*l)
            return
                "XL="..topicNumber(xl).." XC="..topicNumber(xc).." ohm",
                "Z="..topicNumber(r).."+j"..topicNumber(imag).." |Z|="..topicNumber(zmag).." @"..topicNumber(angle).."deg",
                "I="..topicNumber(current).."A @"..topicNumber(currentAngle).."deg PF="..topicNumber(pf).." P="..topicNumber(realPower).."W Q="..topicNumber(reactivePower).."var S="..topicNumber(apparentPower).."VA",
                "f0="..topicNumber(f0).."Hz Q="..topicNumber(q).." BW="..topicNumber(bandwidth).."Hz"
        end
    })
end
