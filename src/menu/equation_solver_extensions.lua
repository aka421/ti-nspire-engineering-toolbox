-- Extend circuit equation solvers and activate the Linear Algebra menu.

for _, item in ipairs(equationSolversMenu.items) do
    if item.label == "Three-Mesh Solver" then
        item.calculator = "meshThree"
        break
    end
end

table.insert(equationSolversMenu.items, {label = "Two-Node Solver", calculator = "nodeTwo"})
table.insert(equationSolversMenu.items, {label = "Three-Node Solver", calculator = "nodeThree"})

local linearSystemsMenu = {
    title = "Linear Systems",
    subtitle = "Gaussian elimination with partial pivoting",
    items = {
        {label = "2x2 Linear System", calculator = "linearSystemTwo"},
        {label = "3x3 Linear System", calculator = "linearSystemThree"}
    }
}

local linearAlgebraMenu = {
    title = "Linear Algebra",
    subtitle = "Matrices and linear systems",
    items = {
        {label = "Linear Systems", menu = linearSystemsMenu},
        {label = "Matrix Operations"},
        {label = "Eigenvalues and Eigenvectors"}
    }
}

for _, item in ipairs(rootMenu.items) do
    if item.label == "Linear Algebra" then
        item.menu = linearAlgebraMenu
        break
    end
end
