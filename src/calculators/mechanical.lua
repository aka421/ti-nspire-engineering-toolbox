-- Mechanical engineering calculator definitions.

local function mechPositive(value, name)
    if value <= 0 then return name .. " must be greater than zero" end
end

local function degToRad(value) return value * math.pi / 180 end
local function radToDeg(value) return value * 180 / math.pi end

function registerMechanicalCalculators(calculators)
    -- Statics
    calculators.forceResultant2D = Calculator.new({
        id="forceResultant2D", title="2D Force Resultant",
        subtitle="Enter up to four forces by magnitude and angle",
        allowOptionalInputs=true, minimumInputs=2,
        inputs={{label="F1",unit="N"},{label="theta1",unit="degrees"},{label="F2",unit="N"},{label="theta2",unit="degrees"},{label="F3",unit="N"},{label="theta3",unit="degrees"},{label="F4",unit="N"},{label="theta4",unit="degrees"}},
        outputs={{label="Resultant Fx",unit="N"},{label="Resultant Fy",unit="N"},{label="Magnitude",unit="N"},{label="Direction",unit="degrees"}},
        visibleInputCount=5,
        validate=function(v)
            for i=1,8,2 do
                if (v[i] == nil) ~= (v[i+1] == nil) then return "Each force needs magnitude and angle" end
            end
        end,
        calculate=function(v)
            local fx,fy=0,0
            for i=1,8,2 do if v[i] then fx=fx+v[i]*math.cos(degToRad(v[i+1])); fy=fy+v[i]*math.sin(degToRad(v[i+1])) end end
            return fx,fy,math.sqrt(fx*fx+fy*fy),radToDeg(math.atan2(fy,fx))
        end
    })

    calculators.moment2D = Calculator.new({
        id="moment2D", title="Moment About a Point", subtitle="M = rx Fy - ry Fx; CCW positive",
        inputs={{label="Position rx",unit="m"},{label="Position ry",unit="m"},{label="Force Fx",unit="N"},{label="Force Fy",unit="N"}},
        outputs={{label="Moment",unit="N*m"},{label="Magnitude",unit="N*m"}},
        calculate=function(v) local m=v[1]*v[4]-v[2]*v[3]; return m,math.abs(m) end
    })

    calculators.coupleMoment = Calculator.new({
        id="coupleMoment", title="Couple Moment", subtitle="M = Fd",
        inputs={{label="Force magnitude",unit="N"},{label="Perpendicular distance",unit="m"}},
        outputs={{label="Couple moment",unit="N*m"}},
        validate=function(v) return mechPositive(v[2],"Distance") end,
        calculate=function(v) return v[1]*v[2] end
    })

    -- Mechanics of materials
    calculators.normalStress = Calculator.new({
        id="normalStress", title="Normal Stress", subtitle="sigma = P/A; tension positive",
        inputs={{label="Axial force P",unit="N"},{label="Area A",unit="m^2"}}, outputs={{label="Normal stress",unit="Pa"}},
        validate=function(v) return mechPositive(v[2],"Area") end, calculate=function(v) return v[1]/v[2] end
    })

    calculators.normalStrain = Calculator.new({
        id="normalStrain", title="Normal Strain", subtitle="epsilon = delta/L",
        inputs={{label="Length change",unit="m"},{label="Original length",unit="m"}}, outputs={{label="Normal strain"}},
        validate=function(v) return mechPositive(v[2],"Original length") end, calculate=function(v) return v[1]/v[2] end
    })

    calculators.axialDeformation = Calculator.new({
        id="axialDeformation", title="Axial Deformation", subtitle="delta = PL/(AE)",
        inputs={{label="Axial force P",unit="N"},{label="Length L",unit="m"},{label="Area A",unit="m^2"},{label="Elastic modulus E",unit="Pa"}},
        outputs={{label="Deformation",unit="m"},{label="Stress",unit="Pa"},{label="Strain"}},
        validate=function(v) return mechPositive(v[2],"Length") or mechPositive(v[3],"Area") or mechPositive(v[4],"Elastic modulus") end,
        calculate=function(v) local stress=v[1]/v[3]; local strain=stress/v[4]; return strain*v[2],stress,strain end
    })

    calculators.torsionSolidShaft = Calculator.new({
        id="torsionSolidShaft", title="Solid-Shaft Torsion", subtitle="Circular solid shaft",
        inputs={{label="Torque T",unit="N*m"},{label="Diameter d",unit="m"},{label="Length L",unit="m"},{label="Shear modulus G",unit="Pa"}},
        outputs={{label="Maximum shear stress",unit="Pa"},{label="Angle of twist",unit="rad"},{label="Angle of twist",unit="degrees"},{label="Polar moment J",unit="m^4"}},
        validate=function(v) return mechPositive(v[2],"Diameter") or mechPositive(v[3],"Length") or mechPositive(v[4],"Shear modulus") end,
        calculate=function(v) local j=math.pi*v[2]^4/32; local tau=16*v[1]/(math.pi*v[2]^3); local phi=v[1]*v[3]/(j*v[4]); return tau,phi,radToDeg(phi),j end
    })

    calculators.bendingStress = Calculator.new({
        id="bendingStress", title="Beam Bending Stress", subtitle="sigma = -My/I",
        inputs={{label="Bending moment M",unit="N*m"},{label="Distance y",unit="m"},{label="Second moment I",unit="m^4"}},
        outputs={{label="Bending stress",unit="Pa"},{label="Magnitude",unit="Pa"}},
        validate=function(v) return mechPositive(v[3],"Second moment of area") end,
        calculate=function(v) local s=-v[1]*v[2]/v[3]; return s,math.abs(s) end
    })

    calculators.transverseShear = Calculator.new({
        id="transverseShear", title="Transverse Shear Stress", subtitle="tau = VQ/(It)",
        inputs={{label="Shear force V",unit="N"},{label="First moment Q",unit="m^3"},{label="Second moment I",unit="m^4"},{label="Width t",unit="m"}},
        outputs={{label="Shear stress",unit="Pa"}},
        validate=function(v) return mechPositive(v[3],"Second moment") or mechPositive(v[4],"Width") end,
        calculate=function(v) return v[1]*v[2]/(v[3]*v[4]) end
    })

    calculators.thinWallCylinder = Calculator.new({
        id="thinWallCylinder", title="Thin-Wall Pressure Vessel", subtitle="Closed cylindrical vessel",
        inputs={{label="Internal pressure p",unit="Pa"},{label="Inner radius r",unit="m"},{label="Wall thickness t",unit="m"}},
        outputs={{label="Hoop stress",unit="Pa"},{label="Longitudinal stress",unit="Pa"}},
        validate=function(v) return mechPositive(v[2],"Radius") or mechPositive(v[3],"Thickness") end,
        calculate=function(v) return v[1]*v[2]/v[3],v[1]*v[2]/(2*v[3]) end
    })

    calculators.planeStressPrincipal = Calculator.new({
        id="planeStressPrincipal", title="Principal Stress and Mohr Circle", subtitle="Plane stress: sigma_x, sigma_y, tau_xy",
        inputs={{label="sigma_x",unit="Pa"},{label="sigma_y",unit="Pa"},{label="tau_xy",unit="Pa"}},
        outputs={{label="Principal sigma1",unit="Pa"},{label="Principal sigma2",unit="Pa"},{label="Max in-plane shear",unit="Pa"},{label="Principal angle",unit="degrees"}},
        calculate=function(v)
            local avg=(v[1]+v[2])/2; local radius=math.sqrt(((v[1]-v[2])/2)^2+v[3]^2)
            local theta=0.5*radToDeg(math.atan2(2*v[3],v[1]-v[2]))
            return avg+radius,avg-radius,radius,theta
        end
    })

    calculators.stressTransformation = Calculator.new({
        id="stressTransformation", title="Plane Stress Transformation", subtitle="Stress on axes rotated by theta",
        inputs={{label="sigma_x",unit="Pa"},{label="sigma_y",unit="Pa"},{label="tau_xy",unit="Pa"},{label="Rotation theta",unit="degrees"}},
        outputs={{label="sigma_x prime",unit="Pa"},{label="sigma_y prime",unit="Pa"},{label="tau_x'y'",unit="Pa"}},
        calculate=function(v)
            local t=2*degToRad(v[4]); local avg=(v[1]+v[2])/2; local half=(v[1]-v[2])/2
            local sx=avg+half*math.cos(t)+v[3]*math.sin(t)
            local sy=avg-half*math.cos(t)-v[3]*math.sin(t)
            local tau=-half*math.sin(t)+v[3]*math.cos(t)
            return sx,sy,tau
        end
    })
end
