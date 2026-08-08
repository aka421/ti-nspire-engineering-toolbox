-- Dynamics calculator definitions.

local G_ACCEL = 9.80665

local function positive(value, name)
    if value <= 0 then return name .. " must be greater than zero" end
end

local function nonnegative(value, name)
    if value < 0 then return name .. " cannot be negative" end
end

local function oneBlankDefinition(id, title, subtitle, variables, validate, solve)
    return Calculator.new({
        id = id,
        title = title,
        subtitle = subtitle or "Leave exactly one field blank",
        allowOneBlank = true,
        inputs = variables,
        outputs = {{label = "Result"}},
        resolveOutputs = function(_, missing) return {variables[missing]} end,
        validate = validate,
        calculate = solve
    })
end

function registerDynamicsCalculators(calculators)
    -- Kinematics
    calculators.constantAcceleration = Calculator.new({
        id = "constantAcceleration",
        title = "Constant Acceleration",
        subtitle = "Motion from initial velocity, acceleration, and time",
        inputs = {
            {label="Initial velocity v0",unit="m/s"},
            {label="Acceleration a",unit="m/s^2"},
            {label="Time t",unit="s"}
        },
        outputs = {
            {label="Final velocity v",unit="m/s"},
            {label="Displacement",unit="m"}
        },
        validate = function(v) return nonnegative(v[3], "Time") end,
        calculate = function(v)
            return v[1] + v[2] * v[3], v[1] * v[3] + 0.5 * v[2] * v[3]^2
        end
    })

    calculators.velocityDisplacement = Calculator.new({
        id = "velocityDisplacement",
        title = "Velocity from Displacement",
        subtitle = "v^2 = v0^2 + 2a Delta x",
        inputs = {
            {label="Initial velocity v0",unit="m/s"},
            {label="Acceleration a",unit="m/s^2"},
            {label="Displacement",unit="m"}
        },
        outputs = {{label="Final speed",unit="m/s"}},
        validate = function(v)
            if v[1]^2 + 2*v[2]*v[3] < 0 then return "No real final velocity" end
        end,
        calculate = function(v) return math.sqrt(v[1]^2 + 2*v[2]*v[3]) end
    })

    calculators.circularMotion = Calculator.new({
        id = "circularMotion",
        title = "Circular Motion",
        inputs = {
            {label="Radius r",unit="m"},
            {label="Angular velocity",unit="rad/s"},
            {label="Angular acceleration",unit="rad/s^2"}
        },
        outputs = {
            {label="Tangential velocity",unit="m/s"},
            {label="Tangential acceleration",unit="m/s^2"},
            {label="Normal acceleration",unit="m/s^2"},
            {label="Total acceleration",unit="m/s^2"}
        },
        validate = function(v) return nonnegative(v[1], "Radius") end,
        calculate = function(v)
            local vt = v[1]*v[2]
            local at = v[1]*v[3]
            local an = v[1]*v[2]^2
            return vt, at, an, math.sqrt(at^2 + an^2)
        end
    })

    calculators.projectileMotion = Calculator.new({
        id = "projectileMotion",
        title = "Projectile Motion",
        subtitle = "No air resistance; landing height is zero",
        inputs = {
            {label="Initial speed",unit="m/s"},
            {label="Launch angle",unit="degrees"},
            {label="Initial height",unit="m"}
        },
        outputs = {
            {label="Flight time",unit="s"},
            {label="Range",unit="m"},
            {label="Maximum height",unit="m"},
            {label="Impact speed",unit="m/s"}
        },
        validate = function(v)
            return nonnegative(v[1], "Initial speed") or nonnegative(v[3], "Initial height")
        end,
        calculate = function(v)
            local angle = v[2]*math.pi/180
            local vx = v[1]*math.cos(angle)
            local vy = v[1]*math.sin(angle)
            local time = (vy + math.sqrt(vy^2 + 2*G_ACCEL*v[3]))/G_ACCEL
            local range = vx*time
            local hmax = v[3] + vy^2/(2*G_ACCEL)
            local vyImpact = vy - G_ACCEL*time
            return time, range, hmax, math.sqrt(vx^2 + vyImpact^2)
        end
    })

    -- Newton's second law and force/work relations
    local fmaVars = {{label="Force F",unit="N"},{label="Mass m",unit="kg"},{label="Acceleration a",unit="m/s^2"}}
    calculators.newtonsSecondLaw = oneBlankDefinition(
        "newtonsSecondLaw", "Newton's Second Law", "F = ma; leave one field blank", fmaVars,
        function(v, missing)
            if v[2] and v[2] <= 0 then return "Mass must be greater than zero" end
            if missing == 2 and v[3] == 0 then return "Acceleration cannot be zero when solving mass" end
        end,
        function(v, missing)
            if missing == 1 then return v[2]*v[3] end
            if missing == 2 then return v[1]/v[3] end
            return v[1]/v[2]
        end
    )

    calculators.workConstantForce = Calculator.new({
        id="workConstantForce", title="Work by Constant Force",
        inputs={{label="Force F",unit="N"},{label="Displacement d",unit="m"},{label="Angle",unit="degrees"}},
        outputs={{label="Work",unit="J"}},
        validate=function(v) return nonnegative(v[2],"Displacement") end,
        calculate=function(v) return v[1]*v[2]*math.cos(v[3]*math.pi/180) end
    })

    calculators.kineticEnergy = Calculator.new({
        id="kineticEnergy", title="Kinetic Energy",
        inputs={{label="Mass m",unit="kg"},{label="Speed v",unit="m/s"}},
        outputs={{label="Kinetic energy",unit="J"}},
        validate=function(v) return positive(v[1],"Mass") or nonnegative(v[2],"Speed") end,
        calculate=function(v) return 0.5*v[1]*v[2]^2 end
    })

    calculators.potentialEnergy = Calculator.new({
        id="potentialEnergy", title="Gravitational Potential Energy",
        inputs={{label="Mass m",unit="kg"},{label="Height h",unit="m"},{label="Gravity g",unit="m/s^2"}},
        outputs={{label="Potential energy",unit="J"}},
        validate=function(v) return positive(v[1],"Mass") or positive(v[3],"Gravity") end,
        calculate=function(v) return v[1]*v[3]*v[2] end
    })

    calculators.springEnergy = Calculator.new({
        id="springEnergy", title="Spring Energy",
        inputs={{label="Spring constant k",unit="N/m"},{label="Deflection x",unit="m"}},
        outputs={{label="Elastic energy",unit="J"}},
        validate=function(v) return positive(v[1],"Spring constant") end,
        calculate=function(v) return 0.5*v[1]*v[2]^2 end
    })

    calculators.linearPower = Calculator.new({
        id="linearPower", title="Mechanical Power",
        subtitle="P = Fv cos(theta)",
        inputs={{label="Force F",unit="N"},{label="Velocity v",unit="m/s"},{label="Angle",unit="degrees"}},
        outputs={{label="Power",unit="W"}},
        calculate=function(v) return v[1]*v[2]*math.cos(v[3]*math.pi/180) end
    })

    -- Momentum and impacts
    calculators.linearMomentum = Calculator.new({
        id="linearMomentum", title="Linear Momentum",
        inputs={{label="Mass m",unit="kg"},{label="Velocity v",unit="m/s"}},
        outputs={{label="Momentum",unit="kg*m/s"}},
        validate=function(v) return positive(v[1],"Mass") end,
        calculate=function(v) return v[1]*v[2] end
    })

    calculators.impulseMomentum = Calculator.new({
        id="impulseMomentum", title="Impulse-Momentum",
        inputs={{label="Mass m",unit="kg"},{label="Initial velocity",unit="m/s"},{label="Final velocity",unit="m/s"}},
        outputs={{label="Impulse",unit="N*s"},{label="Change in momentum",unit="kg*m/s"}},
        validate=function(v) return positive(v[1],"Mass") end,
        calculate=function(v) local j=v[1]*(v[3]-v[2]); return j,j end
    })

    calculators.inelasticCollision = Calculator.new({
        id="inelasticCollision", title="Perfectly Inelastic Collision",
        subtitle="Bodies stick together after a one-dimensional collision",
        inputs={{label="Mass m1",unit="kg"},{label="Velocity u1",unit="m/s"},{label="Mass m2",unit="kg"},{label="Velocity u2",unit="m/s"}},
        outputs={{label="Common final velocity",unit="m/s"},{label="Kinetic energy lost",unit="J"}},
        validate=function(v) return positive(v[1],"Mass m1") or positive(v[3],"Mass m2") end,
        calculate=function(v)
            local vf=(v[1]*v[2]+v[3]*v[4])/(v[1]+v[3])
            local initial=0.5*v[1]*v[2]^2+0.5*v[3]*v[4]^2
            local final=0.5*(v[1]+v[3])*vf^2
            return vf,initial-final
        end
    })

    calculators.restitutionCollision = Calculator.new({
        id="restitutionCollision", title="1D Collision with Restitution",
        inputs={{label="Mass m1",unit="kg"},{label="Initial u1",unit="m/s"},{label="Mass m2",unit="kg"},{label="Initial u2",unit="m/s"},{label="Restitution e"}},
        outputs={{label="Final velocity v1",unit="m/s"},{label="Final velocity v2",unit="m/s"}},
        validate=function(v)
            if v[1]<=0 or v[3]<=0 then return "Masses must be greater than zero" end
            if v[5]<0 or v[5]>1 then return "Restitution must be from 0 to 1" end
        end,
        calculate=function(v)
            local total=v[1]+v[3]
            local v1=(v[1]*v[2]+v[3]*v[4]-v[3]*v[5]*(v[2]-v[4]))/total
            local v2=(v[1]*v[2]+v[3]*v[4]+v[1]*v[5]*(v[2]-v[4]))/total
            return v1,v2
        end
    })

    -- Rotation
    calculators.rotationalDynamics = Calculator.new({
        id="rotationalDynamics", title="Rotational Dynamics",
        inputs={{label="Moment of inertia I",unit="kg*m^2"},{label="Angular velocity",unit="rad/s"},{label="Angular acceleration",unit="rad/s^2"}},
        outputs={{label="Angular momentum",unit="kg*m^2/s"},{label="Rotational energy",unit="J"},{label="Torque",unit="N*m"}},
        validate=function(v) return positive(v[1],"Moment of inertia") end,
        calculate=function(v) return v[1]*v[2],0.5*v[1]*v[2]^2,v[1]*v[3] end
    })

    calculators.parallelAxis = Calculator.new({
        id="parallelAxis", title="Parallel-Axis Theorem",
        inputs={{label="Centroidal inertia",unit="kg*m^2"},{label="Mass m",unit="kg"},{label="Offset d",unit="m"}},
        outputs={{label="Shifted inertia",unit="kg*m^2"}},
        validate=function(v) return nonnegative(v[1],"Centroidal inertia") or positive(v[2],"Mass") or nonnegative(v[3],"Offset") end,
        calculate=function(v) return v[1]+v[2]*v[3]^2 end
    })

    calculators.inertiaCommonShapes = Calculator.new({
        id="inertiaCommonShapes", title="Common Mass Moments of Inertia",
        subtitle="Returns several shapes from the same mass and dimensions",
        inputs={{label="Mass m",unit="kg"},{label="Radius r",unit="m"},{label="Length L",unit="m"}},
        outputs={{label="Solid disk/cylinder",unit="kg*m^2"},{label="Thin ring",unit="kg*m^2"},{label="Solid sphere",unit="kg*m^2"},{label="Slender rod, centre",unit="kg*m^2"}},
        validate=function(v) return positive(v[1],"Mass") or nonnegative(v[2],"Radius") or nonnegative(v[3],"Length") end,
        calculate=function(v) return 0.5*v[1]*v[2]^2,v[1]*v[2]^2,0.4*v[1]*v[2]^2,v[1]*v[3]^2/12 end
    })
end
