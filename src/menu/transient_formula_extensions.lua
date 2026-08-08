-- Register transient calculators and add Transient Analysis to Circuit Analysis.

registerTransientCalculators(calculators)

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
    items={
        {label="First-Order Circuits",menu=firstOrderMenu},
        {label="Second-Order Circuits",menu=secondOrderMenu}
    }
}

table.insert(circuitMenu.items,{label="Transient Analysis",menu=transientMenu})
