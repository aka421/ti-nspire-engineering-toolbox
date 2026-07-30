-- Three-dimensional vector operations.

vectors = {}

function vectors.magnitude(x, y, z)
    return math.sqrt(x * x + y * y + z * z)
end

function vectors.dot(ax, ay, az, bx, by, bz)
    return ax * bx + ay * by + az * bz
end

function vectors.cross(ax, ay, az, bx, by, bz)
    return ay * bz - az * by,
        az * bx - ax * bz,
        ax * by - ay * bx
end

function vectors.unit(x, y, z)
    local magnitude = vectors.magnitude(x, y, z)
    return x / magnitude, y / magnitude, z / magnitude
end

function vectors.angleDegrees(ax, ay, az, bx, by, bz)
    local denominator = vectors.magnitude(ax, ay, az) * vectors.magnitude(bx, by, bz)
    local cosine = vectors.dot(ax, ay, az, bx, by, bz) / denominator
    -- Protect acos from floating-point values just outside [-1, 1].
    cosine = math.max(-1, math.min(1, cosine))
    return math.deg(math.acos(cosine))
end

function vectors.projection(ax, ay, az, bx, by, bz)
    local scale = vectors.dot(ax, ay, az, bx, by, bz) /
        vectors.dot(bx, by, bz, bx, by, bz)
    return scale * bx, scale * by, scale * bz
end
