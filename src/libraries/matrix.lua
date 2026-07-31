-- Small real-matrix utilities for the engineering toolbox.

matrix = {}

local TOL = 1e-10

function matrix.fromFlat(values, rows, columns, startIndex)
    local result = {}
    local index = startIndex or 1
    for row = 1, rows do
        result[row] = {}
        for column = 1, columns do
            result[row][column] = values[index]
            index = index + 1
        end
    end
    return result
end

function matrix.add(a, b)
    local result = {}
    for i = 1, #a do
        result[i] = {}
        for j = 1, #a[i] do result[i][j] = a[i][j] + b[i][j] end
    end
    return result
end

function matrix.subtract(a, b)
    local result = {}
    for i = 1, #a do
        result[i] = {}
        for j = 1, #a[i] do result[i][j] = a[i][j] - b[i][j] end
    end
    return result
end

function matrix.scalarMultiply(k, a)
    local result = {}
    for i = 1, #a do
        result[i] = {}
        for j = 1, #a[i] do result[i][j] = k * a[i][j] end
    end
    return result
end

function matrix.multiply(a, b)
    local result = {}
    for i = 1, #a do
        result[i] = {}
        for j = 1, #b[1] do
            local sum = 0
            for k = 1, #b do sum = sum + a[i][k] * b[k][j] end
            result[i][j] = sum
        end
    end
    return result
end

function matrix.transpose(a)
    local result = {}
    for j = 1, #a[1] do
        result[j] = {}
        for i = 1, #a do result[j][i] = a[i][j] end
    end
    return result
end

function matrix.trace(a)
    local sum = 0
    for i = 1, #a do sum = sum + a[i][i] end
    return sum
end

function matrix.det2(a)
    return a[1][1] * a[2][2] - a[1][2] * a[2][1]
end

function matrix.det3(a)
    return a[1][1] * (a[2][2] * a[3][3] - a[2][3] * a[3][2])
        - a[1][2] * (a[2][1] * a[3][3] - a[2][3] * a[3][1])
        + a[1][3] * (a[2][1] * a[3][2] - a[2][2] * a[3][1])
end

function matrix.inverse2(a)
    local determinant = matrix.det2(a)
    if math.abs(determinant) < TOL then return nil, "Matrix is singular" end
    return {
        {a[2][2] / determinant, -a[1][2] / determinant},
        {-a[2][1] / determinant, a[1][1] / determinant}
    }
end

function matrix.rank2(a)
    if math.abs(matrix.det2(a)) >= TOL then return 2 end
    for i = 1, 2 do
        for j = 1, 2 do if math.abs(a[i][j]) >= TOL then return 1 end end
    end
    return 0
end

function matrix.isSymmetric2(a)
    return math.abs(a[1][2] - a[2][1]) < TOL
end

function matrix.isOrthogonal2(a)
    local p = matrix.multiply(matrix.transpose(a), a)
    return math.abs(p[1][1] - 1) < TOL and math.abs(p[2][2] - 1) < TOL
        and math.abs(p[1][2]) < TOL and math.abs(p[2][1]) < TOL
end

function matrix.isPositiveDefinite2(a)
    return matrix.isSymmetric2(a) and a[1][1] > 0 and matrix.det2(a) > 0
end

function matrix.eigen2(a)
    local trace = matrix.trace(a)
    local determinant = matrix.det2(a)
    local discriminant = trace * trace - 4 * determinant
    if discriminant >= -TOL then
        discriminant = math.max(0, discriminant)
        local root = math.sqrt(discriminant)
        return (trace + root) / 2, 0, (trace - root) / 2, 0
    end
    local imaginary = math.sqrt(-discriminant) / 2
    return trace / 2, imaginary, trace / 2, -imaginary
end

function matrix.eigenvector2(a, lambda)
    local x, y
    if math.abs(a[1][2]) > math.abs(a[2][1]) then
        x, y = a[1][2], lambda - a[1][1]
    else
        x, y = lambda - a[2][2], a[2][1]
    end
    local magnitude = math.sqrt(x * x + y * y)
    if magnitude < TOL then return 1, 0 end
    return x / magnitude, y / magnitude
end
