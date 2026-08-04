-- Shared phasor and complex-polar operations.

phasor = {}

local function radians(degrees)
    return degrees * math.pi / 180
end

local function degrees(radiansValue)
    return radiansValue * 180 / math.pi
end

function phasor.fromPolar(magnitude, angleDegrees)
    local angle = radians(angleDegrees)
    return magnitude * math.cos(angle), magnitude * math.sin(angle)
end

function phasor.toPolar(real, imaginary)
    return math.sqrt(real * real + imaginary * imaginary), degrees(math.atan2(imaginary, real))
end

function phasor.add(ar, ai, br, bi)
    return ar + br, ai + bi
end

function phasor.subtract(ar, ai, br, bi)
    return ar - br, ai - bi
end

function phasor.multiply(ar, ai, br, bi)
    return ar * br - ai * bi, ar * bi + ai * br
end

function phasor.divide(ar, ai, br, bi)
    local denominator = br * br + bi * bi
    if denominator == 0 then error("division by zero") end
    return (ar * br + ai * bi) / denominator,
           (ai * br - ar * bi) / denominator
end

function phasor.conjugate(real, imaginary)
    return real, -imaginary
end

function phasor.reciprocal(real, imaginary)
    return phasor.divide(1, 0, real, imaginary)
end
