-- Register AC/RLC calculators and extend Circuit Analysis.

registerRLCCalculators(calculators)

local rlcCoreMenu = {
    title = "RLC Impedance",
    subtitle = "Reactance and equivalent impedance",
    items = {
        {label="Reactance Calculator",calculator="rlcReactance"},
        {label="Series RLC Impedance",calculator="seriesRLC"},
        {label="Parallel RLC Impedance",calculator="parallelRLC"}
    }
}

local rlcResonanceMenu = {
    title = "Resonance and Bandwidth",
    subtitle = "Natural frequency, Q, and half-power points",
    items = {
        {label="Resonant Frequency",calculator="rlcResonance"},
        {label="Series RLC Q / Bandwidth",calculator="seriesRLCBandwidth"},
        {label="Parallel RLC Q / Bandwidth",calculator="parallelRLCBandwidth"}
    }
}

local rlcPowerMenu = {
    title = "AC Power and Dividers",
    subtitle = "Complex power and phasor divider tools",
    items = {
        {label="AC Complex Power",calculator="acPower"},
        {label="AC Voltage Divider",calculator="acVoltageDivider"},
        {label="AC Current Divider",calculator="acCurrentDivider"}
    }
}

local rlcMenu = {
    title = "AC and RLC Circuits",
    subtitle = "Impedance, resonance, power, and phasors",
    items = {
        {label="RLC Impedance",menu=rlcCoreMenu},
        {label="Resonance and Bandwidth",menu=rlcResonanceMenu},
        {label="AC Power and Dividers",menu=rlcPowerMenu}
    }
}

table.insert(circuitMenu.items, {label="AC and RLC Circuits",menu=rlcMenu})
