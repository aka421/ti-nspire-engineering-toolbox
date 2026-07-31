-- Register Mechanical Engineering calculators and add the root menu.

registerMechanicalCalculators(calculators)
registerDynamicsCalculators(calculators)
registerVibrationCalculators(calculators)

local staticsMenu = {
    title = "Statics",
    subtitle = "Forces and moments in two dimensions",
    items = {
        {label="2D Force Resultant",calculator="forceResultant2D"},
        {label="Moment About a Point",calculator="moment2D"},
        {label="Couple Moment",calculator="coupleMoment"}
    }
}

local stressStrainMenu = {
    title = "Stress, Strain, and Deformation",
    subtitle = "Axial loading and material response",
    items = {
        {label="Normal Stress",calculator="normalStress"},
        {label="Normal Strain",calculator="normalStrain"},
        {label="Axial Deformation",calculator="axialDeformation"}
    }
}

local beamsShaftsMenu = {
    title = "Beams and Shafts",
    subtitle = "Torsion, bending, and transverse shear",
    items = {
        {label="Solid-Shaft Torsion",calculator="torsionSolidShaft"},
        {label="Beam Bending Stress",calculator="bendingStress"},
        {label="Transverse Shear Stress",calculator="transverseShear"}
    }
}

local combinedStressMenu = {
    title = "Combined Stress",
    subtitle = "Plane stress and pressure vessels",
    items = {
        {label="Thin-Wall Pressure Vessel",calculator="thinWallCylinder"},
        {label="Principal Stress / Mohr Circle",calculator="planeStressPrincipal"},
        {label="Plane Stress Transformation",calculator="stressTransformation"}
    }
}

local mechanicsMaterialsMenu = {
    title = "Mechanics of Materials",
    subtitle = "Stress, deformation, beams, and failure states",
    items = {
        {label="Stress and Strain",menu=stressStrainMenu},
        {label="Beams and Shafts",menu=beamsShaftsMenu},
        {label="Combined Stress",menu=combinedStressMenu}
    }
}

local kinematicsMenu = {
    title = "Kinematics",
    subtitle = "Translation, circular motion, and projectiles",
    items = {
        {label="Constant Acceleration",calculator="constantAcceleration"},
        {label="Velocity from Displacement",calculator="velocityDisplacement"},
        {label="Circular Motion",calculator="circularMotion"},
        {label="Projectile Motion",calculator="projectileMotion"}
    }
}

local forceEnergyMenu = {
    title = "Forces, Work, and Energy",
    subtitle = "Newton's law and energy methods",
    items = {
        {label="Newton's Second Law",calculator="newtonsSecondLaw"},
        {label="Work by Constant Force",calculator="workConstantForce"},
        {label="Kinetic Energy",calculator="kineticEnergy"},
        {label="Potential Energy",calculator="potentialEnergy"},
        {label="Spring Energy",calculator="springEnergy"},
        {label="Mechanical Power",calculator="linearPower"}
    }
}

local momentumMenu = {
    title = "Momentum and Impact",
    subtitle = "Impulse and one-dimensional collisions",
    items = {
        {label="Linear Momentum",calculator="linearMomentum"},
        {label="Impulse-Momentum",calculator="impulseMomentum"},
        {label="Perfectly Inelastic Collision",calculator="inelasticCollision"},
        {label="Collision with Restitution",calculator="restitutionCollision"}
    }
}

local rotationMenu = {
    title = "Rotation",
    subtitle = "Angular motion, torque, and inertia",
    items = {
        {label="Rotational Dynamics",calculator="rotationalDynamics"},
        {label="Parallel-Axis Theorem",calculator="parallelAxis"},
        {label="Common Moments of Inertia",calculator="inertiaCommonShapes"}
    }
}

local dynamicsMenu = {
    title = "Dynamics",
    subtitle = "Kinematics, energy, momentum, and rotation",
    items = {
        {label="Kinematics",menu=kinematicsMenu},
        {label="Forces, Work, and Energy",menu=forceEnergyMenu},
        {label="Momentum and Impact",menu=momentumMenu},
        {label="Rotation",menu=rotationMenu}
    }
}

local freeVibrationMenu = {
    title = "Free Vibration",
    subtitle = "Natural frequency and transient response",
    items = {
        {label="Natural Frequency",calculator="naturalFrequency"},
        {label="Damping Properties",calculator="dampingProperties"},
        {label="Logarithmic Decrement",calculator="logarithmicDecrement"},
        {label="Underdamped Free Response",calculator="underdampedFreeResponse"},
        {label="Simple Pendulum",calculator="pendulumFrequency"}
    }
}

local forcedVibrationMenu = {
    title = "Forced Vibration",
    subtitle = "Steady-state response and isolation",
    items = {
        {label="Harmonic Force Response",calculator="harmonicForceResponse"},
        {label="Vibration Transmissibility",calculator="vibrationTransmissibility"}
    }
}

local springSystemsMenu = {
    title = "Equivalent Springs",
    subtitle = "Combine spring stiffnesses",
    items = {
        {label="Springs in Series",calculator="springSeries"},
        {label="Springs in Parallel",calculator="springParallel"}
    }
}

local vibrationsMenu = {
    title = "Vibrations",
    subtitle = "Single-degree-of-freedom vibration tools",
    items = {
        {label="Free Vibration",menu=freeVibrationMenu},
        {label="Forced Vibration",menu=forcedVibrationMenu},
        {label="Equivalent Springs",menu=springSystemsMenu}
    }
}

local mechanicalEngineeringMenu = {
    title = "Mechanical Engineering",
    subtitle = "Statics, materials, dynamics, and vibrations",
    items = {
        {label="Statics",menu=staticsMenu},
        {label="Mechanics of Materials",menu=mechanicsMaterialsMenu},
        {label="Dynamics",menu=dynamicsMenu},
        {label="Vibrations",menu=vibrationsMenu},
        {label="Thermodynamics"},
        {label="Fluid Mechanics"}
    }
}

table.insert(rootMenu.items, #rootMenu.items, {label="Mechanical Engineering",menu=mechanicalEngineeringMenu})
