-- Register transient calculators and Solve-by-Topic workspaces, then extend menus.

registerTransientCalculators(calculators)
registerTopicSolvers(calculators)

local firstOrderMenu = {
    title="First-Order Circuits", subtitle="RC and RL step and decay responses",
    items={
        {label="RC Charging",calculator="rcCharging"},
        {label="RC Discharging",calculator="rcDischarging"},
        {label="RL Step Response",calculator="rlStep"},
        {label="RL Current Decay",calculator="rlDecay"},
        {label="Generic First-Order Response",calculator="firstOrderResponse"},
        {label="Time to Reach Value",calculator="firstOrderTime"}
    }
}

local secondOrderMenu = {
    title="Second-Order Circuits", subtitle="Series RLC natural response properties",
    items={
        {label="Series RLC Properties",calculator="seriesRLCTransient"},
        {label="RLC Natural Roots",calculator="rlcNaturalRoots"}
    }
}

local transientMenu = {
    title="Transient Analysis", subtitle="First- and second-order circuit response",
    items={{label="First-Order Circuits",menu=firstOrderMenu},{label="Second-Order Circuits",menu=secondOrderMenu}}
}

table.insert(circuitMenu.items,{label="Transient Analysis",menu=transientMenu})

local electricalTopicsMenu = {
    title="Electrical Topics",
    subtitle="Enter known values and calculate the full topic",
    items={{label="Series RLC",calculator="topicSeriesRLC"}}
}

local solveByTopicMenu = {
    title="Solve by Topic",
    subtitle="Workspaces that calculate related quantities together",
    items={{label="Electrical",menu=electricalTopicsMenu}}
}

table.insert(rootMenu.items,2,{label="Solve by Topic",menu=solveByTopicMenu})
