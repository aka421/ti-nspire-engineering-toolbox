-- Global numeric workspace shared by every calculator.

Workspace = Workspace or {
    variables = {},
    recentNames = {}
}

local function canonical(name)
    if type(name) ~= "string" then return nil end
    return string.lower(name)
end

local function rememberName(name)
    local key = canonical(name)
    for i = #Workspace.recentNames, 1, -1 do
        if canonical(Workspace.recentNames[i]) == key then table.remove(Workspace.recentNames, i) end
    end
    table.insert(Workspace.recentNames, 1, name)
    while #Workspace.recentNames > 20 do table.remove(Workspace.recentNames) end
end

function Workspace.set(name, value)
    if type(name) ~= "string" or type(value) ~= "number" then return false end
    if value ~= value or value == math.huge or value == -math.huge then return false end
    local key = canonical(name)
    Workspace.variables[key] = {name=name, value=value}
    rememberName(name)
    return true
end

function Workspace.get(name)
    local entry = Workspace.variables[canonical(name)]
    return entry and entry.value or nil
end

function Workspace.clear(name)
    local key = canonical(name)
    Workspace.variables[key] = nil
    for i = #Workspace.recentNames, 1, -1 do
        if canonical(Workspace.recentNames[i]) == key then table.remove(Workspace.recentNames, i) end
    end
end

function Workspace.clearAll()
    Workspace.variables = {}
    Workspace.recentNames = {}
end

function Workspace.sanitizeName(label)
    local name = string.gsub(label or "", "[^%w_]", "")
    if name == "" or string.match(name, "^%d") then return nil end
    return name
end

function Workspace.storeResults(outputs, results)
    for i, value in ipairs(results or {}) do
        if type(value) == "number" then
            Workspace.set("Out" .. i, value)
            local output = outputs and outputs[i]
            local name = output and (output.variable or Workspace.sanitizeName(output.label))
            if name then Workspace.set(name, value) end
        end
    end
end

-- Initialize conventional calculator memory slots.
for code = string.byte("A"), string.byte("J") do
    local name = string.char(code)
    if Workspace.get(name) == nil then Workspace.set(name, 0) end
end
