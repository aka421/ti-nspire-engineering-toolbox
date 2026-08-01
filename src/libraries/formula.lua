-- Reusable framework for equations that can solve one missing variable.

Formula = {}

local function outputForMissing(definition, missing)
    local variable = definition.variables[missing]
    return {{label=variable.label,unit=variable.unit}}
end

function Formula.calculator(definition)
    local inputs = {}
    for i, variable in ipairs(definition.variables) do
        inputs[i] = {label=variable.label,unit=variable.unit}
    end

    return Calculator.new({
        id=definition.id,
        title=definition.title,
        subtitle=definition.equation or "Leave one variable blank",
        inputs=inputs,
        outputs={{label="Result"}},
        allowOneBlank=true,
        resolveOutputs=function(_,missing) return outputForMissing(definition,missing) end,
        validate=function(values,missing)
            if definition.validate then return definition.validate(values,missing) end
        end,
        calculate=function(values,missing)
            local result=definition.solve(values,missing)
            if result==nil or result~=result or result==math.huge or result==-math.huge then error("invalid formula result") end
            return result
        end
    })
end

function Formula.requireNonzero(values,index,name,missing)
    if index~=missing and values[index]==0 then return name .. " cannot be zero" end
end

function Formula.requirePositive(values,index,name,missing)
    if index~=missing and values[index]<=0 then return name .. " must be greater than zero" end
end
