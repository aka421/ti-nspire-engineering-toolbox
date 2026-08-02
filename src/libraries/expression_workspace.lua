-- Extend the expression parser with global workspace variables.

local baseExpressionEvaluate = expression.evaluate

local reservedNames = {
    ans=true, pi=true, e=true,
    sqrt=true, abs=true, exp=true, ln=true, log=true,
    sin=true, cos=true, tan=true, asin=true, acos=true, atan=true
}

local function substituteWorkspaceVariables(text)
    return string.gsub(text, "([%a_][%w_]*)", function(name)
        local lower = string.lower(name)
        if reservedNames[lower] then return name end
        local value = Workspace.get(name)
        if value == nil then return name end
        return "(" .. string.format("%.17g", value) .. ")"
    end)
end

function expression.evaluate(text)
    if text == nil then return nil, "empty expression" end
    return baseExpressionEvaluate(substituteWorkspaceVariables(text))
end

function expression.setVariable(name, value)
    return Workspace.set(name, value)
end

function expression.getVariable(name)
    return Workspace.get(name)
end
