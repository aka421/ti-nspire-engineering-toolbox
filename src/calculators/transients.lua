-- First- and second-order circuit transient calculators.

local function positive(v, i, name)
    if v[i] <= 0 then return name .. " must be greater than zero" end
end

local function nonnegative(v, i, name)
    if v[i] < 0 then return name .. " cannot be negative" end
end

function registerTransientCalculators(calculators)
    calculators.rcCharging = Calculator.new({
        id="rcCharging", title="RC Charging", inputs={{label="Resistance R",unit="ohm"},{label="Capacitance C",unit="F"},{label="Source voltage Vs",unit="V"},{label="Initial voltage V0",unit="V"},{label="Time t",unit="s"}},
        outputs={{label="Time constant",unit="s"},{label="Capacitor voltage",unit="V"},{label="Capacitor current",unit="A"},{label="Resistor voltage",unit="V"}},
        validate=function(v) return positive(v,1,"Resistance") or positive(v,2,"Capacitance") or nonnegative(v,5,"Time") end,
        calculate=function(v) local tau=v[1]*v[2]; local e=math.exp(-v[5]/tau); local vc=v[3]+(v[4]-v[3])*e; return tau,vc,(v[3]-v[4])*e/v[1],v[3]-vc end
    })

    calculators.rcDischarging = Calculator.new({
        id="rcDischarging", title="RC Discharging", inputs={{label="Resistance R",unit="ohm"},{label="Capacitance C",unit="F"},{label="Initial voltage V0",unit="V"},{label="Time t",unit="s"}},
        outputs={{label="Time constant",unit="s"},{label="Capacitor voltage",unit="V"},{label="Current magnitude",unit="A"},{label="Stored energy",unit="J"}},
        validate=function(v) return positive(v,1,"Resistance") or positive(v,2,"Capacitance") or nonnegative(v,4,"Time") end,
        calculate=function(v) local tau=v[1]*v[2]; local vc=v[3]*math.exp(-v[4]/tau); return tau,vc,math.abs(vc/v[1]),0.5*v[2]*vc*vc end
    })

    calculators.rlStep = Calculator.new({
        id="rlStep", title="RL Step Response", inputs={{label="Resistance R",unit="ohm"},{label="Inductance L",unit="H"},{label="Source voltage Vs",unit="V"},{label="Initial current I0",unit="A"},{label="Time t",unit="s"}},
        outputs={{label="Time constant",unit="s"},{label="Inductor current",unit="A"},{label="Inductor voltage",unit="V"},{label="Stored energy",unit="J"}},
        validate=function(v) return positive(v,1,"Resistance") or positive(v,2,"Inductance") or nonnegative(v,5,"Time") end,
        calculate=function(v) local tau=v[2]/v[1]; local inf=v[3]/v[1]; local e=math.exp(-v[5]/tau); local i=inf+(v[4]-inf)*e; return tau,i,v[3]-v[1]*i,0.5*v[2]*i*i end
    })

    calculators.rlDecay = Calculator.new({
        id="rlDecay", title="RL Current Decay", inputs={{label="Resistance R",unit="ohm"},{label="Inductance L",unit="H"},{label="Initial current I0",unit="A"},{label="Time t",unit="s"}},
        outputs={{label="Time constant",unit="s"},{label="Inductor current",unit="A"},{label="Inductor voltage magnitude",unit="V"},{label="Stored energy",unit="J"}},
        validate=function(v) return positive(v,1,"Resistance") or positive(v,2,"Inductance") or nonnegative(v,4,"Time") end,
        calculate=function(v) local tau=v[2]/v[1]; local i=v[3]*math.exp(-v[4]/tau); return tau,i,math.abs(v[1]*i),0.5*v[2]*i*i end
    })

    calculators.firstOrderResponse = Calculator.new({
        id="firstOrderResponse", title="Generic First-Order Response", subtitle="x(t)=xf+(x0-xf)e^(-t/tau)",
        inputs={{label="Initial value x0"},{label="Final value xf"},{label="Time constant tau",unit="s"},{label="Time t",unit="s"}},
        outputs={{label="Response x(t)"},{label="Exponential factor"},{label="Percent complete",unit="%"}},
        validate=function(v) return positive(v,3,"Time constant") or nonnegative(v,4,"Time") end,
        calculate=function(v) local e=math.exp(-v[4]/v[3]); return v[2]+(v[1]-v[2])*e,e,100*(1-e) end
    })

    calculators.firstOrderTime = Calculator.new({
        id="firstOrderTime", title="Time to Reach Value", subtitle="Solve x(t)=xf+(x0-xf)e^(-t/tau)",
        inputs={{label="Initial value x0"},{label="Final value xf"},{label="Target value x"},{label="Time constant tau",unit="s"}},
        outputs={{label="Time",unit="s"},{label="Time constants"}},
        validate=function(v) local ratio=(v[3]-v[2])/(v[1]-v[2]); if v[4]<=0 then return "Time constant must be greater than zero" end; if v[1]==v[2] then return "Initial and final values must differ" end; if ratio<=0 or ratio>1 then return "Target must lie between initial and final values" end end,
        calculate=function(v) local n=-math.log((v[3]-v[2])/(v[1]-v[2])); return n*v[4],n end
    })

    calculators.seriesRLCTransient = Calculator.new({
        id="seriesRLCTransient", title="Series RLC Transient Properties", inputs={{label="Resistance R",unit="ohm"},{label="Inductance L",unit="H"},{label="Capacitance C",unit="F"}},
        outputs={{label="Alpha",unit="1/s"},{label="Natural omega0",unit="rad/s"},{label="Damping ratio"},{label="Damped omega",unit="rad/s"}},
        validate=function(v) return nonnegative(v,1,"Resistance") or positive(v,2,"Inductance") or positive(v,3,"Capacitance") end,
        calculate=function(v) local a=v[1]/(2*v[2]); local w0=1/math.sqrt(v[2]*v[3]); local wd=math.sqrt(math.max(0,w0*w0-a*a)); return a,w0,a/w0,wd end
    })

    calculators.rlcNaturalRoots = Calculator.new({
        id="rlcNaturalRoots", title="RLC Natural Roots", inputs={{label="Resistance R",unit="ohm"},{label="Inductance L",unit="H"},{label="Capacitance C",unit="F"}},
        outputs={{label="s1 real",unit="1/s"},{label="s1 imag",unit="1/s"},{label="s2 real",unit="1/s"},{label="s2 imag",unit="1/s"}},
        validate=function(v) return nonnegative(v,1,"Resistance") or positive(v,2,"Inductance") or positive(v,3,"Capacitance") end,
        calculate=function(v) local a=v[1]/(2*v[2]); local w0=1/math.sqrt(v[2]*v[3]); local d=a*a-w0*w0; if d>=0 then local q=math.sqrt(d); return -a+q,0,-a-q,0 else local q=math.sqrt(-d); return -a,q,-a,-q end end
    })
end
