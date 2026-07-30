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
