-- Solve-by-Topic: two-wire transmission-line design workspace.
-- Homogeneous nonmagnetic dielectric, round conductors, skin-effect conductor loss.

local TWO_WIRE_MU0 = 4 * math.pi * 1e-7
local TWO_WIRE_EPS0 = 8.854187817e-12
local TWO_WIRE_C0 = 299792458

local function twAcosh(x)
    return math.log(x + math.sqrt(x * x - 1))
end

local function twCMul(ar, ai, br, bi)
    return ar * br - ai * bi, ar * bi + ai * br
end

local function twCDiv(ar, ai, br, bi)
    local d = br * br + bi * bi
    if d == 0 then error("complex division by zero") end
    return (ar * br + ai * bi) / d, (ai * br - ar * bi) / d
end

local function twCMag(r, i)
    return math.sqrt(r * r + i * i)
end

local function twCAngle(r, i)
    return math.atan2(i, r) * 180 / math.pi
end

local function twCSqrt(r, i)
    local m = twCMag(r, i)
    local real = math.sqrt(math.max(0, (m + r) / 2))
    local imag = math.sqrt(math.max(0, (m - r) / 2))
    if i < 0 then imag = -imag end
    return real, imag
end

local function twoWireBaseOutputs()
    return {
        {label="Skin depth",unit="m",variable="SkinDepth"},
        {label="R'",unit="ohm/m",variable="Rprime"},
        {label="L'",unit="H/m",variable="Lprime"},
        {label="G'",unit="S/m",variable="Gprime"},
        {label="C'",unit="F/m",variable="Cprime"},
        {label="Z0 real",unit="ohm",variable="Z0real"},
        {label="Z0 imaginary",unit="ohm",variable="Z0imag"},
        {label="|Z0|",unit="ohm",variable="Z0mag"},
        {label="Z0 angle",unit="degrees",variable="Z0angle"},
        {label="Attenuation alpha",unit="Np/m",variable="Alpha"},
        {label="Phase beta",unit="rad/m",variable="Beta"},
        {label="Phase velocity",unit="m/s",variable="PhaseVelocity"},
        {label="Phase velocity / c",variable="VelocityRatio"},
        {label="Wavelength",unit="m",variable="Wavelength"},
        {label="Lossless Z0 estimate",unit="ohm",variable="LosslessZ0"},
        {label="Lossless up / c",variable="LosslessVelocityRatio"}
    }
end

local function twoWireMeasuredOutputs(outputs)
    table.insert(outputs,{label="Measured Z0 difference",unit="%",variable="MeasuredZ0Difference"})
    table.insert(outputs,{label="Measured up difference",unit="%",variable="MeasuredVelocityDifference"})
    table.insert(outputs,{label="Effective epsilon_r",variable="EffectiveEpsilonR"})
    table.insert(outputs,{label="L' inferred from measured",unit="H/m",variable="MeasuredLprime"})
    table.insert(outputs,{label="C' inferred from measured",unit="F/m",variable="MeasuredCprime"})
    return outputs
end

function registerTwoWireLineTopic(calculators)
    calculators.topicTwoWireLine = Calculator.new({
        id="topicTwoWireLine",
        title="Two-Wire Line Design",
        subtitle="Round conductors; homogeneous dielectric; optional measured data",
        inputs={
            {label="Conductivity sigma",unit="S/m"},
            {label="Wire diameter d",unit="m"},
            {label="Center spacing D",unit="m"},
            {label="Relative permittivity er"},
            {label="Frequency f",unit="Hz"},
            {label="Measured Z0 (optional)",unit="ohm"},
            {label="Measured up/c (optional)"}
        },
        outputs=twoWireBaseOutputs(),
        allowOptionalInputs=true,
        minimumInputs=5,
        visibleInputCount=5,
        resolveOutputs=function(v)
            local outputs=twoWireBaseOutputs()
            if v[6] ~= nil and v[7] ~= nil then twoWireMeasuredOutputs(outputs) end
            return outputs
        end,
        validate=function(v)
            if v[1] == nil or v[2] == nil or v[3] == nil or v[4] == nil or v[5] == nil then
                return "Complete sigma, d, D, er, and frequency"
            end
            if v[1] <= 0 then return "Conductivity must be greater than zero" end
            if v[2] <= 0 then return "Wire diameter must be greater than zero" end
            if v[3] <= v[2] then return "Center spacing D must be greater than diameter d" end
            if v[4] <= 0 then return "Relative permittivity must be greater than zero" end
            if v[5] <= 0 then return "Frequency must be greater than zero" end
            if (v[6] == nil) ~= (v[7] == nil) then return "Enter both measured values or leave both blank" end
            if v[6] ~= nil and v[6] <= 0 then return "Measured Z0 must be greater than zero" end
            if v[7] ~= nil and (v[7] <= 0 or v[7] > 1) then return "Measured up/c must be from 0 to 1" end
        end,
        calculate=function(v)
            local sigma,d,D,er,f=v[1],v[2],v[3],v[4],v[5]
            local omega=2*math.pi*f
            local mu=TWO_WIRE_MU0
            local eps=TWO_WIRE_EPS0*er
            local geom=twAcosh(D/d)

            -- Skin-effect resistance for the complete two-conductor loop.
            local skinDepth=math.sqrt(2/(omega*mu*sigma))
            local surfaceResistance=1/(sigma*skinDepth)
            local rPrime=2*surfaceResistance/(math.pi*d)

            -- High-frequency external inductance and electrostatic capacitance.
            local lPrime=(mu/math.pi)*geom
            local gPrime=0
            local cPrime=(math.pi*eps)/geom

            -- Exact distributed-parameter characteristic impedance and propagation constant.
            local zNumeratorR,zNumeratorI=rPrime,omega*lPrime
            local zDenominatorR,zDenominatorI=gPrime,omega*cPrime
            local ratioR,ratioI=twCDiv(zNumeratorR,zNumeratorI,zDenominatorR,zDenominatorI)
            local z0r,z0i=twCSqrt(ratioR,ratioI)
            if z0r < 0 then z0r,z0i=-z0r,-z0i end

            local productR,productI=twCMul(zNumeratorR,zNumeratorI,zDenominatorR,zDenominatorI)
            local alpha,beta=twCSqrt(productR,productI)
            if alpha < 0 then alpha=-alpha end
            if beta < 0 then beta=-beta end

            local phaseVelocity=omega/beta
            local velocityRatio=phaseVelocity/TWO_WIRE_C0
            local wavelength=2*math.pi/beta
            local losslessZ0=math.sqrt(lPrime/cPrime)
            local losslessVelocityRatio=1/math.sqrt(er)

            local results={
                skinDepth,rPrime,lPrime,gPrime,cPrime,
                z0r,z0i,twCMag(z0r,z0i),twCAngle(z0r,z0i),
                alpha,beta,phaseVelocity,velocityRatio,wavelength,
                losslessZ0,losslessVelocityRatio
            }

            if v[6] ~= nil and v[7] ~= nil then
                local measuredZ0=v[6]
                local measuredRatio=v[7]
                local measuredVelocity=measuredRatio*TWO_WIRE_C0
                local z0Difference=100*(measuredZ0-twCMag(z0r,z0i))/twCMag(z0r,z0i)
                local velocityDifference=100*(measuredRatio-velocityRatio)/velocityRatio
                local effectiveEr=1/(measuredRatio*measuredRatio)
                local measuredL=measuredZ0/measuredVelocity
                local measuredC=1/(measuredZ0*measuredVelocity)
                table.insert(results,z0Difference)
                table.insert(results,velocityDifference)
                table.insert(results,effectiveEr)
                table.insert(results,measuredL)
                table.insert(results,measuredC)
            end

            return unpack(results)
        end
    })
end
