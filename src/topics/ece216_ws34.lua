-- ECE 216 Worksheet III/IV flexible workspaces.
-- Coaxial lines, quarter-wave transformers, dielectric current, and Faraday wave EMF.

local E34_EPS0=8.854187817e-12
local E34_MU0=4*math.pi*1e-7
local E34_C0=299792458

local function e34Cmag(r,i) return math.sqrt(r*r+i*i) end
local function e34Cdiv(ar,ai,br,bi)
    local d=br*br+bi*bi
    if d==0 then error("complex division by zero") end
    return (ar*br+ai*bi)/d,(ai*br-ar*bi)/d
end
local function e34Cmul(ar,ai,br,bi) return ar*br-ai*bi,ar*bi+ai*br end
local function e34Csqrt(r,i)
    local m=e34Cmag(r,i)
    local a=math.sqrt(math.max(0,(m+r)/2))
    local b=math.sqrt(math.max(0,(m-r)/2))
    if i<0 then b=-b end
    return a,b
end

local function registerCoax(calculators)
    calculators.topicCoaxLine=Calculator.new({
        id="topicCoaxLine",title="Coaxial Line Design",
        subtitle="Geometry/material -> line parameters and Z0",
        inputs={
            {label="Inner conductor diameter d",unit="m"},{label="Shield inner diameter D",unit="m"},
            {label="Relative permittivity er"},{label="Frequency f",unit="Hz"},
            {label="Conductor conductivity sigma",unit="S/m"},{label="Loss tangent tan(delta)"}
        },
        outputs={
            {label="R'",unit="ohm/m"},{label="L'",unit="H/m"},{label="G'",unit="S/m"},{label="C'",unit="F/m"},
            {label="Z0 real",unit="ohm"},{label="Z0 imag",unit="ohm"},{label="|Z0|",unit="ohm"},
            {label="alpha",unit="Np/m"},{label="alpha",unit="dB/100ft"},{label="beta",unit="rad/m"},
            {label="Phase velocity / c"}
        },
        allowOptionalInputs=true,minimumInputs=4,visibleInputCount=5,
        calculate=function(v)
            local d,D,er,f,sigma,tand=v[1],v[2],v[3],v[4],v[5],v[6] or 0
            if not(d and D and er and f) then error("Enter d, D, er, and f") end
            if d<=0 or D<=d or er<=0 or f<=0 then error("Invalid geometry/material values") end
            local a,b=d/2,D/2
            local ln=math.log(b/a)
            local L=E34_MU0/(2*math.pi)*ln
            local C=2*math.pi*E34_EPS0*er/ln
            local w=2*math.pi*f
            local G=w*C*tand
            local R=0
            if sigma and sigma>0 then
                local Rs=math.sqrt(math.pi*f*E34_MU0/sigma)
                R=Rs/(2*math.pi)*(1/a+1/b)
            end
            local qr,qi=e34Cdiv(R,w*L,G,w*C)
            local zr,zi=e34Csqrt(qr,qi)
            local pr,pi=e34Cmul(R,w*L,G,w*C)
            local alpha,beta=e34Csqrt(pr,pi)
            alpha=math.abs(alpha); beta=math.abs(beta)
            return R,L,G,C,zr,zi,e34Cmag(zr,zi),alpha,alpha*8.686*30.48,beta,(w/beta)/E34_C0
        end
    })

    calculators.topicQuarterWave=Calculator.new({
        id="topicQuarterWave",title="Quarter-Wave Transformer",
        subtitle="Match a real load with a lambda/4 section",
        inputs={{label="Main line Z0",unit="ohm"},{label="Load ZL",unit="ohm"},{label="Transformer Zt",unit="ohm"}},
        outputs={{label="Ideal transformer Zt",unit="ohm"},{label="Transformed load",unit="ohm"},{label="Input |Gamma|"},{label="Gamma",unit="dB"}},
        allowOptionalInputs=true,minimumInputs=2,
        calculate=function(v)
            local z0,zl,zt=v[1],v[2],v[3]
            if not(z0 and zl) or z0<=0 or zl<=0 then error("Enter positive Z0 and ZL") end
            local ideal=math.sqrt(z0*zl)
            local use=zt or ideal
            if use<=0 then error("Zt must be positive") end
            local zin=use*use/zl
            local g=math.abs((zin-z0)/(zin+z0))
            local db=(g==0) and -999 or 20*math.log(g)/math.log(10)
            return ideal,zin,g,db
        end
    })
end

local function registerDielectric(calculators)
    calculators.topicDielectricCurrent=Calculator.new({
        id="topicDielectricCurrent",title="Current in Dielectrics",
        subtitle="Conduction/displacement current and capacitor current",
        inputs={
            {label="Conductivity sigma",unit="S/m"},{label="Relative permittivity er"},{label="Frequency f",unit="Hz"},
            {label="Voltage amplitude V0",unit="V"},{label="Plate diameter D",unit="m"},{label="Dielectric thickness d",unit="m"},
            {label="Loss tangent tan(delta)"}
        },
        outputs={{label="|J| / |Jd|"},{label="Capacitance",unit="F"},{label="Displacement current amplitude",unit="A"}},
        allowOptionalInputs=true,minimumInputs=2,visibleInputCount=5,
        calculate=function(v)
            local sigma,er,f,V,D,d,tand=v[1],v[2],v[3],v[4],v[5],v[6],v[7]
            if not(er and f) or er<=0 or f<=0 then error("Enter er and frequency") end
            local w=2*math.pi*f
            local ratio=tand
            if not ratio and sigma then ratio=sigma/(w*E34_EPS0*er) end
            local C,I=0/0,0/0
            if V and D and d and D>0 and d>0 then
                C=E34_EPS0*er*(math.pi*D*D/4)/d
                I=w*C*V
            end
            return ratio or 0/0,C,I
        end
    })
end

local function registerFaraday(calculators)
    calculators.topicFaradayWave=Calculator.new({
        id="topicFaradayWave",title="Faraday / Wave EMF",
        subtitle="Bz=B0 cos(wt-kx), rectangular loop a by b",
        inputs={{label="B0",unit="T"},{label="Frequency f",unit="Hz"},{label="Wave number k",unit="rad/m"},{label="Loop length a (x)",unit="m"},{label="Loop width b",unit="m"}},
        outputs={{label="k used",unit="rad/m"},{label="EMF real",unit="V"},{label="EMF imag",unit="V"},{label="|EMF|",unit="V"},{label="EMF phase",unit="degrees"}},
        allowOptionalInputs=true,minimumInputs=4,
        calculate=function(v)
            local B0,f,k,a,b=v[1],v[2],v[3],v[4],v[5]
            if not(B0 and f and a and b) then error("Enter B0, f, a, and b") end
            if f<=0 or a<=0 or b<=0 then error("Frequency and dimensions must be positive") end
            local w=2*math.pi*f
            k=k or w/E34_C0
            if k==0 then error("k must be nonzero") end
            -- Flux phasor = B0*b*(1-exp(-jka))/(j*k).
            -- Vemf=-j*w*Flux = -(w*B0*b/k)*(1-exp(-jka)).
            local scale=-(w*B0*b/k)
            local re=scale*(1-math.cos(k*a))
            local im=scale*math.sin(k*a)
            local mag=e34Cmag(re,im)
            local phase=math.atan2(im,re)*180/math.pi
            return k,re,im,mag,phase
        end
    })
end

function registerECE216Worksheet34Topics(calculators)
    registerCoax(calculators)
    registerDielectric(calculators)
    registerFaraday(calculators)
end
