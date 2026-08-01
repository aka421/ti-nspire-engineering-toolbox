-- Solve-by-Topic: Lossless transmission-line workspace.
-- Combines reflection, standing-wave, impedance, length, and power quantities.

function registerTransmissionTopic(calculators)
    calculators.topicTransmissionLine = Calculator.new({
        id = "topicTransmissionLine",
        title = "Transmission Line Workspace",
        subtitle = "Lossless line; forward voltage is RMS magnitude",
        visibleInputCount = 5,
        visibleResultCount = 5,
        inputs = {
            {label="Load resistance RL",unit="ohm"},
            {label="Load reactance XL",unit="ohm"},
            {label="Characteristic Z0",unit="ohm"},
            {label="Phase constant beta",unit="rad/m"},
            {label="Line length l",unit="m"},
            {label="Forward voltage V0+ RMS",unit="V"}
        },
        outputs = {
            {label="Gamma real"},
            {label="Gamma imaginary"},
            {label="Gamma magnitude"},
            {label="Gamma angle",unit="degrees"},
            {label="VSWR"},
            {label="Return loss",unit="dB"},
            {label="Mismatch loss",unit="dB"},
            {label="Reflected power",unit="%"},
            {label="Delivered power",unit="%"},
            {label="Input resistance",unit="ohm"},
            {label="Input reactance",unit="ohm"},
            {label="Input impedance magnitude",unit="ohm"},
            {label="Input impedance angle",unit="degrees"},
            {label="Electrical length",unit="degrees"},
            {label="Electrical length",unit="rad"},
            {label="Nearest voltage maximum",unit="m"},
            {label="Nearest current maximum",unit="m"},
            {label="Maximum voltage",unit="V"},
            {label="Maximum current",unit="A"},
            {label="Incident average power",unit="W"},
            {label="Reflected average power",unit="W"},
            {label="Load average power",unit="W"}
        },
        validate = function(v)
            if v[1] < 0 then return "Load resistance cannot be negative" end
            if v[3] <= 0 then return "Characteristic impedance must be greater than zero" end
            if v[4] <= 0 then return "Phase constant must be greater than zero" end
            if v[5] < 0 then return "Line length cannot be negative" end
            if v[6] < 0 then return "Forward voltage cannot be negative" end
        end,
        calculate = function(v)
            local rl,xl,z0,beta,length,vplus = v[1],v[2],v[3],v[4],v[5],v[6]

            local nr,ni = rl-z0,xl
            local dr,di = rl+z0,xl
            local denominator = dr*dr + di*di
            local gr = (nr*dr + ni*di)/denominator
            local gi = (ni*dr - nr*di)/denominator
            local gmag = math.sqrt(gr*gr + gi*gi)
            local gangle = math.atan2(gi,gr)
            local gangleDeg = gangle*180/math.pi

            local vswr
            if gmag >= 1 then vswr = 1e99 else vswr = (1+gmag)/(1-gmag) end
            local returnLoss = gmag == 0 and 1e99 or -20*math.log(gmag)/math.log(10)
            local mismatchLoss = gmag >= 1 and 1e99 or -10*math.log(1-gmag*gmag)/math.log(10)

            local tangent = math.tan(beta*length)
            local ar,ai = rl,xl + z0*tangent
            local br,bi = z0 - xl*tangent,rl*tangent
            local bd = br*br + bi*bi
            local zinr = z0*(ar*br + ai*bi)/bd
            local zini = z0*(ai*br - ar*bi)/bd
            local zinmag = math.sqrt(zinr*zinr + zini*zini)
            local zinangle = math.atan2(zini,zinr)*180/math.pi

            local electricalRad = beta*length
            local electricalDeg = electricalRad*180/math.pi
            local period = 2*math.pi
            local normalizedAngle = gangle % period
            if normalizedAngle < 0 then normalizedAngle = normalizedAngle + period end
            local voltageMax = normalizedAngle/(2*beta)
            local currentAngle = (gangle-math.pi) % period
            if currentAngle < 0 then currentAngle = currentAngle + period end
            local currentMax = currentAngle/(2*beta)

            local vmax = vplus*(1+gmag)
            local imax = (vplus/z0)*(1+gmag)
            local pinc = vplus*vplus/z0
            local prefl = pinc*gmag*gmag
            local pload = pinc-prefl

            return gr,gi,gmag,gangleDeg,vswr,returnLoss,mismatchLoss,
                100*gmag*gmag,100*(1-gmag*gmag),
                zinr,zini,zinmag,zinangle,electricalDeg,electricalRad,
                voltageMax,currentMax,vmax,imax,pinc,prefl,pload
        end
    })
end
