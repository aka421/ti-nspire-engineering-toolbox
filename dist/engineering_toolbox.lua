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
end-- Complex-number calculations for the Engineering Toolbox.
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
end-- Calculation history screen.

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
-- Lossless transmission-line calculator definitions.

local function tlRequirePositive(value, name)
    if value <= 0 then return name .. " must be greater than zero" end
end

local function cAdd(ar, ai, br, bi) return ar + br, ai + bi end
local function cSub(ar, ai, br, bi) return ar - br, ai - bi end
local function cMul(ar, ai, br, bi) return ar * br - ai * bi, ar * bi + ai * br end
local function cDiv(ar, ai, br, bi)
    local denominator = br * br + bi * bi
    if denominator == 0 then error("complex division by zero") end
    return (ar * br + ai * bi) / denominator, (ai * br - ar * bi) / denominator
end
local function cMagnitude(r, i) return math.sqrt(r * r + i * i) end
local function cAngleDegrees(r, i) return math.atan2(i, r) * 180 / math.pi end

function registerTransmissionCalculators(calculators)
    calculators.reflectionCoefficient = Calculator.new({
        id = "reflectionCoefficient",
        title = "Reflection Coefficient",
        subtitle = "Gamma = (ZL - Z0)/(ZL + Z0)",
        inputs = {
            {label = "Load resistance", unit = "ohm"},
            {label = "Load reactance", unit = "ohm"},
            {label = "Characteristic Z0", unit = "ohm"}
        },
        outputs = {
            {label = "Gamma real"},
            {label = "Gamma imag"},
            {label = "Magnitude"},
            {label = "Angle", unit = "degrees"}
        },
        validate = function(v) return tlRequirePositive(v[3], "Characteristic impedance") end,
        calculate = function(v)
            local nr, ni = cSub(v[1], v[2], v[3], 0)
            local dr, di = cAdd(v[1], v[2], v[3], 0)
            local gr, gi = cDiv(nr, ni, dr, di)
            return gr, gi, cMagnitude(gr, gi), cAngleDegrees(gr, gi)
        end
    })

    calculators.loadFromReflection = Calculator.new({
        id = "loadFromReflection",
        title = "Load from Reflection Coefficient",
        subtitle = "ZL = Z0(1 + Gamma)/(1 - Gamma)",
        inputs = {
            {label = "Gamma real"},
            {label = "Gamma imag"},
            {label = "Characteristic Z0", unit = "ohm"}
        },
        outputs = {
            {label = "Load resistance", unit = "ohm"},
            {label = "Load reactance", unit = "ohm"},
            {label = "Load magnitude", unit = "ohm"},
            {label = "Load angle", unit = "degrees"}
        },
        validate = function(v)
            return tlRequirePositive(v[3], "Characteristic impedance")
        end,
        calculate = function(v)
            local nr, ni = 1 + v[1], v[2]
            local dr, di = 1 - v[1], -v[2]
            local zr, zi = cDiv(nr, ni, dr, di)
            zr, zi = v[3] * zr, v[3] * zi
            return zr, zi, cMagnitude(zr, zi), cAngleDegrees(zr, zi)
        end
    })

    calculators.vswr = Calculator.new({
        id = "vswr",
        title = "VSWR",
        subtitle = "VSWR = (1 + |Gamma|)/(1 - |Gamma|)",
        inputs = {{label = "Reflection magnitude"}},
        outputs = {{label = "VSWR"}},
        validate = function(v)
            if v[1] < 0 or v[1] >= 1 then return "Reflection magnitude must be from 0 to less than 1" end
        end,
        calculate = function(v) return (1 + v[1]) / (1 - v[1]) end
    })

    calculators.returnLoss = Calculator.new({
        id = "returnLoss",
        title = "Return and Mismatch Loss",
        subtitle = "Losses from reflection coefficient magnitude",
        inputs = {{label = "Reflection magnitude"}},
        outputs = {
            {label = "Return loss", unit = "dB"},
            {label = "Mismatch loss", unit = "dB"},
            {label = "Reflected power", unit = "%"},
            {label = "Delivered power", unit = "%"}
        },
        validate = function(v)
            if v[1] < 0 or v[1] >= 1 then return "Reflection magnitude must be from 0 to less than 1" end
        end,
        calculate = function(v)
            local g2 = v[1] ^ 2
            local returnLoss = v[1] == 0 and 1e99 or -20 * math.log(v[1]) / math.log(10)
            local mismatchLoss = -10 * math.log(1 - g2) / math.log(10)
            return returnLoss, mismatchLoss, 100 * g2, 100 * (1 - g2)
        end
    })

    calculators.losslessInputImpedance = Calculator.new({
        id = "losslessInputImpedance",
        title = "Input Impedance",
        subtitle = "Lossless line: Zin at distance l from load",
        inputs = {
            {label = "Load resistance", unit = "ohm"},
            {label = "Load reactance", unit = "ohm"},
            {label = "Characteristic Z0", unit = "ohm"},
            {label = "Phase constant beta", unit = "rad/m"},
            {label = "Line length l", unit = "m"}
        },
        outputs = {
            {label = "Input resistance", unit = "ohm"},
            {label = "Input reactance", unit = "ohm"},
            {label = "Input magnitude", unit = "ohm"},
            {label = "Input angle", unit = "degrees"}
        },
        validate = function(v)
            return tlRequirePositive(v[3], "Characteristic impedance") or
                tlRequirePositive(v[4], "Phase constant") or
                (v[5] < 0 and "Line length cannot be negative" or nil)
        end,
        calculate = function(v)
            local tangent = math.tan(v[4] * v[5])
            local nr, ni = v[1], v[2] + v[3] * tangent
            local zrT, ziT = cMul(v[1], v[2], 0, tangent)
            local dr, di = v[3] + zrT, ziT
            local rr, ri = cDiv(nr, ni, dr, di)
            rr, ri = v[3] * rr, v[3] * ri
            return rr, ri, cMagnitude(rr, ri), cAngleDegrees(rr, ri)
        end
    })

    calculators.quarterWaveTransformer = Calculator.new({
        id = "quarterWaveTransformer",
        title = "Quarter-Wave Transformer",
        subtitle = "Match two positive real impedances",
        inputs = {
            {label = "Source line Z0", unit = "ohm"},
            {label = "Load resistance", unit = "ohm"},
            {label = "Frequency f", unit = "Hz"},
            {label = "Wave velocity", unit = "m/s"}
        },
        outputs = {
            {label = "Transformer impedance", unit = "ohm"},
            {label = "Quarter-wave length", unit = "m"},
            {label = "Wavelength", unit = "m"}
        },
        validate = function(v)
            return tlRequirePositive(v[1], "Source impedance") or
                tlRequirePositive(v[2], "Load resistance") or
                tlRequirePositive(v[3], "Frequency") or
                tlRequirePositive(v[4], "Wave velocity")
        end,
        calculate = function(v)
            local wavelength = v[4] / v[3]
            return math.sqrt(v[1] * v[2]), wavelength / 4, wavelength
        end
    })

    calculators.electricalLength = Calculator.new({
        id = "electricalLength",
        title = "Electrical Length",
        subtitle = "Convert physical length to phase",
        inputs = {
            {label = "Line length", unit = "m"},
            {label = "Frequency f", unit = "Hz"},
            {label = "Wave velocity", unit = "m/s"}
        },
        outputs = {
            {label = "Electrical length", unit = "degrees"},
            {label = "Electrical length", unit = "rad"},
            {label = "Wavelengths"},
            {label = "Wavelength", unit = "m"}
        },
        validate = function(v)
            if v[1] < 0 then return "Line length cannot be negative" end
            return tlRequirePositive(v[2], "Frequency") or tlRequirePositive(v[3], "Wave velocity")
        end,
        calculate = function(v)
            local wavelength = v[3] / v[2]
            local cycles = v[1] / wavelength
            return 360 * cycles, 2 * math.pi * cycles, cycles, wavelength
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
