-- Flexible Solve-by-Topic workspaces for electromagnetic rail launchers.
-- Covers a uniform external magnetic field and the self-field of two rails.
-- Intentionally uses table fields rather than many top-level locals to keep
-- Luna's per-chunk local-variable count low.

RailLauncher = RailLauncher or {}
RailLauncher.mu0 = 4 * math.pi * 1e-7

RailLauncher.externalQuantities = {
    {key="I",label="Current I",unit="A"},
    {key="H",label="Half rail spacing H",unit="m"},
    {key="width",label="Object length / rail spacing 2H",unit="m"},
    {key="B",label="External magnetic field B",unit="T"},
    {key="m",label="Object mass m",unit="kg"},
    {key="L",label="Rail length L",unit="m"},
    {key="vi",label="Initial velocity vi",unit="m/s"},
    {key="vf",label="Final velocity vf",unit="m/s"},
    {key="F",label="Magnetic force F",unit="N"},
    {key="W",label="Work W",unit="J"}
}

RailLauncher.selfQuantities = {
    {key="I",label="Current I",unit="A"},
    {key="H",label="Half center spacing H",unit="m"},
    {key="spacing",label="Center spacing 2H",unit="m"},
    {key="a",label="Rail radius a",unit="m"},
    {key="m",label="Object mass m",unit="kg"},
    {key="L",label="Rail length L",unit="m"},
    {key="vi",label="Initial velocity vi",unit="m/s"},
    {key="vf",label="Final velocity vf",unit="m/s"},
    {key="logFactor",label="Geometry log factor"},
    {key="F",label="Magnetic force F",unit="N"},
    {key="W",label="Work W",unit="J"}
}

function RailLauncher.makeInputs(quantities)
    local inputs={}
    for i,q in ipairs(quantities) do inputs[i]={label=q.label,unit=q.unit} end
    return inputs
end

function RailLauncher.makeOutput(q,source)
    return {label=q.label .. (source=="entered" and " [entered]" or " [calc]"),unit=q.unit,variable=q.key}
end

function RailLauncher.solveCalculator(definition)
    local lastOutputs={}
    local quantities=definition.quantities
    return Calculator.new({
        id=definition.id,
        title=definition.title,
        subtitle="Enter any known values; leave the rest blank",
        inputs=RailLauncher.makeInputs(quantities),
        outputs={{label="Result"}},
        allowOptionalInputs=true,
        minimumInputs=1,
        visibleInputCount=5,
        resolveOutputs=function() return lastOutputs end,
        validate=definition.validate,
        calculate=function(v)
            local initial={}
            for i,q in ipairs(quantities) do if v[i]~=nil then initial[q.key]=v[i] end end
            local solved,sources=TopicDependency.solve(initial,definition.relations)
            lastOutputs={}
            local results={}
            for _,q in ipairs(quantities) do
                if type(solved[q.key])=="number" then
                    table.insert(lastOutputs,RailLauncher.makeOutput(q,sources[q.key]))
                    table.insert(results,solved[q.key])
                end
            end
            if #results==0 then error("No quantities could be determined") end
            return unpack(results)
        end
    })
end

RailLauncher.externalRelations = {
    {needs={"H"},gives="width",label="2H",solve=function(v) return 2*v.H end},
    {needs={"width"},gives="H",label="H = width/2",solve=function(v) return v.width/2 end},
    {needs={},gives="vi",label="initially at rest",solve=function() return 0 end},

    {needs={"I","width","B"},gives="F",label="F = I(2H)B",solve=function(v) return v.I*v.width*v.B end},
    {needs={"F","width","B"},gives="I",label="I = F/((2H)B)",solve=function(v) if v.width==0 or v.B==0 then error() end return v.F/(v.width*v.B) end},
    {needs={"F","I","B"},gives="width",label="2H = F/(IB)",solve=function(v) if v.I==0 or v.B==0 then error() end return v.F/(v.I*v.B) end},
    {needs={"F","I","width"},gives="B",label="B = F/(I(2H))",solve=function(v) if v.I==0 or v.width==0 then error() end return v.F/(v.I*v.width) end},

    {needs={"F","L"},gives="W",label="W = FL",solve=function(v) return v.F*v.L end},
    {needs={"W","L"},gives="F",label="F = W/L",solve=function(v) if v.L==0 then error() end return v.W/v.L end},
    {needs={"W","F"},gives="L",label="L = W/F",solve=function(v) if v.F==0 then error() end return v.W/v.F end},

    {needs={"m","vi","vf"},gives="W",label="work-energy theorem",solve=function(v) return 0.5*v.m*(v.vf*v.vf-v.vi*v.vi) end},
    {needs={"W","m","vi"},gives="vf",label="final velocity from work",solve=function(v) if v.m<=0 then error() end local x=v.vi*v.vi+2*v.W/v.m; if x<0 then error() end return math.sqrt(x) end},
    {needs={"W","m","vf"},gives="vi",label="initial velocity from work",solve=function(v) if v.m<=0 then error() end local x=v.vf*v.vf-2*v.W/v.m; if x<0 then error() end return math.sqrt(x) end},
    {needs={"W","vi","vf"},gives="m",label="mass from work-energy",solve=function(v) local d=v.vf*v.vf-v.vi*v.vi; if d==0 then error() end return 2*v.W/d end}
}

RailLauncher.selfRelations = {
    {needs={"H"},gives="spacing",label="2H",solve=function(v) return 2*v.H end},
    {needs={"spacing"},gives="H",label="H = spacing/2",solve=function(v) return v.spacing/2 end},
    {needs={},gives="vi",label="initially at rest",solve=function() return 0 end},

    -- For two infinitely long rails carrying equal/opposite currents, integrated
    -- over a crossbar from the inner surface of one rail to the other.
    {needs={"H","a"},gives="logFactor",label="ln((2H-a)/a)",solve=function(v) if v.H<=0 or v.a<=0 or 2*v.H<=2*v.a then error() end return math.log((2*v.H-v.a)/v.a) end},
    {needs={"I","logFactor"},gives="F",label="self-field magnetic force",solve=function(v) return (RailLauncher.mu0*v.I*v.I/math.pi)*v.logFactor end},
    {needs={"F","logFactor"},gives="I",label="current from self-field force",solve=function(v) if v.logFactor<=0 or v.F<0 then error() end return math.sqrt(math.pi*v.F/(RailLauncher.mu0*v.logFactor)) end},
    {needs={"F","I"},gives="logFactor",label="geometry factor from force",solve=function(v) if v.I==0 then error() end return math.pi*v.F/(RailLauncher.mu0*v.I*v.I) end},

    {needs={"F","L"},gives="W",label="W = FL",solve=function(v) return v.F*v.L end},
    {needs={"W","L"},gives="F",label="F = W/L",solve=function(v) if v.L==0 then error() end return v.W/v.L end},
    {needs={"W","F"},gives="L",label="L = W/F",solve=function(v) if v.F==0 then error() end return v.W/v.F end},

    {needs={"m","vi","vf"},gives="W",label="work-energy theorem",solve=function(v) return 0.5*v.m*(v.vf*v.vf-v.vi*v.vi) end},
    {needs={"W","m","vi"},gives="vf",label="final velocity from work",solve=function(v) if v.m<=0 then error() end local x=v.vi*v.vi+2*v.W/v.m; if x<0 then error() end return math.sqrt(x) end},
    {needs={"W","m","vf"},gives="vi",label="initial velocity from work",solve=function(v) if v.m<=0 then error() end local x=v.vf*v.vf-2*v.W/v.m; if x<0 then error() end return math.sqrt(x) end},
    {needs={"W","vi","vf"},gives="m",label="mass from work-energy",solve=function(v) local d=v.vf*v.vf-v.vi*v.vi; if d==0 then error() end return 2*v.W/d end}
}

function registerRailLauncherTopics(calculators)
    calculators.topicRailExternal=RailLauncher.solveCalculator({
        id="topicRailExternal",
        title="Rail Launcher - External B",
        quantities=RailLauncher.externalQuantities,
        relations=RailLauncher.externalRelations,
        validate=function(v)
            if v[2]~=nil and v[2]<=0 then return "H must be positive" end
            if v[3]~=nil and v[3]<=0 then return "Rail spacing must be positive" end
            if v[5]~=nil and v[5]<=0 then return "Mass must be positive" end
            if v[6]~=nil and v[6]<0 then return "Rail length cannot be negative" end
        end
    })

    calculators.topicRailSelf=RailLauncher.solveCalculator({
        id="topicRailSelf",
        title="Rail Launcher - Self Field",
        quantities=RailLauncher.selfQuantities,
        relations=RailLauncher.selfRelations,
        validate=function(v)
            if v[2]~=nil and v[2]<=0 then return "H must be positive" end
            if v[3]~=nil and v[3]<=0 then return "Center spacing must be positive" end
            if v[4]~=nil and v[4]<=0 then return "Rail radius must be positive" end
            if v[2]~=nil and v[4]~=nil and v[4]>=v[2] then return "Rail radius must be smaller than H" end
            if v[5]~=nil and v[5]<=0 then return "Mass must be positive" end
            if v[6]~=nil and v[6]<0 then return "Rail length cannot be negative" end
        end
    })
end
