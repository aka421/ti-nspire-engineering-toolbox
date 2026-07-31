-- Register Thermodynamics calculators and replace the Mechanical Engineering placeholder.

registerThermodynamicsCalculators(calculators)

local thermoPropertiesMenu = {
    title = "Thermodynamic Properties",
    subtitle = "Ideal gases and caloric properties",
    items = {
        {label="Ideal Gas Law",calculator="idealGasLaw"},
        {label="Density / Specific Volume",calculator="densitySpecificVolume"},
        {label="Sensible Heat",calculator="sensibleHeat"}
    }
}

local thermoFirstLawMenu = {
    title = "First Law",
    subtitle = "Energy balances for closed and open systems",
    items = {
        {label="Closed-System First Law",calculator="closedSystemFirstLaw"},
        {label="Enthalpy Change",calculator="enthalpyChange"},
        {label="Constant-Pressure Work",calculator="constantPressureWork"},
        {label="Steady-Flow Energy Equation",calculator="steadyFlowEnergy"}
    }
}

local thermoProcessesMenu = {
    title = "Ideal-Gas Processes",
    subtitle = "Common quasi-equilibrium process relations",
    items = {
        {label="Isothermal Process",calculator="isothermalIdealGas"},
        {label="Isentropic Process",calculator="isentropicIdealGas"},
        {label="Polytropic Process",calculator="polytropicProcess"}
    }
}

local thermoCyclesMenu = {
    title = "Thermodynamic Cycles",
    subtitle = "Ideal cycle performance",
    items = {
        {label="Carnot Efficiency and COP",calculator="carnotEfficiency"},
        {label="Otto-Cycle Efficiency",calculator="ottoEfficiency"},
        {label="Brayton-Cycle Efficiency",calculator="braytonEfficiency"}
    }
}

local heatTransferMenu = {
    title = "Heat Transfer",
    subtitle = "Conduction, convection, and radiation",
    items = {
        {label="Plane-Wall Conduction",calculator="fourierConduction"},
        {label="Convection",calculator="convectionHeatTransfer"},
        {label="Thermal Radiation",calculator="radiationHeatTransfer"},
        {label="Series Thermal Resistance",calculator="thermalResistanceSeries"}
    }
}

local thermodynamicsMenu = {
    title = "Thermodynamics",
    subtitle = "Properties, energy, processes, cycles, and heat transfer",
    items = {
        {label="Properties",menu=thermoPropertiesMenu},
        {label="First Law",menu=thermoFirstLawMenu},
        {label="Processes",menu=thermoProcessesMenu},
        {label="Cycles",menu=thermoCyclesMenu},
        {label="Heat Transfer",menu=heatTransferMenu}
    }
}

for _, item in ipairs(mechanicalEngineeringMenu.items) do
    if item.label == "Thermodynamics" then
        item.menu = thermodynamicsMenu
        break
    end
end
