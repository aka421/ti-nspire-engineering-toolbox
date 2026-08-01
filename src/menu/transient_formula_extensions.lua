-- Register transient calculators and formula solvers, then extend menus.

registerTransientCalculators(calculators)
registerFormulaSolvers(calculators)

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

local electricalFormulaMenu={title="Electrical Formulas",subtitle="Leave exactly one variable blank",items={{label="Ohm's Law",calculator="formulaOhm"},{label="Electrical Power",calculator="formulaPower"},{label="Wave Relation",calculator="formulaWave"}}}
local mechanicalFormulaMenu={title="Mechanical Formulas",subtitle="Leave exactly one variable blank",items={{label="Newton's Second Law",calculator="formulaForce"},{label="Density",calculator="formulaDensity"},{label="Pressure",calculator="formulaPressure"},{label="Normal Stress",calculator="formulaStress"}}}
local thermalFormulaMenu={title="Thermal Formulas",subtitle="Leave exactly one variable blank",items={{label="Ideal Gas Law",calculator="formulaIdealGas"},{label="Sensible Heat",calculator="formulaHeat"}}}
local formulaSolverMenu={title="Formula Solver",subtitle="Choose an equation and leave one variable blank",items={{label="Electrical",menu=electricalFormulaMenu},{label="Mechanical",menu=mechanicalFormulaMenu},{label="Thermal",menu=thermalFormulaMenu}}}

table.insert(rootMenu.items,2,{label="Formula Solver",menu=formulaSolverMenu})
