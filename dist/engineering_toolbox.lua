-- Global numeric workspace shared by every calculator.

Workspace = Workspace or {
    variables = {},
    recentNames = {}
}

local function canonical(name)
    if type(name) ~= "string" then return nil end
    return name
end

local function rememberName(name)
    local key = canonical(name)
    for i = #Workspace.recentNames, 1, -1 do
        if canonical(Workspace.recentNames[i]) == key then table.remove(Workspace.recentNames, i) end
    end
    table.insert(Workspace.recentNames, 1, name)
    while #Workspace.recentNames > 20 do table.remove(Workspace.recentNames) end
end

function Workspace.set(name, value)
    if type(name) ~= "string" or type(value) ~= "number" then return false end
    if value ~= value or value == math.huge or value == -math.huge then return false end
    local key = canonical(name)
    Workspace.variables[key] = {name=name, value=value}
    rememberName(name)
    return true
end

function Workspace.get(name)
    local entry = Workspace.variables[canonical(name)]
    return entry and entry.value or nil
end

function Workspace.clear(name)
    local key = canonical(name)
    Workspace.variables[key] = nil
    for i = #Workspace.recentNames, 1, -1 do
        if canonical(Workspace.recentNames[i]) == key then table.remove(Workspace.recentNames, i) end
    end
end

function Workspace.clearAll()
    Workspace.variables = {}
    Workspace.recentNames = {}
end

function Workspace.sanitizeName(label)
    local name = string.gsub(label or "", "[^%w_]", "")
    if name == "" or string.match(name, "^%d") then return nil end
    return name
end

function Workspace.storeResults(outputs, results)
    for i, value in ipairs(results or {}) do
        if type(value) == "number" then
            Workspace.set("Out" .. i, value)
            local output = outputs and outputs[i]
            local name = output and (output.variable or Workspace.sanitizeName(output.label))
            if name then Workspace.set(name, value) end
        end
    end
end

-- Initialize conventional calculator memory slots.
for code = string.byte("A"), string.byte("J") do
    local name = string.char(code)
    if Workspace.get(name) == nil then Workspace.set(name, 0) end
end
-- Mathematical expression parser for calculator inputs.
-- Supports arithmetic, common functions, SI suffixes, and Ans.

expression = {}

local ansValue = 0

local constants = {
    pi = math.pi,
    e = math.exp(1)
}

local siPrefixes = {
    p = 1e-12,
    n = 1e-9,
    u = 1e-6,
    m = 1e-3,
    k = 1e3,
    M = 1e6,
    G = 1e9,
    T = 1e12
}

function expression.setAns(value)
    if type(value) == "number" then ansValue = value end
end

function expression.getAns()
    return ansValue
end

local function degreesToRadians(value)
    return value * math.pi / 180
end

local function radiansToDegrees(value)
    return value * 180 / math.pi
end

local functions = {
    sqrt = function(value)
        if value < 0 then error("sqrt domain error") end
        return math.sqrt(value)
    end,
    abs = math.abs,
    exp = math.exp,
    ln = function(value)
        if value <= 0 then error("ln domain error") end
        return math.log(value)
    end,
    log = function(value)
        if value <= 0 then error("log domain error") end
        return math.log(value) / math.log(10)
    end,
    sin = function(value) return math.sin(degreesToRadians(value)) end,
    cos = function(value) return math.cos(degreesToRadians(value)) end,
    tan = function(value) return math.tan(degreesToRadians(value)) end,
    asin = function(value)
        if value < -1 or value > 1 then error("asin domain error") end
        return radiansToDegrees(math.asin(value))
    end,
    acos = function(value)
        if value < -1 or value > 1 then error("acos domain error") end
        return radiansToDegrees(math.acos(value))
    end,
    atan = function(value) return radiansToDegrees(math.atan(value)) end
}

local function parserFor(text)
    local parser = {text = text, position = 1, length = #text}

    function parser:skipWhitespace()
        while self.position <= self.length and string.match(string.sub(self.text, self.position, self.position), "%s") do
            self.position = self.position + 1
        end
    end

    function parser:consume(character)
        self:skipWhitespace()
        if string.sub(self.text, self.position, self.position) == character then
            self.position = self.position + 1
            return true
        end
        return false
    end

    function parser:parseNumber()
        self:skipWhitespace()
        local start = self.position
        local sawDigit = false
        local sawDecimal = false

        while self.position <= self.length do
            local character = string.sub(self.text, self.position, self.position)
            if character >= "0" and character <= "9" then
                sawDigit = true
                self.position = self.position + 1
            elseif character == "." and not sawDecimal then
                sawDecimal = true
                self.position = self.position + 1
            else
                break
            end
        end

        if not sawDigit then return nil end

        local character = string.sub(self.text, self.position, self.position)
        if character == "e" or character == "E" then
            local exponentStart = self.position
            self.position = self.position + 1
            local sign = string.sub(self.text, self.position, self.position)
            if sign == "+" or sign == "-" then self.position = self.position + 1 end

            local exponentDigits = self.position
            while self.position <= self.length do
                local digit = string.sub(self.text, self.position, self.position)
                if digit >= "0" and digit <= "9" then
                    self.position = self.position + 1
                else
                    break
                end
            end
            if self.position == exponentDigits then self.position = exponentStart end
        end

        local value = tonumber(string.sub(self.text, start, self.position - 1))
        local prefix = string.sub(self.text, self.position, self.position)
        if siPrefixes[prefix] then
            value = value * siPrefixes[prefix]
            self.position = self.position + 1
        end
        return value
    end

    function parser:parseIdentifier()
        self:skipWhitespace()
        local start = self.position
        while self.position <= self.length do
            local character = string.sub(self.text, self.position, self.position)
            if string.match(character, "[%a_]") then
                self.position = self.position + 1
            else
                break
            end
        end
        if self.position == start then return nil end
        return string.sub(self.text, start, self.position - 1)
    end

    function parser:parsePrimary()
        if self:consume("(") then
            local value = self:parseExpression()
            if not self:consume(")") then error("missing closing parenthesis") end
            return value
        end

        local number = self:parseNumber()
        if number ~= nil then return number end

        local identifier = self:parseIdentifier()
        if identifier then
            local lower = string.lower(identifier)
            if lower == "ans" then return ansValue end
            if constants[lower] ~= nil then return constants[lower] end
            local operation = functions[lower]
            if not operation then error("unknown name") end
            if not self:consume("(") then error("function needs parentheses") end
            local argument = self:parseExpression()
            if not self:consume(")") then error("missing closing parenthesis") end
            return operation(argument)
        end

        error("expected a number")
    end

    function parser:parseUnary()
        if self:consume("+") then return self:parseUnary() end
        if self:consume("-") then return -self:parseUnary() end
        return self:parsePower()
    end

    function parser:parsePower()
        local value = self:parsePrimary()
        if self:consume("^") then value = value ^ self:parseUnary() end
        return value
    end

    function parser:parseTerm()
        local value = self:parseUnary()
        while true do
            if self:consume("*") then
                value = value * self:parseUnary()
            elseif self:consume("/") then
                local divisor = self:parseUnary()
                if divisor == 0 then error("division by zero") end
                value = value / divisor
            else
                break
            end
        end
        return value
    end

    function parser:parseExpression()
        local value = self:parseTerm()
        while true do
            if self:consume("+") then
                value = value + self:parseTerm()
            elseif self:consume("-") then
                value = value - self:parseTerm()
            else
                break
            end
        end
        return value
    end

    return parser
end

function expression.evaluate(text)
    if text == nil or string.match(text, "^%s*$") then return nil, "empty expression" end

    local parser = parserFor(text)
    local ok, value = pcall(function()
        local result = parser:parseExpression()
        parser:skipWhitespace()
        if parser.position <= parser.length then error("unexpected character") end
        if result ~= result or result == math.huge or result == -math.huge then error("non-finite result") end
        return result
    end)

    if not ok then return nil, value end
    return value, nil
end-- Extend the expression parser with global workspace variables.

local baseExpressionEvaluate = expression.evaluate

local reservedNames = {
    ans=true, pi=true, e=true,
    sqrt=true, abs=true, exp=true, ln=true, log=true,
    sin=true, cos=true, tan=true, asin=true, acos=true, atan=true
}

local function substituteWorkspaceVariables(text)
    return string.gsub(text, "()([%a_][%w_]*)", function(position, name)
        -- A letter immediately following a number may be an SI suffix, such as
        -- 10M or 4.7G. Leave it untouched rather than treating M or G as memory.
        if position > 1 then
            local previous = string.sub(text, position - 1, position - 1)
            if string.match(previous, "[%d%.]") then return name end
        end

        -- Exact, case-sensitive workspace names take priority. This keeps
        -- uppercase E as memory while lowercase e remains Euler's constant.
        local value = Workspace.get(name)
        if value ~= nil then
            return "(" .. string.format("%.17g", value) .. ")"
        end

        local lower = string.lower(name)
        if reservedNames[lower] then return name end
        return name
    end)
end

function expression.evaluate(text)
    if text == nil then return nil, "empty expression" end
    return baseExpressionEvaluate(substituteWorkspaceVariables(text))
end

function expression.setVariable(name, value)
    return Workspace.set(name, value)
end

function expression.getVariable(name)
    return Workspace.get(name)
end
-- Complex-number calculations for the Engineering Toolbox.
-- This file is concatenated before the application code during the build.

complex = {}

function complex.magnitude(re, im)
    return math.sqrt(re * re + im * im)
end

function complex.phase(re, im)
    return math.atan2(im, re) * 180 / math.pi
end

function complex.rectToPolar(re, im)
    return complex.magnitude(re, im), complex.phase(re, im)
end

function complex.polarToRect(magnitude, angleDegrees)
    local angleRadians = angleDegrees * math.pi / 180

    local realPart = magnitude * math.cos(angleRadians)
    local imaginaryPart = magnitude * math.sin(angleRadians)

    return realPart, imaginaryPart
end

function complex.add(aRe, aIm, bRe, bIm)
    return aRe + bRe, aIm + bIm
end

function complex.subtract(aRe, aIm, bRe, bIm)
    return aRe - bRe, aIm - bIm
end

function complex.multiply(aRe, aIm, bRe, bIm)
    local realPart = (aRe * bRe) - (aIm * bIm)
    local imaginaryPart = (aRe * bIm) + (aIm * bRe)
    return realPart, imaginaryPart
end

function complex.divide(aRe, aIm, bRe, bIm)
    local denominator = (bRe * bRe) + (bIm * bIm)
    local realPart = ((aRe * bRe) + (aIm * bIm)) / denominator
    local imaginaryPart = ((aIm * bRe) - (aRe * bIm)) / denominator
    return realPart, imaginaryPart
end
-- Three-dimensional vector operations.

vectors = {}

function vectors.magnitude(x, y, z)
    return math.sqrt(x * x + y * y + z * z)
end

function vectors.dot(ax, ay, az, bx, by, bz)
    return ax * bx + ay * by + az * bz
end

function vectors.cross(ax, ay, az, bx, by, bz)
    return ay * bz - az * by,
        az * bx - ax * bz,
        ax * by - ay * bx
end

function vectors.unit(x, y, z)
    local magnitude = vectors.magnitude(x, y, z)
    return x / magnitude, y / magnitude, z / magnitude
end

function vectors.angleDegrees(ax, ay, az, bx, by, bz)
    local denominator = vectors.magnitude(ax, ay, az) * vectors.magnitude(bx, by, bz)
    local cosine = vectors.dot(ax, ay, az, bx, by, bz) / denominator
    -- Protect acos from floating-point values just outside [-1, 1].
    cosine = math.max(-1, math.min(1, cosine))
    return math.deg(math.acos(cosine))
end

function vectors.projection(ax, ay, az, bx, by, bz)
    local scale = vectors.dot(ax, ay, az, bx, by, bz) /
        vectors.dot(bx, by, bz, bx, by, bz)
    return scale * bx, scale * by, scale * bz
end
-- Coordinate-system conversion helpers.
-- Angles are supplied in degrees.
-- Cylindrical: (rho, phi, z), where phi is measured from +x toward +y.
-- Spherical: (r, theta, phi), where theta is measured down from +z
-- and phi is measured from +x toward +y in the xy-plane.

coordinates = {}

local function radians(degrees)
    return degrees * math.pi / 180
end

local function degrees(radiansValue)
    return radiansValue * 180 / math.pi
end

local function atan2(y, x)
    if math.atan2 then return math.atan2(y, x) end
    if x > 0 then return math.atan(y / x) end
    if x < 0 and y >= 0 then return math.atan(y / x) + math.pi end
    if x < 0 and y < 0 then return math.atan(y / x) - math.pi end
    if x == 0 and y > 0 then return math.pi / 2 end
    if x == 0 and y < 0 then return -math.pi / 2 end
    return 0
end

local function normalizedAzimuth(y, x)
    local phi = degrees(atan2(y, x))
    if phi < 0 then phi = phi + 360 end
    return phi
end

function coordinates.cartesianToCylindrical(x, y, z)
    local rho = math.sqrt(x * x + y * y)
    return rho, normalizedAzimuth(y, x), z
end

function coordinates.cylindricalToCartesian(rho, phiDegrees, z)
    local phi = radians(phiDegrees)
    return rho * math.cos(phi), rho * math.sin(phi), z
end

function coordinates.cartesianToSpherical(x, y, z)
    local r = math.sqrt(x * x + y * y + z * z)
    if r == 0 then return 0, 0, 0 end
    local ratio = z / r
    if ratio > 1 then ratio = 1 elseif ratio < -1 then ratio = -1 end
    return r, degrees(math.acos(ratio)), normalizedAzimuth(y, x)
end

function coordinates.sphericalToCartesian(r, thetaDegrees, phiDegrees)
    local theta, phi = radians(thetaDegrees), radians(phiDegrees)
    local sinTheta = math.sin(theta)
    return r * sinTheta * math.cos(phi),
        r * sinTheta * math.sin(phi),
        r * math.cos(theta)
end

function coordinates.cylindricalVectorToCartesian(aRho, aPhi, aZ, phiDegrees)
    local phi = radians(phiDegrees)
    return aRho * math.cos(phi) - aPhi * math.sin(phi),
        aRho * math.sin(phi) + aPhi * math.cos(phi),
        aZ
end

function coordinates.sphericalVectorToCartesian(aR, aTheta, aPhi, thetaDegrees, phiDegrees)
    local theta, phi = radians(thetaDegrees), radians(phiDegrees)
    local sinTheta, cosTheta = math.sin(theta), math.cos(theta)
    local sinPhi, cosPhi = math.sin(phi), math.cos(phi)

    local ax = aR * sinTheta * cosPhi + aTheta * cosTheta * cosPhi - aPhi * sinPhi
    local ay = aR * sinTheta * sinPhi + aTheta * cosTheta * sinPhi + aPhi * cosPhi
    local az = aR * cosTheta - aTheta * sinTheta
    return ax, ay, az
end
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
-- Reusable menu drawing and navigation.

Menu = {}

local VISIBLE_ITEMS = 5
local scrollPositions = {}

local function drawCenteredFitted(gc, text, y, bold, preferredSize, minimumSize)
    local width = platform.window:width()
    local padding = 12
    local size = preferredSize
    while size > minimumSize do
        gc:setFont("sansserif", bold and "b" or "r", size)
        if gc:getStringWidth(text) <= width - 2 * padding then break end
        size = size - 1
    end
    gc:setFont("sansserif", bold and "b" or "r", size)
    gc:drawString(text, math.max(padding, (width - gc:getStringWidth(text)) / 2), y, "top")
end

function Menu.ensureVisible(selectedItem, scrollOffset, itemCount)
    scrollOffset = scrollOffset or 0
    if selectedItem <= scrollOffset then
        scrollOffset = selectedItem - 1
    elseif selectedItem > scrollOffset + VISIBLE_ITEMS then
        scrollOffset = selectedItem - VISIBLE_ITEMS
    end
    local maximumOffset = math.max(0, itemCount - VISIBLE_ITEMS)
    if scrollOffset < 0 then scrollOffset = 0 end
    if scrollOffset > maximumOffset then scrollOffset = maximumOffset end
    return scrollOffset
end

function Menu.draw(gc, title, items, selectedItem, subtitle, scrollOffset, breadcrumb)
    local key = title or "menu"
    if scrollOffset == nil then scrollOffset = scrollPositions[key] or 0 end
    scrollOffset = Menu.ensureVisible(selectedItem, scrollOffset, #items)
    scrollPositions[key] = scrollOffset

    drawCenteredFitted(gc, title, 8, true, 14, 9)
    drawCenteredFitted(gc, breadcrumb or subtitle or "Use arrows and Enter", 30, false, 9, 6)

    local first = scrollOffset + 1
    local last = math.min(#items, scrollOffset + VISIBLE_ITEMS)
    for i = first, last do
        local y = 56 + ((i - first) * 30)
        gc:setFont("sansserif", i == selectedItem and "b" or "r", 11)
        gc:drawString((i == selectedItem and "> " or "  ") .. items[i], 26, y, "top")
    end

    gc:setFont("sansserif", "r", 8)
    if first > 1 then gc:drawString("^ more", platform.window:width() - 48, 48, "top") end
    if last < #items then gc:drawString("v more", platform.window:width() - 48, 202, "top") end

    local countText = tostring(selectedItem) .. "/" .. tostring(#items)
    gc:drawString(countText, platform.window:width() - gc:getStringWidth(countText) - 12, 220, "top")
    drawCenteredFitted(gc, "Enter: select   Esc: back", 218, false, 8, 6)

    return scrollOffset
end

function Menu.move(selectedItem, itemCount, key)
    if key == "up" then
        selectedItem = selectedItem - 1
        if selectedItem < 1 then selectedItem = itemCount end
    elseif key == "down" then
        selectedItem = selectedItem + 1
        if selectedItem > itemCount then selectedItem = 1 end
    end
    return selectedItem
end
-- Generic calculator screen.

Calculator = {}
Calculator.__index = Calculator

ToolboxState = ToolboxState or {
    ans = 0,
    history = {},
    favorites = {}
}

local engineeringPrefixes = {
    [-12] = "p", [-9] = "n", [-6] = "u", [-3] = "m",
    [0] = "", [3] = "k", [6] = "M", [9] = "G", [12] = "T"
}

local function engineeringFormat(value)
    if value == 0 then return "0" end
    local absoluteValue = math.abs(value)
    local logarithm = math.log(absoluteValue) / math.log(10)

    -- Gaussian elimination and other floating-point calculations can return
    -- values such as 0.9999999999999999 instead of exactly 1. Without this
    -- tolerance, floor() incorrectly selects the milli prefix and displays
    -- the result as 1000m rather than 1.
    local exponent = math.floor((logarithm + 1e-12) / 3) * 3

    if exponent < -12 or exponent > 12 then return string.format("%.4e", value) end
    return string.format("%.4g%s", value / (10 ^ exponent), engineeringPrefixes[exponent])
end

local function drawCenteredFitted(gc, text, y, bold, preferredSize, minimumSize)
    local width = platform.window:width()
    local padding = 12
    local size = preferredSize
    while size > minimumSize do
        gc:setFont("sansserif", bold and "b" or "r", size)
        if gc:getStringWidth(text) <= width - 2 * padding then break end
        size = size - 1
    end
    gc:setFont("sansserif", bold and "b" or "r", size)
    gc:drawString(text, math.max(padding, (width - gc:getStringWidth(text)) / 2), y, "top")
end

local function makeEmptyValues(count)
    local values = {}
    for i = 1, count do values[i] = "" end
    return values
end

local function copyValues(values)
    local result = {}
    for i, value in ipairs(values) do result[i] = value end
    return result
end

local function labelWithUnit(item)
    if item.unit and item.unit ~= "" then return item.label .. " (" .. item.unit .. ")" end
    return item.label
end

local function formatOutput(output, value)
    local formatted = output.format and output.format(value) or engineeringFormat(value)
    if output.unit and output.unit ~= "" then formatted = formatted .. " " .. output.unit end
    return formatted
end

local function drawInputField(gc, input, text, y, selected)
    local labelX = 18
    local valueX = 158
    local labelRightPadding = 8
    local maximumLabelWidth = valueX - labelX - labelRightPadding
    local labelText = labelWithUnit(input) .. ":"
    local labelSize = 10

    -- Long labels such as "Characteristic Z0 (ohm)" and
    -- "Phase constant beta (rad/m)" used to extend underneath the input.
    -- Shrink only the label, while leaving entered expressions at a readable size.
    while labelSize > 7 do
        gc:setFont("sansserif", "r", labelSize)
        if gc:getStringWidth(labelText) <= maximumLabelWidth then break end
        labelSize = labelSize - 1
    end

    gc:setFont("sansserif", "r", labelSize)
    gc:drawString(labelText, labelX, y, "top")

    if selected then
        gc:setFont("sansserif", "b", 10)
        gc:drawString("> " .. text .. "_", valueX, y, "top")
    else
        gc:setFont("sansserif", "r", 10)
        gc:drawString("  " .. text, valueX, y, "top")
    end
end

local function parseValues(textValues, allowOneBlank, allowOptionalInputs, minimumInputs)
    local numbers = {}
    local missing
    local blankCount = 0
    local enteredCount = 0

    for i, text in ipairs(textValues) do
        if text == "" then
            blankCount = blankCount + 1
            missing = i
            numbers[i] = nil
        else
            local value = expression.evaluate(text)
            if value == nil then return nil, nil, "Invalid expression in field " .. i end
            numbers[i] = value
            enteredCount = enteredCount + 1
        end
    end

    if allowOneBlank then
        if blankCount ~= 1 then return nil, nil, "Leave exactly one value blank" end
    elseif allowOptionalInputs then
        if enteredCount < minimumInputs then return nil, nil, "Enter at least " .. minimumInputs .. " values" end
    elseif blankCount > 0 then
        return nil, nil, "Complete every input"
    end

    return numbers, missing, nil
end

local function saveHistory(calculator, numbers, results)
    local entry = {
        title = calculator.title,
        expressions = copyValues(calculator.values),
        values = copyValues(numbers),
        results = copyValues(results)
    }
    table.insert(ToolboxState.history, 1, entry)
    while #ToolboxState.history > 20 do table.remove(ToolboxState.history) end
end

function Calculator.new(definition)
    return setmetatable({
        id = definition.id,
        title = definition.title,
        subtitle = definition.subtitle,
        inputs = definition.inputs,
        outputs = definition.outputs,
        resolveOutputs = definition.resolveOutputs,
        calculateValues = definition.calculate,
        validate = definition.validate,
        allowOneBlank = definition.allowOneBlank or false,
        allowOptionalInputs = definition.allowOptionalInputs or false,
        minimumInputs = definition.minimumInputs or 1,
        selectedField = 1,
        scrollOffset = 0,
        visibleInputCount = definition.visibleInputCount or 5,
        page = "inputs",
        values = makeEmptyValues(#definition.inputs),
        results = nil,
        resultOutputs = nil,
        errorMessage = nil
    }, Calculator)
end

function Calculator:reset()
    self.selectedField = 1
    self.scrollOffset = 0
    self.page = "inputs"
    self.values = makeEmptyValues(#self.inputs)
    self.results = nil
    self.resultOutputs = nil
    self.errorMessage = nil
end

function Calculator:ensureSelectedVisible()
    if self.selectedField <= self.scrollOffset then
        self.scrollOffset = self.selectedField - 1
    elseif self.selectedField > self.scrollOffset + self.visibleInputCount then
        self.scrollOffset = self.selectedField - self.visibleInputCount
    end
end

function Calculator:drawInputPage(gc)
    local first = self.scrollOffset + 1
    local last = math.min(#self.inputs, self.scrollOffset + self.visibleInputCount)
    for i = first, last do
        drawInputField(gc, self.inputs[i], self.values[i], 60 + (i - first) * 27, self.selectedField == i)
    end

    gc:setFont("sansserif", "r", 8)
    if first > 1 then gc:drawString("^ more", platform.window:width() - 48, 51, "top") end
    if last < #self.inputs then gc:drawString("v more", platform.window:width() - 48, 194, "top") end
    if self.errorMessage then drawCenteredFitted(gc, self.errorMessage, 192, true, 9, 7) end
    drawCenteredFitted(gc, "Enter: next/calculate   Esc: back   Del: erase", 214, false, 8, 6)
end

function Calculator:drawResultsPage(gc)
    local outputs = self.resultOutputs or self.outputs
    drawCenteredFitted(gc, "Results", 48, true, 12, 9)
    gc:setFont("sansserif", "b", 11)
    for i, output in ipairs(outputs) do
        gc:drawString(output.label .. ": " .. formatOutput(output, self.results[i]), 20, 78 + (i - 1) * 32, "top")
    end
    drawCenteredFitted(gc, "Enter: edit inputs   Esc: back", 214, false, 9, 7)
end

function Calculator:draw(gc)
    drawCenteredFitted(gc, self.title, 8, true, 14, 10)
    if self.page == "results" then self:drawResultsPage(gc) return end

    local defaultSubtitle
    if self.allowOneBlank then
        defaultSubtitle = "Leave one value blank, then press Enter"
    elseif self.allowOptionalInputs then
        defaultSubtitle = "Enter values; unused fields may stay blank"
    else
        defaultSubtitle = "Expressions, SI prefixes, or Ans"
    end
    drawCenteredFitted(gc, self.subtitle or defaultSubtitle, 32, false, 9, 7)
    self:drawInputPage(gc)
end

function Calculator:moveField(key)
    if self.page ~= "inputs" then return end
    if key == "up" then
        self.selectedField = self.selectedField - 1
        if self.selectedField < 1 then self.selectedField = #self.inputs end
    elseif key == "down" then
        self.selectedField = self.selectedField + 1
        if self.selectedField > #self.inputs then self.selectedField = 1 end
    end
    self:ensureSelectedVisible()
    self.errorMessage = nil
end

function Calculator:calculate()
    local numbers, missing, parseError = parseValues(
        self.values, self.allowOneBlank, self.allowOptionalInputs, self.minimumInputs
    )
    if parseError then
        self.errorMessage = parseError
        self.results = nil
        self.resultOutputs = nil
        return false
    end

    if self.validate then
        local validationError = self.validate(numbers, missing)
        if validationError then
            self.errorMessage = validationError
            self.results = nil
            self.resultOutputs = nil
            return false
        end
    end

    local ok, calculated = pcall(function()
        return {self.calculateValues(numbers, missing)}
    end)
    if not ok then
        self.errorMessage = "Calculation error"
        self.results = nil
        self.resultOutputs = nil
        return false
    end

    self.results = calculated
    self.resultOutputs = self.resolveOutputs and self.resolveOutputs(numbers, missing) or self.outputs
    if type(calculated[1]) == "number" then
        ToolboxState.ans = calculated[1]
        expression.setAns(calculated[1])
    end
    saveHistory(self, numbers, calculated)
    self.errorMessage = nil
    self.page = "results"
    return true
end

function Calculator:enter()
    if self.page == "results" then
        self.page = "inputs"
        self:ensureSelectedVisible()
        return
    end
    if self.selectedField < #self.inputs then
        self.selectedField = self.selectedField + 1
        self:ensureSelectedVisible()
        self.errorMessage = nil
        return
    end
    self:calculate()
end

function Calculator:append(character)
    if self.page ~= "inputs" then return end
    local allowedSymbols = ".+-*/^()_ "
    local isDigit = character >= "0" and character <= "9"
    local isLetter = (character >= "a" and character <= "z") or (character >= "A" and character <= "Z")
    local isSymbol = string.find(allowedSymbols, character, 1, true) ~= nil
    if not isDigit and not isLetter and not isSymbol then return end

    self.values[self.selectedField] = self.values[self.selectedField] .. character
    self.results = nil
    self.resultOutputs = nil
    self.errorMessage = nil
end

function Calculator:backspace()
    if self.page ~= "inputs" then return end
    local text = self.values[self.selectedField]
    self.values[self.selectedField] = string.sub(text, 1, -2)
    self.results = nil
    self.resultOutputs = nil
    self.errorMessage = nil
end-- Shared scrolling for calculator result pages.
-- Loaded after calculator.lua so it can extend the existing Calculator class.

local previousCalculatorNew = Calculator.new
local previousCalculatorReset = Calculator.reset
local previousCalculatorMoveField = Calculator.moveField
local previousCalculatorCalculate = Calculator.calculate

local resultPrefixes = {
    [-12] = "p", [-9] = "n", [-6] = "u", [-3] = "m",
    [0] = "", [3] = "k", [6] = "M", [9] = "G", [12] = "T"
}

local function resultEngineeringFormat(value)
    if type(value) ~= "number" then return tostring(value) end
    if value == 0 then return "0" end

    local absoluteValue = math.abs(value)
    local exponent = math.floor(((math.log(absoluteValue) / math.log(10)) + 1e-12) / 3) * 3
    if exponent < -12 or exponent > 12 then
        return string.format("%.4e", value)
    end
    return string.format("%.4g%s", value / (10 ^ exponent), resultPrefixes[exponent])
end

local function resultText(output, value)
    local formatted
    if output.format then
        formatted = output.format(value)
    else
        formatted = resultEngineeringFormat(value)
    end
    formatted = tostring(formatted)
    if output.unit and output.unit ~= "" then
        formatted = formatted .. " " .. output.unit
    end
    return output.label .. ": " .. formatted
end

local function drawFittedResultLine(gc, text, y, selected)
    local maximumWidth = platform.window:width() - 30
    local fontSize = 10
    local weight = selected and "b" or "r"

    while fontSize > 7 do
        gc:setFont("sansserif", weight, fontSize)
        if gc:getStringWidth(text) <= maximumWidth then break end
        fontSize = fontSize - 1
    end

    gc:setFont("sansserif", weight, fontSize)
    gc:drawString((selected and "> " or "  ") .. text, 12, y, "top")
end

function Calculator.new(definition)
    local calculator = previousCalculatorNew(definition)
    calculator.resultScrollOffset = 0
    calculator.selectedResult = 1
    calculator.visibleResultCount = definition.visibleResultCount or 5
    return calculator
end

function Calculator:reset()
    previousCalculatorReset(self)
    self.resultScrollOffset = 0
    self.selectedResult = 1
end

function Calculator:ensureResultVisible()
    local outputs = self.resultOutputs or self.outputs or {}
    if #outputs == 0 then return end

    if self.selectedResult < 1 then self.selectedResult = #outputs end
    if self.selectedResult > #outputs then self.selectedResult = 1 end

    if self.selectedResult <= self.resultScrollOffset then
        self.resultScrollOffset = self.selectedResult - 1
    elseif self.selectedResult > self.resultScrollOffset + self.visibleResultCount then
        self.resultScrollOffset = self.selectedResult - self.visibleResultCount
    end
end

function Calculator:moveField(key)
    if self.page ~= "results" then
        previousCalculatorMoveField(self, key)
        return
    end

    local outputs = self.resultOutputs or self.outputs or {}
    if #outputs <= 1 then return end

    if key == "up" then
        self.selectedResult = self.selectedResult - 1
    elseif key == "down" then
        self.selectedResult = self.selectedResult + 1
    else
        return
    end

    self:ensureResultVisible()
end

function Calculator:calculate()
    local succeeded = previousCalculatorCalculate(self)
    if succeeded then
        self.resultScrollOffset = 0
        self.selectedResult = 1
    end
    return succeeded
end

function Calculator:drawResultsPage(gc)
    local outputs = self.resultOutputs or self.outputs or {}
    local first = self.resultScrollOffset + 1
    local last = math.min(#outputs, self.resultScrollOffset + self.visibleResultCount)

    gc:setFont("sansserif", "b", 12)
    gc:drawString("Results", 12, 46, "top")

    gc:setFont("sansserif", "r", 8)
    gc:drawString(self.selectedResult .. "/" .. #outputs, platform.window:width() - 38, 49, "top")
    if first > 1 then gc:drawString("^ more", platform.window:width() - 48, 64, "top") end
    if last < #outputs then gc:drawString("v more", platform.window:width() - 48, 198, "top") end

    for index = first, last do
        local y = 70 + (index - first) * 27
        drawFittedResultLine(gc, resultText(outputs[index], self.results[index]), y, index == self.selectedResult)
    end

    gc:setFont("sansserif", "r", 8)
    gc:drawString("Up/Down: scroll   Enter: edit   Esc: back", 28, 216, "top")
end
-- Workspace memory calculators and automatic result storage.

local baseCalculatorCalculate = Calculator.calculate

function Calculator:calculate()
    local success = baseCalculatorCalculate(self)
    if success then
        local outputs = self.resultOutputs or self.outputs
        Workspace.storeResults(outputs, self.results)
    end
    return success
end

local function memoryInputs()
    local inputs = {}
    for code = string.byte("A"), string.byte("J") do
        local name = string.char(code)
        table.insert(inputs, {label="Store " .. name})
    end
    return inputs
end

local function memoryOutputs()
    local outputs = {}
    for code = string.byte("A"), string.byte("J") do
        local name = string.char(code)
        table.insert(outputs, {label=name, variable=name})
    end
    return outputs
end

function registerWorkspaceMemoryCalculators(calculators)
    calculators.workspaceMemory = Calculator.new({
        id="workspaceMemory",
        title="Workspace Memory A-J",
        subtitle="Enter expressions for slots to change; blanks keep old values",
        inputs=memoryInputs(),
        outputs=memoryOutputs(),
        allowOptionalInputs=true,
        minimumInputs=1,
        visibleInputCount=5,
        calculate=function(v)
            local results = {}
            for i = 1, 10 do
                local name = string.char(string.byte("A") + i - 1)
                if v[i] ~= nil then Workspace.set(name, v[i]) end
                results[i] = Workspace.get(name) or 0
            end
            return unpack(results)
        end
    })

    calculators.workspaceRecall = Calculator.new({
        id="workspaceRecall",
        title="Recall Workspace Values",
        subtitle="Results also auto-store as Out1, Out2, and descriptive names",
        inputs={{label="Enter any expression using A-J or Out1"}},
        outputs={{label="Value",variable="Recall"}},
        calculate=function(v) return v[1] end
    })
end
-- Calculation history screen.

HistoryView = {}
HistoryView.__index = HistoryView

local function fittedText(gc, text, maximumWidth, size)
    gc:setFont("sansserif", "r", size)
    if gc:getStringWidth(text) <= maximumWidth then return text end

    local shortened = text
    while #shortened > 1 and gc:getStringWidth(shortened .. "...") > maximumWidth do
        shortened = string.sub(shortened, 1, -2)
    end
    return shortened .. "..."
end

local function compactValue(value)
    if type(value) ~= "number" then return tostring(value) end
    return string.format("%.6g", value)
end

function HistoryView.new()
    return setmetatable({selected = 1, scrollOffset = 0, visibleCount = 6}, HistoryView)
end

function HistoryView:reset()
    self.selected = 1
    self.scrollOffset = 0
end

function HistoryView:count()
    return #ToolboxState.history
end

function HistoryView:ensureVisible()
    local count = self:count()
    if count == 0 then
        self.selected = 1
        self.scrollOffset = 0
        return
    end

    if self.selected < 1 then self.selected = count end
    if self.selected > count then self.selected = 1 end

    if self.selected <= self.scrollOffset then
        self.scrollOffset = self.selected - 1
    elseif self.selected > self.scrollOffset + self.visibleCount then
        self.scrollOffset = self.selected - self.visibleCount
    end
end

function HistoryView:move(key)
    local count = self:count()
    if count == 0 then return end
    if key == "up" then self.selected = self.selected - 1 end
    if key == "down" then self.selected = self.selected + 1 end
    self:ensureVisible()
end

function HistoryView:getSelected()
    return ToolboxState.history[self.selected]
end

function HistoryView:clear()
    ToolboxState.history = {}
    self:reset()
end

function HistoryView:draw(gc)
    local width = platform.window:width()
    gc:setFont("sansserif", "b", 14)
    local title = "Calculation History"
    gc:drawString(title, (width - gc:getStringWidth(title)) / 2, 8, "top")

    if self:count() == 0 then
        gc:setFont("sansserif", "r", 11)
        local empty = "No calculations yet"
        gc:drawString(empty, (width - gc:getStringWidth(empty)) / 2, 95, "top")
        gc:setFont("sansserif", "r", 8)
        gc:drawString("Esc: back", (width - gc:getStringWidth("Esc: back")) / 2, 214, "top")
        return
    end

    local first = self.scrollOffset + 1
    local last = math.min(self:count(), self.scrollOffset + self.visibleCount)
    local y = 42

    for i = first, last do
        local entry = ToolboxState.history[i]
        local selected = i == self.selected
        gc:setFont("sansserif", selected and "b" or "r", 10)
        local marker = selected and "> " or "  "
        gc:drawString(marker .. fittedText(gc, entry.title or "Calculation", width - 34, 10), 12, y, "top")

        local resultText = "Result: "
        if entry.results and #entry.results > 0 then
            local values = {}
            for j = 1, math.min(#entry.results, 3) do values[j] = compactValue(entry.results[j]) end
            resultText = resultText .. table.concat(values, ", ")
        else
            resultText = resultText .. "--"
        end
        gc:setFont("sansserif", "r", 8)
        gc:drawString(fittedText(gc, resultText, width - 48, 8), 30, y + 15, "top")
        y = y + 28
    end

    gc:setFont("sansserif", "r", 8)
    if first > 1 then gc:drawString("^ more", width - 48, 31, "top") end
    if last < self:count() then gc:drawString("v more", width - 48, 198, "top") end
    local help = "Enter: reopen   Del: clear history   Esc: back"
    gc:drawString(help, math.max(6, (width - gc:getStringWidth(help)) / 2), 214, "top")
end
-- Complex-number calculator definitions.

local function degrees(value)
    return string.format("%.4f degrees", value)
end

local function arithmeticInputs()
    return {
        {label = "A real"}, {label = "A imaginary"},
        {label = "B real"}, {label = "B imaginary"}
    }
end

local function arithmeticOutputs()
    return {{label = "Real part"}, {label = "Imaginary part"}}
end

function registerComplexCalculators(calculators)
    calculators.rectToPolar = Calculator.new({
        title = "Rectangular to Polar",
        inputs = {{label = "Real part"}, {label = "Imaginary part"}},
        outputs = {{label = "Magnitude"}, {label = "Angle", format = degrees}},
        calculate = function(v) return complex.rectToPolar(v[1], v[2]) end
    })

    calculators.polarToRect = Calculator.new({
        title = "Polar to Rectangular",
        subtitle = "Angle is entered in degrees",
        inputs = {{label = "Magnitude"}, {label = "Angle", unit = "degrees"}},
        outputs = {{label = "Real part"}, {label = "Imaginary part"}},
        validate = function(v)
            if v[1] < 0 then return "Magnitude cannot be negative" end
        end,
        calculate = function(v) return complex.polarToRect(v[1], v[2]) end
    })

    calculators.magnitudePhase = Calculator.new({
        title = "Magnitude and Phase",
        inputs = {{label = "Real part"}, {label = "Imaginary part"}},
        outputs = {{label = "Magnitude"}, {label = "Phase", format = degrees}},
        calculate = function(v)
            return complex.magnitude(v[1], v[2]), complex.phase(v[1], v[2])
        end
    })

    calculators.complexAdd = Calculator.new({
        title = "Complex Addition", subtitle = "A + B",
        inputs = arithmeticInputs(), outputs = arithmeticOutputs(),
        calculate = function(v) return complex.add(v[1], v[2], v[3], v[4]) end
    })

    calculators.complexSubtract = Calculator.new({
        title = "Complex Subtraction", subtitle = "A - B",
        inputs = arithmeticInputs(), outputs = arithmeticOutputs(),
        calculate = function(v) return complex.subtract(v[1], v[2], v[3], v[4]) end
    })

    calculators.complexMultiply = Calculator.new({
        title = "Complex Multiplication", subtitle = "A x B",
        inputs = arithmeticInputs(), outputs = arithmeticOutputs(),
        calculate = function(v) return complex.multiply(v[1], v[2], v[3], v[4]) end
    })

    calculators.complexDivide = Calculator.new({
        title = "Complex Division", subtitle = "A / B",
        inputs = arithmeticInputs(), outputs = arithmeticOutputs(),
        validate = function(v)
            if v[3] == 0 and v[4] == 0 then return "Cannot divide by zero" end
        end,
        calculate = function(v) return complex.divide(v[1], v[2], v[3], v[4]) end
    })
end
-- Circuit-analysis calculator definitions.

local function approximatelyEqual(a, b)
    local scale = math.max(1, math.abs(a), math.abs(b))
    return math.abs(a - b) <= 1e-7 * scale
end

local function resistorInputs(count)
    local inputs = {}
    for i = 1, count do inputs[i] = {label = "R" .. i, unit = "ohm"} end
    return inputs
end

local function eachEnteredValue(values, callback)
    for i = 1, #values do
        if values[i] ~= nil then callback(values[i], i) end
    end
end

local function validatePositiveResistors(values)
    for i = 1, #values do
        if values[i] <= 0 then return "Resistances must be positive" end
    end
end

local function validatePositiveEquivalentResistance(values)
    if values[2] <= 0 then return "Resistance must be positive" end
end

function registerCircuitCalculators(calculators)
    local ohmsLawVariables = {
        {label = "Voltage", unit = "V"},
        {label = "Current", unit = "A"},
        {label = "Resistance", unit = "ohm"}
    }
    local powerVariables = {
        {label = "Voltage", unit = "V"},
        {label = "Current", unit = "A"},
        {label = "Resistance", unit = "ohm"},
        {label = "Power", unit = "W"}
    }

    calculators.ohmsLaw = Calculator.new({
        title = "Ohm's Law", allowOneBlank = true,
        inputs = ohmsLawVariables, outputs = {{label = "Result"}},
        resolveOutputs = function(v, missing) return {ohmsLawVariables[missing]} end,
        validate = function(v, missing)
            if v[3] and v[3] < 0 then return "Resistance cannot be negative" end
            if missing == 2 and v[3] == 0 then return "Resistance cannot be zero" end
            if missing == 3 and v[2] == 0 then return "Current cannot be zero" end
        end,
        calculate = function(v, missing)
            if missing == 1 then return v[2] * v[3] end
            if missing == 2 then return v[1] / v[3] end
            return v[1] / v[2]
        end
    })

    calculators.electricalPower = Calculator.new({
        title = "Electrical Power", subtitle = "Leave exactly one field blank",
        allowOneBlank = true, inputs = powerVariables, outputs = {{label = "Result"}},
        resolveOutputs = function(v, missing) return {powerVariables[missing]} end,
        validate = function(v, missing)
            local voltage, current, resistance, power = v[1], v[2], v[3], v[4]
            if resistance and resistance < 0 then return "Resistance cannot be negative" end
            if power and power < 0 then return "Power cannot be negative" end
            if missing == 1 and not approximatelyEqual(power, current * current * resistance) then
                return "I, R, and P are inconsistent"
            elseif missing == 2 then
                if resistance == 0 then return "Resistance cannot be zero" end
                if not approximatelyEqual(power, voltage * voltage / resistance) then return "V, R, and P are inconsistent" end
            elseif missing == 3 then
                if current == 0 then return "Current cannot be zero" end
                if not approximatelyEqual(power, voltage * current) then return "V, I, and P are inconsistent" end
                if voltage / current < 0 then return "Resistance cannot be negative" end
            elseif missing == 4 and not approximatelyEqual(voltage, current * resistance) then
                return "V, I, and R are inconsistent"
            end
        end,
        calculate = function(v, missing)
            if missing == 1 then return v[2] * v[3] end
            if missing == 2 then return v[1] / v[3] end
            if missing == 3 then return v[1] / v[2] end
            return v[1] * v[2]
        end
    })

    calculators.voltageDivider = Calculator.new({
        title = "Voltage Divider", subtitle = "Output is measured across R2",
        inputs = {{label = "Input voltage", unit = "V"}, {label = "R1", unit = "ohm"}, {label = "R2", unit = "ohm"}},
        outputs = {{label = "Output voltage", unit = "V"}},
        validate = function(v)
            if v[2] < 0 or v[3] < 0 then return "Resistance cannot be negative" end
            if v[2] + v[3] == 0 then return "Total resistance cannot be zero" end
        end,
        calculate = function(v) return v[1] * v[3] / (v[2] + v[3]) end
    })

    calculators.currentDivider = Calculator.new({
        title = "Current Divider", subtitle = "R1 and R2 are parallel branches",
        inputs = {{label = "Input current", unit = "A"}, {label = "R1", unit = "ohm"}, {label = "R2", unit = "ohm"}},
        outputs = {{label = "Current through R1", unit = "A"}, {label = "Current through R2", unit = "A"}},
        validate = function(v)
            if v[2] < 0 or v[3] < 0 then return "Resistance cannot be negative" end
            if v[2] + v[3] == 0 then return "Total resistance cannot be zero" end
        end,
        calculate = function(v)
            local total = v[2] + v[3]
            return v[1] * v[3] / total, v[1] * v[2] / total
        end
    })

    calculators.seriesResistance = Calculator.new({
        title = "Series Resistance", subtitle = "Enter 2 to 5 resistors",
        allowOptionalInputs = true, minimumInputs = 2, inputs = resistorInputs(5),
        outputs = {{label = "Equivalent resistance", unit = "ohm"}},
        validate = function(v)
            local invalid = false
            eachEnteredValue(v, function(value) if value < 0 then invalid = true end end)
            if invalid then return "Resistance cannot be negative" end
        end,
        calculate = function(v)
            local total = 0
            eachEnteredValue(v, function(value) total = total + value end)
            return total
        end
    })

    calculators.parallelResistance = Calculator.new({
        title = "Parallel Resistance", subtitle = "Enter 2 to 5 resistors",
        allowOptionalInputs = true, minimumInputs = 2, inputs = resistorInputs(5),
        outputs = {{label = "Equivalent resistance", unit = "ohm"}},
        validate = function(v)
            local negative, zero = false, false
            eachEnteredValue(v, function(value)
                if value < 0 then negative = true end
                if value == 0 then zero = true end
            end)
            if negative then return "Resistance cannot be negative" end
            if zero then return "Parallel resistance cannot be zero" end
        end,
        calculate = function(v)
            local reciprocalSum = 0
            eachEnteredValue(v, function(value) reciprocalSum = reciprocalSum + 1 / value end)
            return 1 / reciprocalSum
        end
    })

    calculators.deltaToWye = Calculator.new({
        title = "Delta to Wye", subtitle = "Delta resistors connect terminal pairs",
        inputs = {{label = "R_AB", unit = "ohm"}, {label = "R_BC", unit = "ohm"}, {label = "R_CA", unit = "ohm"}},
        outputs = {{label = "R_A", unit = "ohm"}, {label = "R_B", unit = "ohm"}, {label = "R_C", unit = "ohm"}},
        validate = validatePositiveResistors,
        calculate = function(v)
            local sum = v[1] + v[2] + v[3]
            return v[1] * v[3] / sum, v[1] * v[2] / sum, v[2] * v[3] / sum
        end
    })

    calculators.wyeToDelta = Calculator.new({
        title = "Wye to Delta", subtitle = "Wye resistors run from terminal to centre",
        inputs = {{label = "R_A", unit = "ohm"}, {label = "R_B", unit = "ohm"}, {label = "R_C", unit = "ohm"}},
        outputs = {{label = "R_AB", unit = "ohm"}, {label = "R_BC", unit = "ohm"}, {label = "R_CA", unit = "ohm"}},
        validate = validatePositiveResistors,
        calculate = function(v)
            local sum = v[1] * v[2] + v[2] * v[3] + v[3] * v[1]
            return sum / v[3], sum / v[1], sum / v[2]
        end
    })

    calculators.voltageToCurrentSource = Calculator.new({
        title = "Voltage to Current Source", subtitle = "Series voltage source to parallel current source",
        inputs = {{label = "Voltage source", unit = "V"}, {label = "Series resistance", unit = "ohm"}},
        outputs = {{label = "Current source", unit = "A"}, {label = "Parallel resistance", unit = "ohm"}},
        validate = validatePositiveEquivalentResistance,
        calculate = function(v) return v[1] / v[2], v[2] end
    })

    calculators.currentToVoltageSource = Calculator.new({
        title = "Current to Voltage Source", subtitle = "Parallel current source to series voltage source",
        inputs = {{label = "Current source", unit = "A"}, {label = "Parallel resistance", unit = "ohm"}},
        outputs = {{label = "Voltage source", unit = "V"}, {label = "Series resistance", unit = "ohm"}},
        validate = validatePositiveEquivalentResistance,
        calculate = function(v) return v[1] * v[2], v[2] end
    })

    calculators.theveninToNorton = Calculator.new({
        title = "Thevenin to Norton", subtitle = "Convert V_th and R_th to I_N and R_N",
        inputs = {{label = "V_th", unit = "V"}, {label = "R_th", unit = "ohm"}},
        outputs = {{label = "I_N", unit = "A"}, {label = "R_N", unit = "ohm"}},
        validate = validatePositiveEquivalentResistance,
        calculate = function(v) return v[1] / v[2], v[2] end
    })

    calculators.nortonToThevenin = Calculator.new({
        title = "Norton to Thevenin", subtitle = "Convert I_N and R_N to V_th and R_th",
        inputs = {{label = "I_N", unit = "A"}, {label = "R_N", unit = "ohm"}},
        outputs = {{label = "V_th", unit = "V"}, {label = "R_th", unit = "ohm"}},
        validate = validatePositiveEquivalentResistance,
        calculate = function(v) return v[1] * v[2], v[2] end
    })

    calculators.meshTwo = Calculator.new({
        title = "Two-Mesh Equation Solver",
        subtitle = "a11 I1 + a12 I2 = b1; a21 I1 + a22 I2 = b2",
        inputs = {
            {label = "a11", unit = "ohm"}, {label = "a12", unit = "ohm"}, {label = "b1", unit = "V"},
            {label = "a21", unit = "ohm"}, {label = "a22", unit = "ohm"}, {label = "b2", unit = "V"}
        },
        outputs = {{label = "Mesh current I1", unit = "A"}, {label = "Mesh current I2", unit = "A"}},
        validate = function(v)
            if math.abs(v[1] * v[5] - v[2] * v[4]) < 1e-12 then return "Equations are singular" end
        end,
        calculate = function(v)
            local determinant = v[1] * v[5] - v[2] * v[4]
            return (v[3] * v[5] - v[2] * v[6]) / determinant,
                (v[1] * v[6] - v[3] * v[4]) / determinant
        end
    })
end
-- AC and RLC circuit calculators.

local function rlcPositive(value, name)
    if value <= 0 then return name .. " must be greater than zero" end
end

local function rlcDiv(ar, ai, br, bi)
    local d = br * br + bi * bi
    if d == 0 then error("complex division by zero") end
    return (ar * br + ai * bi) / d, (ai * br - ar * bi) / d
end

local function rlcMul(ar, ai, br, bi)
    return ar * br - ai * bi, ar * bi + ai * br
end

local function rlcPolar(magnitude, angleDegrees)
    local angle = angleDegrees * math.pi / 180
    return magnitude * math.cos(angle), magnitude * math.sin(angle)
end

local function rlcMagnitude(real, imag)
    return math.sqrt(real * real + imag * imag)
end

local function rlcAngle(real, imag)
    return math.atan2(imag, real) * 180 / math.pi
end

function registerRLCCalculators(calculators)
    calculators.rlcReactance = Calculator.new({
        id="rlcReactance", title="Inductive and Capacitive Reactance",
        inputs={{label="Frequency f",unit="Hz"},{label="Inductance L",unit="H"},{label="Capacitance C",unit="F"}},
        outputs={{label="Angular frequency",unit="rad/s"},{label="Inductive reactance XL",unit="ohm"},{label="Capacitive reactance XC",unit="ohm"}},
        validate=function(v) return rlcPositive(v[1],"Frequency") or rlcPositive(v[2],"Inductance") or rlcPositive(v[3],"Capacitance") end,
        calculate=function(v) local w=2*math.pi*v[1]; return w,w*v[2],1/(w*v[3]) end
    })

    calculators.seriesRLC = Calculator.new({
        id="seriesRLC", title="Series RLC Impedance",
        inputs={{label="Resistance R",unit="ohm"},{label="Inductance L",unit="H"},{label="Capacitance C",unit="F"},{label="Frequency f",unit="Hz"}},
        outputs={{label="Impedance real",unit="ohm"},{label="Impedance imag",unit="ohm"},{label="Magnitude",unit="ohm"},{label="Phase",unit="degrees"}},
        validate=function(v) if v[1] < 0 then return "Resistance cannot be negative" end; return rlcPositive(v[2],"Inductance") or rlcPositive(v[3],"Capacitance") or rlcPositive(v[4],"Frequency") end,
        calculate=function(v) local w=2*math.pi*v[4]; local x=w*v[2]-1/(w*v[3]); return v[1],x,rlcMagnitude(v[1],x),rlcAngle(v[1],x) end
    })

    calculators.parallelRLC = Calculator.new({
        id="parallelRLC", title="Parallel RLC Impedance",
        inputs={{label="Resistance R",unit="ohm"},{label="Inductance L",unit="H"},{label="Capacitance C",unit="F"},{label="Frequency f",unit="Hz"}},
        outputs={{label="Conductance G",unit="S"},{label="Susceptance B",unit="S"},{label="Impedance magnitude",unit="ohm"},{label="Impedance phase",unit="degrees"}},
        validate=function(v) return rlcPositive(v[1],"Resistance") or rlcPositive(v[2],"Inductance") or rlcPositive(v[3],"Capacitance") or rlcPositive(v[4],"Frequency") end,
        calculate=function(v)
            local w=2*math.pi*v[4]; local g=1/v[1]; local b=w*v[3]-1/(w*v[2]); local zr,zi=rlcDiv(1,0,g,b)
            return g,b,rlcMagnitude(zr,zi),rlcAngle(zr,zi)
        end
    })

    calculators.rlcResonance = Calculator.new({
        id="rlcResonance", title="RLC Resonance",
        inputs={{label="Inductance L",unit="H"},{label="Capacitance C",unit="F"}},
        outputs={{label="Resonant angular frequency",unit="rad/s"},{label="Resonant frequency",unit="Hz"},{label="Period",unit="s"}},
        validate=function(v) return rlcPositive(v[1],"Inductance") or rlcPositive(v[2],"Capacitance") end,
        calculate=function(v) local w=1/math.sqrt(v[1]*v[2]); return w,w/(2*math.pi),2*math.pi/w end
    })

    calculators.seriesRLCBandwidth = Calculator.new({
        id="seriesRLCBandwidth", title="Series RLC Q and Bandwidth",
        inputs={{label="Resistance R",unit="ohm"},{label="Inductance L",unit="H"},{label="Capacitance C",unit="F"}},
        outputs={{label="Quality factor Q"},{label="Bandwidth",unit="Hz"},{label="Lower half-power f1",unit="Hz"},{label="Upper half-power f2",unit="Hz"}},
        validate=function(v) return rlcPositive(v[1],"Resistance") or rlcPositive(v[2],"Inductance") or rlcPositive(v[3],"Capacitance") end,
        calculate=function(v)
            local root=math.sqrt(v[1]^2+4*v[2]/v[3]); local w1=(-v[1]+root)/(2*v[2]); local w2=(v[1]+root)/(2*v[2]); local w0=1/math.sqrt(v[2]*v[3])
            return w0*v[2]/v[1],(w2-w1)/(2*math.pi),w1/(2*math.pi),w2/(2*math.pi)
        end
    })

    calculators.parallelRLCBandwidth = Calculator.new({
        id="parallelRLCBandwidth", title="Parallel RLC Q and Bandwidth",
        subtitle="Ideal parallel R, L, and C",
        inputs={{label="Resistance R",unit="ohm"},{label="Inductance L",unit="H"},{label="Capacitance C",unit="F"}},
        outputs={{label="Quality factor Q"},{label="Resonant frequency",unit="Hz"},{label="Bandwidth",unit="Hz"}},
        validate=function(v) return rlcPositive(v[1],"Resistance") or rlcPositive(v[2],"Inductance") or rlcPositive(v[3],"Capacitance") end,
        calculate=function(v) local f0=1/(2*math.pi*math.sqrt(v[2]*v[3])); local q=v[1]*math.sqrt(v[3]/v[2]); return q,f0,f0/q end
    })

    calculators.acPower = Calculator.new({
        id="acPower", title="AC Complex Power",
        inputs={{label="Voltage RMS",unit="V"},{label="Current RMS",unit="A"},{label="Voltage-current phase",unit="degrees"}},
        outputs={{label="Real power P",unit="W"},{label="Reactive power Q",unit="var"},{label="Apparent power |S|",unit="VA"},{label="Power factor"}},
        validate=function(v) if v[1] < 0 or v[2] < 0 then return "RMS magnitudes cannot be negative" end end,
        calculate=function(v) local s=v[1]*v[2]; local a=v[3]*math.pi/180; return s*math.cos(a),s*math.sin(a),s,math.cos(a) end
    })

    calculators.acVoltageDivider = Calculator.new({
        id="acVoltageDivider", title="AC Voltage Divider",
        subtitle="Vout is across Z2",
        inputs={{label="Source magnitude",unit="V"},{label="Source phase",unit="degrees"},{label="Z1 resistance",unit="ohm"},{label="Z1 reactance",unit="ohm"},{label="Z2 resistance",unit="ohm"},{label="Z2 reactance",unit="ohm"}},
        outputs={{label="Vout real",unit="V"},{label="Vout imag",unit="V"},{label="Vout magnitude",unit="V"},{label="Vout phase",unit="degrees"}},
        validate=function(v) if v[1] < 0 then return "Source magnitude cannot be negative" end; if rlcMagnitude(v[3]+v[5],v[4]+v[6])==0 then return "Total impedance cannot be zero" end end,
        calculate=function(v)
            local sr,si=rlcPolar(v[1],v[2]); local rr,ri=rlcDiv(v[5],v[6],v[3]+v[5],v[4]+v[6]); local orr,oi=rlcMul(sr,si,rr,ri)
            return orr,oi,rlcMagnitude(orr,oi),rlcAngle(orr,oi)
        end
    })

    calculators.acCurrentDivider = Calculator.new({
        id="acCurrentDivider", title="AC Current Divider",
        subtitle="I1 is current through Z1",
        inputs={{label="Total current magnitude",unit="A"},{label="Total current phase",unit="degrees"},{label="Z1 resistance",unit="ohm"},{label="Z1 reactance",unit="ohm"},{label="Z2 resistance",unit="ohm"},{label="Z2 reactance",unit="ohm"}},
        outputs={{label="I1 real",unit="A"},{label="I1 imag",unit="A"},{label="I1 magnitude",unit="A"},{label="I1 phase",unit="degrees"}},
        validate=function(v) if v[1] < 0 then return "Current magnitude cannot be negative" end; if rlcMagnitude(v[3]+v[5],v[4]+v[6])==0 then return "Impedance sum cannot be zero" end end,
        calculate=function(v)
            local ir,ii=rlcPolar(v[1],v[2]); local rr,ri=rlcDiv(v[5],v[6],v[3]+v[5],v[4]+v[6]); local orr,oi=rlcMul(ir,ii,rr,ri)
            return orr,oi,rlcMagnitude(orr,oi),rlcAngle(orr,oi)
        end
    })
end
-- First- and second-order circuit transient calculators.

local function positive(v, i, name)
    if v[i] <= 0 then return name .. " must be greater than zero" end
end

local function nonnegative(v, i, name)
    if v[i] < 0 then return name .. " cannot be negative" end
end

function registerTransientCalculators(calculators)
    calculators.rcCharging = Calculator.new({
        id="rcCharging", title="RC Charging", inputs={{label="Resistance R",unit="ohm"},{label="Capacitance C",unit="F"},{label="Source voltage Vs",unit="V"},{label="Initial voltage V0",unit="V"},{label="Time t",unit="s"}},
        outputs={{label="Time constant",unit="s"},{label="Capacitor voltage",unit="V"},{label="Capacitor current",unit="A"},{label="Resistor voltage",unit="V"}},
        validate=function(v) return positive(v,1,"Resistance") or positive(v,2,"Capacitance") or nonnegative(v,5,"Time") end,
        calculate=function(v) local tau=v[1]*v[2]; local e=math.exp(-v[5]/tau); local vc=v[3]+(v[4]-v[3])*e; return tau,vc,(v[3]-v[4])*e/v[1],v[3]-vc end
    })

    calculators.rcDischarging = Calculator.new({
        id="rcDischarging", title="RC Discharging", inputs={{label="Resistance R",unit="ohm"},{label="Capacitance C",unit="F"},{label="Initial voltage V0",unit="V"},{label="Time t",unit="s"}},
        outputs={{label="Time constant",unit="s"},{label="Capacitor voltage",unit="V"},{label="Current magnitude",unit="A"},{label="Stored energy",unit="J"}},
        validate=function(v) return positive(v,1,"Resistance") or positive(v,2,"Capacitance") or nonnegative(v,4,"Time") end,
        calculate=function(v) local tau=v[1]*v[2]; local vc=v[3]*math.exp(-v[4]/tau); return tau,vc,math.abs(vc/v[1]),0.5*v[2]*vc*vc end
    })

    calculators.rlStep = Calculator.new({
        id="rlStep", title="RL Step Response", inputs={{label="Resistance R",unit="ohm"},{label="Inductance L",unit="H"},{label="Source voltage Vs",unit="V"},{label="Initial current I0",unit="A"},{label="Time t",unit="s"}},
        outputs={{label="Time constant",unit="s"},{label="Inductor current",unit="A"},{label="Inductor voltage",unit="V"},{label="Stored energy",unit="J"}},
        validate=function(v) return positive(v,1,"Resistance") or positive(v,2,"Inductance") or nonnegative(v,5,"Time") end,
        calculate=function(v) local tau=v[2]/v[1]; local inf=v[3]/v[1]; local e=math.exp(-v[5]/tau); local i=inf+(v[4]-inf)*e; return tau,i,v[3]-v[1]*i,0.5*v[2]*i*i end
    })

    calculators.rlDecay = Calculator.new({
        id="rlDecay", title="RL Current Decay", inputs={{label="Resistance R",unit="ohm"},{label="Inductance L",unit="H"},{label="Initial current I0",unit="A"},{label="Time t",unit="s"}},
        outputs={{label="Time constant",unit="s"},{label="Inductor current",unit="A"},{label="Inductor voltage magnitude",unit="V"},{label="Stored energy",unit="J"}},
        validate=function(v) return positive(v,1,"Resistance") or positive(v,2,"Inductance") or nonnegative(v,4,"Time") end,
        calculate=function(v) local tau=v[2]/v[1]; local i=v[3]*math.exp(-v[4]/tau); return tau,i,math.abs(v[1]*i),0.5*v[2]*i*i end
    })

    calculators.firstOrderResponse = Calculator.new({
        id="firstOrderResponse", title="Generic First-Order Response", subtitle="x(t)=xf+(x0-xf)e^(-t/tau)",
        inputs={{label="Initial value x0"},{label="Final value xf"},{label="Time constant tau",unit="s"},{label="Time t",unit="s"}},
        outputs={{label="Response x(t)"},{label="Exponential factor"},{label="Percent complete",unit="%"}},
        validate=function(v) return positive(v,3,"Time constant") or nonnegative(v,4,"Time") end,
        calculate=function(v) local e=math.exp(-v[4]/v[3]); return v[2]+(v[1]-v[2])*e,e,100*(1-e) end
    })

    calculators.firstOrderTime = Calculator.new({
        id="firstOrderTime", title="Time to Reach Value", subtitle="Solve x(t)=xf+(x0-xf)e^(-t/tau)",
        inputs={{label="Initial value x0"},{label="Final value xf"},{label="Target value x"},{label="Time constant tau",unit="s"}},
        outputs={{label="Time",unit="s"},{label="Time constants"}},
        validate=function(v) local ratio=(v[3]-v[2])/(v[1]-v[2]); if v[4]<=0 then return "Time constant must be greater than zero" end; if v[1]==v[2] then return "Initial and final values must differ" end; if ratio<=0 or ratio>1 then return "Target must lie between initial and final values" end end,
        calculate=function(v) local n=-math.log((v[3]-v[2])/(v[1]-v[2])); return n*v[4],n end
    })

    calculators.seriesRLCTransient = Calculator.new({
        id="seriesRLCTransient", title="Series RLC Transient Properties", inputs={{label="Resistance R",unit="ohm"},{label="Inductance L",unit="H"},{label="Capacitance C",unit="F"}},
        outputs={{label="Alpha",unit="1/s"},{label="Natural omega0",unit="rad/s"},{label="Damping ratio"},{label="Damped omega",unit="rad/s"}},
        validate=function(v) return nonnegative(v,1,"Resistance") or positive(v,2,"Inductance") or positive(v,3,"Capacitance") end,
        calculate=function(v) local a=v[1]/(2*v[2]); local w0=1/math.sqrt(v[2]*v[3]); local wd=math.sqrt(math.max(0,w0*w0-a*a)); return a,w0,a/w0,wd end
    })

    calculators.rlcNaturalRoots = Calculator.new({
        id="rlcNaturalRoots", title="RLC Natural Roots", inputs={{label="Resistance R",unit="ohm"},{label="Inductance L",unit="H"},{label="Capacitance C",unit="F"}},
        outputs={{label="s1 real",unit="1/s"},{label="s1 imag",unit="1/s"},{label="s2 real",unit="1/s"},{label="s2 imag",unit="1/s"}},
        validate=function(v) return nonnegative(v,1,"Resistance") or positive(v,2,"Inductance") or positive(v,3,"Capacitance") end,
        calculate=function(v) local a=v[1]/(2*v[2]); local w0=1/math.sqrt(v[2]*v[3]); local d=a*a-w0*w0; if d>=0 then local q=math.sqrt(d); return -a+q,0,-a-q,0 else local q=math.sqrt(-d); return -a,q,-a,-q end end
    })
end
-- Solve-by-Topic: Series RLC workspace.
-- Computes operating-point, power, and resonance quantities together.

function registerTopicSolvers(calculators)
    calculators.topicSeriesRLC = Calculator.new({
        id = "topicSeriesRLC",
        title = "Series RLC Workspace",
        subtitle = "RMS source; computes operating point and resonance",
        visibleResultCount = 5,
        inputs = {
            {label="Resistance R",unit="ohm"},
            {label="Inductance L",unit="H"},
            {label="Capacitance C",unit="F"},
            {label="Frequency f",unit="Hz"},
            {label="Source voltage RMS",unit="V"}
        },
        outputs = {
            {label="Inductive reactance XL",unit="ohm"},
            {label="Capacitive reactance XC",unit="ohm"},
            {label="Net reactance X",unit="ohm"},
            {label="Impedance real",unit="ohm"},
            {label="Impedance imaginary",unit="ohm"},
            {label="Impedance magnitude",unit="ohm"},
            {label="Impedance phase",unit="degrees"},
            {label="Current magnitude",unit="A"},
            {label="Current phase",unit="degrees"},
            {label="Power factor"},
            {label="Real power P",unit="W"},
            {label="Reactive power Q",unit="var"},
            {label="Apparent power S",unit="VA"},
            {label="Resonant frequency",unit="Hz"},
            {label="Quality factor"},
            {label="Bandwidth",unit="Hz"}
        },
        validate = function(v)
            if v[1] <= 0 then return "Resistance must be greater than zero" end
            if v[2] <= 0 then return "Inductance must be greater than zero" end
            if v[3] <= 0 then return "Capacitance must be greater than zero" end
            if v[4] <= 0 then return "Frequency must be greater than zero" end
            if v[5] < 0 then return "Source voltage cannot be negative" end
        end,
        calculate = function(v)
            local r,l,c,f,vrms=v[1],v[2],v[3],v[4],v[5]
            local w=2*math.pi*f
            local xl=w*l
            local xc=1/(w*c)
            local x=xl-xc
            local zmag=math.sqrt(r*r+x*x)
            local angle=math.atan2(x,r)*180/math.pi
            local current=vrms/zmag
            local currentAngle=-angle
            local pf=r/zmag
            local realPower=current*current*r
            local reactivePower=current*current*x
            local apparentPower=vrms*current
            local f0=1/(2*math.pi*math.sqrt(l*c))
            local q=(2*math.pi*f0*l)/r
            local bandwidth=r/(2*math.pi*l)

            return xl,xc,x,r,x,zmag,angle,current,currentAngle,pf,
                realPower,reactivePower,apparentPower,f0,q,bandwidth
        end
    })
end
-- Solve-by-Topic: Lossless transmission-line workspace.
-- Combines reflection, standing-wave, impedance, length, and power quantities.

function registerTransmissionTopic(calculators)
    calculators.topicTransmissionLine = Calculator.new({
        id = "topicTransmissionLine",
        title = "Transmission Line Workspace",
        subtitle = "Lossless line; forward voltage is RMS magnitude",
        visibleInputCount = 5,
        visibleResultCount = 5,
        inputs = {
            {label="Load resistance RL",unit="ohm"},
            {label="Load reactance XL",unit="ohm"},
            {label="Characteristic Z0",unit="ohm"},
            {label="Phase constant beta",unit="rad/m"},
            {label="Line length l",unit="m"},
            {label="Forward voltage V0+ RMS",unit="V"}
        },
        outputs = {
            {label="Gamma real"},
            {label="Gamma imaginary"},
            {label="Gamma magnitude"},
            {label="Gamma angle",unit="degrees"},
            {label="VSWR"},
            {label="Return loss",unit="dB"},
            {label="Mismatch loss",unit="dB"},
            {label="Reflected power",unit="%"},
            {label="Delivered power",unit="%"},
            {label="Input resistance",unit="ohm"},
            {label="Input reactance",unit="ohm"},
            {label="Input impedance magnitude",unit="ohm"},
            {label="Input impedance angle",unit="degrees"},
            {label="Electrical length",unit="degrees"},
            {label="Electrical length",unit="rad"},
            {label="Nearest voltage maximum",unit="m"},
            {label="Nearest current maximum",unit="m"},
            {label="Maximum voltage",unit="V"},
            {label="Maximum current",unit="A"},
            {label="Incident average power",unit="W"},
            {label="Reflected average power",unit="W"},
            {label="Load average power",unit="W"}
        },
        validate = function(v)
            if v[1] < 0 then return "Load resistance cannot be negative" end
            if v[3] <= 0 then return "Characteristic impedance must be greater than zero" end
            if v[4] <= 0 then return "Phase constant must be greater than zero" end
            if v[5] < 0 then return "Line length cannot be negative" end
            if v[6] < 0 then return "Forward voltage cannot be negative" end
        end,
        calculate = function(v)
            local rl,xl,z0,beta,length,vplus = v[1],v[2],v[3],v[4],v[5],v[6]

            local nr,ni = rl-z0,xl
            local dr,di = rl+z0,xl
            local denominator = dr*dr + di*di
            local gr = (nr*dr + ni*di)/denominator
            local gi = (ni*dr - nr*di)/denominator
            local gmag = math.sqrt(gr*gr + gi*gi)
            local gangle = math.atan2(gi,gr)
            local gangleDeg = gangle*180/math.pi

            local vswr
            if gmag >= 1 then vswr = 1e99 else vswr = (1+gmag)/(1-gmag) end
            local returnLoss = gmag == 0 and 1e99 or -20*math.log(gmag)/math.log(10)
            local mismatchLoss = gmag >= 1 and 1e99 or -10*math.log(1-gmag*gmag)/math.log(10)

            local tangent = math.tan(beta*length)
            local ar,ai = rl,xl + z0*tangent
            local br,bi = z0 - xl*tangent,rl*tangent
            local bd = br*br + bi*bi
            local zinr = z0*(ar*br + ai*bi)/bd
            local zini = z0*(ai*br - ar*bi)/bd
            local zinmag = math.sqrt(zinr*zinr + zini*zini)
            local zinangle = math.atan2(zini,zinr)*180/math.pi

            local electricalRad = beta*length
            local electricalDeg = electricalRad*180/math.pi
            local period = 2*math.pi
            local normalizedAngle = gangle % period
            if normalizedAngle < 0 then normalizedAngle = normalizedAngle + period end
            local voltageMax = normalizedAngle/(2*beta)
            local currentAngle = (gangle-math.pi) % period
            if currentAngle < 0 then currentAngle = currentAngle + period end
            local currentMax = currentAngle/(2*beta)

            local vmax = vplus*(1+gmag)
            local imax = (vplus/z0)*(1+gmag)
            local pinc = vplus*vplus/z0
            local prefl = pinc*gmag*gmag
            local pload = pinc-prefl

            return gr,gi,gmag,gangleDeg,vswr,returnLoss,mismatchLoss,
                100*gmag*gmag,100*(1-gmag*gmag),
                zinr,zini,zinmag,zinangle,electricalDeg,electricalRad,
                voltageMax,currentMax,vmax,imax,pinc,prefl,pload
        end
    })
end
-- Linear-system calculators layered onto the circuit calculator registry.

local previousRegisterCircuitCalculators = registerCircuitCalculators

local function solveTwo(v)
    return linear.solve({{v[1], v[2]}, {v[4], v[5]}}, {v[3], v[6]})
end

local function solveThree(v)
    return linear.solve({
        {v[1], v[2], v[3]},
        {v[5], v[6], v[7]},
        {v[9], v[10], v[11]}
    }, {v[4], v[8], v[12]})
end

local function validateTwo(v)
    local solution, err = solveTwo(v)
    if not solution then return err end
end

local function validateThree(v)
    local solution, err = solveThree(v)
    if not solution then return err end
end

local function twoSystemInputs(coefficientUnit, sourceUnit)
    return {
        {label = "a11", unit = coefficientUnit}, {label = "a12", unit = coefficientUnit}, {label = "b1", unit = sourceUnit},
        {label = "a21", unit = coefficientUnit}, {label = "a22", unit = coefficientUnit}, {label = "b2", unit = sourceUnit}
    }
end

local function threeSystemInputs(coefficientUnit, sourceUnit)
    return {
        {label = "a11", unit = coefficientUnit}, {label = "a12", unit = coefficientUnit}, {label = "a13", unit = coefficientUnit}, {label = "b1", unit = sourceUnit},
        {label = "a21", unit = coefficientUnit}, {label = "a22", unit = coefficientUnit}, {label = "a23", unit = coefficientUnit}, {label = "b2", unit = sourceUnit},
        {label = "a31", unit = coefficientUnit}, {label = "a32", unit = coefficientUnit}, {label = "a33", unit = coefficientUnit}, {label = "b3", unit = sourceUnit}
    }
end

function registerCircuitCalculators(calculators)
    previousRegisterCircuitCalculators(calculators)

    calculators.meshThree = Calculator.new({
        id = "meshThree",
        title = "Three-Mesh Equation Solver",
        subtitle = "Enter coefficients row by row, including each source term",
        inputs = threeSystemInputs("ohm", "V"),
        outputs = {
            {label = "Mesh current I1", unit = "A"},
            {label = "Mesh current I2", unit = "A"},
            {label = "Mesh current I3", unit = "A"}
        },
        visibleInputCount = 5,
        validate = validateThree,
        calculate = function(v)
            local solution = solveThree(v)
            return solution[1], solution[2], solution[3]
        end
    })

    calculators.nodeTwo = Calculator.new({
        id = "nodeTwo",
        title = "Two-Node Equation Solver",
        subtitle = "a11 V1 + a12 V2 = b1; a21 V1 + a22 V2 = b2",
        inputs = twoSystemInputs("S", "A"),
        outputs = {
            {label = "Node voltage V1", unit = "V"},
            {label = "Node voltage V2", unit = "V"}
        },
        validate = validateTwo,
        calculate = function(v)
            local solution = solveTwo(v)
            return solution[1], solution[2]
        end
    })

    calculators.nodeThree = Calculator.new({
        id = "nodeThree",
        title = "Three-Node Equation Solver",
        subtitle = "Enter conductance coefficients and current terms row by row",
        inputs = threeSystemInputs("S", "A"),
        outputs = {
            {label = "Node voltage V1", unit = "V"},
            {label = "Node voltage V2", unit = "V"},
            {label = "Node voltage V3", unit = "V"}
        },
        visibleInputCount = 5,
        validate = validateThree,
        calculate = function(v)
            local solution = solveThree(v)
            return solution[1], solution[2], solution[3]
        end
    })

    calculators.linearSystemTwo = Calculator.new({
        id = "linearSystemTwo",
        title = "2x2 Linear System",
        subtitle = "Solve A x = b using Gaussian elimination",
        inputs = twoSystemInputs("", ""),
        outputs = {{label = "x1"}, {label = "x2"}},
        validate = validateTwo,
        calculate = function(v)
            local solution = solveTwo(v)
            return solution[1], solution[2]
        end
    })

    calculators.linearSystemThree = Calculator.new({
        id = "linearSystemThree",
        title = "3x3 Linear System",
        subtitle = "Solve A x = b using Gaussian elimination",
        inputs = threeSystemInputs("", ""),
        outputs = {{label = "x1"}, {label = "x2"}, {label = "x3"}},
        visibleInputCount = 5,
        validate = validateThree,
        calculate = function(v)
            local solution = solveThree(v)
            return solution[1], solution[2], solution[3]
        end
    })
end
-- Linear-algebra calculator definitions.

local function inputs2(prefix)
    return {{label=prefix.."11"},{label=prefix.."12"},{label=prefix.."21"},{label=prefix.."22"}}
end

local function twoMatrixInputs()
    local result = inputs2("A")
    local second = inputs2("B")
    for _, item in ipairs(second) do result[#result + 1] = item end
    return result
end

local function outputs2(prefix)
    return {{label=prefix.."11"},{label=prefix.."12"},{label=prefix.."21"},{label=prefix.."22"}}
end

local function unpack2(a) return a[1][1], a[1][2], a[2][1], a[2][2] end
local function yesNo(value) return value ~= 0 and "YES" or "NO" end

function registerLinearAlgebraCalculators(calculators)
    calculators.matrixAdd2 = Calculator.new({id="matrixAdd2",title="Matrix Addition 2x2",inputs=twoMatrixInputs(),outputs=outputs2("C"),calculate=function(v) return unpack2(matrix.add(matrix.fromFlat(v,2,2,1),matrix.fromFlat(v,2,2,5))) end})
    calculators.matrixSubtract2 = Calculator.new({id="matrixSubtract2",title="Matrix Subtraction 2x2",inputs=twoMatrixInputs(),outputs=outputs2("C"),calculate=function(v) return unpack2(matrix.subtract(matrix.fromFlat(v,2,2,1),matrix.fromFlat(v,2,2,5))) end})
    calculators.matrixMultiply2 = Calculator.new({id="matrixMultiply2",title="Matrix Multiplication 2x2",inputs=twoMatrixInputs(),outputs=outputs2("C"),calculate=function(v) return unpack2(matrix.multiply(matrix.fromFlat(v,2,2,1),matrix.fromFlat(v,2,2,5))) end})
    calculators.matrixVector2 = Calculator.new({id="matrixVector2",title="Matrix-Vector Product 2x2",inputs={{label="A11"},{label="A12"},{label="A21"},{label="A22"},{label="x1"},{label="x2"}},outputs={{label="y1"},{label="y2"}},calculate=function(v) return v[1]*v[5]+v[2]*v[6],v[3]*v[5]+v[4]*v[6] end})
    calculators.matrixScalar2 = Calculator.new({id="matrixScalar2",title="Scalar Multiplication 2x2",inputs={{label="Scalar k"},{label="A11"},{label="A12"},{label="A21"},{label="A22"}},outputs=outputs2("C"),calculate=function(v) return unpack2(matrix.scalarMultiply(v[1],matrix.fromFlat(v,2,2,2))) end})
    calculators.matrixTranspose2 = Calculator.new({id="matrixTranspose2",title="Matrix Transpose 2x2",inputs=inputs2("A"),outputs=outputs2("T"),calculate=function(v) return unpack2(matrix.transpose(matrix.fromFlat(v,2,2,1))) end})
    calculators.matrixDet2 = Calculator.new({id="matrixDet2",title="Determinant 2x2",inputs=inputs2("A"),outputs={{label="det(A)"}},calculate=function(v) return matrix.det2(matrix.fromFlat(v,2,2,1)) end})
    calculators.matrixDet3 = Calculator.new({id="matrixDet3",title="Determinant 3x3",inputs={{label="A11"},{label="A12"},{label="A13"},{label="A21"},{label="A22"},{label="A23"},{label="A31"},{label="A32"},{label="A33"}},outputs={{label="det(A)"}},visibleInputCount=5,calculate=function(v) return matrix.det3(matrix.fromFlat(v,3,3,1)) end})
    calculators.matrixInverse2 = Calculator.new({id="matrixInverse2",title="Matrix Inverse 2x2",inputs=inputs2("A"),outputs=outputs2("Inv"),validate=function(v) local inv,err=matrix.inverse2(matrix.fromFlat(v,2,2,1)); if not inv then return err end end,calculate=function(v) return unpack2(matrix.inverse2(matrix.fromFlat(v,2,2,1))) end})
    calculators.matrixTrace2 = Calculator.new({id="matrixTrace2",title="Matrix Trace 2x2",inputs=inputs2("A"),outputs={{label="tr(A)"}},calculate=function(v) return v[1]+v[4] end})
    calculators.matrixTrace3 = Calculator.new({id="matrixTrace3",title="Matrix Trace 3x3",inputs={{label="A11"},{label="A12"},{label="A13"},{label="A21"},{label="A22"},{label="A23"},{label="A31"},{label="A32"},{label="A33"}},outputs={{label="tr(A)"}},visibleInputCount=5,calculate=function(v) return v[1]+v[5]+v[9] end})

    calculators.matrixProperties2 = Calculator.new({
        id="matrixProperties2",title="Matrix Properties 2x2",inputs=inputs2("A"),
        outputs={{label="Determinant"},{label="Trace"},{label="Rank"},{label="Singular",format=yesNo}},
        calculate=function(v)
            local a=matrix.fromFlat(v,2,2,1); local det=matrix.det2(a)
            return det,matrix.trace(a),matrix.rank2(a),math.abs(det)<1e-10 and 1 or 0
        end
    })

    calculators.matrixTests2 = Calculator.new({
        id="matrixTests2",title="Matrix Tests 2x2",inputs=inputs2("A"),
        outputs={{label="Symmetric",format=yesNo},{label="Orthogonal",format=yesNo},{label="Positive definite",format=yesNo}},
        calculate=function(v)
            local a=matrix.fromFlat(v,2,2,1)
            return matrix.isSymmetric2(a) and 1 or 0,matrix.isOrthogonal2(a) and 1 or 0,matrix.isPositiveDefinite2(a) and 1 or 0
        end
    })

    calculators.eigenvalues2 = Calculator.new({id="eigenvalues2",title="Eigenvalues 2x2",inputs=inputs2("A"),outputs={{label="lambda1 real"},{label="lambda1 imag"},{label="lambda2 real"},{label="lambda2 imag"}},calculate=function(v) return matrix.eigen2(matrix.fromFlat(v,2,2,1)) end})
    calculators.eigenvectors2 = Calculator.new({id="eigenvectors2",title="Eigenvectors 2x2",subtitle="Real, distinct eigenvalues only",inputs=inputs2("A"),outputs={{label="v1 x"},{label="v1 y"},{label="v2 x"},{label="v2 y"}},validate=function(v) local r1,i1,r2,i2=matrix.eigen2(matrix.fromFlat(v,2,2,1)); if math.abs(i1)>1e-10 or math.abs(i2)>1e-10 then return "Eigenvectors require real eigenvalues" end; if math.abs(r1-r2)<1e-10 then return "Repeated eigenvalue; eigenspace may not be unique" end end,calculate=function(v) local a=matrix.fromFlat(v,2,2,1); local l1,_,l2=matrix.eigen2(a); local x1,y1=matrix.eigenvector2(a,l1); local x2,y2=matrix.eigenvector2(a,l2); return x1,y1,x2,y2 end})
    calculators.characteristicPolynomial2 = Calculator.new({id="characteristicPolynomial2",title="Characteristic Polynomial 2x2",subtitle="lambda^2 + b lambda + c",inputs=inputs2("A"),outputs={{label="lambda^2 coefficient"},{label="lambda coefficient"},{label="constant"}},calculate=function(v) local a=matrix.fromFlat(v,2,2,1); return 1,-matrix.trace(a),matrix.det2(a) end})
    calculators.diagonalizable2 = Calculator.new({id="diagonalizable2",title="Diagonalization Check 2x2",inputs=inputs2("A"),outputs={{label="Real diagonalizable",format=yesNo},{label="Repeated eigenvalue",format=yesNo}},calculate=function(v) local a=matrix.fromFlat(v,2,2,1); local l1,i1,l2,i2=matrix.eigen2(a); local repeated=math.abs(i1)<1e-10 and math.abs(i2)<1e-10 and math.abs(l1-l2)<1e-10; local scalar=math.abs(a[1][2])<1e-10 and math.abs(a[2][1])<1e-10 and math.abs(a[1][1]-a[2][2])<1e-10; local diagonalizable=(math.abs(i1)<1e-10 and math.abs(i2)<1e-10 and (not repeated or scalar)); return diagonalizable and 1 or 0,repeated and 1 or 0 end})
end
-- Electromagnetics calculator definitions.

local EPSILON_0 = 8.854187817e-12
local MU_0 = 4e-7 * math.pi
local COULOMB_K = 1 / (4 * math.pi * EPSILON_0)

local function vectorInputs(prefix)
    return {{label=prefix.."x"},{label=prefix.."y"},{label=prefix.."z"}}
end

local function twoVectorInputs()
    return {{label="Ax"},{label="Ay"},{label="Az"},{label="Bx"},{label="By"},{label="Bz"}}
end

local function vectorOutputs(prefix)
    return {{label=prefix.."x"},{label=prefix.."y"},{label=prefix.."z"}}
end

local function validateNonzeroVector(v, i, name)
    if vectors.magnitude(v[i],v[i+1],v[i+2]) == 0 then return name.." cannot be the zero vector" end
end

local function requirePositive(value, name)
    if value <= 0 then return name.." must be greater than zero" end
end

function registerElectromagneticsCalculators(calculators)
    calculators.vectorMagnitude = Calculator.new({id="vectorMagnitude",title="Vector Magnitude",subtitle="Enter Cartesian components",inputs=vectorInputs("A"),outputs={{label="Magnitude"}},calculate=function(v) return vectors.magnitude(v[1],v[2],v[3]) end})
    calculators.vectorUnit = Calculator.new({id="vectorUnit",title="Unit Vector",subtitle="Find a unit vector parallel to A",inputs=vectorInputs("A"),outputs=vectorOutputs("u"),validate=function(v) return validateNonzeroVector(v,1,"A") end,calculate=function(v) return vectors.unit(v[1],v[2],v[3]) end})
    calculators.vectorDot = Calculator.new({id="vectorDot",title="Dot Product",subtitle="Calculate A dot B",inputs=twoVectorInputs(),outputs={{label="A dot B"}},calculate=function(v) return vectors.dot(v[1],v[2],v[3],v[4],v[5],v[6]) end})
    calculators.vectorCross = Calculator.new({id="vectorCross",title="Cross Product",subtitle="Calculate A x B",inputs=twoVectorInputs(),outputs={{label="Cx"},{label="Cy"},{label="Cz"},{label="Magnitude"}},calculate=function(v) local x,y,z=vectors.cross(v[1],v[2],v[3],v[4],v[5],v[6]); return x,y,z,vectors.magnitude(x,y,z) end})
    calculators.vectorAngle = Calculator.new({id="vectorAngle",title="Angle Between Vectors",subtitle="Smallest angle from A to B",inputs=twoVectorInputs(),outputs={{label="Angle",unit="degrees"}},validate=function(v) return validateNonzeroVector(v,1,"A") or validateNonzeroVector(v,4,"B") end,calculate=function(v) return vectors.angleDegrees(v[1],v[2],v[3],v[4],v[5],v[6]) end})
    calculators.vectorProjection = Calculator.new({id="vectorProjection",title="Vector Projection",subtitle="Projection of A onto B",inputs=twoVectorInputs(),outputs=vectorOutputs("P"),validate=function(v) return validateNonzeroVector(v,4,"B") end,calculate=function(v) return vectors.projection(v[1],v[2],v[3],v[4],v[5],v[6]) end})

    -- Electrostatics
    calculators.coulombsLaw = Calculator.new({id="coulombsLaw",title="Coulomb's Law",subtitle="Signed radial force; + repulsive, - attractive",inputs={{label="Charge q1",unit="C"},{label="Charge q2",unit="C"},{label="Separation r",unit="m"},{label="Relative permittivity"}},outputs={{label="Radial force",unit="N"},{label="Magnitude",unit="N"}},validate=function(v) return requirePositive(v[3],"Separation") or requirePositive(v[4],"Relative permittivity") end,calculate=function(v) local f=COULOMB_K*v[1]*v[2]/(v[4]*v[3]^2); return f,math.abs(f) end})
    calculators.pointChargeField = Calculator.new({id="pointChargeField",title="Point-Charge Electric Field",subtitle="Signed radial field from a point charge",inputs={{label="Source charge q",unit="C"},{label="Distance r",unit="m"},{label="Relative permittivity"}},outputs={{label="Radial E",unit="V/m"},{label="Magnitude",unit="V/m"}},validate=function(v) return requirePositive(v[2],"Distance") or requirePositive(v[3],"Relative permittivity") end,calculate=function(v) local e=COULOMB_K*v[1]/(v[3]*v[2]^2); return e,math.abs(e) end})
    calculators.pointChargePotential = Calculator.new({id="pointChargePotential",title="Electric Potential",subtitle="Potential due to a point charge, zero at infinity",inputs={{label="Source charge q",unit="C"},{label="Distance r",unit="m"},{label="Relative permittivity"}},outputs={{label="Potential",unit="V"}},validate=function(v) return requirePositive(v[2],"Distance") or requirePositive(v[3],"Relative permittivity") end,calculate=function(v) return COULOMB_K*v[1]/(v[3]*v[2]) end})
    calculators.forceOnCharge = Calculator.new({id="forceOnCharge",title="Force on a Charge",subtitle="Calculate F = qE in Cartesian components",inputs={{label="Charge q",unit="C"},{label="Ex",unit="V/m"},{label="Ey",unit="V/m"},{label="Ez",unit="V/m"}},outputs={{label="Fx",unit="N"},{label="Fy",unit="N"},{label="Fz",unit="N"},{label="Magnitude",unit="N"}},calculate=function(v) local x,y,z=v[1]*v[2],v[1]*v[3],v[1]*v[4]; return x,y,z,vectors.magnitude(x,y,z) end})
    calculators.gaussLaw = Calculator.new({id="gaussLaw",title="Gauss's Law",subtitle="Electric flux through a closed surface",inputs={{label="Enclosed charge",unit="C"},{label="Relative permittivity"}},outputs={{label="Electric flux",unit="V*m"}},validate=function(v) return requirePositive(v[2],"Relative permittivity") end,calculate=function(v) return v[1]/(EPSILON_0*v[2]) end})
    calculators.parallelPlateCapacitance = Calculator.new({id="parallelPlateCapacitance",title="Parallel-Plate Capacitance",subtitle="Ideal plates with uniform dielectric",inputs={{label="Plate area",unit="m^2"},{label="Plate spacing",unit="m"},{label="Relative permittivity"}},outputs={{label="Capacitance",unit="F"}},validate=function(v) return requirePositive(v[1],"Area") or requirePositive(v[2],"Spacing") or requirePositive(v[3],"Relative permittivity") end,calculate=function(v) return EPSILON_0*v[3]*v[1]/v[2] end})

    -- Magnetostatics: magnetic fields
    calculators.infiniteWireField = Calculator.new({id="infiniteWireField",title="Infinite Straight Wire",subtitle="Magnetic field at radial distance r",inputs={{label="Current I",unit="A"},{label="Distance r",unit="m"},{label="Relative permeability"}},outputs={{label="Magnetic field B",unit="T"}},validate=function(v) return requirePositive(v[2],"Distance") or requirePositive(v[3],"Relative permeability") end,calculate=function(v) return MU_0*v[3]*v[1]/(2*math.pi*v[2]) end})
    calculators.finiteWireField = Calculator.new({id="finiteWireField",title="Finite Straight Wire",subtitle="Point at perpendicular distance r",inputs={{label="Current I",unit="A"},{label="Distance r",unit="m"},{label="Angle alpha1",unit="degrees"},{label="Angle alpha2",unit="degrees"},{label="Relative permeability"}},outputs={{label="Magnetic field B",unit="T"}},validate=function(v) return requirePositive(v[2],"Distance") or requirePositive(v[5],"Relative permeability") end,calculate=function(v) return MU_0*v[5]*v[1]*(math.sin(v[3]*math.pi/180)+math.sin(v[4]*math.pi/180))/(4*math.pi*v[2]) end})
    calculators.circularLoopField = Calculator.new({id="circularLoopField",title="Circular Loop Field",subtitle="Field at center of an N-turn loop",inputs={{label="Current I",unit="A"},{label="Radius R",unit="m"},{label="Turns N"},{label="Relative permeability"}},outputs={{label="Magnetic field B",unit="T"}},validate=function(v) return requirePositive(v[2],"Radius") or requirePositive(v[3],"Turns") or requirePositive(v[4],"Relative permeability") end,calculate=function(v) return MU_0*v[4]*v[3]*v[1]/(2*v[2]) end})
    calculators.solenoidField = Calculator.new({id="solenoidField",title="Ideal Solenoid Field",subtitle="Uniform interior field B = mu NI/L",inputs={{label="Current I",unit="A"},{label="Turns N"},{label="Length L",unit="m"},{label="Relative permeability"}},outputs={{label="Magnetic field B",unit="T"}},validate=function(v) return requirePositive(v[2],"Turns") or requirePositive(v[3],"Length") or requirePositive(v[4],"Relative permeability") end,calculate=function(v) return MU_0*v[4]*v[2]*v[1]/v[3] end})
    calculators.toroidField = Calculator.new({id="toroidField",title="Ideal Toroid Field",subtitle="Field at radius r inside the core",inputs={{label="Current I",unit="A"},{label="Turns N"},{label="Radius r",unit="m"},{label="Relative permeability"}},outputs={{label="Magnetic field B",unit="T"}},validate=function(v) return requirePositive(v[2],"Turns") or requirePositive(v[3],"Radius") or requirePositive(v[4],"Relative permeability") end,calculate=function(v) return MU_0*v[4]*v[2]*v[1]/(2*math.pi*v[3]) end})

    -- Magnetostatics: forces and torque
    calculators.movingChargeMagneticForce = Calculator.new({id="movingChargeMagneticForce",title="Force on Moving Charge",subtitle="F = q(v x B)",inputs={{label="Charge q",unit="C"},{label="vx",unit="m/s"},{label="vy",unit="m/s"},{label="vz",unit="m/s"},{label="Bx",unit="T"},{label="By",unit="T"},{label="Bz",unit="T"}},outputs={{label="Fx",unit="N"},{label="Fy",unit="N"},{label="Fz",unit="N"},{label="Magnitude",unit="N"}},visibleInputCount=5,calculate=function(v) local x,y,z=vectors.cross(v[2],v[3],v[4],v[5],v[6],v[7]); x,y,z=v[1]*x,v[1]*y,v[1]*z; return x,y,z,vectors.magnitude(x,y,z) end})
    calculators.currentWireForce = Calculator.new({id="currentWireForce",title="Force on Current-Carrying Wire",subtitle="F = I(L x B)",inputs={{label="Current I",unit="A"},{label="Lx",unit="m"},{label="Ly",unit="m"},{label="Lz",unit="m"},{label="Bx",unit="T"},{label="By",unit="T"},{label="Bz",unit="T"}},outputs={{label="Fx",unit="N"},{label="Fy",unit="N"},{label="Fz",unit="N"},{label="Magnitude",unit="N"}},visibleInputCount=5,calculate=function(v) local x,y,z=vectors.cross(v[2],v[3],v[4],v[5],v[6],v[7]); x,y,z=v[1]*x,v[1]*y,v[1]*z; return x,y,z,vectors.magnitude(x,y,z) end})
    calculators.parallelWireForce = Calculator.new({id="parallelWireForce",title="Force Between Parallel Wires",subtitle="Signed F/L; + same current direction",inputs={{label="Current I1",unit="A"},{label="Current I2",unit="A"},{label="Separation d",unit="m"},{label="Relative permeability"}},outputs={{label="Force per length",unit="N/m"},{label="Magnitude",unit="N/m"}},validate=function(v) return requirePositive(v[3],"Separation") or requirePositive(v[4],"Relative permeability") end,calculate=function(v) local f=MU_0*v[4]*v[1]*v[2]/(2*math.pi*v[3]); return f,math.abs(f) end})
    calculators.currentLoopTorque = Calculator.new({id="currentLoopTorque",title="Torque on Current Loop",subtitle="Magnitude tau = NIAB sin(theta)",inputs={{label="Turns N"},{label="Current I",unit="A"},{label="Loop area A",unit="m^2"},{label="Magnetic field B",unit="T"},{label="Angle theta",unit="degrees"}},outputs={{label="Torque",unit="N*m"},{label="Magnetic moment",unit="A*m^2"}},validate=function(v) return requirePositive(v[1],"Turns") or requirePositive(v[3],"Area") or requirePositive(v[4],"Magnetic field") end,calculate=function(v) local m=v[1]*v[2]*v[3]; return m*v[4]*math.sin(v[5]*math.pi/180),m end})

    -- Flux, induction, and inductance
    calculators.magneticFlux = Calculator.new({id="magneticFlux",title="Magnetic Flux",subtitle="Uniform field through a flat surface",inputs={{label="Magnetic field B",unit="T"},{label="Area A",unit="m^2"},{label="Angle theta",unit="degrees"}},outputs={{label="Magnetic flux",unit="Wb"}},validate=function(v) return requirePositive(v[2],"Area") end,calculate=function(v) return v[1]*v[2]*math.cos(v[3]*math.pi/180) end})
    calculators.faradayLaw = Calculator.new({id="faradayLaw",title="Faraday's Law",subtitle="Average induced EMF = -N DeltaPhi/Delta t",inputs={{label="Turns N"},{label="Initial flux",unit="Wb"},{label="Final flux",unit="Wb"},{label="Time interval",unit="s"}},outputs={{label="Induced EMF",unit="V"},{label="Magnitude",unit="V"}},validate=function(v) return requirePositive(v[1],"Turns") or requirePositive(v[4],"Time interval") end,calculate=function(v) local e=-v[1]*(v[3]-v[2])/v[4]; return e,math.abs(e) end})
    calculators.solenoidInductance = Calculator.new({id="solenoidInductance",title="Solenoid Inductance",subtitle="Ideal L = mu N^2 A / length",inputs={{label="Turns N"},{label="Area A",unit="m^2"},{label="Length",unit="m"},{label="Relative permeability"}},outputs={{label="Inductance",unit="H"}},validate=function(v) return requirePositive(v[1],"Turns") or requirePositive(v[2],"Area") or requirePositive(v[3],"Length") or requirePositive(v[4],"Relative permeability") end,calculate=function(v) return MU_0*v[4]*v[1]^2*v[2]/v[3] end})
    calculators.mutualInductance = Calculator.new({id="mutualInductance",title="Mutual Inductance",subtitle="M = k sqrt(L1 L2)",inputs={{label="Inductance L1",unit="H"},{label="Inductance L2",unit="H"},{label="Coupling coefficient k"}},outputs={{label="Mutual inductance",unit="H"}},validate=function(v) if v[1] <= 0 or v[2] <= 0 then return "Inductances must be greater than zero" end; if v[3] < 0 or v[3] > 1 then return "Coupling coefficient must be from 0 to 1" end end,calculate=function(v) return v[3]*math.sqrt(v[1]*v[2]) end})
    calculators.inductorEnergy = Calculator.new({id="inductorEnergy",title="Energy Stored in Inductor",subtitle="W = 1/2 L I^2",inputs={{label="Inductance L",unit="H"},{label="Current I",unit="A"}},outputs={{label="Stored energy",unit="J"}},validate=function(v) return requirePositive(v[1],"Inductance") end,calculate=function(v) return 0.5*v[1]*v[2]^2 end})
end
-- Electromagnetic wave calculator definitions.

local WAVE_EPSILON_0 = 8.854187817e-12
local WAVE_MU_0 = 4e-7 * math.pi
local C_0 = 1 / math.sqrt(WAVE_MU_0 * WAVE_EPSILON_0)
local ETA_0 = math.sqrt(WAVE_MU_0 / WAVE_EPSILON_0)

local function waveRequirePositive(value, name)
    if value <= 0 then return name .. " must be greater than zero" end
end

local function waveValidateMaterial(v, erIndex, mrIndex)
    return waveRequirePositive(v[erIndex], "Relative permittivity") or
        waveRequirePositive(v[mrIndex], "Relative permeability")
end

function registerWaveCalculators(calculators)
    calculators.waveSpeed = Calculator.new({
        id = "waveSpeed",
        title = "Wave Speed",
        subtitle = "Lossless homogeneous medium",
        inputs = {
            {label = "Relative permittivity"},
            {label = "Relative permeability"}
        },
        outputs = {{label = "Wave speed", unit = "m/s"}},
        validate = function(v) return waveValidateMaterial(v, 1, 2) end,
        calculate = function(v) return C_0 / math.sqrt(v[1] * v[2]) end
    })

    calculators.intrinsicImpedance = Calculator.new({
        id = "intrinsicImpedance",
        title = "Intrinsic Impedance",
        subtitle = "Lossless homogeneous medium",
        inputs = {
            {label = "Relative permittivity"},
            {label = "Relative permeability"}
        },
        outputs = {{label = "Intrinsic impedance", unit = "ohm"}},
        validate = function(v) return waveValidateMaterial(v, 1, 2) end,
        calculate = function(v) return ETA_0 * math.sqrt(v[2] / v[1]) end
    })

    calculators.waveWavelength = Calculator.new({
        id = "waveWavelength",
        title = "Wavelength",
        subtitle = "lambda = v/f for a lossless medium",
        inputs = {
            {label = "Frequency f", unit = "Hz"},
            {label = "Relative permittivity"},
            {label = "Relative permeability"}
        },
        outputs = {
            {label = "Wavelength", unit = "m"},
            {label = "Wave speed", unit = "m/s"},
            {label = "Phase constant", unit = "rad/m"}
        },
        validate = function(v)
            return waveRequirePositive(v[1], "Frequency") or waveValidateMaterial(v, 2, 3)
        end,
        calculate = function(v)
            local speed = C_0 / math.sqrt(v[2] * v[3])
            local wavelength = speed / v[1]
            return wavelength, speed, 2 * math.pi / wavelength
        end
    })

    calculators.lossyPropagation = Calculator.new({
        id = "lossyPropagation",
        title = "Propagation Constant",
        subtitle = "General lossy homogeneous medium",
        inputs = {
            {label = "Frequency f", unit = "Hz"},
            {label = "Conductivity sigma", unit = "S/m"},
            {label = "Relative permittivity"},
            {label = "Relative permeability"}
        },
        outputs = {
            {label = "Attenuation alpha", unit = "Np/m"},
            {label = "Phase beta", unit = "rad/m"},
            {label = "Wavelength", unit = "m"},
            {label = "Phase velocity", unit = "m/s"}
        },
        validate = function(v)
            if v[2] < 0 then return "Conductivity cannot be negative" end
            return waveRequirePositive(v[1], "Frequency") or waveValidateMaterial(v, 3, 4)
        end,
        calculate = function(v)
            local omega = 2 * math.pi * v[1]
            local epsilon = WAVE_EPSILON_0 * v[3]
            local mu = WAVE_MU_0 * v[4]
            local ratio = v[2] / (omega * epsilon)
            local root = math.sqrt(1 + ratio ^ 2)
            local common = omega * math.sqrt(mu * epsilon / 2)
            local alpha = common * math.sqrt(root - 1)
            local beta = common * math.sqrt(root + 1)
            return alpha, beta, 2 * math.pi / beta, omega / beta
        end
    })

    calculators.skinDepth = Calculator.new({
        id = "skinDepth",
        title = "Skin Depth",
        subtitle = "Good-conductor approximation",
        inputs = {
            {label = "Frequency f", unit = "Hz"},
            {label = "Conductivity sigma", unit = "S/m"},
            {label = "Relative permeability"}
        },
        outputs = {
            {label = "Skin depth", unit = "m"},
            {label = "Attenuation alpha", unit = "Np/m"}
        },
        validate = function(v)
            return waveRequirePositive(v[1], "Frequency") or
                waveRequirePositive(v[2], "Conductivity") or
                waveRequirePositive(v[3], "Relative permeability")
        end,
        calculate = function(v)
            local delta = math.sqrt(2 / (2 * math.pi * v[1] * WAVE_MU_0 * v[3] * v[2]))
            return delta, 1 / delta
        end
    })

    calculators.powerDensity = Calculator.new({
        id = "powerDensity",
        title = "Plane-Wave Power Density",
        subtitle = "Time-average power from peak electric field",
        inputs = {
            {label = "Peak electric field", unit = "V/m"},
            {label = "Relative permittivity"},
            {label = "Relative permeability"}
        },
        outputs = {
            {label = "Power density", unit = "W/m^2"},
            {label = "Intrinsic impedance", unit = "ohm"},
            {label = "Peak magnetic field", unit = "A/m"}
        },
        validate = function(v) return waveValidateMaterial(v, 2, 3) end,
        calculate = function(v)
            local eta = ETA_0 * math.sqrt(v[3] / v[2])
            return v[1] ^ 2 / (2 * eta), eta, v[1] / eta
        end
    })
end
-- Transmission-line calculator definitions.

local function tlRequirePositive(value, name)
    if value <= 0 then return name .. " must be greater than zero" end
end

local function cAdd(ar, ai, br, bi) return ar + br, ai + bi end
local function cSub(ar, ai, br, bi) return ar - br, ai - bi end
local function cMul(ar, ai, br, bi) return ar * br - ai * bi, ar * bi + ai * br end
local function cDiv(ar, ai, br, bi)
    local d = br * br + bi * bi
    if d == 0 then error("complex division by zero") end
    return (ar * br + ai * bi) / d, (ai * br - ar * bi) / d
end
local function cMagnitude(r, i) return math.sqrt(r * r + i * i) end
local function cAngleDegrees(r, i) return math.atan2(i, r) * 180 / math.pi end
local function cSqrt(r, i)
    local m = cMagnitude(r, i)
    local real = math.sqrt(math.max(0, (m + r) / 2))
    local imag = math.sqrt(math.max(0, (m - r) / 2))
    if i < 0 then imag = -imag end
    return real, imag
end
local function positiveModulo(value, period)
    local result = value % period
    if result < 0 then result = result + period end
    return result
end

function registerTransmissionCalculators(calculators)
    calculators.reflectionCoefficient = Calculator.new({
        id="reflectionCoefficient", title="Reflection Coefficient",
        subtitle="Gamma = (ZL - Z0)/(ZL + Z0)",
        inputs={{label="Load resistance",unit="ohm"},{label="Load reactance",unit="ohm"},{label="Characteristic Z0",unit="ohm"}},
        outputs={{label="Gamma real"},{label="Gamma imag"},{label="Magnitude"},{label="Angle",unit="degrees"}},
        validate=function(v) return tlRequirePositive(v[3],"Characteristic impedance") end,
        calculate=function(v)
            local nr,ni=cSub(v[1],v[2],v[3],0)
            local dr,di=cAdd(v[1],v[2],v[3],0)
            local gr,gi=cDiv(nr,ni,dr,di)
            return gr,gi,cMagnitude(gr,gi),cAngleDegrees(gr,gi)
        end
    })

    calculators.loadFromReflection = Calculator.new({
        id="loadFromReflection", title="Load from Reflection Coefficient",
        subtitle="ZL = Z0(1 + Gamma)/(1 - Gamma)",
        inputs={{label="Gamma real"},{label="Gamma imag"},{label="Characteristic Z0",unit="ohm"}},
        outputs={{label="Load resistance",unit="ohm"},{label="Load reactance",unit="ohm"},{label="Load magnitude",unit="ohm"},{label="Load angle",unit="degrees"}},
        validate=function(v) return tlRequirePositive(v[3],"Characteristic impedance") end,
        calculate=function(v)
            local zr,zi=cDiv(1+v[1],v[2],1-v[1],-v[2])
            zr,zi=v[3]*zr,v[3]*zi
            return zr,zi,cMagnitude(zr,zi),cAngleDegrees(zr,zi)
        end
    })

    calculators.vswr = Calculator.new({
        id="vswr", title="VSWR", subtitle="VSWR = (1 + |Gamma|)/(1 - |Gamma|)",
        inputs={{label="Reflection magnitude"}}, outputs={{label="VSWR"}},
        validate=function(v) if v[1] < 0 or v[1] >= 1 then return "Reflection magnitude must be from 0 to less than 1" end end,
        calculate=function(v) return (1+v[1])/(1-v[1]) end
    })

    calculators.returnLoss = Calculator.new({
        id="returnLoss", title="Return and Mismatch Loss",
        subtitle="Losses from reflection coefficient magnitude",
        inputs={{label="Reflection magnitude"}},
        outputs={{label="Return loss",unit="dB"},{label="Mismatch loss",unit="dB"},{label="Reflected power",unit="%"},{label="Delivered power",unit="%"}},
        validate=function(v) if v[1] < 0 or v[1] >= 1 then return "Reflection magnitude must be from 0 to less than 1" end end,
        calculate=function(v)
            local g2=v[1]^2
            local rl=v[1]==0 and 1e99 or -20*math.log(v[1])/math.log(10)
            local ml=-10*math.log(1-g2)/math.log(10)
            return rl,ml,100*g2,100*(1-g2)
        end
    })

    calculators.losslessInputImpedance = Calculator.new({
        id="losslessInputImpedance", title="Input Impedance",
        subtitle="Lossless line at distance l from load",
        inputs={{label="Load resistance",unit="ohm"},{label="Load reactance",unit="ohm"},{label="Characteristic Z0",unit="ohm"},{label="Phase constant beta",unit="rad/m"},{label="Line length l",unit="m"}},
        outputs={{label="Input resistance",unit="ohm"},{label="Input reactance",unit="ohm"},{label="Input magnitude",unit="ohm"},{label="Input angle",unit="degrees"}},
        validate=function(v)
            return tlRequirePositive(v[3],"Characteristic impedance") or tlRequirePositive(v[4],"Phase constant") or (v[5] < 0 and "Line length cannot be negative" or nil)
        end,
        calculate=function(v)
            local t=math.tan(v[4]*v[5])
            local nr,ni=v[1],v[2]+v[3]*t
            local zrt,zit=cMul(v[1],v[2],0,t)
            local rr,ri=cDiv(nr,ni,v[3]+zrt,zit)
            rr,ri=v[3]*rr,v[3]*ri
            return rr,ri,cMagnitude(rr,ri),cAngleDegrees(rr,ri)
        end
    })

    calculators.quarterWaveTransformer = Calculator.new({
        id="quarterWaveTransformer", title="Quarter-Wave Transformer",
        subtitle="Match two positive real impedances",
        inputs={{label="Source line Z0",unit="ohm"},{label="Load resistance",unit="ohm"},{label="Frequency f",unit="Hz"},{label="Wave velocity",unit="m/s"}},
        outputs={{label="Transformer impedance",unit="ohm"},{label="Quarter-wave length",unit="m"},{label="Wavelength",unit="m"}},
        validate=function(v)
            return tlRequirePositive(v[1],"Source impedance") or tlRequirePositive(v[2],"Load resistance") or tlRequirePositive(v[3],"Frequency") or tlRequirePositive(v[4],"Wave velocity")
        end,
        calculate=function(v) local wavelength=v[4]/v[3]; return math.sqrt(v[1]*v[2]),wavelength/4,wavelength end
    })

    calculators.characteristicImpedance = Calculator.new({
        id="characteristicImpedance", title="Characteristic Impedance",
        subtitle="Z0 = sqrt((R + jwL)/(G + jwC))",
        inputs={{label="Resistance R'",unit="ohm/m"},{label="Inductance L'",unit="H/m"},{label="Conductance G'",unit="S/m"},{label="Capacitance C'",unit="F/m"},{label="Frequency f",unit="Hz"}},
        outputs={{label="Z0 real",unit="ohm"},{label="Z0 imag",unit="ohm"},{label="Z0 magnitude",unit="ohm"},{label="Z0 angle",unit="degrees"}},
        validate=function(v)
            if v[1] < 0 or v[3] < 0 then return "R' and G' cannot be negative" end
            return tlRequirePositive(v[2],"Inductance") or tlRequirePositive(v[4],"Capacitance") or tlRequirePositive(v[5],"Frequency")
        end,
        calculate=function(v)
            local w=2*math.pi*v[5]
            local rr,ri=cDiv(v[1],w*v[2],v[3],w*v[4])
            local zr,zi=cSqrt(rr,ri)
            return zr,zi,cMagnitude(zr,zi),cAngleDegrees(zr,zi)
        end
    })

    calculators.lineParameters = Calculator.new({
        id="lineParameters", title="Line Parameters",
        subtitle="Propagation from distributed R', L', G', and C'",
        inputs={{label="Resistance R'",unit="ohm/m"},{label="Inductance L'",unit="H/m"},{label="Conductance G'",unit="S/m"},{label="Capacitance C'",unit="F/m"},{label="Frequency f",unit="Hz"}},
        outputs={{label="Attenuation alpha",unit="Np/m"},{label="Phase beta",unit="rad/m"},{label="Phase velocity",unit="m/s"},{label="Wavelength",unit="m"}},
        validate=function(v)
            if v[1] < 0 or v[3] < 0 then return "R' and G' cannot be negative" end
            return tlRequirePositive(v[2],"Inductance") or tlRequirePositive(v[4],"Capacitance") or tlRequirePositive(v[5],"Frequency")
        end,
        calculate=function(v)
            local w=2*math.pi*v[5]
            local pr,pi=cMul(v[1],w*v[2],v[3],w*v[4])
            local alpha,beta=cSqrt(pr,pi)
            if beta < 0 then beta=-beta end
            return alpha,beta,w/beta,2*math.pi/beta
        end
    })

    calculators.voltageCurrentMaxima = Calculator.new({
        id="voltageCurrentMaxima", title="Voltage and Current Maxima",
        subtitle="Lossless line; distances measured from load",
        inputs={{label="Forward voltage magnitude",unit="V"},{label="Reflection magnitude"},{label="Reflection angle",unit="degrees"},{label="Characteristic Z0",unit="ohm"},{label="Phase constant beta",unit="rad/m"}},
        outputs={{label="Maximum voltage",unit="V"},{label="Maximum current",unit="A"},{label="Nearest V max",unit="m"},{label="Nearest I max",unit="m"}},
        validate=function(v)
            if v[1] < 0 then return "Forward voltage cannot be negative" end
            if v[2] < 0 or v[2] > 1 then return "Reflection magnitude must be from 0 to 1" end
            return tlRequirePositive(v[4],"Characteristic impedance") or tlRequirePositive(v[5],"Phase constant")
        end,
        calculate=function(v)
            local angle=v[3]*math.pi/180
            local period=2*math.pi
            local zv=positiveModulo(angle,period)/(2*v[5])
            local zi=positiveModulo(angle-math.pi,period)/(2*v[5])
            return v[1]*(1+v[2]),(v[1]/v[4])*(1+v[2]),zv,zi
        end
    })

    calculators.electricalLength = Calculator.new({
        id="electricalLength", title="Electrical Length", subtitle="Convert physical length to phase",
        inputs={{label="Line length",unit="m"},{label="Frequency f",unit="Hz"},{label="Wave velocity",unit="m/s"}},
        outputs={{label="Electrical length",unit="degrees"},{label="Electrical length",unit="rad"},{label="Wavelengths"},{label="Wavelength",unit="m"}},
        validate=function(v) if v[1] < 0 then return "Line length cannot be negative" end; return tlRequirePositive(v[2],"Frequency") or tlRequirePositive(v[3],"Wave velocity") end,
        calculate=function(v) local wavelength=v[3]/v[2]; local cycles=v[1]/wavelength; return 360*cycles,2*math.pi*cycles,cycles,wavelength end
    })
end
-- Transmission-line time-average power calculators.

local previousRegisterTransmissionCalculators = registerTransmissionCalculators

function registerTransmissionCalculators(calculators)
    previousRegisterTransmissionCalculators(calculators)

    -- Use this version when the forward-traveling RMS voltage is known.
    calculators.transmissionAveragePower = Calculator.new({
        id = "transmissionAveragePower",
        title = "Power from Forward Voltage",
        subtitle = "Lossless line; forward voltage is RMS magnitude",
        inputs = {
            {label = "Forward voltage V0+ RMS", unit = "V"},
            {label = "Characteristic Z0", unit = "ohm"},
            {label = "Reflection magnitude |Gamma|"}
        },
        outputs = {
            {label = "Incident average power", unit = "W"},
            {label = "Reflected average power", unit = "W"},
            {label = "Load average power", unit = "W"},
            {label = "Power delivered", unit = "%"}
        },
        validate = function(v)
            if v[1] < 0 then return "Forward voltage cannot be negative" end
            if v[2] <= 0 then return "Characteristic impedance must be greater than zero" end
            if v[3] < 0 or v[3] > 1 then return "Reflection magnitude must be from 0 to 1" end
        end,
        calculate = function(v)
            local incident = v[1] * v[1] / v[2]
            local reflected = incident * v[3] * v[3]
            local load = incident - reflected
            return incident, reflected, load, 100 * (1 - v[3] * v[3])
        end
    })

    -- Use this version when a peak load-voltage magnitude is measured, as in
    -- ECE 216 Assignment 8 Question 5. Peak phasors require the factor 1/2.
    calculators.transmissionPowerFromLoadVoltage = Calculator.new({
        id = "transmissionPowerFromLoadVoltage",
        title = "Power from Load Voltage",
        subtitle = "Lossless line; load voltage is peak magnitude",
        inputs = {
            {label = "Load voltage |VL| peak", unit = "V"},
            {label = "Load resistance RL", unit = "ohm"},
            {label = "Load reactance XL", unit = "ohm"},
            {label = "Characteristic Z0", unit = "ohm"}
        },
        outputs = {
            {label = "Incident average power", unit = "W"},
            {label = "Reflected average power", unit = "W"},
            {label = "Load average power", unit = "W"},
            {label = "Recovered |V0+| peak", unit = "V"}
        },
        validate = function(v)
            if v[1] < 0 then return "Load voltage cannot be negative" end
            if v[2] < 0 then return "Load resistance cannot be negative" end
            if v[4] <= 0 then return "Characteristic impedance must be greater than zero" end
            if v[2] == 0 and v[3] == 0 then return "Load impedance cannot be zero" end
        end,
        calculate = function(v)
            local vl = v[1]
            local rl = v[2]
            local xl = v[3]
            local z0 = v[4]

            -- Gamma_L = (ZL - Z0)/(ZL + Z0)
            local numeratorReal = rl - z0
            local numeratorImag = xl
            local denominatorReal = rl + z0
            local denominatorImag = xl
            local denominatorMagnitudeSquared = denominatorReal * denominatorReal + denominatorImag * denominatorImag
            local gammaReal = (numeratorReal * denominatorReal + numeratorImag * denominatorImag) / denominatorMagnitudeSquared
            local gammaImag = (numeratorImag * denominatorReal - numeratorReal * denominatorImag) / denominatorMagnitudeSquared
            local gammaMagnitudeSquared = gammaReal * gammaReal + gammaImag * gammaImag

            -- VL = V0+ (1 + Gamma_L)
            local onePlusGammaMagnitude = math.sqrt((1 + gammaReal) * (1 + gammaReal) + gammaImag * gammaImag)
            local vForwardPeak = vl / onePlusGammaMagnitude

            local incident = vForwardPeak * vForwardPeak / (2 * z0)
            local reflected = incident * gammaMagnitudeSquared
            local load = incident - reflected
            return incident, reflected, load, vForwardPeak
        end
    })
end
-- Coordinate-system calculator definitions.

local function validateNonnegative(value, name)
    if value < 0 then return name .. " cannot be negative" end
end

local function validateTheta(value)
    if value < 0 or value > 180 then
        return "Theta must be between 0 and 180 degrees"
    end
end

function registerCoordinateCalculators(calculators)
    calculators.cartesianToCylindrical = Calculator.new({
        title = "Cartesian to Cylindrical",
        subtitle = "phi is measured from +x toward +y",
        inputs = {{label = "x"}, {label = "y"}, {label = "z"}},
        outputs = {
            {label = "rho"},
            {label = "phi", unit = "degrees"},
            {label = "z"}
        },
        calculate = function(v)
            return coordinates.cartesianToCylindrical(v[1], v[2], v[3])
        end
    })

    calculators.cylindricalToCartesian = Calculator.new({
        title = "Cylindrical to Cartesian",
        subtitle = "phi is entered in degrees",
        inputs = {
            {label = "rho"},
            {label = "phi", unit = "degrees"},
            {label = "z"}
        },
        outputs = {{label = "x"}, {label = "y"}, {label = "z"}},
        validate = function(v)
            return validateNonnegative(v[1], "rho")
        end,
        calculate = function(v)
            return coordinates.cylindricalToCartesian(v[1], v[2], v[3])
        end
    })

    calculators.cartesianToSpherical = Calculator.new({
        title = "Cartesian to Spherical",
        subtitle = "theta from +z; phi from +x",
        inputs = {{label = "x"}, {label = "y"}, {label = "z"}},
        outputs = {
            {label = "r"},
            {label = "theta", unit = "degrees"},
            {label = "phi", unit = "degrees"}
        },
        calculate = function(v)
            return coordinates.cartesianToSpherical(v[1], v[2], v[3])
        end
    })

    calculators.sphericalToCartesian = Calculator.new({
        title = "Spherical to Cartesian",
        subtitle = "theta from +z; phi from +x",
        inputs = {
            {label = "r"},
            {label = "theta", unit = "degrees"},
            {label = "phi", unit = "degrees"}
        },
        outputs = {{label = "x"}, {label = "y"}, {label = "z"}},
        validate = function(v)
            return validateNonnegative(v[1], "r") or validateTheta(v[2])
        end,
        calculate = function(v)
            return coordinates.sphericalToCartesian(v[1], v[2], v[3])
        end
    })

    calculators.cylindricalVectorToCartesian = Calculator.new({
        title = "Cylindrical Vector to Cartesian",
        subtitle = "Enter vector components and point angle",
        inputs = {
            {label = "A rho"},
            {label = "A phi"},
            {label = "A z"},
            {label = "phi", unit = "degrees"}
        },
        outputs = {{label = "Ax"}, {label = "Ay"}, {label = "Az"}},
        calculate = function(v)
            return coordinates.cylindricalVectorToCartesian(v[1], v[2], v[3], v[4])
        end
    })

    calculators.sphericalVectorToCartesian = Calculator.new({
        title = "Spherical Vector to Cartesian",
        subtitle = "theta from +z; phi from +x",
        inputs = {
            {label = "A r"},
            {label = "A theta"},
            {label = "A phi"},
            {label = "theta", unit = "degrees"},
            {label = "phi", unit = "degrees"}
        },
        outputs = {{label = "Ax"}, {label = "Ay"}, {label = "Az"}},
        validate = function(v)
            return validateTheta(v[4])
        end,
        calculate = function(v)
            return coordinates.sphericalVectorToCartesian(v[1], v[2], v[3], v[4], v[5])
        end
    })
end
-- Mechanical engineering calculator definitions.

local function mechPositive(value, name)
    if value <= 0 then return name .. " must be greater than zero" end
end

local function degToRad(value) return value * math.pi / 180 end
local function radToDeg(value) return value * 180 / math.pi end

function registerMechanicalCalculators(calculators)
    -- Statics
    calculators.forceResultant2D = Calculator.new({
        id="forceResultant2D", title="2D Force Resultant",
        subtitle="Enter up to four forces by magnitude and angle",
        allowOptionalInputs=true, minimumInputs=2,
        inputs={{label="F1",unit="N"},{label="theta1",unit="degrees"},{label="F2",unit="N"},{label="theta2",unit="degrees"},{label="F3",unit="N"},{label="theta3",unit="degrees"},{label="F4",unit="N"},{label="theta4",unit="degrees"}},
        outputs={{label="Resultant Fx",unit="N"},{label="Resultant Fy",unit="N"},{label="Magnitude",unit="N"},{label="Direction",unit="degrees"}},
        visibleInputCount=5,
        validate=function(v)
            for i=1,8,2 do
                if (v[i] == nil) ~= (v[i+1] == nil) then return "Each force needs magnitude and angle" end
            end
        end,
        calculate=function(v)
            local fx,fy=0,0
            for i=1,8,2 do if v[i] then fx=fx+v[i]*math.cos(degToRad(v[i+1])); fy=fy+v[i]*math.sin(degToRad(v[i+1])) end end
            return fx,fy,math.sqrt(fx*fx+fy*fy),radToDeg(math.atan2(fy,fx))
        end
    })

    calculators.moment2D = Calculator.new({
        id="moment2D", title="Moment About a Point", subtitle="M = rx Fy - ry Fx; CCW positive",
        inputs={{label="Position rx",unit="m"},{label="Position ry",unit="m"},{label="Force Fx",unit="N"},{label="Force Fy",unit="N"}},
        outputs={{label="Moment",unit="N*m"},{label="Magnitude",unit="N*m"}},
        calculate=function(v) local m=v[1]*v[4]-v[2]*v[3]; return m,math.abs(m) end
    })

    calculators.coupleMoment = Calculator.new({
        id="coupleMoment", title="Couple Moment", subtitle="M = Fd",
        inputs={{label="Force magnitude",unit="N"},{label="Perpendicular distance",unit="m"}},
        outputs={{label="Couple moment",unit="N*m"}},
        validate=function(v) return mechPositive(v[2],"Distance") end,
        calculate=function(v) return v[1]*v[2] end
    })

    -- Mechanics of materials
    calculators.normalStress = Calculator.new({
        id="normalStress", title="Normal Stress", subtitle="sigma = P/A; tension positive",
        inputs={{label="Axial force P",unit="N"},{label="Area A",unit="m^2"}}, outputs={{label="Normal stress",unit="Pa"}},
        validate=function(v) return mechPositive(v[2],"Area") end, calculate=function(v) return v[1]/v[2] end
    })

    calculators.normalStrain = Calculator.new({
        id="normalStrain", title="Normal Strain", subtitle="epsilon = delta/L",
        inputs={{label="Length change",unit="m"},{label="Original length",unit="m"}}, outputs={{label="Normal strain"}},
        validate=function(v) return mechPositive(v[2],"Original length") end, calculate=function(v) return v[1]/v[2] end
    })

    calculators.axialDeformation = Calculator.new({
        id="axialDeformation", title="Axial Deformation", subtitle="delta = PL/(AE)",
        inputs={{label="Axial force P",unit="N"},{label="Length L",unit="m"},{label="Area A",unit="m^2"},{label="Elastic modulus E",unit="Pa"}},
        outputs={{label="Deformation",unit="m"},{label="Stress",unit="Pa"},{label="Strain"}},
        validate=function(v) return mechPositive(v[2],"Length") or mechPositive(v[3],"Area") or mechPositive(v[4],"Elastic modulus") end,
        calculate=function(v) local stress=v[1]/v[3]; local strain=stress/v[4]; return strain*v[2],stress,strain end
    })

    calculators.torsionSolidShaft = Calculator.new({
        id="torsionSolidShaft", title="Solid-Shaft Torsion", subtitle="Circular solid shaft",
        inputs={{label="Torque T",unit="N*m"},{label="Diameter d",unit="m"},{label="Length L",unit="m"},{label="Shear modulus G",unit="Pa"}},
        outputs={{label="Maximum shear stress",unit="Pa"},{label="Angle of twist",unit="rad"},{label="Angle of twist",unit="degrees"},{label="Polar moment J",unit="m^4"}},
        validate=function(v) return mechPositive(v[2],"Diameter") or mechPositive(v[3],"Length") or mechPositive(v[4],"Shear modulus") end,
        calculate=function(v) local j=math.pi*v[2]^4/32; local tau=16*v[1]/(math.pi*v[2]^3); local phi=v[1]*v[3]/(j*v[4]); return tau,phi,radToDeg(phi),j end
    })

    calculators.bendingStress = Calculator.new({
        id="bendingStress", title="Beam Bending Stress", subtitle="sigma = -My/I",
        inputs={{label="Bending moment M",unit="N*m"},{label="Distance y",unit="m"},{label="Second moment I",unit="m^4"}},
        outputs={{label="Bending stress",unit="Pa"},{label="Magnitude",unit="Pa"}},
        validate=function(v) return mechPositive(v[3],"Second moment of area") end,
        calculate=function(v) local s=-v[1]*v[2]/v[3]; return s,math.abs(s) end
    })

    calculators.transverseShear = Calculator.new({
        id="transverseShear", title="Transverse Shear Stress", subtitle="tau = VQ/(It)",
        inputs={{label="Shear force V",unit="N"},{label="First moment Q",unit="m^3"},{label="Second moment I",unit="m^4"},{label="Width t",unit="m"}},
        outputs={{label="Shear stress",unit="Pa"}},
        validate=function(v) return mechPositive(v[3],"Second moment") or mechPositive(v[4],"Width") end,
        calculate=function(v) return v[1]*v[2]/(v[3]*v[4]) end
    })

    calculators.thinWallCylinder = Calculator.new({
        id="thinWallCylinder", title="Thin-Wall Pressure Vessel", subtitle="Closed cylindrical vessel",
        inputs={{label="Internal pressure p",unit="Pa"},{label="Inner radius r",unit="m"},{label="Wall thickness t",unit="m"}},
        outputs={{label="Hoop stress",unit="Pa"},{label="Longitudinal stress",unit="Pa"}},
        validate=function(v) return mechPositive(v[2],"Radius") or mechPositive(v[3],"Thickness") end,
        calculate=function(v) return v[1]*v[2]/v[3],v[1]*v[2]/(2*v[3]) end
    })

    calculators.planeStressPrincipal = Calculator.new({
        id="planeStressPrincipal", title="Principal Stress and Mohr Circle", subtitle="Plane stress: sigma_x, sigma_y, tau_xy",
        inputs={{label="sigma_x",unit="Pa"},{label="sigma_y",unit="Pa"},{label="tau_xy",unit="Pa"}},
        outputs={{label="Principal sigma1",unit="Pa"},{label="Principal sigma2",unit="Pa"},{label="Max in-plane shear",unit="Pa"},{label="Principal angle",unit="degrees"}},
        calculate=function(v)
            local avg=(v[1]+v[2])/2; local radius=math.sqrt(((v[1]-v[2])/2)^2+v[3]^2)
            local theta=0.5*radToDeg(math.atan2(2*v[3],v[1]-v[2]))
            return avg+radius,avg-radius,radius,theta
        end
    })

    calculators.stressTransformation = Calculator.new({
        id="stressTransformation", title="Plane Stress Transformation", subtitle="Stress on axes rotated by theta",
        inputs={{label="sigma_x",unit="Pa"},{label="sigma_y",unit="Pa"},{label="tau_xy",unit="Pa"},{label="Rotation theta",unit="degrees"}},
        outputs={{label="sigma_x prime",unit="Pa"},{label="sigma_y prime",unit="Pa"},{label="tau_x'y'",unit="Pa"}},
        calculate=function(v)
            local t=2*degToRad(v[4]); local avg=(v[1]+v[2])/2; local half=(v[1]-v[2])/2
            local sx=avg+half*math.cos(t)+v[3]*math.sin(t)
            local sy=avg-half*math.cos(t)-v[3]*math.sin(t)
            local tau=-half*math.sin(t)+v[3]*math.cos(t)
            return sx,sy,tau
        end
    })
end
-- Dynamics calculator definitions.

local G_ACCEL = 9.80665

local function positive(value, name)
    if value <= 0 then return name .. " must be greater than zero" end
end

local function nonnegative(value, name)
    if value < 0 then return name .. " cannot be negative" end
end

local function oneBlankDefinition(id, title, subtitle, variables, validate, solve)
    return Calculator.new({
        id = id,
        title = title,
        subtitle = subtitle or "Leave exactly one field blank",
        allowOneBlank = true,
        inputs = variables,
        outputs = {{label = "Result"}},
        resolveOutputs = function(_, missing) return {variables[missing]} end,
        validate = validate,
        calculate = solve
    })
end

function registerDynamicsCalculators(calculators)
    -- Kinematics
    calculators.constantAcceleration = Calculator.new({
        id = "constantAcceleration",
        title = "Constant Acceleration",
        subtitle = "Motion from initial velocity, acceleration, and time",
        inputs = {
            {label="Initial velocity v0",unit="m/s"},
            {label="Acceleration a",unit="m/s^2"},
            {label="Time t",unit="s"}
        },
        outputs = {
            {label="Final velocity v",unit="m/s"},
            {label="Displacement",unit="m"}
        },
        validate = function(v) return nonnegative(v[3], "Time") end,
        calculate = function(v)
            return v[1] + v[2] * v[3], v[1] * v[3] + 0.5 * v[2] * v[3]^2
        end
    })

    calculators.velocityDisplacement = Calculator.new({
        id = "velocityDisplacement",
        title = "Velocity from Displacement",
        subtitle = "v^2 = v0^2 + 2a Delta x",
        inputs = {
            {label="Initial velocity v0",unit="m/s"},
            {label="Acceleration a",unit="m/s^2"},
            {label="Displacement",unit="m"}
        },
        outputs = {{label="Final speed",unit="m/s"}},
        validate = function(v)
            if v[1]^2 + 2*v[2]*v[3] < 0 then return "No real final velocity" end
        end,
        calculate = function(v) return math.sqrt(v[1]^2 + 2*v[2]*v[3]) end
    })

    calculators.circularMotion = Calculator.new({
        id = "circularMotion",
        title = "Circular Motion",
        inputs = {
            {label="Radius r",unit="m"},
            {label="Angular velocity",unit="rad/s"},
            {label="Angular acceleration",unit="rad/s^2"}
        },
        outputs = {
            {label="Tangential velocity",unit="m/s"},
            {label="Tangential acceleration",unit="m/s^2"},
            {label="Normal acceleration",unit="m/s^2"},
            {label="Total acceleration",unit="m/s^2"}
        },
        validate = function(v) return nonnegative(v[1], "Radius") end,
        calculate = function(v)
            local vt = v[1]*v[2]
            local at = v[1]*v[3]
            local an = v[1]*v[2]^2
            return vt, at, an, math.sqrt(at^2 + an^2)
        end
    })

    calculators.projectileMotion = Calculator.new({
        id = "projectileMotion",
        title = "Projectile Motion",
        subtitle = "No air resistance; landing height is zero",
        inputs = {
            {label="Initial speed",unit="m/s"},
            {label="Launch angle",unit="degrees"},
            {label="Initial height",unit="m"}
        },
        outputs = {
            {label="Flight time",unit="s"},
            {label="Range",unit="m"},
            {label="Maximum height",unit="m"},
            {label="Impact speed",unit="m/s"}
        },
        validate = function(v)
            return nonnegative(v[1], "Initial speed") or nonnegative(v[3], "Initial height")
        end,
        calculate = function(v)
            local angle = v[2]*math.pi/180
            local vx = v[1]*math.cos(angle)
            local vy = v[1]*math.sin(angle)
            local time = (vy + math.sqrt(vy^2 + 2*G_ACCEL*v[3]))/G_ACCEL
            local range = vx*time
            local hmax = v[3] + vy^2/(2*G_ACCEL)
            local vyImpact = vy - G_ACCEL*time
            return time, range, hmax, math.sqrt(vx^2 + vyImpact^2)
        end
    })

    -- Newton's second law and force/work relations
    local fmaVars = {{label="Force F",unit="N"},{label="Mass m",unit="kg"},{label="Acceleration a",unit="m/s^2"}}
    calculators.newtonsSecondLaw = oneBlankDefinition(
        "newtonsSecondLaw", "Newton's Second Law", "F = ma; leave one field blank", fmaVars,
        function(v, missing)
            if v[2] and v[2] <= 0 then return "Mass must be greater than zero" end
            if missing == 2 and v[3] == 0 then return "Acceleration cannot be zero when solving mass" end
        end,
        function(v, missing)
            if missing == 1 then return v[2]*v[3] end
            if missing == 2 then return v[1]/v[3] end
            return v[1]/v[2]
        end
    )

    calculators.workConstantForce = Calculator.new({
        id="workConstantForce", title="Work by Constant Force",
        inputs={{label="Force F",unit="N"},{label="Displacement d",unit="m"},{label="Angle",unit="degrees"}},
        outputs={{label="Work",unit="J"}},
        validate=function(v) return nonnegative(v[2],"Displacement") end,
        calculate=function(v) return v[1]*v[2]*math.cos(v[3]*math.pi/180) end
    })

    calculators.kineticEnergy = Calculator.new({
        id="kineticEnergy", title="Kinetic Energy",
        inputs={{label="Mass m",unit="kg"},{label="Speed v",unit="m/s"}},
        outputs={{label="Kinetic energy",unit="J"}},
        validate=function(v) return positive(v[1],"Mass") or nonnegative(v[2],"Speed") end,
        calculate=function(v) return 0.5*v[1]*v[2]^2 end
    })

    calculators.potentialEnergy = Calculator.new({
        id="potentialEnergy", title="Gravitational Potential Energy",
        inputs={{label="Mass m",unit="kg"},{label="Height h",unit="m"},{label="Gravity g",unit="m/s^2"}},
        outputs={{label="Potential energy",unit="J"}},
        validate=function(v) return positive(v[1],"Mass") or positive(v[3],"Gravity") end,
        calculate=function(v) return v[1]*v[3]*v[2] end
    })

    calculators.springEnergy = Calculator.new({
        id="springEnergy", title="Spring Energy",
        inputs={{label="Spring constant k",unit="N/m"},{label="Deflection x",unit="m"}},
        outputs={{label="Elastic energy",unit="J"}},
        validate=function(v) return positive(v[1],"Spring constant") end,
        calculate=function(v) return 0.5*v[1]*v[2]^2 end
    })

    calculators.linearPower = Calculator.new({
        id="linearPower", title="Mechanical Power",
        subtitle="P = Fv cos(theta)",
        inputs={{label="Force F",unit="N"},{label="Velocity v",unit="m/s"},{label="Angle",unit="degrees"}},
        outputs={{label="Power",unit="W"}},
        calculate=function(v) return v[1]*v[2]*math.cos(v[3]*math.pi/180) end
    })

    -- Momentum and impacts
    calculators.linearMomentum = Calculator.new({
        id="linearMomentum", title="Linear Momentum",
        inputs={{label="Mass m",unit="kg"},{label="Velocity v",unit="m/s"}},
        outputs={{label="Momentum",unit="kg*m/s"}},
        validate=function(v) return positive(v[1],"Mass") end,
        calculate=function(v) return v[1]*v[2] end
    })

    calculators.impulseMomentum = Calculator.new({
        id="impulseMomentum", title="Impulse-Momentum",
        inputs={{label="Mass m",unit="kg"},{label="Initial velocity",unit="m/s"},{label="Final velocity",unit="m/s"}},
        outputs={{label="Impulse",unit="N*s"},{label="Change in momentum",unit="kg*m/s"}},
        validate=function(v) return positive(v[1],"Mass") end,
        calculate=function(v) local j=v[1]*(v[3]-v[2]); return j,j end
    })

    calculators.inelasticCollision = Calculator.new({
        id="inelasticCollision", title="Perfectly Inelastic Collision",
        subtitle="Bodies stick together after a one-dimensional collision",
        inputs={{label="Mass m1",unit="kg"},{label="Velocity u1",unit="m/s"},{label="Mass m2",unit="kg"},{label="Velocity u2",unit="m/s"}},
        outputs={{label="Common final velocity",unit="m/s"},{label="Kinetic energy lost",unit="J"}},
        validate=function(v) return positive(v[1],"Mass m1") or positive(v[3],"Mass m2") end,
        calculate=function(v)
            local vf=(v[1]*v[2]+v[3]*v[4])/(v[1]+v[3])
            local initial=0.5*v[1]*v[2]^2+0.5*v[3]*v[4]^2
            local final=0.5*(v[1]+v[3])*vf^2
            return vf,initial-final
        end
    })

    calculators.restitutionCollision = Calculator.new({
        id="restitutionCollision", title="1D Collision with Restitution",
        inputs={{label="Mass m1",unit="kg"},{label="Initial u1",unit="m/s"},{label="Mass m2",unit="kg"},{label="Initial u2",unit="m/s"},{label="Restitution e"}},
        outputs={{label="Final velocity v1",unit="m/s"},{label="Final velocity v2",unit="m/s"}},
        validate=function(v)
            if v[1]<=0 or v[3]<=0 then return "Masses must be greater than zero" end
            if v[5]<0 or v[5]>1 then return "Restitution must be from 0 to 1" end
        end,
        calculate=function(v)
            local total=v[1]+v[3]
            local v1=(v[1]*v[2]+v[3]*v[4]-v[3]*v[5]*(v[2]-v[4]))/total
            local v2=(v[1]*v[2]+v[3]*v[4]+v[1]*v[5]*(v[2]-v[4]))/total
            return v1,v2
        end
    })

    -- Rotation
    calculators.rotationalDynamics = Calculator.new({
        id="rotationalDynamics", title="Rotational Dynamics",
        inputs={{label="Moment of inertia I",unit="kg*m^2"},{label="Angular velocity",unit="rad/s"},{label="Angular acceleration",unit="rad/s^2"}},
        outputs={{label="Angular momentum",unit="kg*m^2/s"},{label="Rotational energy",unit="J"},{label="Torque",unit="N*m"}},
        validate=function(v) return positive(v[1],"Moment of inertia") end,
        calculate=function(v) return v[1]*v[2],0.5*v[1]*v[2]^2,v[1]*v[3] end
    })

    calculators.parallelAxis = Calculator.new({
        id="parallelAxis", title="Parallel-Axis Theorem",
        inputs={{label="Centroidal inertia",unit="kg*m^2"},{label="Mass m",unit="kg"},{label="Offset d",unit="m"}},
        outputs={{label="Shifted inertia",unit="kg*m^2"}},
        validate=function(v) return nonnegative(v[1],"Centroidal inertia") or positive(v[2],"Mass") or nonnegative(v[3],"Offset") end,
        calculate=function(v) return v[1]+v[2]*v[3]^2 end
    })

    calculators.inertiaCommonShapes = Calculator.new({
        id="inertiaCommonShapes", title="Common Mass Moments of Inertia",
        subtitle="Returns several shapes from the same mass and dimensions",
        inputs={{label="Mass m",unit="kg"},{label="Radius r",unit="m"},{label="Length L",unit="m"}},
        outputs={{label="Solid disk/cylinder",unit="kg*m^2"},{label="Thin ring",unit="kg*m^2"},{label="Solid sphere",unit="kg*m^2"},{label="Slender rod, centre",unit="kg*m^2"}},
        validate=function(v) return positive(v[1],"Mass") or nonnegative(v[2],"Radius") or nonnegative(v[3],"Length") end,
        calculate=function(v) return 0.5*v[1]*v[2]^2,v[1]*v[2]^2,0.4*v[1]*v[2]^2,v[1]*v[3]^2/12 end
    })
end
-- Mechanical-vibration calculator definitions.

local function vibPositive(value, name)
    if value <= 0 then return name .. " must be greater than zero" end
end

local function vibNonnegative(value, name)
    if value < 0 then return name .. " cannot be negative" end
end

local function vibrationParameters(m, k, c)
    local wn = math.sqrt(k / m)
    local cc = 2 * math.sqrt(k * m)
    local zeta = c / cc
    local wd = zeta < 1 and wn * math.sqrt(1 - zeta * zeta) or 0
    return wn, cc, zeta, wd
end

function registerVibrationCalculators(calculators)
    calculators.naturalFrequency = Calculator.new({
        id="naturalFrequency", title="Undamped Natural Frequency",
        subtitle="Single-degree-of-freedom spring-mass system",
        inputs={{label="Mass m",unit="kg"},{label="Stiffness k",unit="N/m"}},
        outputs={{label="Angular frequency",unit="rad/s"},{label="Natural frequency",unit="Hz"},{label="Natural period",unit="s"}},
        validate=function(v) return vibPositive(v[1],"Mass") or vibPositive(v[2],"Stiffness") end,
        calculate=function(v)
            local wn=math.sqrt(v[2]/v[1])
            return wn,wn/(2*math.pi),2*math.pi/wn
        end
    })

    calculators.dampingProperties = Calculator.new({
        id="dampingProperties", title="Damping Properties",
        subtitle="Viscously damped spring-mass system",
        inputs={{label="Mass m",unit="kg"},{label="Stiffness k",unit="N/m"},{label="Damping c",unit="N*s/m"}},
        outputs={{label="Critical damping",unit="N*s/m"},{label="Damping ratio"},{label="Damped frequency",unit="rad/s"},{label="Decay rate",unit="1/s"}},
        validate=function(v) return vibPositive(v[1],"Mass") or vibPositive(v[2],"Stiffness") or vibNonnegative(v[3],"Damping") end,
        calculate=function(v)
            local wn,cc,zeta,wd=vibrationParameters(v[1],v[2],v[3])
            return cc,zeta,wd,zeta*wn
        end
    })

    calculators.logarithmicDecrement = Calculator.new({
        id="logarithmicDecrement", title="Logarithmic Decrement",
        subtitle="Use amplitudes separated by N cycles",
        inputs={{label="Earlier amplitude x1"},{label="Later amplitude xN"},{label="Number of cycles N"}},
        outputs={{label="Logarithmic decrement"},{label="Damping ratio"}},
        validate=function(v)
            return vibPositive(math.abs(v[1]),"Earlier amplitude magnitude") or
                vibPositive(math.abs(v[2]),"Later amplitude magnitude") or
                vibPositive(v[3],"Number of cycles") or
                (math.abs(v[1])<=math.abs(v[2]) and "Earlier amplitude must exceed later amplitude" or nil)
        end,
        calculate=function(v)
            local delta=math.log(math.abs(v[1]/v[2]))/v[3]
            local zeta=delta/math.sqrt(4*math.pi*math.pi+delta*delta)
            return delta,zeta
        end
    })

    calculators.underdampedFreeResponse = Calculator.new({
        id="underdampedFreeResponse", title="Underdamped Free Response",
        subtitle="Displacement and velocity at time t",
        inputs={{label="Mass m",unit="kg"},{label="Stiffness k",unit="N/m"},{label="Damping c",unit="N*s/m"},{label="Initial displacement x0",unit="m"},{label="Initial velocity v0",unit="m/s"},{label="Time t",unit="s"}},
        outputs={{label="Displacement x",unit="m"},{label="Velocity v",unit="m/s"},{label="Damped frequency",unit="rad/s"}}, visibleInputCount=5,
        validate=function(v)
            local err=vibPositive(v[1],"Mass") or vibPositive(v[2],"Stiffness") or vibNonnegative(v[3],"Damping") or vibNonnegative(v[6],"Time")
            if err then return err end
            local _,_,zeta=vibrationParameters(v[1],v[2],v[3])
            if zeta>=1 then return "System must be underdamped (zeta < 1)" end
        end,
        calculate=function(v)
            local wn,_,zeta,wd=vibrationParameters(v[1],v[2],v[3])
            local a=zeta*wn
            local A=v[4]
            local B=(v[5]+a*v[4])/wd
            local e=math.exp(-a*v[6])
            local c=math.cos(wd*v[6]); local s=math.sin(wd*v[6])
            local x=e*(A*c+B*s)
            local velocity=e*((-a*A+wd*B)*c+(-a*B-wd*A)*s)
            return x,velocity,wd
        end
    })

    calculators.harmonicForceResponse = Calculator.new({
        id="harmonicForceResponse", title="Harmonic Force Response",
        subtitle="Steady-state response to F0 cos(omega t)",
        inputs={{label="Force amplitude F0",unit="N"},{label="Mass m",unit="kg"},{label="Damping c",unit="N*s/m"},{label="Stiffness k",unit="N/m"},{label="Forcing frequency",unit="rad/s"}},
        outputs={{label="Displacement amplitude",unit="m"},{label="Phase lag",unit="degrees"},{label="Frequency ratio r"},{label="Dynamic magnification"}},
        validate=function(v) return vibNonnegative(v[1],"Force amplitude") or vibPositive(v[2],"Mass") or vibNonnegative(v[3],"Damping") or vibPositive(v[4],"Stiffness") or vibNonnegative(v[5],"Forcing frequency") end,
        calculate=function(v)
            local wn,_,zeta=vibrationParameters(v[2],v[4],v[3])
            local r=v[5]/wn
            local denominator=math.sqrt((1-r*r)^2+(2*zeta*r)^2)
            if denominator==0 then error("undamped resonance") end
            local magnification=1/denominator
            local amplitude=(v[1]/v[4])*magnification
            local phase=math.atan2(2*zeta*r,1-r*r)*180/math.pi
            return amplitude,phase,r,magnification
        end
    })

    calculators.vibrationTransmissibility = Calculator.new({
        id="vibrationTransmissibility", title="Vibration Transmissibility",
        subtitle="Force/base-motion transmissibility for an SDOF system",
        inputs={{label="Mass m",unit="kg"},{label="Damping c",unit="N*s/m"},{label="Stiffness k",unit="N/m"},{label="Excitation frequency",unit="rad/s"}},
        outputs={{label="Frequency ratio r"},{label="Displacement magnification"},{label="Transmissibility"},{label="Isolation",unit="%"}},
        validate=function(v) return vibPositive(v[1],"Mass") or vibNonnegative(v[2],"Damping") or vibPositive(v[3],"Stiffness") or vibNonnegative(v[4],"Excitation frequency") end,
        calculate=function(v)
            local wn,_,zeta=vibrationParameters(v[1],v[3],v[2])
            local r=v[4]/wn
            local den=math.sqrt((1-r*r)^2+(2*zeta*r)^2)
            if den==0 then error("undamped resonance") end
            local dm=1/den
            local tr=math.sqrt(1+(2*zeta*r)^2)/den
            return r,dm,tr,100*(1-tr)
        end
    })

    calculators.springSeries = Calculator.new({
        id="springSeries", title="Springs in Series", subtitle="Enter two to five spring constants",
        allowOptionalInputs=true, minimumInputs=2,
        inputs={{label="k1",unit="N/m"},{label="k2",unit="N/m"},{label="k3",unit="N/m"},{label="k4",unit="N/m"},{label="k5",unit="N/m"}},
        outputs={{label="Equivalent stiffness",unit="N/m"}},
        validate=function(v) for _,k in pairs(v) do if k and k<=0 then return "Spring constants must be positive" end end end,
        calculate=function(v) local sum=0; for _,k in pairs(v) do if k then sum=sum+1/k end end; return 1/sum end
    })

    calculators.springParallel = Calculator.new({
        id="springParallel", title="Springs in Parallel", subtitle="Enter two to five spring constants",
        allowOptionalInputs=true, minimumInputs=2,
        inputs={{label="k1",unit="N/m"},{label="k2",unit="N/m"},{label="k3",unit="N/m"},{label="k4",unit="N/m"},{label="k5",unit="N/m"}},
        outputs={{label="Equivalent stiffness",unit="N/m"}},
        validate=function(v) for _,k in pairs(v) do if k and k<0 then return "Spring constants cannot be negative" end end end,
        calculate=function(v) local sum=0; for _,k in pairs(v) do if k then sum=sum+k end end; return sum end
    })

    calculators.pendulumFrequency = Calculator.new({
        id="pendulumFrequency", title="Simple Pendulum Frequency",
        subtitle="Small-angle approximation",
        inputs={{label="Pendulum length L",unit="m"},{label="Gravity g",unit="m/s^2"}},
        outputs={{label="Angular frequency",unit="rad/s"},{label="Frequency",unit="Hz"},{label="Period",unit="s"}},
        validate=function(v) return vibPositive(v[1],"Length") or vibPositive(v[2],"Gravity") end,
        calculate=function(v) local wn=math.sqrt(v[2]/v[1]); return wn,wn/(2*math.pi),2*math.pi/wn end
    })
end
-- Thermodynamics and heat-transfer calculator definitions.

local function thermoPositive(value, name)
    if value <= 0 then return name .. " must be greater than zero" end
end

local function thermoNonnegative(value, name)
    if value < 0 then return name .. " cannot be negative" end
end

function registerThermodynamicsCalculators(calculators)
    local idealGasVariables = {
        {label="Pressure P",unit="Pa"},{label="Volume V",unit="m^3"},{label="Moles n",unit="mol"},{label="Gas constant R",unit="J/(mol K)"},{label="Temperature T",unit="K"}
    }
    calculators.idealGasLaw = Calculator.new({
        id="idealGasLaw",title="Ideal Gas Law",subtitle="PV = nRT; leave one field blank",allowOneBlank=true,
        inputs=idealGasVariables,outputs={{label="Result"}},resolveOutputs=function(v,m) return {idealGasVariables[m]} end,
        validate=function(v,m)
            for i,value in ipairs(v) do if value and value <= 0 then return idealGasVariables[i].label .. " must be positive" end end
        end,
        calculate=function(v,m)
            if m==1 then return v[3]*v[4]*v[5]/v[2] end
            if m==2 then return v[3]*v[4]*v[5]/v[1] end
            if m==3 then return v[1]*v[2]/(v[4]*v[5]) end
            if m==4 then return v[1]*v[2]/(v[3]*v[5]) end
            return v[1]*v[2]/(v[3]*v[4])
        end
    })

    calculators.densitySpecificVolume = Calculator.new({
        id="densitySpecificVolume",title="Density and Specific Volume",subtitle="rho = 1/v; leave one field blank",allowOneBlank=true,
        inputs={{label="Density rho",unit="kg/m^3"},{label="Specific volume v",unit="m^3/kg"}},outputs={{label="Result"}},
        resolveOutputs=function(v,m) return {m==1 and {label="Density rho",unit="kg/m^3"} or {label="Specific volume v",unit="m^3/kg"}} end,
        validate=function(v) for _,x in ipairs(v) do if x and x<=0 then return "Entered value must be positive" end end end,
        calculate=function(v,m) return m==1 and 1/v[2] or 1/v[1] end
    })

    calculators.sensibleHeat = Calculator.new({
        id="sensibleHeat",title="Sensible Heat",subtitle="Q = m c DeltaT; leave one field blank",allowOneBlank=true,
        inputs={{label="Heat Q",unit="J"},{label="Mass m",unit="kg"},{label="Specific heat c",unit="J/(kg K)"},{label="Temperature change",unit="K"}},outputs={{label="Result"}},
        resolveOutputs=function(v,m) local o={{label="Heat Q",unit="J"},{label="Mass m",unit="kg"},{label="Specific heat c",unit="J/(kg K)"},{label="Temperature change",unit="K"}}; return {o[m]} end,
        validate=function(v,m) if v[2] and v[2]<=0 then return "Mass must be positive" end; if v[3] and v[3]<=0 then return "Specific heat must be positive" end end,
        calculate=function(v,m)
            if m==1 then return v[2]*v[3]*v[4] end
            if m==2 then return v[1]/(v[3]*v[4]) end
            if m==3 then return v[1]/(v[2]*v[4]) end
            return v[1]/(v[2]*v[3])
        end
    })

    calculators.closedSystemFirstLaw = Calculator.new({
        id="closedSystemFirstLaw",title="Closed-System First Law",subtitle="DeltaU = Q - W; work positive out",allowOneBlank=true,
        inputs={{label="Change in internal energy",unit="J"},{label="Heat into system Q",unit="J"},{label="Work by system W",unit="J"}},outputs={{label="Result"}},
        resolveOutputs=function(v,m) local o={{label="Change in internal energy",unit="J"},{label="Heat into system Q",unit="J"},{label="Work by system W",unit="J"}}; return {o[m]} end,
        calculate=function(v,m) if m==1 then return v[2]-v[3] elseif m==2 then return v[1]+v[3] else return v[2]-v[1] end end
    })

    calculators.enthalpyChange = Calculator.new({
        id="enthalpyChange",title="Enthalpy Change",subtitle="DeltaH = m cp DeltaT",
        inputs={{label="Mass",unit="kg"},{label="cp",unit="J/(kg K)"},{label="Temperature change",unit="K"}},
        outputs={{label="Enthalpy change",unit="J"}},
        validate=function(v) return thermoPositive(v[1],"Mass") or thermoPositive(v[2],"cp") end,
        calculate=function(v) return v[1]*v[2]*v[3] end
    })

    calculators.constantPressureWork = Calculator.new({
        id="constantPressureWork",title="Constant-Pressure Boundary Work",subtitle="W = P(V2 - V1)",
        inputs={{label="Pressure",unit="Pa"},{label="Initial volume",unit="m^3"},{label="Final volume",unit="m^3"}},
        outputs={{label="Boundary work",unit="J"}},
        validate=function(v) return thermoPositive(v[1],"Pressure") or thermoNonnegative(v[2],"Initial volume") or thermoNonnegative(v[3],"Final volume") end,
        calculate=function(v) return v[1]*(v[3]-v[2]) end
    })

    calculators.steadyFlowEnergy = Calculator.new({
        id="steadyFlowEnergy",title="Steady-Flow Energy Equation",subtitle="q-w = dh + d(V^2/2) + g dz",
        inputs={{label="Heat per mass q",unit="J/kg"},{label="Work per mass w",unit="J/kg"},{label="h1",unit="J/kg"},{label="h2",unit="J/kg"},{label="V1",unit="m/s"},{label="V2",unit="m/s"},{label="z1",unit="m"},{label="z2",unit="m"}},
        outputs={{label="Energy residual",unit="J/kg"}},visibleInputCount=5,
        calculate=function(v) return v[1]-v[2]-(v[4]-v[3])-(v[6]^2-v[5]^2)/2-9.80665*(v[8]-v[7]) end
    })

    calculators.isothermalIdealGas = Calculator.new({
        id="isothermalIdealGas",title="Isothermal Ideal-Gas Process",subtitle="P1V1 = P2V2 and W = nRT ln(V2/V1)",
        inputs={{label="P1",unit="Pa"},{label="V1",unit="m^3"},{label="V2",unit="m^3"}},
        outputs={{label="P2",unit="Pa"},{label="Work by gas",unit="J"}},
        validate=function(v) return thermoPositive(v[1],"P1") or thermoPositive(v[2],"V1") or thermoPositive(v[3],"V2") end,
        calculate=function(v) return v[1]*v[2]/v[3],v[1]*v[2]*math.log(v[3]/v[2]) end
    })

    calculators.isentropicIdealGas = Calculator.new({
        id="isentropicIdealGas",title="Isentropic Ideal-Gas Process",subtitle="T2/T1 = (P2/P1)^((k-1)/k)",
        inputs={{label="T1",unit="K"},{label="P1",unit="Pa"},{label="P2",unit="Pa"},{label="Specific-heat ratio k"}},
        outputs={{label="T2",unit="K"},{label="Volume ratio V2/V1"}},
        validate=function(v) return thermoPositive(v[1],"T1") or thermoPositive(v[2],"P1") or thermoPositive(v[3],"P2") or (v[4]<=1 and "k must be greater than 1" or nil) end,
        calculate=function(v) return v[1]*(v[3]/v[2])^((v[4]-1)/v[4]),(v[2]/v[3])^(1/v[4]) end
    })

    calculators.polytropicProcess = Calculator.new({
        id="polytropicProcess",title="Polytropic Process",subtitle="P V^n = constant",
        inputs={{label="P1",unit="Pa"},{label="V1",unit="m^3"},{label="V2",unit="m^3"},{label="Exponent n"}},
        outputs={{label="P2",unit="Pa"},{label="Boundary work",unit="J"}},
        validate=function(v) return thermoPositive(v[1],"P1") or thermoPositive(v[2],"V1") or thermoPositive(v[3],"V2") end,
        calculate=function(v)
            local p2=v[1]*(v[2]/v[3])^v[4]
            local work
            if math.abs(v[4]-1)<1e-10 then work=v[1]*v[2]*math.log(v[3]/v[2]) else work=(p2*v[3]-v[1]*v[2])/(1-v[4]) end
            return p2,work
        end
    })

    calculators.carnotEfficiency = Calculator.new({
        id="carnotEfficiency",title="Carnot Efficiency",subtitle="eta = 1 - Tc/Th",
        inputs={{label="Hot reservoir Th",unit="K"},{label="Cold reservoir Tc",unit="K"}},
        outputs={{label="Thermal efficiency",unit="%"},{label="Refrigerator COP"},{label="Heat-pump COP"}},
        validate=function(v) if v[1]<=0 or v[2]<=0 then return "Temperatures must be positive" end; if v[1]<=v[2] then return "Th must exceed Tc" end end,
        calculate=function(v) return 100*(1-v[2]/v[1]),v[2]/(v[1]-v[2]),v[1]/(v[1]-v[2]) end
    })

    calculators.ottoEfficiency = Calculator.new({
        id="ottoEfficiency",title="Otto-Cycle Efficiency",subtitle="eta = 1 - 1/r^(k-1)",
        inputs={{label="Compression ratio r"},{label="Specific-heat ratio k"}},outputs={{label="Thermal efficiency",unit="%"}},
        validate=function(v) if v[1]<=1 then return "Compression ratio must exceed 1" end; if v[2]<=1 then return "k must exceed 1" end end,
        calculate=function(v) return 100*(1-1/(v[1]^(v[2]-1))) end
    })

    calculators.braytonEfficiency = Calculator.new({
        id="braytonEfficiency",title="Brayton-Cycle Efficiency",subtitle="Ideal cycle from pressure ratio",
        inputs={{label="Pressure ratio rp"},{label="Specific-heat ratio k"}},outputs={{label="Thermal efficiency",unit="%"}},
        validate=function(v) if v[1]<=1 then return "Pressure ratio must exceed 1" end; if v[2]<=1 then return "k must exceed 1" end end,
        calculate=function(v) return 100*(1-1/(v[1]^((v[2]-1)/v[2]))) end
    })

    calculators.fourierConduction = Calculator.new({
        id="fourierConduction",title="Plane-Wall Conduction",subtitle="Qdot = k A (T_hot-T_cold)/L",
        inputs={{label="Thermal conductivity k",unit="W/(m K)"},{label="Area A",unit="m^2"},{label="Thickness L",unit="m"},{label="Hot temperature",unit="K"},{label="Cold temperature",unit="K"}},
        outputs={{label="Heat-transfer rate",unit="W"},{label="Thermal resistance",unit="K/W"}},
        validate=function(v) return thermoPositive(v[1],"Thermal conductivity") or thermoPositive(v[2],"Area") or thermoPositive(v[3],"Thickness") end,
        calculate=function(v) return v[1]*v[2]*(v[4]-v[5])/v[3],v[3]/(v[1]*v[2]) end
    })

    calculators.convectionHeatTransfer = Calculator.new({
        id="convectionHeatTransfer",title="Convection Heat Transfer",subtitle="Qdot = h A (Ts - Tinf)",
        inputs={{label="Convection coefficient h",unit="W/(m^2 K)"},{label="Area A",unit="m^2"},{label="Surface temperature",unit="K"},{label="Fluid temperature",unit="K"}},
        outputs={{label="Heat-transfer rate",unit="W"},{label="Thermal resistance",unit="K/W"}},
        validate=function(v) return thermoPositive(v[1],"h") or thermoPositive(v[2],"Area") end,
        calculate=function(v) return v[1]*v[2]*(v[3]-v[4]),1/(v[1]*v[2]) end
    })

    calculators.radiationHeatTransfer = Calculator.new({
        id="radiationHeatTransfer",title="Thermal Radiation",subtitle="Qdot = eps sigma A (Ts^4 - Tsur^4)",
        inputs={{label="Emissivity"},{label="Area A",unit="m^2"},{label="Surface temperature",unit="K"},{label="Surroundings temperature",unit="K"}},
        outputs={{label="Net radiation rate",unit="W"}},
        validate=function(v) if v[1]<0 or v[1]>1 then return "Emissivity must be from 0 to 1" end; return thermoPositive(v[2],"Area") or thermoNonnegative(v[3],"Surface temperature") or thermoNonnegative(v[4],"Surroundings temperature") end,
        calculate=function(v) return v[1]*5.670374419e-8*v[2]*(v[3]^4-v[4]^4) end
    })

    calculators.thermalResistanceSeries = Calculator.new({
        id="thermalResistanceSeries",title="Thermal Resistances in Series",subtitle="Enter 2 to 5 resistances",allowOptionalInputs=true,minimumInputs=2,
        inputs={{label="R1",unit="K/W"},{label="R2",unit="K/W"},{label="R3",unit="K/W"},{label="R4",unit="K/W"},{label="R5",unit="K/W"}},
        outputs={{label="Equivalent resistance",unit="K/W"}},
        validate=function(v) for _,x in ipairs(v) do if x and x<0 then return "Resistance cannot be negative" end end end,
        calculate=function(v) local s=0; for _,x in ipairs(v) do if x then s=s+x end end; return s end
    })
end
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
    subtitle = "2x2 matrix eigenanalysis",
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
        {label="Matrix Tests 2x2",calculator="matrixTests2"},
        {label="Eigenvalues and Eigenvectors",menu=eigenMenu}
    }
}

for _, item in ipairs(rootMenu.items) do
    if item.label == "Linear Algebra" then
        item.menu = linearAlgebraMenu
        break
    end
end
-- Register Mechanical Engineering calculators and add the root menu.

registerMechanicalCalculators(calculators)
registerDynamicsCalculators(calculators)
registerVibrationCalculators(calculators)

local staticsMenu = {
    title = "Statics",
    subtitle = "Forces and moments in two dimensions",
    items = {
        {label="2D Force Resultant",calculator="forceResultant2D"},
        {label="Moment About a Point",calculator="moment2D"},
        {label="Couple Moment",calculator="coupleMoment"}
    }
}

local stressStrainMenu = {
    title = "Stress, Strain, and Deformation",
    subtitle = "Axial loading and material response",
    items = {
        {label="Normal Stress",calculator="normalStress"},
        {label="Normal Strain",calculator="normalStrain"},
        {label="Axial Deformation",calculator="axialDeformation"}
    }
}

local beamsShaftsMenu = {
    title = "Beams and Shafts",
    subtitle = "Torsion, bending, and transverse shear",
    items = {
        {label="Solid-Shaft Torsion",calculator="torsionSolidShaft"},
        {label="Beam Bending Stress",calculator="bendingStress"},
        {label="Transverse Shear Stress",calculator="transverseShear"}
    }
}

local combinedStressMenu = {
    title = "Combined Stress",
    subtitle = "Plane stress and pressure vessels",
    items = {
        {label="Thin-Wall Pressure Vessel",calculator="thinWallCylinder"},
        {label="Principal Stress / Mohr Circle",calculator="planeStressPrincipal"},
        {label="Plane Stress Transformation",calculator="stressTransformation"}
    }
}

local mechanicsMaterialsMenu = {
    title = "Mechanics of Materials",
    subtitle = "Stress, deformation, beams, and failure states",
    items = {
        {label="Stress and Strain",menu=stressStrainMenu},
        {label="Beams and Shafts",menu=beamsShaftsMenu},
        {label="Combined Stress",menu=combinedStressMenu}
    }
}

local kinematicsMenu = {
    title = "Kinematics",
    subtitle = "Translation, circular motion, and projectiles",
    items = {
        {label="Constant Acceleration",calculator="constantAcceleration"},
        {label="Velocity from Displacement",calculator="velocityDisplacement"},
        {label="Circular Motion",calculator="circularMotion"},
        {label="Projectile Motion",calculator="projectileMotion"}
    }
}

local forceEnergyMenu = {
    title = "Forces, Work, and Energy",
    subtitle = "Newton's law and energy methods",
    items = {
        {label="Newton's Second Law",calculator="newtonsSecondLaw"},
        {label="Work by Constant Force",calculator="workConstantForce"},
        {label="Kinetic Energy",calculator="kineticEnergy"},
        {label="Potential Energy",calculator="potentialEnergy"},
        {label="Spring Energy",calculator="springEnergy"},
        {label="Mechanical Power",calculator="linearPower"}
    }
}

local momentumMenu = {
    title = "Momentum and Impact",
    subtitle = "Impulse and one-dimensional collisions",
    items = {
        {label="Linear Momentum",calculator="linearMomentum"},
        {label="Impulse-Momentum",calculator="impulseMomentum"},
        {label="Perfectly Inelastic Collision",calculator="inelasticCollision"},
        {label="Collision with Restitution",calculator="restitutionCollision"}
    }
}

local rotationMenu = {
    title = "Rotation",
    subtitle = "Angular motion, torque, and inertia",
    items = {
        {label="Rotational Dynamics",calculator="rotationalDynamics"},
        {label="Parallel-Axis Theorem",calculator="parallelAxis"},
        {label="Common Moments of Inertia",calculator="inertiaCommonShapes"}
    }
}

local dynamicsMenu = {
    title = "Dynamics",
    subtitle = "Kinematics, energy, momentum, and rotation",
    items = {
        {label="Kinematics",menu=kinematicsMenu},
        {label="Forces, Work, and Energy",menu=forceEnergyMenu},
        {label="Momentum and Impact",menu=momentumMenu},
        {label="Rotation",menu=rotationMenu}
    }
}

local freeVibrationMenu = {
    title = "Free Vibration",
    subtitle = "Natural frequency and transient response",
    items = {
        {label="Natural Frequency",calculator="naturalFrequency"},
        {label="Damping Properties",calculator="dampingProperties"},
        {label="Logarithmic Decrement",calculator="logarithmicDecrement"},
        {label="Underdamped Free Response",calculator="underdampedFreeResponse"},
        {label="Simple Pendulum",calculator="pendulumFrequency"}
    }
}

local forcedVibrationMenu = {
    title = "Forced Vibration",
    subtitle = "Steady-state response and isolation",
    items = {
        {label="Harmonic Force Response",calculator="harmonicForceResponse"},
        {label="Vibration Transmissibility",calculator="vibrationTransmissibility"}
    }
}

local springSystemsMenu = {
    title = "Equivalent Springs",
    subtitle = "Combine spring stiffnesses",
    items = {
        {label="Springs in Series",calculator="springSeries"},
        {label="Springs in Parallel",calculator="springParallel"}
    }
}

local vibrationsMenu = {
    title = "Vibrations",
    subtitle = "Single-degree-of-freedom vibration tools",
    items = {
        {label="Free Vibration",menu=freeVibrationMenu},
        {label="Forced Vibration",menu=forcedVibrationMenu},
        {label="Equivalent Springs",menu=springSystemsMenu}
    }
}

local mechanicalEngineeringMenu = {
    title = "Mechanical Engineering",
    subtitle = "Statics, materials, dynamics, and vibrations",
    items = {
        {label="Statics",menu=staticsMenu},
        {label="Mechanics of Materials",menu=mechanicsMaterialsMenu},
        {label="Dynamics",menu=dynamicsMenu},
        {label="Vibrations",menu=vibrationsMenu},
        {label="Thermodynamics"},
        {label="Fluid Mechanics"}
    }
}

table.insert(rootMenu.items, #rootMenu.items, {label="Mechanical Engineering",menu=mechanicalEngineeringMenu})
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
-- Register AC/RLC calculators and extend Circuit Analysis.

registerRLCCalculators(calculators)

local rlcCoreMenu = {
    title = "RLC Impedance",
    subtitle = "Reactance and equivalent impedance",
    items = {
        {label="Reactance Calculator",calculator="rlcReactance"},
        {label="Series RLC Impedance",calculator="seriesRLC"},
        {label="Parallel RLC Impedance",calculator="parallelRLC"}
    }
}

local rlcResonanceMenu = {
    title = "Resonance and Bandwidth",
    subtitle = "Natural frequency, Q, and half-power points",
    items = {
        {label="Resonant Frequency",calculator="rlcResonance"},
        {label="Series RLC Q / Bandwidth",calculator="seriesRLCBandwidth"},
        {label="Parallel RLC Q / Bandwidth",calculator="parallelRLCBandwidth"}
    }
}

local rlcPowerMenu = {
    title = "AC Power and Dividers",
    subtitle = "Complex power and phasor divider tools",
    items = {
        {label="AC Complex Power",calculator="acPower"},
        {label="AC Voltage Divider",calculator="acVoltageDivider"},
        {label="AC Current Divider",calculator="acCurrentDivider"}
    }
}

local rlcMenu = {
    title = "AC and RLC Circuits",
    subtitle = "Impedance, resonance, power, and phasors",
    items = {
        {label="RLC Impedance",menu=rlcCoreMenu},
        {label="Resonance and Bandwidth",menu=rlcResonanceMenu},
        {label="AC Power and Dividers",menu=rlcPowerMenu}
    }
}

table.insert(circuitMenu.items, {label="AC and RLC Circuits",menu=rlcMenu})
-- Register transient calculators and Solve-by-Topic workspaces, then extend menus.

registerTransientCalculators(calculators)
registerTopicSolvers(calculators)
registerTransmissionTopic(calculators)

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

local electricalTopicsMenu = {
    title="Electrical Topics",
    subtitle="Enter known values and calculate the full topic",
    items={
        {label="Series RLC",calculator="topicSeriesRLC"},
        {label="Transmission Lines",calculator="topicTransmissionLine"}
    }
}

local solveByTopicMenu = {
    title="Solve by Topic",
    subtitle="Workspaces that calculate related quantities together",
    items={{label="Electrical",menu=electricalTopicsMenu}}
}

table.insert(rootMenu.items,2,{label="Solve by Topic",menu=solveByTopicMenu})
-- Register workspace memory and add it near the top of the main menu.

registerWorkspaceMemoryCalculators(calculators)

local workspaceMemoryMenu = {
    title="Workspace Memory",
    subtitle="Reuse stored values in any calculator expression",
    items={
        {label="Store / View A-J",calculator="workspaceMemory"},
        {label="Evaluate Stored Expression",calculator="workspaceRecall"}
    }
}

table.insert(rootMenu.items, 2, {label="Workspace Memory",menu=workspaceMemoryMenu})
