-- Transmission-line calculator definitions.

local function tlRequirePositive(value, name)
    if value <= 0 then return name .. " must be greater than zero" end
end

local function cAdd(ar, ai, br, bi) return ar + br, ai + bi end
local function cSub(ar, ai, br, bi) return ar - br, ai - bi end
local function cMul(ar, ai, br, bi) return ar * br - ai * bi, ar * bi + ai * br end
local function cDiv(ar, ai, br, bi)
    local d = br * br + bi * bi
    if d == 0 then error("complex division by zero") end
    return (ar * br + ai * bi) / d, (ai * br - ar * bi) / d
end
local function cMagnitude(r, i) return math.sqrt(r * r + i * i) end
local function cAngleDegrees(r, i) return math.atan2(i, r) * 180 / math.pi end
local function cSqrt(r, i)
    local m = cMagnitude(r, i)
    local real = math.sqrt(math.max(0, (m + r) / 2))
    local imag = math.sqrt(math.max(0, (m - r) / 2))
    if i < 0 then imag = -imag end
    return real, imag
end
local function positiveModulo(value, period)
    local result = value % period
    if result < 0 then result = result + period end
    return result
end

function registerTransmissionCalculators(calculators)
    calculators.reflectionCoefficient = Calculator.new({
        id="reflectionCoefficient", title="Reflection Coefficient",
        subtitle="Gamma = (ZL - Z0)/(ZL + Z0)",
        inputs={{label="Load resistance",unit="ohm"},{label="Load reactance",unit="ohm"},{label="Characteristic Z0",unit="ohm"}},
        outputs={{label="Gamma real"},{label="Gamma imag"},{label="Magnitude"},{label="Angle",unit="degrees"}},
        validate=function(v) return tlRequirePositive(v[3],"Characteristic impedance") end,
        calculate=function(v)
            local nr,ni=cSub(v[1],v[2],v[3],0)
            local dr,di=cAdd(v[1],v[2],v[3],0)
            local gr,gi=cDiv(nr,ni,dr,di)
            return gr,gi,cMagnitude(gr,gi),cAngleDegrees(gr,gi)
        end
    })

    calculators.loadFromReflection = Calculator.new({
        id="loadFromReflection", title="Load from Reflection Coefficient",
        subtitle="ZL = Z0(1 + Gamma)/(1 - Gamma)",
        inputs={{label="Gamma real"},{label="Gamma imag"},{label="Characteristic Z0",unit="ohm"}},
        outputs={{label="Load resistance",unit="ohm"},{label="Load reactance",unit="ohm"},{label="Load magnitude",unit="ohm"},{label="Load angle",unit="degrees"}},
        validate=function(v) return tlRequirePositive(v[3],"Characteristic impedance") end,
        calculate=function(v)
            local zr,zi=cDiv(1+v[1],v[2],1-v[1],-v[2])
            zr,zi=v[3]*zr,v[3]*zi
            return zr,zi,cMagnitude(zr,zi),cAngleDegrees(zr,zi)
        end
    })

    calculators.vswr = Calculator.new({
        id="vswr", title="VSWR", subtitle="VSWR = (1 + |Gamma|)/(1 - |Gamma|)",
        inputs={{label="Reflection magnitude"}}, outputs={{label="VSWR"}},
        validate=function(v) if v[1] < 0 or v[1] >= 1 then return "Reflection magnitude must be from 0 to less than 1" end end,
        calculate=function(v) return (1+v[1])/(1-v[1]) end
    })

    calculators.returnLoss = Calculator.new({
        id="returnLoss", title="Return and Mismatch Loss",
        subtitle="Losses from reflection coefficient magnitude",
        inputs={{label="Reflection magnitude"}},
        outputs={{label="Return loss",unit="dB"},{label="Mismatch loss",unit="dB"},{label="Reflected power",unit="%"},{label="Delivered power",unit="%"}},
        validate=function(v) if v[1] < 0 or v[1] >= 1 then return "Reflection magnitude must be from 0 to less than 1" end end,
        calculate=function(v)
            local g2=v[1]^2
            local rl=v[1]==0 and 1e99 or -20*math.log(v[1])/math.log(10)
            local ml=-10*math.log(1-g2)/math.log(10)
            return rl,ml,100*g2,100*(1-g2)
        end
    })

    calculators.losslessInputImpedance = Calculator.new({
        id="losslessInputImpedance", title="Input Impedance",
        subtitle="Lossless line at distance l from load",
        inputs={{label="Load resistance",unit="ohm"},{label="Load reactance",unit="ohm"},{label="Characteristic Z0",unit="ohm"},{label="Phase constant beta",unit="rad/m"},{label="Line length l",unit="m"}},
        outputs={{label="Input resistance",unit="ohm"},{label="Input reactance",unit="ohm"},{label="Input magnitude",unit="ohm"},{label="Input angle",unit="degrees"}},
        validate=function(v)
            return tlRequirePositive(v[3],"Characteristic impedance") or tlRequirePositive(v[4],"Phase constant") or (v[5] < 0 and "Line length cannot be negative" or nil)
        end,
        calculate=function(v)
            local t=math.tan(v[4]*v[5])
            local nr,ni=v[1],v[2]+v[3]*t
            local zrt,zit=cMul(v[1],v[2],0,t)
            local rr,ri=cDiv(nr,ni,v[3]+zrt,zit)
            rr,ri=v[3]*rr,v[3]*ri
            return rr,ri,cMagnitude(rr,ri),cAngleDegrees(rr,ri)
        end
    })

    calculators.quarterWaveTransformer = Calculator.new({
        id="quarterWaveTransformer", title="Quarter-Wave Transformer",
        subtitle="Match two positive real impedances",
        inputs={{label="Source line Z0",unit="ohm"},{label="Load resistance",unit="ohm"},{label="Frequency f",unit="Hz"},{label="Wave velocity",unit="m/s"}},
        outputs={{label="Transformer impedance",unit="ohm"},{label="Quarter-wave length",unit="m"},{label="Wavelength",unit="m"}},
        validate=function(v)
            return tlRequirePositive(v[1],"Source impedance") or tlRequirePositive(v[2],"Load resistance") or tlRequirePositive(v[3],"Frequency") or tlRequirePositive(v[4],"Wave velocity")
        end,
        calculate=function(v) local wavelength=v[4]/v[3]; return math.sqrt(v[1]*v[2]),wavelength/4,wavelength end
    })

    calculators.characteristicImpedance = Calculator.new({
        id="characteristicImpedance", title="Characteristic Impedance",
        subtitle="Z0 = sqrt((R + jwL)/(G + jwC))",
        inputs={{label="Resistance R'",unit="ohm/m"},{label="Inductance L'",unit="H/m"},{label="Conductance G'",unit="S/m"},{label="Capacitance C'",unit="F/m"},{label="Frequency f",unit="Hz"}},
        outputs={{label="Z0 real",unit="ohm"},{label="Z0 imag",unit="ohm"},{label="Z0 magnitude",unit="ohm"},{label="Z0 angle",unit="degrees"}},
        validate=function(v)
            if v[1] < 0 or v[3] < 0 then return "R' and G' cannot be negative" end
            return tlRequirePositive(v[2],"Inductance") or tlRequirePositive(v[4],"Capacitance") or tlRequirePositive(v[5],"Frequency")
        end,
        calculate=function(v)
            local w=2*math.pi*v[5]
            local rr,ri=cDiv(v[1],w*v[2],v[3],w*v[4])
            local zr,zi=cSqrt(rr,ri)
            return zr,zi,cMagnitude(zr,zi),cAngleDegrees(zr,zi)
        end
    })

    calculators.lineParameters = Calculator.new({
        id="lineParameters", title="Line Parameters",
        subtitle="Propagation from distributed R', L', G', and C'",
        inputs={{label="Resistance R'",unit="ohm/m"},{label="Inductance L'",unit="H/m"},{label="Conductance G'",unit="S/m"},{label="Capacitance C'",unit="F/m"},{label="Frequency f",unit="Hz"}},
        outputs={{label="Attenuation alpha",unit="Np/m"},{label="Phase beta",unit="rad/m"},{label="Phase velocity",unit="m/s"},{label="Wavelength",unit="m"}},
        validate=function(v)
            if v[1] < 0 or v[3] < 0 then return "R' and G' cannot be negative" end
            return tlRequirePositive(v[2],"Inductance") or tlRequirePositive(v[4],"Capacitance") or tlRequirePositive(v[5],"Frequency")
        end,
        calculate=function(v)
            local w=2*math.pi*v[5]
            local pr,pi=cMul(v[1],w*v[2],v[3],w*v[4])
            local alpha,beta=cSqrt(pr,pi)
            if beta < 0 then beta=-beta end
            return alpha,beta,w/beta,2*math.pi/beta
        end
    })

    calculators.voltageCurrentMaxima = Calculator.new({
        id="voltageCurrentMaxima", title="Voltage and Current Maxima",
        subtitle="Lossless line; distances measured from load",
        inputs={{label="Forward voltage magnitude",unit="V"},{label="Reflection magnitude"},{label="Reflection angle",unit="degrees"},{label="Characteristic Z0",unit="ohm"},{label="Phase constant beta",unit="rad/m"}},
        outputs={{label="Maximum voltage",unit="V"},{label="Maximum current",unit="A"},{label="Nearest V max",unit="m"},{label="Nearest I max",unit="m"}},
        validate=function(v)
            if v[1] < 0 then return "Forward voltage cannot be negative" end
            if v[2] < 0 or v[2] > 1 then return "Reflection magnitude must be from 0 to 1" end
            return tlRequirePositive(v[4],"Characteristic impedance") or tlRequirePositive(v[5],"Phase constant")
        end,
        calculate=function(v)
            local angle=v[3]*math.pi/180
            local period=2*math.pi
            local zv=positiveModulo(angle,period)/(2*v[5])
            local zi=positiveModulo(angle-math.pi,period)/(2*v[5])
            return v[1]*(1+v[2]),(v[1]/v[4])*(1+v[2]),zv,zi
        end
    })

    calculators.electricalLength = Calculator.new({
        id="electricalLength", title="Electrical Length", subtitle="Convert physical length to phase",
        inputs={{label="Line length",unit="m"},{label="Frequency f",unit="Hz"},{label="Wave velocity",unit="m/s"}},
        outputs={{label="Electrical length",unit="degrees"},{label="Electrical length",unit="rad"},{label="Wavelengths"},{label="Wavelength",unit="m"}},
        validate=function(v) if v[1] < 0 then return "Line length cannot be negative" end; return tlRequirePositive(v[2],"Frequency") or tlRequirePositive(v[3],"Wave velocity") end,
        calculate=function(v) local wavelength=v[3]/v[2]; local cycles=v[1]/wavelength; return 360*cycles,2*math.pi*cycles,cycles,wavelength end
    })
end
