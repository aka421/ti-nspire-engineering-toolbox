-- Complex-number calculations for the Engineering Toolbox.
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
