-- Mechanical-vibration calculator definitions.

local function vibPositive(value, name)
    if value <= 0 then return name .. " must be greater than zero" end
end

local function vibNonnegative(value, name)
    if value < 0 then return name .. " cannot be negative" end
end

local function vibrationParameters(m, k, c)
    local wn = math.sqrt(k / m)
    local cc = 2 * math.sqrt(k * m)
    local zeta = c / cc
    local wd = zeta < 1 and wn * math.sqrt(1 - zeta * zeta) or 0
    return wn, cc, zeta, wd
end

function registerVibrationCalculators(calculators)
    calculators.naturalFrequency = Calculator.new({
        id="naturalFrequency", title="Undamped Natural Frequency",
        subtitle="Single-degree-of-freedom spring-mass system",
        inputs={{label="Mass m",unit="kg"},{label="Stiffness k",unit="N/m"}},
        outputs={{label="Angular frequency",unit="rad/s"},{label="Natural frequency",unit="Hz"},{label="Natural period",unit="s"}},
        validate=function(v) return vibPositive(v[1],"Mass") or vibPositive(v[2],"Stiffness") end,
        calculate=function(v)
            local wn=math.sqrt(v[2]/v[1])
            return wn,wn/(2*math.pi),2*math.pi/wn
        end
    })

    calculators.dampingProperties = Calculator.new({
        id="dampingProperties", title="Damping Properties",
        subtitle="Viscously damped spring-mass system",
        inputs={{label="Mass m",unit="kg"},{label="Stiffness k",unit="N/m"},{label="Damping c",unit="N*s/m"}},
        outputs={{label="Critical damping",unit="N*s/m"},{label="Damping ratio"},{label="Damped frequency",unit="rad/s"},{label="Decay rate",unit="1/s"}},
        validate=function(v) return vibPositive(v[1],"Mass") or vibPositive(v[2],"Stiffness") or vibNonnegative(v[3],"Damping") end,
        calculate=function(v)
            local wn,cc,zeta,wd=vibrationParameters(v[1],v[2],v[3])
            return cc,zeta,wd,zeta*wn
        end
    })

    calculators.logarithmicDecrement = Calculator.new({
        id="logarithmicDecrement", title="Logarithmic Decrement",
        subtitle="Use amplitudes separated by N cycles",
        inputs={{label="Earlier amplitude x1"},{label="Later amplitude xN"},{label="Number of cycles N"}},
        outputs={{label="Logarithmic decrement"},{label="Damping ratio"}},
        validate=function(v)
            return vibPositive(math.abs(v[1]),"Earlier amplitude magnitude") or
                vibPositive(math.abs(v[2]),"Later amplitude magnitude") or
                vibPositive(v[3],"Number of cycles") or
                (math.abs(v[1])<=math.abs(v[2]) and "Earlier amplitude must exceed later amplitude" or nil)
        end,
        calculate=function(v)
            local delta=math.log(math.abs(v[1]/v[2]))/v[3]
            local zeta=delta/math.sqrt(4*math.pi*math.pi+delta*delta)
            return delta,zeta
        end
    })

    calculators.underdampedFreeResponse = Calculator.new({
        id="underdampedFreeResponse", title="Underdamped Free Response",
        subtitle="Displacement and velocity at time t",
        inputs={{label="Mass m",unit="kg"},{label="Stiffness k",unit="N/m"},{label="Damping c",unit="N*s/m"},{label="Initial displacement x0",unit="m"},{label="Initial velocity v0",unit="m/s"},{label="Time t",unit="s"}},
        outputs={{label="Displacement x",unit="m"},{label="Velocity v",unit="m/s"},{label="Damped frequency",unit="rad/s"}}, visibleInputCount=5,
        validate=function(v)
            local err=vibPositive(v[1],"Mass") or vibPositive(v[2],"Stiffness") or vibNonnegative(v[3],"Damping") or vibNonnegative(v[6],"Time")
            if err then return err end
            local _,_,zeta=vibrationParameters(v[1],v[2],v[3])
            if zeta>=1 then return "System must be underdamped (zeta < 1)" end
        end,
        calculate=function(v)
            local wn,_,zeta,wd=vibrationParameters(v[1],v[2],v[3])
            local a=zeta*wn
            local A=v[4]
            local B=(v[5]+a*v[4])/wd
            local e=math.exp(-a*v[6])
            local c=math.cos(wd*v[6]); local s=math.sin(wd*v[6])
            local x=e*(A*c+B*s)
            local velocity=e*((-a*A+wd*B)*c+(-a*B-wd*A)*s)
            return x,velocity,wd
        end
    })

    calculators.harmonicForceResponse = Calculator.new({
        id="harmonicForceResponse", title="Harmonic Force Response",
        subtitle="Steady-state response to F0 cos(omega t)",
        inputs={{label="Force amplitude F0",unit="N"},{label="Mass m",unit="kg"},{label="Damping c",unit="N*s/m"},{label="Stiffness k",unit="N/m"},{label="Forcing frequency",unit="rad/s"}},
        outputs={{label="Displacement amplitude",unit="m"},{label="Phase lag",unit="degrees"},{label="Frequency ratio r"},{label="Dynamic magnification"}},
        validate=function(v) return vibNonnegative(v[1],"Force amplitude") or vibPositive(v[2],"Mass") or vibNonnegative(v[3],"Damping") or vibPositive(v[4],"Stiffness") or vibNonnegative(v[5],"Forcing frequency") end,
        calculate=function(v)
            local wn,_,zeta=vibrationParameters(v[2],v[4],v[3])
            local r=v[5]/wn
            local denominator=math.sqrt((1-r*r)^2+(2*zeta*r)^2)
            if denominator==0 then error("undamped resonance") end
            local magnification=1/denominator
            local amplitude=(v[1]/v[4])*magnification
            local phase=math.atan2(2*zeta*r,1-r*r)*180/math.pi
            return amplitude,phase,r,magnification
        end
    })

    calculators.vibrationTransmissibility = Calculator.new({
        id="vibrationTransmissibility", title="Vibration Transmissibility",
        subtitle="Force/base-motion transmissibility for an SDOF system",
        inputs={{label="Mass m",unit="kg"},{label="Damping c",unit="N*s/m"},{label="Stiffness k",unit="N/m"},{label="Excitation frequency",unit="rad/s"}},
        outputs={{label="Frequency ratio r"},{label="Displacement magnification"},{label="Transmissibility"},{label="Isolation",unit="%"}},
        validate=function(v) return vibPositive(v[1],"Mass") or vibNonnegative(v[2],"Damping") or vibPositive(v[3],"Stiffness") or vibNonnegative(v[4],"Excitation frequency") end,
        calculate=function(v)
            local wn,_,zeta=vibrationParameters(v[1],v[3],v[2])
            local r=v[4]/wn
            local den=math.sqrt((1-r*r)^2+(2*zeta*r)^2)
            if den==0 then error("undamped resonance") end
            local dm=1/den
            local tr=math.sqrt(1+(2*zeta*r)^2)/den
            return r,dm,tr,100*(1-tr)
        end
    })

    calculators.springSeries = Calculator.new({
        id="springSeries", title="Springs in Series", subtitle="Enter two to five spring constants",
        allowOptionalInputs=true, minimumInputs=2,
        inputs={{label="k1",unit="N/m"},{label="k2",unit="N/m"},{label="k3",unit="N/m"},{label="k4",unit="N/m"},{label="k5",unit="N/m"}},
        outputs={{label="Equivalent stiffness",unit="N/m"}},
        validate=function(v) for _,k in pairs(v) do if k and k<=0 then return "Spring constants must be positive" end end end,
        calculate=function(v) local sum=0; for _,k in pairs(v) do if k then sum=sum+1/k end end; return 1/sum end
    })

    calculators.springParallel = Calculator.new({
        id="springParallel", title="Springs in Parallel", subtitle="Enter two to five spring constants",
        allowOptionalInputs=true, minimumInputs=2,
        inputs={{label="k1",unit="N/m"},{label="k2",unit="N/m"},{label="k3",unit="N/m"},{label="k4",unit="N/m"},{label="k5",unit="N/m"}},
        outputs={{label="Equivalent stiffness",unit="N/m"}},
        validate=function(v) for _,k in pairs(v) do if k and k<0 then return "Spring constants cannot be negative" end end end,
        calculate=function(v) local sum=0; for _,k in pairs(v) do if k then sum=sum+k end end; return sum end
    })

    calculators.pendulumFrequency = Calculator.new({
        id="pendulumFrequency", title="Simple Pendulum Frequency",
        subtitle="Small-angle approximation",
        inputs={{label="Pendulum length L",unit="m"},{label="Gravity g",unit="m/s^2"}},
        outputs={{label="Angular frequency",unit="rad/s"},{label="Frequency",unit="Hz"},{label="Period",unit="s"}},
        validate=function(v) return vibPositive(v[1],"Length") or vibPositive(v[2],"Gravity") end,
        calculate=function(v) local wn=math.sqrt(v[2]/v[1]); return wn,wn/(2*math.pi),2*math.pi/wn end
    })
end
