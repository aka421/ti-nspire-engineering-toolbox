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

function complex.add(aRe, aIm, bRe, bIm)
    return aRe + bRe, aIm + bIm
end

function complex.subtract(aRe, aIm, bRe, bIm)
    return aRe - bRe, aIm - bIm
end

function complex.multiply(aRe, aIm, bRe, bIm)
    local realPart = (aRe * bRe) - (aIm * bIm)
    local imaginaryPart = (aRe * bIm) + (aIm * bRe)
    return realPart, imaginaryPart
end

function complex.divide(aRe, aIm, bRe, bIm)
    local denominator = (bRe * bRe) + (bIm * bIm)
    local realPart = ((aRe * bRe) + (aIm * bIm)) / denominator
    local imaginaryPart = ((aIm * bRe) - (aRe * bIm)) / denominator
    return realPart, imaginaryPart
end
