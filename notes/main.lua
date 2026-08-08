-- TI-Nspire Engineering Notes
-- Standalone quick-reference app for ECE 216 and ECE 250.

platform.apiLevel = "2.0"

local categories = {
    {
        title = "ECE 250 - Circuits",
        topics = {
            {title="KCL & KVL", lines={
                "KCL: sum of currents at a node = 0",
                "KVL: sum of voltages around a loop = 0",
                "Ohm: V = I R",
                "Power: P = V I = I^2 R = V^2/R",
                "Passive sign: current enters + terminal => P>0",
                "Source delivering power normally has P<0"
            }},
            {title="Nodal Analysis", lines={
                "1. Choose reference (ground) node",
                "2. Label remaining node voltages",
                "3. Write KCL at each unknown node",
                "4. Branch current: (Va-Vb)/R",
                "5. Solve simultaneous equations",
                "Voltage source to ground: node V is known",
                "Check: KCL residual should be ~0"
            }},
            {title="Supernodes", lines={
                "Use when a voltage source joins 2 unknown nodes",
                "1. Enclose source + both nodes as supernode",
                "2. Write KCL around supernode boundary",
                "3. Add voltage-source constraint",
                "Example: Va - Vb = Vs (respect polarity)",
                "Dependent source: also write control relation"
            }},
            {title="Mesh Analysis", lines={
                "1. Assign clockwise mesh currents",
                "2. Write KVL for each mesh",
                "Shared R drop in mesh 1: R(I1-I2)",
                "Shared R drop in mesh 2: R(I2-I1)",
                "Solve simultaneous equations",
                "Current source in one mesh sets that mesh current"
            }},
            {title="Supermeshes", lines={
                "Use for current source shared by two meshes",
                "1. Exclude current-source branch from KVL path",
                "2. Write KVL around outer supermesh",
                "3. Add current-source constraint",
                "Example form: I1 - I2 = Is",
                "Sign depends on source arrow direction"
            }},
            {title="Dependent Sources", lines={
                "Never turn off a dependent source",
                "Keep its controlling variable equation",
                "VCVS: v = mu*v_control",
                "VCCS: i = g*v_control",
                "CCVS: v = r*i_control",
                "CCCS: i = beta*i_control"
            }},
            {title="Thevenin & Norton", lines={
                "Vth = open-circuit terminal voltage",
                "In = short-circuit terminal current",
                "Rth = Rn = Vth/In",
                "Independent V source off => short",
                "Independent I source off => open",
                "Dependent sources stay active",
                "With dependent sources: use test source for Rth"
            }},
            {title="Source Transform", lines={
                "Vs in series with R <=> Is in parallel with R",
                "Is = Vs/R",
                "Vs = Is*R",
                "Transformation must preserve terminal behavior",
                "Keep source polarity/arrow consistent"
            }},
            {title="Capacitors & Inductors", lines={
                "Capacitor: i = C dv/dt",
                "Capacitor: v cannot change instantly",
                "DC steady state capacitor => open circuit",
                "Inductor: v = L di/dt",
                "Inductor: i cannot change instantly",
                "DC steady state inductor => short circuit",
                "Energy C: 0.5*C*v^2; L: 0.5*L*i^2"
            }},
            {title="First-Order RC/RL", lines={
                "x(t)=x(inf)+[x(0+)-x(inf)]e^(-t/tau)",
                "RC: tau = Req*C",
                "RL: tau = L/Req",
                "C continuity: vC(0+)=vC(0-)",
                "L continuity: iL(0+)=iL(0-)",
                "Find initial, final, then Req seen by storage",
                "At 5 tau response is essentially settled"
            }},
            {title="Second-Order RLC", lines={
                "Natural form: s^2 + 2 alpha s + w0^2 = 0",
                "Series RLC: alpha=R/(2L), w0=1/sqrt(LC)",
                "alpha > w0: overdamped",
                "alpha = w0: critically damped",
                "alpha < w0: underdamped",
                "wd = sqrt(w0^2-alpha^2)",
                "Use capacitor-voltage + inductor-current continuity"
            }},
            {title="AC / Phasors", lines={
                "Z_R = R",
                "Z_L = j*w*L",
                "Z_C = 1/(j*w*C) = -j/(w*C)",
                "Ohm in phasors: V = I Z",
                "Series impedances add",
                "Parallel: 1/Zeq = sum(1/Zk)",
                "Convert sinusoid to phasor before solving"
            }},
            {title="AC Power", lines={
                "Use RMS phasors for power",
                "Complex power: S = V * conj(I)",
                "S = P + jQ",
                "P = |V||I| cos(phi) [W]",
                "Q = |V||I| sin(phi) [VAR]",
                "|S| = |V||I| [VA]",
                "PF = cos(phi); lagging usually inductive"
            }}
        }
    },
    {
        title = "ECE 216 - Signals",
        topics = {
            {title="Complex Numbers", lines={
                "z = a + jb = r angle(theta)",
                "r = sqrt(a^2+b^2)",
                "theta = atan2(b,a)",
                "a = r cos(theta); b = r sin(theta)",
                "Euler: e^(j theta)=cos(theta)+j sin(theta)",
                "conj(a+jb)=a-jb",
                "|z|^2 = z*conj(z)"
            }},
            {title="Signal Basics", lines={
                "Even: x(-t)=x(t)",
                "Odd: x(-t)=-x(t)",
                "xe(t)=[x(t)+x(-t)]/2",
                "xo(t)=[x(t)-x(-t)]/2",
                "Time shift: x(t-t0) shifts right by t0",
                "Time scale: x(a t); |a|>1 compresses",
                "a<0 also reverses time"
            }},
            {title="LTI Systems", lines={
                "Linear: superposition holds",
                "Time invariant: shift input => same output shift",
                "Causal LTI: h(t)=0 for t<0",
                "BIBO stable LTI: integral |h(t)| dt < infinity",
                "Impulse response completely describes LTI system"
            }},
            {title="Convolution", lines={
                "Continuous: y(t)=integral x(tau)h(t-tau) d tau",
                "Discrete: y[n]=sum x[k]h[n-k]",
                "Graphical: flip, shift, multiply, integrate/sum",
                "x*h = h*x (commutative)",
                "x*(h1*h2)=(x*h1)*h2 (associative)",
                "x*delta = x"
            }},
            {title="Sinusoids", lines={
                "x(t)=A cos(wt+phi)",
                "f = w/(2*pi); T=1/f=2*pi/w",
                "cos(theta)=Re{e^(j theta)}",
                "sin(theta)=cos(theta-pi/2)",
                "Phase comparisons require same frequency"
            }},
            {title="Exponentials", lines={
                "e^(a t): a<0 decays, a>0 grows",
                "d/dt e^(a t) = a e^(a t)",
                "Integral e^(a t) dt = e^(a t)/a, a!=0",
                "e^(a+b)=e^a e^b",
                "ln(e^x)=x; e^(ln x)=x"
            }}
        }
    },
    {
        title = "Quick Math",
        topics = {
            {title="Trig Identities", lines={
                "sin^2(x)+cos^2(x)=1",
                "1+tan^2(x)=sec^2(x)",
                "sin(2x)=2 sin(x) cos(x)",
                "cos(2x)=cos^2(x)-sin^2(x)",
                "cos(A+B)=cosA cosB-sinA sinB",
                "sin(A+B)=sinA cosB+cosA sinB"
            }},
            {title="Common Derivatives", lines={
                "d(x^n)/dx = n*x^(n-1)",
                "d(e^x)/dx = e^x",
                "d(ln x)/dx = 1/x",
                "d(sin x)/dx = cos x",
                "d(cos x)/dx = -sin x",
                "Product: (fg)'=f'g+fg'",
                "Chain: d f(g(x))/dx=f'(g(x))*g'(x)"
            }},
            {title="Common Integrals", lines={
                "int x^n dx = x^(n+1)/(n+1), n!=-1",
                "int 1/x dx = ln|x|",
                "int e^(a x) dx = e^(a x)/a",
                "int sin x dx = -cos x",
                "int cos x dx = sin x",
                "Definite integral: F(b)-F(a)"
            }},
            {title="Prefixes", lines={
                "G giga = 10^9; M mega = 10^6",
                "k kilo = 10^3; m milli = 10^-3",
                "u micro = 10^-6; n nano = 10^-9",
                "p pico = 10^-12",
                "Always convert units before substituting"
            }}
        }
    }
}

local mode = "categories"
local categoryIndex = 1
local topicIndex = 1
local scroll = 0
local lineHeight = 20
local firstY = 55
local bottomY = 205

local function clampTopic()
    local n = #categories[categoryIndex].topics
    if topicIndex < 1 then topicIndex = n end
    if topicIndex > n then topicIndex = 1 end
end

local function drawHeader(gc, title, subtitle)
    local w = platform.window:width()
    gc:setFont("sansserif", "b", 14)
    gc:drawString(title, w/2, 12, "middle")
    gc:setFont("sansserif", "r", 8)
    gc:drawString(subtitle, w/2, 34, "middle")
end

local function drawList(gc, title, items, selected, subtitle)
    drawHeader(gc, title, subtitle)
    for i,item in ipairs(items) do
        local y = firstY + (i-1)*27
        if y <= bottomY then
            gc:setFont("sansserif", i==selected and "b" or "r", 10)
            gc:drawString((i==selected and "> " or "  ") .. item, 20, y, "top")
        end
    end
end

local function drawTopic(gc)
    local cat = categories[categoryIndex]
    local topic = cat.topics[topicIndex]
    drawHeader(gc, topic.title, cat.title .. "   Esc: back")
    local y = firstY
    gc:setFont("sansserif", "r", 9)
    for i=scroll+1,#topic.lines do
        if y > bottomY then break end
        gc:drawString(topic.lines[i], 10, y, "top")
        y = y + lineHeight
    end
    gc:setFont("sansserif", "r", 8)
    local footer = "Up/Down: scroll"
    if #topic.lines <= 8 then footer = "Left/Right: prev/next topic" end
    gc:drawString(footer, platform.window:width()/2, 225, "middle")
end

function on.paint(gc)
    if mode == "categories" then
        local names = {}
        for i,c in ipairs(categories) do names[i]=c.title end
        drawList(gc, "Engineering Notes", names, categoryIndex, "ECE 216 + ECE 250")
    elseif mode == "topics" then
        local cat = categories[categoryIndex]
        local names = {}
        for i,t in ipairs(cat.topics) do names[i]=t.title end
        drawList(gc, cat.title, names, topicIndex, "Enter: open   Esc: categories")
    else
        drawTopic(gc)
    end
end

function on.arrowKey(key)
    if mode == "categories" then
        if key == "up" then categoryIndex=categoryIndex-1 end
        if key == "down" then categoryIndex=categoryIndex+1 end
        if categoryIndex < 1 then categoryIndex=#categories end
        if categoryIndex > #categories then categoryIndex=1 end
    elseif mode == "topics" then
        if key == "up" then topicIndex=topicIndex-1 end
        if key == "down" then topicIndex=topicIndex+1 end
        clampTopic()
    else
        local lines = categories[categoryIndex].topics[topicIndex].lines
        local maxScroll = math.max(0,#lines-8)
        if key == "up" then scroll=math.max(0,scroll-1) end
        if key == "down" then scroll=math.min(maxScroll,scroll+1) end
        if key == "left" then topicIndex=topicIndex-1; clampTopic(); scroll=0 end
        if key == "right" then topicIndex=topicIndex+1; clampTopic(); scroll=0 end
    end
    platform.window:invalidate()
end

function on.enterKey()
    if mode == "categories" then
        mode="topics"; topicIndex=1
    elseif mode == "topics" then
        mode="topic"; scroll=0
    end
    platform.window:invalidate()
end

function on.escapeKey()
    if mode == "topic" then
        mode="topics"; scroll=0
    elseif mode == "topics" then
        mode="categories"; topicIndex=1
    end
    platform.window:invalidate()
end
