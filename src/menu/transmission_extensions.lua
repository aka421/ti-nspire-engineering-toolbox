-- Extend the Transmission Lines menus after main.lua defines them.

table.insert(transmissionTransformsMenu.items, 3, {
    label = "Characteristic Impedance",
    calculator = "characteristicImpedance"
})

table.insert(transmissionTransformsMenu.items, 4, {
    label = "Line Parameters",
    calculator = "lineParameters"
})

table.insert(transmissionTransformsMenu.items, 5, {
    label = "Voltage/Current Maxima",
    calculator = "voltageCurrentMaxima"
})

table.insert(transmissionMetricsMenu.items, {
    label = "Power from Forward Voltage",
    calculator = "transmissionAveragePower"
})

table.insert(transmissionMetricsMenu.items, {
    label = "Power from Load Voltage",
    calculator = "transmissionPowerFromLoadVoltage"
})
