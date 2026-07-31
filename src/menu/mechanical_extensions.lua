-- Register Mechanical Engineering calculators and add the root menu.

registerMechanicalCalculators(calculators)

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

local mechanicalEngineeringMenu = {
    title = "Mechanical Engineering",
    subtitle = "Statics and mechanics of materials",
    items = {
        {label="Statics",menu=staticsMenu},
        {label="Mechanics of Materials",menu=mechanicsMaterialsMenu},
        {label="Dynamics"},
        {label="Vibrations"},
        {label="Thermodynamics"},
        {label="Fluid Mechanics"}
    }
}

table.insert(rootMenu.items, #rootMenu.items, {label="Mechanical Engineering",menu=mechanicalEngineeringMenu})
