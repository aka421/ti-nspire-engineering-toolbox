-- Workspace memory calculators and automatic result storage.

local baseCalculatorCalculate = Calculator.calculate

function Calculator:calculate()
    local success = baseCalculatorCalculate(self)
    if success then
        local outputs = self.resultOutputs or self.outputs
        Workspace.storeResults(outputs, self.results)
    end
    return success
end

local function memoryInputs()
    local inputs = {}
    for code = string.byte("A"), string.byte("J") do
        local name = string.char(code)
        table.insert(inputs, {label="Store " .. name})
    end
    return inputs
end

local function memoryOutputs()
    local outputs = {}
    for code = string.byte("A"), string.byte("J") do
        local name = string.char(code)
        table.insert(outputs, {label=name, variable=name})
    end
    return outputs
end

function registerWorkspaceMemoryCalculators(calculators)
    calculators.workspaceMemory = Calculator.new({
        id="workspaceMemory",
        title="Workspace Memory A-J",
        subtitle="Enter expressions for slots to change; blanks keep old values",
        inputs=memoryInputs(),
        outputs=memoryOutputs(),
        allowOptionalInputs=true,
        minimumInputs=1,
        visibleInputCount=5,
        calculate=function(v)
            local results = {}
            for i = 1, 10 do
                local name = string.char(string.byte("A") + i - 1)
                if v[i] ~= nil then Workspace.set(name, v[i]) end
                results[i] = Workspace.get(name) or 0
            end
            return unpack(results)
        end
    })

    calculators.workspaceRecall = Calculator.new({
        id="workspaceRecall",
        title="Recall Workspace Values",
        subtitle="Results also auto-store as Out1, Out2, and descriptive names",
        inputs={{label="Enter any expression using A-J or Out1"}},
        outputs={{label="Value",variable="Recall"}},
        calculate=function(v) return v[1] end
    })
end
