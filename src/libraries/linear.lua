-- Linear-system utilities using Gaussian elimination with partial pivoting.

linear = {}

local function copyMatrix(matrix)
    local result = {}
    for row = 1, #matrix do
        result[row] = {}
        for column = 1, #matrix[row] do
            result[row][column] = matrix[row][column]
        end
    end
    return result
end

function linear.solve(matrix, vector)
    local n = #matrix
    if n == 0 or #vector ~= n then return nil, "Invalid system size" end

    local augmented = copyMatrix(matrix)
    for row = 1, n do
        if #augmented[row] ~= n then return nil, "Matrix must be square" end
        augmented[row][n + 1] = vector[row]
    end

    local tolerance = 1e-12

    for pivotColumn = 1, n do
        local pivotRow = pivotColumn
        local pivotMagnitude = math.abs(augmented[pivotRow][pivotColumn])

        for row = pivotColumn + 1, n do
            local magnitude = math.abs(augmented[row][pivotColumn])
            if magnitude > pivotMagnitude then
                pivotMagnitude = magnitude
                pivotRow = row
            end
        end

        if pivotMagnitude < tolerance then return nil, "Equations are singular" end

        if pivotRow ~= pivotColumn then
            augmented[pivotColumn], augmented[pivotRow] = augmented[pivotRow], augmented[pivotColumn]
        end

        for row = pivotColumn + 1, n do
            local factor = augmented[row][pivotColumn] / augmented[pivotColumn][pivotColumn]
            augmented[row][pivotColumn] = 0
            for column = pivotColumn + 1, n + 1 do
                augmented[row][column] = augmented[row][column] - factor * augmented[pivotColumn][column]
            end
        end
    end

    local solution = {}
    for row = n, 1, -1 do
        local value = augmented[row][n + 1]
        for column = row + 1, n do
            value = value - augmented[row][column] * solution[column]
        end
        local pivot = augmented[row][row]
        if math.abs(pivot) < tolerance then return nil, "Equations are singular" end
        solution[row] = value / pivot
    end

    return solution, nil
end
