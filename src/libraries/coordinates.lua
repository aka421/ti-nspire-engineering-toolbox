-- Coordinate-system conversion helpers.
-- Angles are supplied in degrees.
-- Cylindrical: (rho, phi, z), where phi is measured from +x toward +y.
-- Spherical: (r, theta, phi), where theta is measured down from +z
-- and phi is measured from +x toward +y in the xy-plane.

coordinates = {}

local function radians(degrees)
    return degrees * math.pi / 180
end

local function degrees(radiansValue)
    return radiansValue * 180 / math.pi
end

local function atan2(y, x)
    if math.atan2 then return math.atan2(y, x) end
    if x > 0 then return math.atan(y / x) end
    if x < 0 and y >= 0 then return math.atan(y / x) + math.pi end
    if x < 0 and y < 0 then return math.atan(y / x) - math.pi end
    if x == 0 and y > 0 then return math.pi / 2 end
    if x == 0 and y < 0 then return -math.pi / 2 end
    return 0
end

local function normalizedAzimuth(y, x)
    local phi = degrees(atan2(y, x))
    if phi < 0 then phi = phi + 360 end
    return phi
end

function coordinates.cartesianToCylindrical(x, y, z)
    local rho = math.sqrt(x * x + y * y)
    return rho, normalizedAzimuth(y, x), z
end

function coordinates.cylindricalToCartesian(rho, phiDegrees, z)
    local phi = radians(phiDegrees)
    return rho * math.cos(phi), rho * math.sin(phi), z
end

function coordinates.cartesianToSpherical(x, y, z)
    local r = math.sqrt(x * x + y * y + z * z)
    if r == 0 then return 0, 0, 0 end
    local ratio = z / r
    if ratio > 1 then ratio = 1 elseif ratio < -1 then ratio = -1 end
    return r, degrees(math.acos(ratio)), normalizedAzimuth(y, x)
end

function coordinates.sphericalToCartesian(r, thetaDegrees, phiDegrees)
    local theta, phi = radians(thetaDegrees), radians(phiDegrees)
    local sinTheta = math.sin(theta)
    return r * sinTheta * math.cos(phi),
        r * sinTheta * math.sin(phi),
        r * math.cos(theta)
end

function coordinates.cylindricalVectorToCartesian(aRho, aPhi, aZ, phiDegrees)
    local phi = radians(phiDegrees)
    return aRho * math.cos(phi) - aPhi * math.sin(phi),
        aRho * math.sin(phi) + aPhi * math.cos(phi),
        aZ
end

function coordinates.sphericalVectorToCartesian(aR, aTheta, aPhi, thetaDegrees, phiDegrees)
    local theta, phi = radians(thetaDegrees), radians(phiDegrees)
    local sinTheta, cosTheta = math.sin(theta), math.cos(theta)
    local sinPhi, cosPhi = math.sin(phi), math.cos(phi)

    local ax = aR * sinTheta * cosPhi + aTheta * cosTheta * cosPhi - aPhi * sinPhi
    local ay = aR * sinTheta * sinPhi + aTheta * cosTheta * sinPhi + aPhi * cosPhi
    local az = aR * cosTheta - aTheta * sinTheta
    return ax, ay, az
end
