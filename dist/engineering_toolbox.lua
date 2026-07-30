-- Mathematical expression parser for calculator inputs.
-- Supports +, -, *, /, ^, parentheses, constants, and common functions.

expression = {}

local constants = {
    pi = math.pi,
    e = math.exp(1)
}

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

    function parser:peek()
        self:skipWhitespace()
        return string.sub(self.text, self.position, self.position)
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

        while self.position <= self.length do
            local character = string.sub(self.text, self.position, self.position)
            if character >= "0" and character <= "9" then
                sawDigit = true
                self.position = self.position + 1
            elseif character == "." then
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

        return tonumber(string.sub(self.text, start, self.position - 1))
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
        return string.lower(string.sub(self.text, start, self.position - 1))
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
            if constants[identifier] ~= nil then return constants[identifier] end
            local operation = functions[identifier]
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
        if self:consume("^") then
            value = value ^ self:parseUnary()
        end
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
    if text == nil or string.match(text, "^%s*$") then
        return nil, "empty expression"
    end

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
-- Reusable menu drawing and navigation.

Menu = {}

local function drawCenteredFitted(gc, text, y, bold, preferredSize, minimumSize)
    local width = platform.window:width()
    local horizontalPadding = 12
    local size = preferredSize

    while size > minimumSize do
        gc:setFont("sansserif", bold and "b" or "r", size)
        if gc:getStringWidth(text) <= width - (2 * horizontalPadding) then
            break
        end
        size = size - 1
    end

    gc:setFont("sansserif", bold and "b" or "r", size)
    local x = math.max(horizontalPadding, (width - gc:getStringWidth(text)) / 2)
    gc:drawString(text, x, y, "top")
end

function Menu.draw(gc, title, items, selectedItem, subtitle)
    drawCenteredFitted(gc, title, 10, true, 14, 10)
    drawCenteredFitted(gc, subtitle or "Use arrows and Enter", 34, false, 9, 7)

    for i, item in ipairs(items) do
        local y = 58 + ((i - 1) * 28)

        if i == selectedItem then
            gc:setFont("sansserif", "b", 11)
            gc:drawString("> " .. item, 30, y, "top")
        else
            gc:setFont("sansserif", "r", 11)
            gc:drawString("  " .. item, 30, y, "top")
        end
    end
end

function Menu.move(selectedItem, itemCount, key)
    if key == "up" then
        selectedItem = selectedItem - 1
        if selectedItem < 1 then
            selectedItem = itemCount
        end
    elseif key == "down" then
        selectedItem = selectedItem + 1
        if selectedItem > itemCount then
            selectedItem = 1
        end
    end

    return selectedItem
end-- Generic calculator screen.

Calculator = {}
Calculator.__index = Calculator

local engineeringPrefixes = {
    [-12] = "p", [-9] = "n", [-6] = "u", [-3] = "m",
    [0] = "", [3] = "k", [6] = "M", [9] = "G", [12] = "T"
}

local function engineeringFormat(value)
    if value == 0 then return "0" end
    local absoluteValue = math.abs(value)
    local exponent = math.floor(math.log(absoluteValue) / math.log(10) / 3) * 3
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
    gc:setFont("sansserif", "r", 10)
    gc:drawString(labelWithUnit(input) .. ":", 18, y, "top")
    if selected then
        gc:setFont("sansserif", "b", 10)
        gc:drawString("> " .. text .. "_", 145, y, "top")
    else
        gc:drawString("  " .. text, 145, y, "top")
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

function Calculator.new(definition)
    return setmetatable({
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
        defaultSubtitle = "Numbers or expressions; Enter to continue"
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
-- Electromagnetics calculator definitions.

local function vectorInputs(prefix)
    return {
        {label = prefix .. "x"},
        {label = prefix .. "y"},
        {label = prefix .. "z"}
    }
end

local function twoVectorInputs()
    return {
        {label = "Ax"}, {label = "Ay"}, {label = "Az"},
        {label = "Bx"}, {label = "By"}, {label = "Bz"}
    }
end

local function vectorOutputs(prefix)
    return {
        {label = prefix .. "x"},
        {label = prefix .. "y"},
        {label = prefix .. "z"}
    }
end

local function validateNonzeroVector(values, startIndex, name)
    local x, y, z = values[startIndex], values[startIndex + 1], values[startIndex + 2]
    if vectors.magnitude(x, y, z) == 0 then
        return name .. " cannot be the zero vector"
    end
end

function registerElectromagneticsCalculators(calculators)
    calculators.vectorMagnitude = Calculator.new({
        title = "Vector Magnitude",
        subtitle = "Enter Cartesian components",
        inputs = vectorInputs("A"),
        outputs = {{label = "Magnitude"}},
        calculate = function(v)
            return vectors.magnitude(v[1], v[2], v[3])
        end
    })

    calculators.vectorUnit = Calculator.new({
        title = "Unit Vector",
        subtitle = "Find a unit vector parallel to A",
        inputs = vectorInputs("A"),
        outputs = vectorOutputs("u"),
        validate = function(v)
            return validateNonzeroVector(v, 1, "A")
        end,
        calculate = function(v)
            return vectors.unit(v[1], v[2], v[3])
        end
    })

    calculators.vectorDot = Calculator.new({
        title = "Dot Product",
        subtitle = "Calculate A dot B",
        inputs = twoVectorInputs(),
        outputs = {{label = "A dot B"}},
        calculate = function(v)
            return vectors.dot(v[1], v[2], v[3], v[4], v[5], v[6])
        end
    })

    calculators.vectorCross = Calculator.new({
        title = "Cross Product",
        subtitle = "Calculate A x B",
        inputs = twoVectorInputs(),
        outputs = {
            {label = "Cx"}, {label = "Cy"}, {label = "Cz"},
            {label = "Magnitude"}
        },
        calculate = function(v)
            local x, y, z = vectors.cross(v[1], v[2], v[3], v[4], v[5], v[6])
            return x, y, z, vectors.magnitude(x, y, z)
        end
    })

    calculators.vectorAngle = Calculator.new({
        title = "Angle Between Vectors",
        subtitle = "Smallest angle from A to B",
        inputs = twoVectorInputs(),
        outputs = {{label = "Angle", unit = "degrees"}},
        validate = function(v)
            return validateNonzeroVector(v, 1, "A") or
                validateNonzeroVector(v, 4, "B")
        end,
        calculate = function(v)
            return vectors.angleDegrees(v[1], v[2], v[3], v[4], v[5], v[6])
        end
    })

    calculators.vectorProjection = Calculator.new({
        title = "Vector Projection",
        subtitle = "Projection of A onto B",
        inputs = twoVectorInputs(),
        outputs = vectorOutputs("P"),
        validate = function(v)
            return validateNonzeroVector(v, 4, "B")
        end,
        calculate = function(v)
            return vectors.projection(v[1], v[2], v[3], v[4], v[5], v[6])
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
-- TI-Nspire Engineering Toolbox
-- Application menu tree and navigation.

platform.apiLevel = "2.0"

local calculators = {}
registerComplexCalculators(calculators)
registerCircuitCalculators(calculators)
registerElectromagneticsCalculators(calculators)
registerCoordinateCalculators(calculators)

local complexArithmeticMenu = {
    title = "Complex Arithmetic",
    subtitle = "Choose an operation",
    items = {
        {label = "Add", calculator = "complexAdd"},
        {label = "Subtract", calculator = "complexSubtract"},
        {label = "Multiply", calculator = "complexMultiply"},
        {label = "Divide", calculator = "complexDivide"}
    }
}

local complexMenu = {
    title = "Complex Numbers",
    subtitle = "Enter to select, Esc to return",
    items = {
        {label = "Rectangular to Polar", calculator = "rectToPolar"},
        {label = "Polar to Rectangular", calculator = "polarToRect"},
        {label = "Magnitude and Phase", calculator = "magnitudePhase"},
        {label = "Complex Arithmetic", menu = complexArithmeticMenu}
    }
}

local basicCircuitsMenu = {
    title = "Basic Circuits",
    subtitle = "Enter to select, Esc to return",
    items = {
        {label = "Ohm's Law", calculator = "ohmsLaw"},
        {label = "Electrical Power", calculator = "electricalPower"},
        {label = "Voltage Divider", calculator = "voltageDivider"},
        {label = "Current Divider", calculator = "currentDivider"}
    }
}

local resistorNetworksMenu = {
    title = "Resistor Networks",
    subtitle = "Equivalent resistance and conversions",
    items = {
        {label = "Series Resistance", calculator = "seriesResistance"},
        {label = "Parallel Resistance", calculator = "parallelResistance"},
        {label = "Delta to Wye", calculator = "deltaToWye"},
        {label = "Wye to Delta", calculator = "wyeToDelta"}
    }
}

local sourceTransformationMenu = {
    title = "Source Transformation",
    subtitle = "Choose the source conversion direction",
    items = {
        {label = "Voltage to Current", calculator = "voltageToCurrentSource"},
        {label = "Current to Voltage", calculator = "currentToVoltageSource"}
    }
}

local equivalentConversionMenu = {
    title = "Thevenin and Norton",
    subtitle = "Choose the equivalent conversion direction",
    items = {
        {label = "Thevenin to Norton", calculator = "theveninToNorton"},
        {label = "Norton to Thevenin", calculator = "nortonToThevenin"}
    }
}

local networkTheoremsMenu = {
    title = "Network Theorems",
    subtitle = "Source and equivalent-circuit conversions",
    items = {
        {label = "Thevenin / Norton", menu = equivalentConversionMenu},
        {label = "Source Transformation", menu = sourceTransformationMenu}
    }
}

local equationSolversMenu = {
    title = "Equation Solvers",
    subtitle = "Solve circuit equation systems",
    items = {
        {label = "Two-Mesh Solver", calculator = "meshTwo"},
        {label = "Three-Mesh Solver"}
    }
}

local circuitMenu = {
    title = "Circuit Analysis",
    subtitle = "Choose a category",
    items = {
        {label = "Basic Circuits", menu = basicCircuitsMenu},
        {label = "Resistor Networks", menu = resistorNetworksMenu},
        {label = "Network Theorems", menu = networkTheoremsMenu},
        {label = "Equation Solvers", menu = equationSolversMenu}
    }
}

local vectorOperationsMenu = {
    title = "Vector Operations",
    subtitle = "Three-dimensional Cartesian vectors",
    items = {
        {label = "Magnitude", calculator = "vectorMagnitude"},
        {label = "Unit Vector", calculator = "vectorUnit"},
        {label = "Dot Product", calculator = "vectorDot"},
        {label = "Cross Product", calculator = "vectorCross"},
        {label = "Angle Between", calculator = "vectorAngle"},
        {label = "Projection A onto B", calculator = "vectorProjection"}
    }
}

local coordinateSystemsMenu = {
    title = "Coordinate Systems",
    subtitle = "Points and vector components",
    items = {
        {label = "Cartesian to Cylindrical", calculator = "cartesianToCylindrical"},
        {label = "Cylindrical to Cartesian", calculator = "cylindricalToCartesian"},
        {label = "Cartesian to Spherical", calculator = "cartesianToSpherical"},
        {label = "Spherical to Cartesian", calculator = "sphericalToCartesian"},
        {label = "Cyl Vector to Cartesian", calculator = "cylindricalVectorToCartesian"},
        {label = "Sph Vector to Cartesian", calculator = "sphericalVectorToCartesian"}
    }
}

local generalMathMenu = {
    title = "General Math",
    subtitle = "Reusable mathematical tools",
    items = {
        {label = "Vector Operations", menu = vectorOperationsMenu},
        {label = "Coordinate Systems", menu = coordinateSystemsMenu}
    }
}

local electromagneticsMenu = {
    title = "Electromagnetics",
    subtitle = "ECE 216 tools",
    items = {
        {label = "Electrostatics"},
        {label = "Magnetostatics"},
        {label = "Waves"},
        {label = "Transmission Lines"}
    }
}

local rootMenu = {
    title = "Engineering Toolbox",
    subtitle = "Use arrows and Enter",
    items = {
        {label = "Complex Numbers", menu = complexMenu},
        {label = "Circuit Analysis", menu = circuitMenu},
        {label = "Electromagnetics", menu = electromagneticsMenu},
        {label = "Linear Algebra"},
        {label = "Signals and Systems"},
        {label = "General Math", menu = generalMathMenu}
    }
}

local menuStack = {{menu = rootMenu, selected = 1}}
local activeCalculator = nil

local function currentFrame()
    return menuStack[#menuStack]
end

local function menuLabels(menu)
    local labels = {}
    for i, item in ipairs(menu.items) do labels[i] = item.label end
    return labels
end

local function openCalculator(name)
    activeCalculator = calculators[name]
    activeCalculator:reset()
end

local function openSelectedMenuItem()
    local frame = currentFrame()
    local item = frame.menu.items[frame.selected]
    if item.menu then
        menuStack[#menuStack + 1] = {menu = item.menu, selected = 1}
    elseif item.calculator then
        openCalculator(item.calculator)
    end
end

function on.paint(gc)
    if activeCalculator then
        activeCalculator:draw(gc)
        return
    end
    local frame = currentFrame()
    Menu.draw(gc, frame.menu.title, menuLabels(frame.menu), frame.selected, frame.menu.subtitle)
end

function on.arrowKey(key)
    if activeCalculator then
        activeCalculator:moveField(key)
    else
        local frame = currentFrame()
        frame.selected = Menu.move(frame.selected, #frame.menu.items, key)
    end
    platform.window:invalidate()
end

function on.enterKey()
    if activeCalculator then activeCalculator:enter() else openSelectedMenuItem() end
    platform.window:invalidate()
end

function on.charIn(character)
    if activeCalculator then
        activeCalculator:append(character)
        platform.window:invalidate()
    end
end

function on.backspaceKey()
    if activeCalculator then
        activeCalculator:backspace()
        platform.window:invalidate()
    end
end

function on.escapeKey()
    if activeCalculator then
        if activeCalculator.page == "results" then
            activeCalculator.page = "inputs"
            activeCalculator:ensureSelectedVisible()
        else
            activeCalculator = nil
        end
    elseif #menuStack > 1 then
        table.remove(menuStack)
    end
    platform.window:invalidate()
end
