-- TI-Nspire Engineering Workspaces
-- Standalone Solve-by-Topic application kept separate from the main toolbox.

platform.apiLevel = "2.0"

local calculators = {}
registerWorkspaceMemoryCalculators(calculators)
registerTopicSolvers(calculators)
registerTransmissionTopic(calculators)
registerTwoWireLineTopic(calculators)
registerRailLauncherTopics(calculators)
registerECE216Worksheet34Topics(calculators)

local memoryMenu = {
    title="Workspace Memory",
    subtitle="Reuse stored values in workspace expressions",
    items={
        {label="Store / View A-J",calculator="workspaceMemory"},
        {label="Evaluate Stored Expression",calculator="workspaceRecall"}
    }
}

local electricalMenu = {
    title="Electrical Workspaces",
    subtitle="Enter known values and calculate related quantities",
    items={
        {label="Series RLC",calculator="topicSeriesRLC"},
        {label="Transmission Lines",calculator="topicTransmissionLine"},
        {label="Two-Wire Line Design",calculator="topicTwoWireLine"},
        {label="Coaxial Line Design",calculator="topicCoaxLine"},
        {label="Quarter-Wave Transformer",calculator="topicQuarterWave"},
        {label="Current in Dielectrics",calculator="topicDielectricCurrent"},
        {label="Faraday / Wave EMF",calculator="topicFaradayWave"},
        {label="Rail Launcher - External B",calculator="topicRailExternal"},
        {label="Rail Launcher - Self Field",calculator="topicRailSelf"}
    }
}

local rootMenu = {
    title="Engineering Workspaces",
    subtitle="Solve by Topic",
    items={
        {label="Workspace Memory",menu=memoryMenu},
        {label="Electrical",menu=electricalMenu}
    }
}

local menuStack={{menu=rootMenu,selected=1}}
local activeCalculator=nil

local function currentFrame() return menuStack[#menuStack] end
local function menuLabels(menu)
    local labels={}
    for i,item in ipairs(menu.items) do labels[i]=item.label end
    return labels
end
local function openCalculator(name)
    activeCalculator=calculators[name]
    if not activeCalculator then return false end
    activeCalculator:reset(); return true
end
local function openSelectedMenuItem()
    local frame=currentFrame(); local item=frame.menu.items[frame.selected]
    if item.menu then menuStack[#menuStack+1]={menu=item.menu,selected=1}
    elseif item.calculator then openCalculator(item.calculator) end
end

function on.paint(gc)
    if activeCalculator then activeCalculator:draw(gc)
    else local frame=currentFrame(); Menu.draw(gc,frame.menu.title,menuLabels(frame.menu),frame.selected,frame.menu.subtitle) end
end
function on.arrowKey(key)
    if activeCalculator then activeCalculator:moveField(key)
    else local frame=currentFrame(); frame.selected=Menu.move(frame.selected,#frame.menu.items,key) end
    platform.window:invalidate()
end
function on.enterKey()
    if activeCalculator then activeCalculator:enter() else openSelectedMenuItem() end
    platform.window:invalidate()
end
function on.charIn(character) if activeCalculator then activeCalculator:append(character); platform.window:invalidate() end end
function on.backspaceKey() if activeCalculator then activeCalculator:backspace(); platform.window:invalidate() end end
function on.escapeKey()
    if activeCalculator then
        if activeCalculator.page=="results" then activeCalculator.page="inputs"; activeCalculator:ensureSelectedVisible()
        else activeCalculator=nil end
    elseif #menuStack>1 then table.remove(menuStack) end
    platform.window:invalidate()
end
