-- Polar-form and mixed-form complex arithmetic calculators.

local function polarInputs()
    return {
        {label="A magnitude"}, {label="A angle",unit="degrees"},
        {label="B magnitude"}, {label="B angle",unit="degrees"}
    }
end

local function mixedInputs()
    return {
        {label="A magnitude"}, {label="A angle",unit="degrees"},
        {label="B real"}, {label="B imaginary"}
    }
end

local function fullComplexOutputs()
    return {
        {label="Real part",variable="ResultReal"},
        {label="Imaginary part",variable="ResultImag"},
        {label="Magnitude",variable="ResultMagnitude"},
        {label="Angle",unit="degrees",variable="ResultAngle"}
    }
end

local function returnFull(real, imaginary)
    local magnitude, angle = phasor.toPolar(real, imaginary)
    return real, imaginary, magnitude, angle
end

local function polarOperationCalculator(id, title, subtitle, operation, divide)
    return Calculator.new({
        id=id,
        title=title,
        subtitle=subtitle,
        inputs=polarInputs(),
        outputs=fullComplexOutputs(),
        validate=function(v)
            if v[1] < 0 or v[3] < 0 then return "Magnitudes cannot be negative" end
            if divide and v[3] == 0 then return "Cannot divide by zero magnitude" end
        end,
        calculate=function(v)
            local ar,ai=phasor.fromPolar(v[1],v[2])
            local br,bi=phasor.fromPolar(v[3],v[4])
            return returnFull(operation(ar,ai,br,bi))
        end
    })
end

local function mixedOperationCalculator(id, title, subtitle, operation, divide)
    return Calculator.new({
        id=id,
        title=title,
        subtitle=subtitle,
        inputs=mixedInputs(),
        outputs=fullComplexOutputs(),
        validate=function(v)
            if v[1] < 0 then return "A magnitude cannot be negative" end
            if divide and v[3] == 0 and v[4] == 0 then return "Cannot divide by zero" end
        end,
        calculate=function(v)
            local ar,ai=phasor.fromPolar(v[1],v[2])
            return returnFull(operation(ar,ai,v[3],v[4]))
        end
    })
end

function registerComplexPolarCalculators(calculators)
    calculators.polarAdd=polarOperationCalculator("polarAdd","Polar Addition","A polar + B polar",phasor.add,false)
    calculators.polarSubtract=polarOperationCalculator("polarSubtract","Polar Subtraction","A polar - B polar",phasor.subtract,false)
    calculators.polarMultiply=polarOperationCalculator("polarMultiply","Polar Multiplication","A polar x B polar",phasor.multiply,false)
    calculators.polarDivide=polarOperationCalculator("polarDivide","Polar Division","A polar / B polar",phasor.divide,true)

    calculators.mixedAdd=mixedOperationCalculator("mixedAdd","Mixed Addition","A polar + B rectangular",phasor.add,false)
    calculators.mixedSubtract=mixedOperationCalculator("mixedSubtract","Mixed Subtraction","A polar - B rectangular",phasor.subtract,false)
    calculators.mixedMultiply=mixedOperationCalculator("mixedMultiply","Mixed Multiplication","A polar x B rectangular",phasor.multiply,false)
    calculators.mixedDivide=mixedOperationCalculator("mixedDivide","Mixed Division","A polar / B rectangular",phasor.divide,true)

    calculators.complexUtilities=Calculator.new({
        id="complexUtilities",
        title="Complex Utilities",
        subtitle="Rectangular input; returns conjugate and reciprocal",
        inputs={{label="Real part"},{label="Imaginary part"}},
        outputs={
            {label="Magnitude"},{label="Angle",unit="degrees"},
            {label="Conjugate real"},{label="Conjugate imag"},
            {label="Reciprocal real"},{label="Reciprocal imag"}
        },
        validate=function(v)
            if v[1] == 0 and v[2] == 0 then return "Reciprocal undefined at zero" end
        end,
        calculate=function(v)
            local magnitude,angle=phasor.toPolar(v[1],v[2])
            local cr,ci=phasor.conjugate(v[1],v[2])
            local rr,ri=phasor.reciprocal(v[1],v[2])
            return magnitude,angle,cr,ci,rr,ri
        end
    })
end
