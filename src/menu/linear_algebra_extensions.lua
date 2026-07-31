-- Register Linear Algebra calculators and replace the root placeholder.

registerLinearAlgebraCalculators(calculators)

local matrixOperationsMenu = {
    title = "Matrix Operations",
    subtitle = "Core 2x2 and 3x3 operations",
    items = {
        {label="Addition 2x2",calculator="matrixAdd2"},
        {label="Subtraction 2x2",calculator="matrixSubtract2"},
        {label="Multiplication 2x2",calculator="matrixMultiply2"},
        {label="Matrix x Vector 2x2",calculator="matrixVector2"},
        {label="Scalar Multiply 2x2",calculator="matrixScalar2"},
        {label="Transpose 2x2",calculator="matrixTranspose2"},
        {label="Determinant 2x2",calculator="matrixDet2"},
        {label="Determinant 3x3",calculator="matrixDet3"},
        {label="Inverse 2x2",calculator="matrixInverse2"},
        {label="Trace 2x2",calculator="matrixTrace2"},
        {label="Trace 3x3",calculator="matrixTrace3"}
    }
}

local eigenMenu = {
    title = "Eigenvalues and Eigenvectors",
    subtitle = "Real 2x2 matrix analysis",
    items = {
        {label="Eigenvalues 2x2",calculator="eigenvalues2"},
        {label="Eigenvectors 2x2",calculator="eigenvectors2"},
        {label="Characteristic Polynomial",calculator="characteristicPolynomial2"},
        {label="Diagonalization Check",calculator="diagonalizable2"}
    }
}

local linearSystemsMenu = {
    title = "Linear Systems",
    subtitle = "Gaussian elimination with pivoting",
    items = {
        {label="2x2 Linear System",calculator="linearSystem2"},
        {label="3x3 Linear System",calculator="linearSystem3"}
    }
}

local linearAlgebraMenu = {
    title = "Linear Algebra",
    subtitle = "Matrices, systems, and eigenanalysis",
    items = {
        {label="Matrix Operations",menu=matrixOperationsMenu},
        {label="Linear Systems",menu=linearSystemsMenu},
        {label="Matrix Properties 2x2",calculator="matrixProperties2"},
        {label="Eigenvalues and Eigenvectors",menu=eigenMenu}
    }
}

for _, item in ipairs(rootMenu.items) do
    if item.label == "Linear Algebra" then
        item.menu = linearAlgebraMenu
        break
    end
end
