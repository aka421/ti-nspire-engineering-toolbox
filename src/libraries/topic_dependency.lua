-- Reusable dependency/constraint solver for Solve-by-Topic workspaces.
-- Repeatedly applies relationships whose required quantities are known.

TopicDependency = {}

local function finiteNumber(value)
    return type(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
end

local function requirementsKnown(values, needs)
    for _, name in ipairs(needs or {}) do
        if not finiteNumber(values[name]) then return false end
    end
    return true
end

function TopicDependency.solve(initialValues, relations, maxPasses)
    local values = {}
    local sources = {}

    for name, value in pairs(initialValues or {}) do
        if finiteNumber(value) then
            values[name] = value
            sources[name] = "entered"
        end
    end

    local passes = 0
    local changed = true
    maxPasses = maxPasses or 30

    while changed and passes < maxPasses do
        changed = false
        passes = passes + 1

        for _, relation in ipairs(relations or {}) do
            if requirementsKnown(values, relation.needs) then
                local gives = relation.gives
                local missing = false

                if type(gives) == "table" then
                    for _, name in ipairs(gives) do
                        if not finiteNumber(values[name]) then missing = true; break end
                    end
                else
                    missing = not finiteNumber(values[gives])
                end

                if missing then
                    local ok, result = pcall(relation.solve, values)
                    if ok then
                        if type(gives) == "table" and type(result) == "table" then
                            for _, name in ipairs(gives) do
                                local value = result[name]
                                if not finiteNumber(values[name]) and finiteNumber(value) then
                                    values[name] = value
                                    sources[name] = relation.label or "calculated"
                                    changed = true
                                end
                            end
                        elseif type(gives) == "string" and finiteNumber(result) then
                            values[gives] = result
                            sources[gives] = relation.label or "calculated"
                            changed = true
                        end
                    end
                end
            end
        end
    end

    return values, sources
end

function TopicDependency.count(values)
    local count = 0
    for _, value in pairs(values or {}) do if finiteNumber(value) then count = count + 1 end end
    return count
end
