-- AC and RLC circuit calculators.

local function rlcPositive(value, name)
    if value <= 0 then return name .. " must be greater than zero" end
end

local function rlcDiv(ar, ai, br, bi)
    local d = br * br + bi * bi
    if d == 0 then error("complex division by zero") end
    return (ar * br + ai * bi) / d, (ai * br - ar * bi) / d
end

local function rlcMul(ar, ai, br, bi)
    return ar * br - ai * bi, ar * bi + ai * br
end

local function rlcPolar(magnitude, angleDegrees)
    local angle = angleDegrees * math.pi / 180
    return magnitude * math.cos(angle), magnitude * math.sin(angle)
end

local function rlcMagnitude(real, imag)
    return math.sqrt(real * real + imag * imag)
end

local function rlcAngle(real, imag)
    return math.atan2(imag, real) * 180 / math.pi
end

function registerRLCCalculators(calculators)
    calculators.rlcReactance = Calculator.new({
        id="rlcReactance", title="Inductive and Capacitive Reactance",
        inputs={{label="Frequency f",unit="Hz"},{label="Inductance L",unit="H"},{label="Capacitance C",unit="F"}},
        outputs={{label="Angular frequency",unit="rad/s"},{label="Inductive reactance XL",unit="ohm"},{label="Capacitive reactance XC",unit="ohm"}},
        validate=function(v) return rlcPositive(v[1],"Frequency") or rlcPositive(v[2],"Inductance") or rlcPositive(v[3],"Capacitance") end,
        calculate=function(v) local w=2*math.pi*v[1]; return w,w*v[2],1/(w*v[3]) end
    })

    calculators.seriesRLC = Calculator.new({
        id="seriesRLC", title="Series RLC Impedance",
        inputs={{label="Resistance R",unit="ohm"},{label="Inductance L",unit="H"},{label="Capacitance C",unit="F"},{label="Frequency f",unit="Hz"}},
        outputs={{label="Impedance real",unit="ohm"},{label="Impedance imag",unit="ohm"},{label="Magnitude",unit="ohm"},{label="Phase",unit="degrees"}},
        validate=function(v) if v[1] < 0 then return "Resistance cannot be negative" end; return rlcPositive(v[2],"Inductance") or rlcPositive(v[3],"Capacitance") or rlcPositive(v[4],"Frequency") end,
        calculate=function(v) local w=2*math.pi*v[4]; local x=w*v[2]-1/(w*v[3]); return v[1],x,rlcMagnitude(v[1],x),rlcAngle(v[1],x) end
    })

    calculators.parallelRLC = Calculator.new({
        id="parallelRLC", title="Parallel RLC Impedance",
        inputs={{label="Resistance R",unit="ohm"},{label="Inductance L",unit="H"},{label="Capacitance C",unit="F"},{label="Frequency f",unit="Hz"}},
        outputs={{label="Conductance G",unit="S"},{label="Susceptance B",unit="S"},{label="Impedance magnitude",unit="ohm"},{label="Impedance phase",unit="degrees"}},
        validate=function(v) return rlcPositive(v[1],"Resistance") or rlcPositive(v[2],"Inductance") or rlcPositive(v[3],"Capacitance") or rlcPositive(v[4],"Frequency") end,
        calculate=function(v)
            local w=2*math.pi*v[4]; local g=1/v[1]; local b=w*v[3]-1/(w*v[2]); local zr,zi=rlcDiv(1,0,g,b)
            return g,b,rlcMagnitude(zr,zi),rlcAngle(zr,zi)
        end
    })

    calculators.rlcResonance = Calculator.new({
        id="rlcResonance", title="RLC Resonance",
        inputs={{label="Inductance L",unit="H"},{label="Capacitance C",unit="F"}},
        outputs={{label="Resonant angular frequency",unit="rad/s"},{label="Resonant frequency",unit="Hz"},{label="Period",unit="s"}},
        validate=function(v) return rlcPositive(v[1],"Inductance") or rlcPositive(v[2],"Capacitance") end,
        calculate=function(v) local w=1/math.sqrt(v[1]*v[2]); return w,w/(2*math.pi),2*math.pi/w end
    })

    calculators.seriesRLCBandwidth = Calculator.new({
        id="seriesRLCBandwidth", title="Series RLC Q and Bandwidth",
        inputs={{label="Resistance R",unit="ohm"},{label="Inductance L",unit="H"},{label="Capacitance C",unit="F"}},
        outputs={{label="Quality factor Q"},{label="Bandwidth",unit="Hz"},{label="Lower half-power f1",unit="Hz"},{label="Upper half-power f2",unit="Hz"}},
        validate=function(v) return rlcPositive(v[1],"Resistance") or rlcPositive(v[2],"Inductance") or rlcPositive(v[3],"Capacitance") end,
        calculate=function(v)
            local root=math.sqrt(v[1]^2+4*v[2]/v[3]); local w1=(-v[1]+root)/(2*v[2]); local w2=(v[1]+root)/(2*v[2]); local w0=1/math.sqrt(v[2]*v[3])
            return w0*v[2]/v[1],(w2-w1)/(2*math.pi),w1/(2*math.pi),w2/(2*math.pi)
        end
    })

    calculators.parallelRLCBandwidth = Calculator.new({
        id="parallelRLCBandwidth", title="Parallel RLC Q and Bandwidth",
        subtitle="Ideal parallel R, L, and C",
        inputs={{label="Resistance R",unit="ohm"},{label="Inductance L",unit="H"},{label="Capacitance C",unit="F"}},
        outputs={{label="Quality factor Q"},{label="Resonant frequency",unit="Hz"},{label="Bandwidth",unit="Hz"}},
        validate=function(v) return rlcPositive(v[1],"Resistance") or rlcPositive(v[2],"Inductance") or rlcPositive(v[3],"Capacitance") end,
        calculate=function(v) local f0=1/(2*math.pi*math.sqrt(v[2]*v[3])); local q=v[1]*math.sqrt(v[3]/v[2]); return q,f0,f0/q end
    })

    calculators.acPower = Calculator.new({
        id="acPower", title="AC Complex Power",
        inputs={{label="Voltage RMS",unit="V"},{label="Current RMS",unit="A"},{label="Voltage-current phase",unit="degrees"}},
        outputs={{label="Real power P",unit="W"},{label="Reactive power Q",unit="var"},{label="Apparent power |S|",unit="VA"},{label="Power factor"}},
        validate=function(v) if v[1] < 0 or v[2] < 0 then return "RMS magnitudes cannot be negative" end end,
        calculate=function(v) local s=v[1]*v[2]; local a=v[3]*math.pi/180; return s*math.cos(a),s*math.sin(a),s,math.cos(a) end
    })

    calculators.acVoltageDivider = Calculator.new({
        id="acVoltageDivider", title="AC Voltage Divider",
        subtitle="Vout is across Z2",
        inputs={{label="Source magnitude",unit="V"},{label="Source phase",unit="degrees"},{label="Z1 resistance",unit="ohm"},{label="Z1 reactance",unit="ohm"},{label="Z2 resistance",unit="ohm"},{label="Z2 reactance",unit="ohm"}},
        outputs={{label="Vout real",unit="V"},{label="Vout imag",unit="V"},{label="Vout magnitude",unit="V"},{label="Vout phase",unit="degrees"}},
        validate=function(v) if v[1] < 0 then return "Source magnitude cannot be negative" end; if rlcMagnitude(v[3]+v[5],v[4]+v[6])==0 then return "Total impedance cannot be zero" end end,
        calculate=function(v)
            local sr,si=rlcPolar(v[1],v[2]); local rr,ri=rlcDiv(v[5],v[6],v[3]+v[5],v[4]+v[6]); local orr,oi=rlcMul(sr,si,rr,ri)
            return orr,oi,rlcMagnitude(orr,oi),rlcAngle(orr,oi)
        end
    })

    calculators.acCurrentDivider = Calculator.new({
        id="acCurrentDivider", title="AC Current Divider",
        subtitle="I1 is current through Z1",
        inputs={{label="Total current magnitude",unit="A"},{label="Total current phase",unit="degrees"},{label="Z1 resistance",unit="ohm"},{label="Z1 reactance",unit="ohm"},{label="Z2 resistance",unit="ohm"},{label="Z2 reactance",unit="ohm"}},
        outputs={{label="I1 real",unit="A"},{label="I1 imag",unit="A"},{label="I1 magnitude",unit="A"},{label="I1 phase",unit="degrees"}},
        validate=function(v) if v[1] < 0 then return "Current magnitude cannot be negative" end; if rlcMagnitude(v[3]+v[5],v[4]+v[6])==0 then return "Impedance sum cannot be zero" end end,
        calculate=function(v)
            local ir,ii=rlcPolar(v[1],v[2]); local rr,ri=rlcDiv(v[5],v[6],v[3]+v[5],v[4]+v[6]); local orr,oi=rlcMul(ir,ii,rr,ri)
            return orr,oi,rlcMagnitude(orr,oi),rlcAngle(orr,oi)
        end
    })
end
