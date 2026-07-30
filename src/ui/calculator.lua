-- Generic calculator screen.

Calculator = {}
Calculator.__index = Calculator

local engineeringPrefixes = {
    [-12] = "p",
    [-9] = "n",
    [-6] = "u",
    [-3] = "m",
    [0] = "",
    [3] = "k",
    [6] = "M",
    [9] = "G",
    [12] = "T"
}

local function engineeringFormat(value)
    if value == 0 then
        return "0"
    end

    local absoluteValue = math.abs(value)
    local exponent = math.floor(math.log(absoluteValue) / math.log(10) / 3) * 3

    if exponent < -12 or exponent > 12 then
        return string.format("%.4e", value)
    end

    local scaledValue = value / (10 ^ exponent)
    return string.format("%.4g%s", scaledValue, engineeringPrefixes[exponent])
end

local function makeEmptyValues(count)
    local values = {}
    for i = 1, count do
        values[i] = ""
    end
    return values
end

function Calculator.new(definition)
    local instance = {
        title = definition.title,
        subtitle = definition.subtitle,
        inputs = definition.inputs,
        outputs = definition.outputs,
        resolveOutputs = definition.resolveOutputs,
        calculateValues = definition.calculate,
        validate = definition.validate,
        allowOneBlank = definition.allowOneBlank or false,
        selectedField = 1,
        values = makeEmptyValues(#definition.inputs),
        results = nil,
        resultOutputs = nil,
        errorMessage = nil
    }

    return setmetatable(instance, Calculator)
end

function Calculator:reset()
    self.selectedField = 1
    self.values = makeEmptyValues(#self.inputs)
    self.results = nil
    self.resultOutputs = nil
    self.errorMessage = nil
end

local function labelWithUnit(item)
    if item.unit and item.unit ~= "" then
        return item.label .. " (" .. item.unit .. ")"
    end
    return item.label
end

local function drawInputField(gc, input, text, y, selected)
    gc:setFont("sansserif", "r", 10)
    gc:drawString(labelWithUnit(input) .. ":", 20, y, "top")

    if selected then
        gc:setFont("sansserif", "b", 10)
        gc:drawString("> " .. text .. "_", 145, y, "top")
    else
        gc:drawString("  " .. text, 145, y, "top")
    end
end

local function formatOutput(output, value)
    local formatted
    if output.format then
        formatted = output.format(value)
    else
        formatted = engineeringFormat(value)
    end

    if output.unit and output.unit ~= "" then
        formatted = formatted .. " " .. output.unit
    end

    return formatted
end

function Calculator:draw(gc)
    local width = platform.window:width()
    local inputSpacing = #self.inputs > 2 and 24 or 30
    local inputStart = 60
    local outputStart = inputStart + (#self.inputs * inputSpacing) + 8

    gc:setFont("sansserif", "b", 14)
    gc:drawString(self.title, width / 2, 12, "middle")

    gc:setFont("sansserif", "r", 9)
    local defaultSubtitle = self.allowOneBlank
        and "Leave one value blank, then press Enter"
        or "Type a value, then press Enter"
    gc:drawString(self.subtitle or defaultSubtitle, width / 2, 34, "middle")

    for i, input in ipairs(self.inputs) do
        drawInputField(
            gc,
            input,
            self.values[i],
            inputStart + ((i - 1) * inputSpacing),
            self.selectedField == i
        )
    end

    if self.errorMessage then
        gc:setFont("sansserif", "b", 10)
        gc:drawString(self.errorMessage, width / 2, outputStart, "middle")
    elseif self.results then
        gc:setFont("sansserif", "b", 10)
        local outputs = self.resultOutputs or self.outputs
        for i, output in ipairs(outputs) do
            gc:drawString(
                output.label .. ": " .. formatOutput(output, self.results[i]),
                20,
                outputStart + ((i - 1) * 24),
                "top"
            )
        end
    end

    gc:setFont("sansserif", "r", 9)
    gc:drawString("Esc: back   Del: erase", width / 2, 218, "middle")
end

function Calculator:moveField(key)
    if key == "up" then
        self.selectedField = self.selectedField - 1
        if self.selectedField < 1 then
            self.selectedField = #self.inputs
        end
    elseif key == "down" then
        self.selectedField = self.selectedField + 1
        if self.selectedField > #self.inputs then
            self.selectedField = 1
        end
    end
end

local function parseValues(textValues, allowOneBlank)
    local numbers = {}
    local missing = nil
    local blankCount = 0

    for i, text in ipairs(textValues) do
        if text == "" then
            blankCount = blankCount + 1
            missing = i
            numbers[i] = nil
        else
            numbers[i] = tonumber(text)
            if numbers[i] == nil then
                return nil, nil, "Enter valid numbers"
            end
        end
    end

    if allowOneBlank then
        if blankCount ~= 1 then
            return nil, nil, "Leave exactly one value blank"
        end
    elseif blankCount > 0 then
        return nil, nil, "Complete every input"
    end

    return numbers, missing, nil
end

function Calculator:enter()
    if self.selectedField < #self.inputs then
        self.selectedField = self.selectedField + 1
        return
    end

    local numbers, missing, parseError = parseValues(self.values, self.allowOneBlank)
    if parseError then
        self.errorMessage = parseError
        self.results = nil
        self.resultOutputs = nil
        return
    end

    if self.validate then
        local errorMessage = self.validate(numbers, missing)
        if errorMessage then
            self.errorMessage = errorMessage
            self.results = nil
            self.resultOutputs = nil
            return
        end
    end

    self.results = {self.calculateValues(numbers, missing)}
    self.resultOutputs = self.resolveOutputs and self.resolveOutputs(numbers, missing) or self.outputs
    self.errorMessage = nil
end

function Calculator:append(character)
    local text = self.values[self.selectedField]
    local isDigit = character >= "0" and character <= "9"
    local isDecimal = character == "."
    local isNegative = character == "-"

    if not isDigit and not isDecimal and not isNegative then
        return
    end

    if isDecimal and string.find(text, ".", 1, true) then
        return
    end

    if isNegative and text ~= "" then
        return
    end

    self.values[self.selectedField] = text .. character
    self.results = nil
    self.resultOutputs = nil
    self.errorMessage = nil
end

function Calculator:backspace()
    local text = self.values[self.selectedField]
    self.values[self.selectedField] = string.sub(text, 1, -2)
    self.results = nil
    self.resultOutputs = nil
    self.errorMessage = nil
end
