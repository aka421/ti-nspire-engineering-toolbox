-- Thermodynamics and heat-transfer calculator definitions.

local function thermoPositive(value, name)
    if value <= 0 then return name .. " must be greater than zero" end
end

local function thermoNonnegative(value, name)
    if value < 0 then return name .. " cannot be negative" end
end

function registerThermodynamicsCalculators(calculators)
    local idealGasVariables = {
        {label="Pressure P",unit="Pa"},{label="Volume V",unit="m^3"},{label="Moles n",unit="mol"},{label="Gas constant R",unit="J/(mol K)"},{label="Temperature T",unit="K"}
    }
    calculators.idealGasLaw = Calculator.new({
        id="idealGasLaw",title="Ideal Gas Law",subtitle="PV = nRT; leave one field blank",allowOneBlank=true,
        inputs=idealGasVariables,outputs={{label="Result"}},resolveOutputs=function(v,m) return {idealGasVariables[m]} end,
        validate=function(v,m)
            for i,value in ipairs(v) do if value and value <= 0 then return idealGasVariables[i].label .. " must be positive" end end
        end,
        calculate=function(v,m)
            if m==1 then return v[3]*v[4]*v[5]/v[2] end
            if m==2 then return v[3]*v[4]*v[5]/v[1] end
            if m==3 then return v[1]*v[2]/(v[4]*v[5]) end
            if m==4 then return v[1]*v[2]/(v[3]*v[5]) end
            return v[1]*v[2]/(v[3]*v[4])
        end
    })

    calculators.densitySpecificVolume = Calculator.new({
        id="densitySpecificVolume",title="Density and Specific Volume",subtitle="rho = 1/v; leave one field blank",allowOneBlank=true,
        inputs={{label="Density rho",unit="kg/m^3"},{label="Specific volume v",unit="m^3/kg"}},outputs={{label="Result"}},
        resolveOutputs=function(v,m) return {m==1 and {label="Density rho",unit="kg/m^3"} or {label="Specific volume v",unit="m^3/kg"}} end,
        validate=function(v) for _,x in ipairs(v) do if x and x<=0 then return "Entered value must be positive" end end end,
        calculate=function(v,m) return m==1 and 1/v[2] or 1/v[1] end
    })

    calculators.sensibleHeat = Calculator.new({
        id="sensibleHeat",title="Sensible Heat",subtitle="Q = m c DeltaT; leave one field blank",allowOneBlank=true,
        inputs={{label="Heat Q",unit="J"},{label="Mass m",unit="kg"},{label="Specific heat c",unit="J/(kg K)"},{label="Temperature change",unit="K"}},outputs={{label="Result"}},
        resolveOutputs=function(v,m) local o={{label="Heat Q",unit="J"},{label="Mass m",unit="kg"},{label="Specific heat c",unit="J/(kg K)"},{label="Temperature change",unit="K"}}; return {o[m]} end,
        validate=function(v,m) if v[2] and v[2]<=0 then return "Mass must be positive" end; if v[3] and v[3]<=0 then return "Specific heat must be positive" end end,
        calculate=function(v,m)
            if m==1 then return v[2]*v[3]*v[4] end
            if m==2 then return v[1]/(v[3]*v[4]) end
            if m==3 then return v[1]/(v[2]*v[4]) end
            return v[1]/(v[2]*v[3])
        end
    })

    calculators.closedSystemFirstLaw = Calculator.new({
        id="closedSystemFirstLaw",title="Closed-System First Law",subtitle="DeltaU = Q - W; work positive out",allowOneBlank=true,
        inputs={{label="Change in internal energy",unit="J"},{label="Heat into system Q",unit="J"},{label="Work by system W",unit="J"}},outputs={{label="Result"}},
        resolveOutputs=function(v,m) local o={{label="Change in internal energy",unit="J"},{label="Heat into system Q",unit="J"},{label="Work by system W",unit="J"}}; return {o[m]} end,
        calculate=function(v,m) if m==1 then return v[2]-v[3] elseif m==2 then return v[1]+v[3] else return v[2]-v[1] end end
    })

    calculators.enthalpyChange = Calculator.new({
        id="enthalpyChange",title="Enthalpy Change",subtitle="DeltaH = m cp DeltaT",
        inputs={{label="Mass",unit="kg"},{label="cp",unit="J/(kg K)"},{label="Temperature change",unit="K"}},
        outputs={{label="Enthalpy change",unit="J"}},
        validate=function(v) return thermoPositive(v[1],"Mass") or thermoPositive(v[2],"cp") end,
        calculate=function(v) return v[1]*v[2]*v[3] end
    })

    calculators.constantPressureWork = Calculator.new({
        id="constantPressureWork",title="Constant-Pressure Boundary Work",subtitle="W = P(V2 - V1)",
        inputs={{label="Pressure",unit="Pa"},{label="Initial volume",unit="m^3"},{label="Final volume",unit="m^3"}},
        outputs={{label="Boundary work",unit="J"}},
        validate=function(v) return thermoPositive(v[1],"Pressure") or thermoNonnegative(v[2],"Initial volume") or thermoNonnegative(v[3],"Final volume") end,
        calculate=function(v) return v[1]*(v[3]-v[2]) end
    })

    calculators.steadyFlowEnergy = Calculator.new({
        id="steadyFlowEnergy",title="Steady-Flow Energy Equation",subtitle="q-w = dh + d(V^2/2) + g dz",
        inputs={{label="Heat per mass q",unit="J/kg"},{label="Work per mass w",unit="J/kg"},{label="h1",unit="J/kg"},{label="h2",unit="J/kg"},{label="V1",unit="m/s"},{label="V2",unit="m/s"},{label="z1",unit="m"},{label="z2",unit="m"}},
        outputs={{label="Energy residual",unit="J/kg"}},visibleInputCount=5,
        calculate=function(v) return v[1]-v[2]-(v[4]-v[3])-(v[6]^2-v[5]^2)/2-9.80665*(v[8]-v[7]) end
    })

    calculators.isothermalIdealGas = Calculator.new({
        id="isothermalIdealGas",title="Isothermal Ideal-Gas Process",subtitle="P1V1 = P2V2 and W = nRT ln(V2/V1)",
        inputs={{label="P1",unit="Pa"},{label="V1",unit="m^3"},{label="V2",unit="m^3"}},
        outputs={{label="P2",unit="Pa"},{label="Work by gas",unit="J"}},
        validate=function(v) return thermoPositive(v[1],"P1") or thermoPositive(v[2],"V1") or thermoPositive(v[3],"V2") end,
        calculate=function(v) return v[1]*v[2]/v[3],v[1]*v[2]*math.log(v[3]/v[2]) end
    })

    calculators.isentropicIdealGas = Calculator.new({
        id="isentropicIdealGas",title="Isentropic Ideal-Gas Process",subtitle="T2/T1 = (P2/P1)^((k-1)/k)",
        inputs={{label="T1",unit="K"},{label="P1",unit="Pa"},{label="P2",unit="Pa"},{label="Specific-heat ratio k"}},
        outputs={{label="T2",unit="K"},{label="Volume ratio V2/V1"}},
        validate=function(v) return thermoPositive(v[1],"T1") or thermoPositive(v[2],"P1") or thermoPositive(v[3],"P2") or (v[4]<=1 and "k must be greater than 1" or nil) end,
        calculate=function(v) return v[1]*(v[3]/v[2])^((v[4]-1)/v[4]),(v[2]/v[3])^(1/v[4]) end
    })

    calculators.polytropicProcess = Calculator.new({
        id="polytropicProcess",title="Polytropic Process",subtitle="P V^n = constant",
        inputs={{label="P1",unit="Pa"},{label="V1",unit="m^3"},{label="V2",unit="m^3"},{label="Exponent n"}},
        outputs={{label="P2",unit="Pa"},{label="Boundary work",unit="J"}},
        validate=function(v) return thermoPositive(v[1],"P1") or thermoPositive(v[2],"V1") or thermoPositive(v[3],"V2") end,
        calculate=function(v)
            local p2=v[1]*(v[2]/v[3])^v[4]
            local work
            if math.abs(v[4]-1)<1e-10 then work=v[1]*v[2]*math.log(v[3]/v[2]) else work=(p2*v[3]-v[1]*v[2])/(1-v[4]) end
            return p2,work
        end
    })

    calculators.carnotEfficiency = Calculator.new({
        id="carnotEfficiency",title="Carnot Efficiency",subtitle="eta = 1 - Tc/Th",
        inputs={{label="Hot reservoir Th",unit="K"},{label="Cold reservoir Tc",unit="K"}},
        outputs={{label="Thermal efficiency",unit="%"},{label="Refrigerator COP"},{label="Heat-pump COP"}},
        validate=function(v) if v[1]<=0 or v[2]<=0 then return "Temperatures must be positive" end; if v[1]<=v[2] then return "Th must exceed Tc" end end,
        calculate=function(v) return 100*(1-v[2]/v[1]),v[2]/(v[1]-v[2]),v[1]/(v[1]-v[2]) end
    })

    calculators.ottoEfficiency = Calculator.new({
        id="ottoEfficiency",title="Otto-Cycle Efficiency",subtitle="eta = 1 - 1/r^(k-1)",
        inputs={{label="Compression ratio r"},{label="Specific-heat ratio k"}},outputs={{label="Thermal efficiency",unit="%"}},
        validate=function(v) if v[1]<=1 then return "Compression ratio must exceed 1" end; if v[2]<=1 then return "k must exceed 1" end end,
        calculate=function(v) return 100*(1-1/(v[1]^(v[2]-1))) end
    })

    calculators.braytonEfficiency = Calculator.new({
        id="braytonEfficiency",title="Brayton-Cycle Efficiency",subtitle="Ideal cycle from pressure ratio",
        inputs={{label="Pressure ratio rp"},{label="Specific-heat ratio k"}},outputs={{label="Thermal efficiency",unit="%"}},
        validate=function(v) if v[1]<=1 then return "Pressure ratio must exceed 1" end; if v[2]<=1 then return "k must exceed 1" end end,
        calculate=function(v) return 100*(1-1/(v[1]^((v[2]-1)/v[2]))) end
    })

    calculators.fourierConduction = Calculator.new({
        id="fourierConduction",title="Plane-Wall Conduction",subtitle="Qdot = k A (T_hot-T_cold)/L",
        inputs={{label="Thermal conductivity k",unit="W/(m K)"},{label="Area A",unit="m^2"},{label="Thickness L",unit="m"},{label="Hot temperature",unit="K"},{label="Cold temperature",unit="K"}},
        outputs={{label="Heat-transfer rate",unit="W"},{label="Thermal resistance",unit="K/W"}},
        validate=function(v) return thermoPositive(v[1],"Thermal conductivity") or thermoPositive(v[2],"Area") or thermoPositive(v[3],"Thickness") end,
        calculate=function(v) return v[1]*v[2]*(v[4]-v[5])/v[3],v[3]/(v[1]*v[2]) end
    })

    calculators.convectionHeatTransfer = Calculator.new({
        id="convectionHeatTransfer",title="Convection Heat Transfer",subtitle="Qdot = h A (Ts - Tinf)",
        inputs={{label="Convection coefficient h",unit="W/(m^2 K)"},{label="Area A",unit="m^2"},{label="Surface temperature",unit="K"},{label="Fluid temperature",unit="K"}},
        outputs={{label="Heat-transfer rate",unit="W"},{label="Thermal resistance",unit="K/W"}},
        validate=function(v) return thermoPositive(v[1],"h") or thermoPositive(v[2],"Area") end,
        calculate=function(v) return v[1]*v[2]*(v[3]-v[4]),1/(v[1]*v[2]) end
    })

    calculators.radiationHeatTransfer = Calculator.new({
        id="radiationHeatTransfer",title="Thermal Radiation",subtitle="Qdot = eps sigma A (Ts^4 - Tsur^4)",
        inputs={{label="Emissivity"},{label="Area A",unit="m^2"},{label="Surface temperature",unit="K"},{label="Surroundings temperature",unit="K"}},
        outputs={{label="Net radiation rate",unit="W"}},
        validate=function(v) if v[1]<0 or v[1]>1 then return "Emissivity must be from 0 to 1" end; return thermoPositive(v[2],"Area") or thermoNonnegative(v[3],"Surface temperature") or thermoNonnegative(v[4],"Surroundings temperature") end,
        calculate=function(v) return v[1]*5.670374419e-8*v[2]*(v[3]^4-v[4]^4) end
    })

    calculators.thermalResistanceSeries = Calculator.new({
        id="thermalResistanceSeries",title="Thermal Resistances in Series",subtitle="Enter 2 to 5 resistances",allowOptionalInputs=true,minimumInputs=2,
        inputs={{label="R1",unit="K/W"},{label="R2",unit="K/W"},{label="R3",unit="K/W"},{label="R4",unit="K/W"},{label="R5",unit="K/W"}},
        outputs={{label="Equivalent resistance",unit="K/W"}},
        validate=function(v) for _,x in ipairs(v) do if x and x<0 then return "Resistance cannot be negative" end end end,
        calculate=function(v) local s=0; for _,x in ipairs(v) do if x then s=s+x end end; return s end
    })
end
