-- Flexible Solve-by-Topic: two-wire transmission line.
-- Enter any known values; the dependency engine derives everything it can.

local TW_MU0 = 4 * math.pi * 1e-7
local TW_EPS0 = 8.854187817e-12
local TW_C0 = 299792458

local function twAcosh(x)
    return math.log(x + math.sqrt(x * x - 1))
end

local function twCMag(r, i)
    return math.sqrt(r * r + i * i)
end

local function twCAngle(r, i)
    return math.atan2(i, r) * 180 / math.pi
end

local function twCDiv(ar, ai, br, bi)
    local d = br * br + bi * bi
    if d == 0 then error("complex division by zero") end
    return (ar * br + ai * bi) / d, (ai * br - ar * bi) / d
end

local function twCMul(ar, ai, br, bi)
    return ar * br - ai * bi, ar * bi + ai * br
end

local function twCSqrt(r, i)
    local m = twCMag(r, i)
    local real = math.sqrt(math.max(0, (m + r) / 2))
    local imag = math.sqrt(math.max(0, (m - r) / 2))
    if i < 0 then imag = -imag end
    return real, imag
end

local quantities = {
    {key="sigma",label="Conductivity sigma",unit="S/m"},
    {key="d",label="Wire diameter d",unit="m"},
    {key="D",label="Center spacing D",unit="m"},
    {key="er",label="Relative permittivity er"},
    {key="f",label="Frequency f",unit="Hz"},
    {key="R",label="R'",unit="ohm/m",variable="Rprime"},
    {key="L",label="L'",unit="H/m",variable="Lprime"},
    {key="G",label="G'",unit="S/m",variable="Gprime"},
    {key="C",label="C'",unit="F/m",variable="Cprime"},
    {key="Z0",label="|Z0|",unit="ohm",variable="Z0mag"},
    {key="beta",label="Phase beta",unit="rad/m",variable="Beta"},
    {key="up",label="Phase velocity",unit="m/s",variable="PhaseVelocity"},
    {key="upratio",label="Phase velocity / c",variable="VelocityRatio"},
    {key="lambda",label="Wavelength",unit="m",variable="Wavelength"},
    {key="alpha",label="Attenuation alpha",unit="Np/m",variable="Alpha"},
    {key="delta",label="Skin depth",unit="m",variable="SkinDepth"},
    {key="Z0real",label="Z0 real",unit="ohm",variable="Z0real"},
    {key="Z0imag",label="Z0 imaginary",unit="ohm",variable="Z0imag"},
    {key="Z0angle",label="Z0 angle",unit="degrees",variable="Z0angle"}
}

local inputQuantities = {
    quantities[1],quantities[2],quantities[3],quantities[4],quantities[5],
    quantities[6],quantities[7],quantities[8],quantities[9],quantities[10],
    quantities[11],quantities[12],quantities[13],quantities[14],quantities[15],quantities[16]
}

local function makeInputs()
    local inputs = {}
    for i, q in ipairs(inputQuantities) do inputs[i] = {label=q.label,unit=q.unit} end
    return inputs
end

local function makeOutputDefinition(q, source)
    local suffix = source == "entered" and " [entered]" or " [calc]"
    return {label=q.label .. suffix,unit=q.unit,variable=q.variable or q.key}
end

local lastOutputs = {}
local lastResults = {}

local relations = {
    {needs={"f"},gives="omega",label="omega = 2*pi*f",solve=function(v) return 2*math.pi*v.f end},
    {needs={"omega"},gives="f",label="f = omega/(2*pi)",solve=function(v) return v.omega/(2*math.pi) end},
    {needs={"upratio"},gives="up",label="up = (up/c)c",solve=function(v) return v.upratio*TW_C0 end},
    {needs={"up"},gives="upratio",label="up/c",solve=function(v) return v.up/TW_C0 end},
    {needs={"upratio"},gives="er",label="er = 1/(up/c)^2",solve=function(v) if v.upratio<=0 then error() end return 1/(v.upratio*v.upratio) end},
    {needs={"er"},gives="upratio",label="up/c = 1/sqrt(er)",solve=function(v) if v.er<=0 then error() end return 1/math.sqrt(v.er) end},
    {needs={"f","up"},gives="lambda",label="lambda = up/f",solve=function(v) return v.up/v.f end},
    {needs={"lambda","f"},gives="up",label="up = lambda*f",solve=function(v) return v.lambda*v.f end},
    {needs={"omega","up"},gives="beta",label="beta = omega/up",solve=function(v) return v.omega/v.up end},
    {needs={"omega","beta"},gives="up",label="up = omega/beta",solve=function(v) return v.omega/v.beta end},
    {needs={"beta"},gives="lambda",label="lambda = 2*pi/beta",solve=function(v) return 2*math.pi/v.beta end},
    {needs={"lambda"},gives="beta",label="beta = 2*pi/lambda",solve=function(v) return 2*math.pi/v.lambda end},

    {needs={"D","d"},gives="geom",label="two-wire geometry",solve=function(v) if v.d<=0 or v.D<=v.d then error() end return twAcosh(v.D/v.d) end},
    {needs={"geom"},gives="L",label="two-wire L'",solve=function(v) return (TW_MU0/math.pi)*v.geom end},
    {needs={"geom","er"},gives="C",label="two-wire C'",solve=function(v) if v.er<=0 then error() end return (math.pi*TW_EPS0*v.er)/v.geom end},
    {needs={},gives="G",label="lossless dielectric",solve=function() return 0 end},

    {needs={"f","sigma"},gives="delta",label="skin depth",solve=function(v) if v.f<=0 or v.sigma<=0 then error() end return math.sqrt(2/(2*math.pi*v.f*TW_MU0*v.sigma)) end},
    {needs={"sigma","delta","d"},gives="R",label="skin-effect R'",solve=function(v) if v.sigma<=0 or v.delta<=0 or v.d<=0 then error() end local rs=1/(v.sigma*v.delta); return 2*rs/(math.pi*v.d) end},

    {needs={"L","C"},gives="up",label="up = 1/sqrt(LC)",solve=function(v) if v.L<=0 or v.C<=0 then error() end return 1/math.sqrt(v.L*v.C) end},
    {needs={"L","C"},gives="Z0",label="Z0 = sqrt(L/C)",solve=function(v) if v.L<=0 or v.C<=0 then error() end return math.sqrt(v.L/v.C) end},
    {needs={"Z0","up"},gives="L",label="L' = Z0/up",solve=function(v) if v.Z0<=0 or v.up<=0 then error() end return v.Z0/v.up end},
    {needs={"Z0","up"},gives="C",label="C' = 1/(Z0*up)",solve=function(v) if v.Z0<=0 or v.up<=0 then error() end return 1/(v.Z0*v.up) end},
    {needs={"L","Z0"},gives="C",label="C' = L'/Z0^2",solve=function(v) return v.L/(v.Z0*v.Z0) end},
    {needs={"C","Z0"},gives="L",label="L' = C'Z0^2",solve=function(v) return v.C*v.Z0*v.Z0 end},

    {needs={"R","Z0"},gives="alpha",label="low-loss alpha",solve=function(v) if v.Z0<=0 then error() end return v.R/(2*v.Z0) end},

    {needs={"R","L","G","C","f"},gives={"Z0real","Z0imag","Z0","Z0angle","alpha","beta","up","upratio","lambda"},label="exact distributed line",solve=function(v)
        if v.f<=0 or v.C<=0 then error() end
        local w=2*math.pi*v.f
        local rr,ri=twCDiv(v.R,w*v.L,v.G,w*v.C)
        local zr,zi=twCSqrt(rr,ri)
        if zr<0 then zr,zi=-zr,-zi end
        local pr,pi=twCMul(v.R,w*v.L,v.G,w*v.C)
        local a,b=twCSqrt(pr,pi)
        if a<0 then a=-a end
        if b<0 then b=-b end
        local up=w/b
        return {
            Z0real=zr,Z0imag=zi,Z0=twCMag(zr,zi),Z0angle=twCAngle(zr,zi),
            alpha=a,beta=b,up=up,upratio=up/TW_C0,lambda=2*math.pi/b
        }
    end}
}

function registerTwoWireLineTopic(calculators)
    calculators.topicTwoWireLine = Calculator.new({
        id="topicTwoWireLine",
        title="Two-Wire Line Flexible Solver",
        subtitle="Enter any known values; leave everything else blank",
        inputs=makeInputs(),
        outputs={{label="Result"}},
        allowOptionalInputs=true,
        minimumInputs=1,
        visibleInputCount=5,
        resolveOutputs=function() return lastOutputs end,
        validate=function(v)
            if v[2]~=nil and v[2]<=0 then return "Diameter must be greater than zero" end
            if v[3]~=nil and v[2]~=nil and v[3]<=v[2] then return "Center spacing must exceed diameter" end
            if v[4]~=nil and v[4]<=0 then return "Relative permittivity must be positive" end
            if v[5]~=nil and v[5]<=0 then return "Frequency must be positive" end
            if v[10]~=nil and v[10]<=0 then return "Z0 must be positive" end
            if v[13]~=nil and v[13]<=0 then return "up/c must be positive" end
        end,
        calculate=function(v)
            local initial = {}
            for i,q in ipairs(inputQuantities) do if v[i]~=nil then initial[q.key]=v[i] end end

            local solved,sources=TopicDependency.solve(initial,relations)
            lastOutputs={}
            lastResults={}

            for _,q in ipairs(quantities) do
                local value=solved[q.key]
                if type(value)=="number" then
                    table.insert(lastOutputs,makeOutputDefinition(q,sources[q.key]))
                    table.insert(lastResults,value)
                end
            end

            if #lastResults==0 then error("No quantities could be determined") end
            return unpack(lastResults)
        end
    })
end
