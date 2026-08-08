-- Register polar and mixed complex calculators, then extend Complex Numbers.

registerComplexPolarCalculators(calculators)

local polarArithmeticMenu={
    title="Polar Arithmetic",
    subtitle="Both numbers entered as magnitude and angle",
    items={
        {label="Add",calculator="polarAdd"},
        {label="Subtract",calculator="polarSubtract"},
        {label="Multiply",calculator="polarMultiply"},
        {label="Divide",calculator="polarDivide"}
    }
}

local mixedArithmeticMenu={
    title="Mixed Arithmetic",
    subtitle="A is polar; B is rectangular",
    items={
        {label="Add",calculator="mixedAdd"},
        {label="Subtract",calculator="mixedSubtract"},
        {label="Multiply",calculator="mixedMultiply"},
        {label="Divide",calculator="mixedDivide"}
    }
}

table.insert(complexArithmeticMenu.items,{label="Polar Arithmetic",menu=polarArithmeticMenu})
table.insert(complexArithmeticMenu.items,{label="Mixed Arithmetic",menu=mixedArithmeticMenu})
table.insert(complexMenu.items,{label="Complex Utilities",calculator="complexUtilities"})
