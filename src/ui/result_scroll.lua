-- Shared scrolling for calculator result pages.
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
