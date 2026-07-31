-- Replace the Three-Mesh placeholder after main.lua defines the menu.

for _, item in ipairs(equationSolversMenu.items) do
    if item.label == "Three-Mesh Solver" then
        item.calculator = "meshThree"
        break
    end
end
