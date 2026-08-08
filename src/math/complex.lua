local complex = {}

function complex.magnitude(re, im)
    return math.sqrt(re * re + im * im)
end

return complex
