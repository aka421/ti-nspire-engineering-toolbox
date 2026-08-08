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
end