-- Solve-by-Topic: Series RLC workspace.
-- Computes operating-point, power, and resonance quantities together.

function registerTopicSolvers(calculators)
    calculators.topicSeriesRLC = Calculator.new({
        id = "topicSeriesRLC",
        title = "Series RLC Workspace",
        subtitle = "RMS source; computes operating point and resonance",
        visibleResultCount = 5,
        inputs = {
            {label="Resistance R",unit="ohm"},
            {label="Inductance L",unit="H"},
            {label="Capacitance C",unit="F"},
            {label="Frequency f",unit="Hz"},
            {label="Source voltage RMS",unit="V"}
        },
        outputs = {
            {label="Inductive reactance XL",unit="ohm"},
            {label="Capacitive reactance XC",unit="ohm"},
            {label="Net reactance X",unit="ohm"},
            {label="Impedance real",unit="ohm"},
            {label="Impedance imaginary",unit="ohm"},
            {label="Impedance magnitude",unit="ohm"},
            {label="Impedance phase",unit="degrees"},
            {label="Current magnitude",unit="A"},
            {label="Current phase",unit="degrees"},
            {label="Power factor"},
            {label="Real power P",unit="W"},
            {label="Reactive power Q",unit="var"},
            {label="Apparent power S",unit="VA"},
            {label="Resonant frequency",unit="Hz"},
            {label="Quality factor"},
            {label="Bandwidth",unit="Hz"}
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
            local current=vrms/zmag
            local currentAngle=-angle
            local pf=r/zmag
            local realPower=current*current*r
            local reactivePower=current*current*x
            local apparentPower=vrms*current
            local f0=1/(2*math.pi*math.sqrt(l*c))
            local q=(2*math.pi*f0*l)/r
            local bandwidth=r/(2*math.pi*l)

            return xl,xc,x,r,x,zmag,angle,current,currentAngle,pf,
                realPower,reactivePower,apparentPower,f0,q,bandwidth
        end
    })
end
