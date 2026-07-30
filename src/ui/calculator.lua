-- Generic two-input calculator screen.

Calculator = {}
Calculator.__index = Calculator

function Calculator.new(definition)
    local instance = {
        title = definition.title,
        subtitle = definition.subtitle,
        inputs = definition.inputs,
        outputs = definition.outputs,
        calculateValues = definition.calculate,
        validate = definition.validate,
        selectedField = 1,
        values = {"", ""},
        results = nil,
        errorMessage = nil
    }

    return setmetatable(instance, Calculator)
end

function Calculator:reset()
    self.selectedField = 1
    self.values = {"", ""}
    self.results = nil
    self.errorMessage = nil
end

local function drawInputField(gc, label, text, y, selected)
    gc:setFont("sansserif", "r", 11)
    gc:drawString(label .. ":", 25, y, "top")

    if selected then
        gc:setFont("sansserif", "b", 11)
        gc:drawString("> " .. text .. "_", 135, y, "top")
    else
        gc:drawString("  " .. text, 135, y, "top")
    end
end

function Calculator:draw(gc)
    local width = platform.window:width()

    gc:setFont("sansserif", "b", 14)
    gc:drawString(self.title, width / 2, 15, "middle")

    gc:setFont("sansserif", "r", 9)
    gc:drawString(self.subtitle or "Type a value, then press Enter", width / 2, 38, "middle")

    for i, input in ipairs(self.inputs) do
        drawInputField(gc, input.label, self.values[i], 65 + ((i - 1) * 30), self.selectedField == i)
    end

    if self.errorMessage then
        gc:setFont("sansserif", "b", 10)
        gc:drawString(self.errorMessage, width / 2, 130, "middle")
    elseif self.results then
        gc:setFont("sansserif", "b", 11)
        for i, output in ipairs(self.outputs) do
            local formatted = output.format and output.format(self.results[i]) or string.format("%.4f", self.results[i])
            gc:drawString(output.label .. ": " .. formatted, 25, 145 + ((i - 1) * 30), "top")
        end
    end

    gc:setFont("sansserif", "r", 9)
    gc:drawString("Esc: back   Del: erase", width / 2, 210, "middle")
end

function Calculator:moveField(key)
    if key == "up" or key == "down" then
        if self.selectedField == 1 then
            self.selectedField = 2
        else
            self.selectedField = 1
        end
    end
end

function Calculator:enter()
    if self.selectedField < #self.inputs then
        self.selectedField = self.selectedField + 1
        return
    end

    local numbers = {}
    for i, text in ipairs(self.values) do
        numbers[i] = tonumber(text)
        if numbers[i] == nil then
            self.errorMessage = "Enter two valid numbers"
            self.results = nil
            return
        end
    end

    if self.validate then
        local errorMessage = self.validate(numbers)
        if errorMessage then
            self.errorMessage = errorMessage
            self.results = nil
            return
        end
    end

    self.results = {self.calculateValues(numbers)}
    self.errorMessage = nil
end

function Calculator:append(character)
    local isDigit = character >= "0" and character <= "9"
    local isDecimal = character == "."
    local isNegative = character == "-"

    if not isDigit and not isDecimal and not isNegative then
        return
    end

    self.values[self.selectedField] = self.values[self.selectedField] .. character
    self.results = nil
    self.errorMessage = nil
end

function Calculator:backspace()
    local text = self.values[self.selectedField]
    self.values[self.selectedField] = string.sub(text, 1, -2)
    self.results = nil
    self.errorMessage = nil
end
