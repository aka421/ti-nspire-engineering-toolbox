-- TI-Nspire Engineering Toolbox
-- Application menu tree and navigation.

platform.apiLevel = "2.0"

local calculators = {}
registerComplexCalculators(calculators)
registerCircuitCalculators(calculators)
registerElectromagneticsCalculators(calculators)
registerWaveCalculators(calculators)
registerTransmissionCalculators(calculators)
registerCoordinateCalculators(calculators)

local complexArithmeticMenu={title="Complex Arithmetic",subtitle="Choose an operation",items={{label="Add",calculator="complexAdd"},{label="Subtract",calculator="complexSubtract"},{label="Multiply",calculator="complexMultiply"},{label="Divide",calculator="complexDivide"}}}
local complexMenu={title="Complex Numbers",subtitle="Enter to select, Esc to return",items={{label="Rectangular to Polar",calculator="rectToPolar"},{label="Polar to Rectangular",calculator="polarToRect"},{label="Magnitude and Phase",calculator="magnitudePhase"},{label="Complex Arithmetic",menu=complexArithmeticMenu}}}

local basicCircuitsMenu={title="Basic Circuits",subtitle="Enter to select, Esc to return",items={{label="Ohm's Law",calculator="ohmsLaw"},{label="Electrical Power",calculator="electricalPower"},{label="Voltage Divider",calculator="voltageDivider"},{label="Current Divider",calculator="currentDivider"}}}
local resistorNetworksMenu={title="Resistor Networks",subtitle="Equivalent resistance and conversions",items={{label="Series Resistance",calculator="seriesResistance"},{label="Parallel Resistance",calculator="parallelResistance"},{label="Delta to Wye",calculator="deltaToWye"},{label="Wye to Delta",calculator="wyeToDelta"}}}
local sourceTransformationMenu={title="Source Transformation",subtitle="Choose the source conversion direction",items={{label="Voltage to Current",calculator="voltageToCurrentSource"},{label="Current to Voltage",calculator="currentToVoltageSource"}}}
local equivalentConversionMenu={title="Thevenin and Norton",subtitle="Choose the equivalent conversion direction",items={{label="Thevenin to Norton",calculator="theveninToNorton"},{label="Norton to Thevenin",calculator="nortonToThevenin"}}}
local networkTheoremsMenu={title="Network Theorems",subtitle="Source and equivalent-circuit conversions",items={{label="Thevenin / Norton",menu=equivalentConversionMenu},{label="Source Transformation",menu=sourceTransformationMenu}}}
local equationSolversMenu={title="Equation Solvers",subtitle="Solve circuit equation systems",items={{label="Two-Mesh Solver",calculator="meshTwo"},{label="Three-Mesh Solver"}}}
local circuitMenu={title="Circuit Analysis",subtitle="Choose a category",items={{label="Basic Circuits",menu=basicCircuitsMenu},{label="Resistor Networks",menu=resistorNetworksMenu},{label="Network Theorems",menu=networkTheoremsMenu},{label="Equation Solvers",menu=equationSolversMenu}}}

local vectorOperationsMenu={title="Vector Operations",subtitle="Three-dimensional Cartesian vectors",items={{label="Magnitude",calculator="vectorMagnitude"},{label="Unit Vector",calculator="vectorUnit"},{label="Dot Product",calculator="vectorDot"},{label="Cross Product",calculator="vectorCross"},{label="Angle Between",calculator="vectorAngle"},{label="Projection A onto B",calculator="vectorProjection"}}}
local coordinateSystemsMenu={title="Coordinate Systems",subtitle="Points and vector components",items={{label="Cartesian to Cylindrical",calculator="cartesianToCylindrical"},{label="Cylindrical to Cartesian",calculator="cylindricalToCartesian"},{label="Cartesian to Spherical",calculator="cartesianToSpherical"},{label="Spherical to Cartesian",calculator="sphericalToCartesian"},{label="Cyl Vector to Cartesian",calculator="cylindricalVectorToCartesian"},{label="Sph Vector to Cartesian",calculator="sphericalVectorToCartesian"}}}
local generalMathMenu={title="General Math",subtitle="Reusable mathematical tools",items={{label="Vector Operations",menu=vectorOperationsMenu},{label="Coordinate Systems",menu=coordinateSystemsMenu}}}

local electrostaticsMenu={title="Electrostatics",subtitle="Charges, fields, flux, and capacitance",items={{label="Coulomb's Law",calculator="coulombsLaw"},{label="Point-Charge Electric Field",calculator="pointChargeField"},{label="Electric Potential",calculator="pointChargePotential"},{label="Force on a Charge",calculator="forceOnCharge"},{label="Gauss's Law",calculator="gaussLaw"},{label="Parallel-Plate Capacitance",calculator="parallelPlateCapacitance"}}}

local magneticFieldsMenu={title="Magnetic Fields",subtitle="Fields from common current distributions",items={{label="Infinite Straight Wire",calculator="infiniteWireField"},{label="Finite Straight Wire",calculator="finiteWireField"},{label="Circular Loop",calculator="circularLoopField"},{label="Ideal Solenoid",calculator="solenoidField"},{label="Ideal Toroid",calculator="toroidField"}}}
local magneticForcesMenu={title="Magnetic Forces",subtitle="Lorentz force, wire force, and torque",items={{label="Force on Moving Charge",calculator="movingChargeMagneticForce"},{label="Force on Current-Carrying Wire",calculator="currentWireForce"},{label="Force Between Parallel Wires",calculator="parallelWireForce"},{label="Torque on Current Loop",calculator="currentLoopTorque"}}}
local magneticFluxMenu={title="Flux and Induction",subtitle="Magnetic flux and Faraday's law",items={{label="Magnetic Flux",calculator="magneticFlux"},{label="Faraday's Law",calculator="faradayLaw"}}}
local inductanceMenu={title="Inductance",subtitle="Self, mutual, and stored energy",items={{label="Ideal Solenoid Inductance",calculator="solenoidInductance"},{label="Mutual Inductance",calculator="mutualInductance"},{label="Energy Stored",calculator="inductorEnergy"}}}
local magnetostaticsMenu={title="Magnetostatics",subtitle="Fields, forces, flux, and inductance",items={{label="Magnetic Fields",menu=magneticFieldsMenu},{label="Magnetic Forces",menu=magneticForcesMenu},{label="Flux and Induction",menu=magneticFluxMenu},{label="Inductance",menu=inductanceMenu}}}

local wavesMenu={title="Electromagnetic Waves",subtitle="Wave properties and lossy media",items={{label="Wave Speed",calculator="waveSpeed"},{label="Intrinsic Impedance",calculator="intrinsicImpedance"},{label="Wavelength",calculator="waveWavelength"},{label="Propagation Constant",calculator="lossyPropagation"},{label="Skin Depth",calculator="skinDepth"},{label="Plane-Wave Power Density",calculator="powerDensity"}}}

local transmissionMetricsMenu={title="Reflection and Matching",subtitle="Reflection, standing waves, and losses",items={{label="Reflection Coefficient",calculator="reflectionCoefficient"},{label="Load from Reflection",calculator="loadFromReflection"},{label="VSWR",calculator="vswr"},{label="Return and Mismatch Loss",calculator="returnLoss"}}}
local transmissionTransformsMenu={title="Line Transformations",subtitle="Impedance and electrical length",items={{label="Input Impedance",calculator="losslessInputImpedance"},{label="Quarter-Wave Transformer",calculator="quarterWaveTransformer"},{label="Electrical Length",calculator="electricalLength"}}}
local transmissionLinesMenu={title="Transmission Lines",subtitle="Lossless-line analysis tools",items={{label="Reflection and Matching",menu=transmissionMetricsMenu},{label="Line Transformations",menu=transmissionTransformsMenu}}}

local electromagneticsMenu={title="Electromagnetics",subtitle="ECE 216 tools",items={{label="Electrostatics",menu=electrostaticsMenu},{label="Magnetostatics",menu=magnetostaticsMenu},{label="Waves",menu=wavesMenu},{label="Transmission Lines",menu=transmissionLinesMenu}}}

local rootMenu={title="Engineering Toolbox",subtitle="Use arrows and Enter",items={{label="History",special="history"},{label="Complex Numbers",menu=complexMenu},{label="Circuit Analysis",menu=circuitMenu},{label="Electromagnetics",menu=electromagneticsMenu},{label="Linear Algebra"},{label="Signals and Systems"},{label="General Math",menu=generalMathMenu}}}

local menuStack={{menu=rootMenu,selected=1}}
local activeCalculator=nil
local historyView=HistoryView.new()
local showingHistory=false

local function currentFrame() return menuStack[#menuStack] end
local function menuLabels(menu) local labels={}; for i,item in ipairs(menu.items) do labels[i]=item.label end; return labels end

local function openCalculator(name,expressions)
    activeCalculator=calculators[name]
    if not activeCalculator then return false end
    activeCalculator:reset()
    if expressions then for i=1,math.min(#expressions,#activeCalculator.values) do activeCalculator.values[i]=expressions[i] or "" end end
    return true
end

local function reopenHistoryEntry(entry)
    if not entry then return end
    for name,calculator in pairs(calculators) do
        if calculator.title==entry.title and openCalculator(name,entry.expressions) then showingHistory=false; return end
    end
end

local function openSelectedMenuItem()
    local frame=currentFrame()
    local item=frame.menu.items[frame.selected]
    if item.menu then menuStack[#menuStack+1]={menu=item.menu,selected=1}
    elseif item.calculator then openCalculator(item.calculator)
    elseif item.special=="history" then historyView:reset(); showingHistory=true end
end

function on.paint(gc)
    if activeCalculator then activeCalculator:draw(gc)
    elseif showingHistory then historyView:draw(gc)
    else local frame=currentFrame(); Menu.draw(gc,frame.menu.title,menuLabels(frame.menu),frame.selected,frame.menu.subtitle) end
end

function on.arrowKey(key)
    if activeCalculator then activeCalculator:moveField(key)
    elseif showingHistory then historyView:move(key)
    else local frame=currentFrame(); frame.selected=Menu.move(frame.selected,#frame.menu.items,key) end
    platform.window:invalidate()
end

function on.enterKey()
    if activeCalculator then activeCalculator:enter()
    elseif showingHistory then reopenHistoryEntry(historyView:getSelected())
    else openSelectedMenuItem() end
    platform.window:invalidate()
end

function on.charIn(character) if activeCalculator then activeCalculator:append(character); platform.window:invalidate() end end
function on.backspaceKey() if activeCalculator then activeCalculator:backspace() elseif showingHistory then historyView:clear() end; platform.window:invalidate() end

function on.escapeKey()
    if activeCalculator then
        if activeCalculator.page=="results" then activeCalculator.page="inputs"; activeCalculator:ensureSelectedVisible() else activeCalculator=nil end
    elseif showingHistory then showingHistory=false
    elseif #menuStack>1 then table.remove(menuStack) end
    platform.window:invalidate()
end
