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
